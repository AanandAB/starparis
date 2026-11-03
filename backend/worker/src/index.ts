/**
 * HTTP surface. Small by design: five things the device actually needs —
 * sign in, push, pull, a cheap head check, and a number block.
 *
 * Everything else (lists, search, pricing, PDFs, Excel) happens on the device
 * against its local database, which is why the counter keeps working when the
 * internet does not.
 */

import { Hono } from 'hono';
import { z } from 'zod';

import { error, loadSession, login, loginSchema, refreshSchema, refreshSession, revokeDevice } from './auth';
import { loadCatalogue } from './catalogue';
import {
  bulkAdjust,
  bulkAdjustSchema,
  createProduct,
  createProductSchema,
  priceBreakSchema,
  productPatchSchema,
  setPriceBreak,
  rulePatchSchema,
  updateProduct,
  updateRule,
} from './price_book';
import { verifyAccessToken } from './crypto';
import { leaseBlock } from './numbers';
import { can } from './policy';
import {
  ageingReport,
  expensesByCategory,
  tillHistory,
  vatExportCsv,
  vatSummary,
} from './reports';
import {
  createStaff,
  createStaffSchema,
  listStaff,
  updateStaff,
  updateStaffSchema,
} from './staff';
import { loadSettings, saveSettings, settingsSchema } from './settings';
import { prepareVendorJobPatch } from './vendors';
import { currentHead, pullChanges, pushMutations } from './sync';
import type { AuthContext, Env, Mutation } from './types';

type Variables = { auth: AuthContext };
const app = new Hono<{ Bindings: Env; Variables: Variables }>();

const MAX_BODY_BYTES = 262_144; // 256 KB: a full batch of 100 mutations fits easily

app.onError((err, c) => {
  console.error(JSON.stringify({ level: 'error', message: err.message }));
  return c.json(
    error('INTERNAL', 'Something went wrong on the server. Please try again.'),
    500,
  );
});

app.notFound((c) => c.json(error('NOT_FOUND', 'No such endpoint.'), 404));

// ---------------------------------------------------------------------------
// Public
// ---------------------------------------------------------------------------

app.get('/v1/health', (c) =>
  c.json({
    ok: true,
    environment: c.env.ENVIRONMENT,
    schema: 1,
    server_time: new Date().toISOString(),
  }),
);

app.post('/v1/auth/login', async (c) => {
  const tooLarge = rejectLargeBody(c.req.header('content-length'));
  if (tooLarge) return tooLarge;

  const parsed = loginSchema.safeParse(await safeJson(c));
  if (!parsed.success) {
    return c.json(error('BAD_REQUEST', 'Phone, password and device are required.'), 400);
  }

  const result = await login(c.env, parsed.data);
  return c.json(result.body, result.status as 200);
});

app.post('/v1/auth/refresh', async (c) => {
  const parsed = refreshSchema.safeParse(await safeJson(c));
  if (!parsed.success) {
    return c.json(error('BAD_REQUEST', 'refresh_token is required.'), 400);
  }
  const result = await refreshSession(c.env, parsed.data.refresh_token);
  return c.json(result.body, result.status as 200);
});

// ---------------------------------------------------------------------------
// Authenticated
// ---------------------------------------------------------------------------

app.use('/v1/*', async (c, next) => {
  const path = c.req.path;
  if (path === '/v1/health' || path.startsWith('/v1/auth/')) {
    return next();
  }

  const header = c.req.header('authorization') ?? '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : '';
  const claims = token ? await verifyAccessToken(token, c.env.JWT_SECRET) : null;
  if (!claims) {
    return c.json(error('UNAUTHORIZED', 'Sign in again.'), 401);
  }

  c.set('auth', claims);
  await next();
});

app.post('/v1/auth/logout', async (c) => {
  await revokeDevice(c.env, c.get('auth'));
  return c.json({ ok: true });
});

/**
 * The cheap poll. Returns one number, supports ETag so an unchanged answer is a
 * 304 with no body, and carries the permission version that drives revocation.
 */
app.get('/v1/head', async (c) => {
  const ctx = c.get('auth');
  const session = await loadSession(c.env, ctx);
  if (!session.ok) {
    return c.json(error(session.code, session.message), 401);
  }

  const head = await currentHead(c.env, ctx.tenantId);
  const etag = `W/"${head}-${session.permissionVersion}"`;
  if (c.req.header('if-none-match') === etag) {
    return c.body(null, 304);
  }

  return c.json(
    {
      head,
      pv: session.permissionVersion,
      min_app_version: c.env.MIN_APP_VERSION,
      server_time: new Date().toISOString(),
    },
    200,
    { ETag: etag },
  );
});

const mutationSchema = z.object({
  mutation_id: z.string().min(8),
  entity: z.string().min(1),
  row_id: z.string().min(8),
  op: z.enum(['insert', 'patch', 'delete']),
  fields: z.record(z.string(), z.unknown()).optional(),
  base_version: z.number().int().min(0),
  device_ts: z.string().min(10),
  job_id: z.string().nullable().optional(),
});

const pushSchema = z.object({
  device_id: z.string().min(8),
  mutations: z.array(mutationSchema).min(1).max(100),
});

app.post('/v1/push', async (c) => {
  const tooLarge = rejectLargeBody(c.req.header('content-length'));
  if (tooLarge) return tooLarge;

  const ctx = c.get('auth');
  const session = await loadSession(c.env, ctx);
  if (!session.ok) {
    return c.json(error(session.code, session.message), 401);
  }

  const parsed = pushSchema.safeParse(await safeJson(c));
  if (!parsed.success) {
    return c.json(error('BAD_REQUEST', 'Malformed push batch.'), 400);
  }
  if (parsed.data.device_id !== ctx.deviceId) {
    return c.json(error('DEVICE_MISMATCH', 'This token belongs to another device.'), 403);
  }

  const response = await pushMutations(
    c.env,
    ctx,
    parsed.data.mutations as unknown as Mutation[],
  );
  return c.json(response);
});

app.get('/v1/catalogue', async (c) => {
  const ctx = c.get('auth');
  const catalogue = await loadCatalogue(c.env, ctx.tenantId);
  return c.json(catalogue);
});

// --- price book editing (owner / price.edit only) -------------------------

app.patch('/v1/price-book/rules/:id', async (c) => {
  const ctx = c.get('auth');
  const session = await loadSession(c.env, ctx);
  if (!session.ok) return c.json(error(session.code, session.message), 401);

  const parsed = rulePatchSchema.safeParse(await safeJson(c));
  if (!parsed.success) {
    return c.json(error('BAD_REQUEST', 'Nothing valid to change.'), 400);
  }

  const result = await updateRule(c.env, ctx, c.req.param('id'), parsed.data);
  return c.json(result.body, result.status as 200);
});

app.post('/v1/catalogue/products', async (c) => {
  const ctx = c.get('auth');
  const session = await loadSession(c.env, ctx);
  if (!session.ok) return c.json(error(session.code, session.message), 401);

  const parsed = createProductSchema.safeParse(await safeJson(c));
  if (!parsed.success) {
    return c.json(
      error('BAD_REQUEST', parsed.error.issues[0]?.message ?? 'Check the product.'),
      400,
    );
  }

  const result = await createProduct(c.env, ctx, parsed.data);
  return c.json(result.body, result.status as 201);
});

app.post('/v1/catalogue/price-breaks', async (c) => {
  const ctx = c.get('auth');
  const session = await loadSession(c.env, ctx);
  if (!session.ok) return c.json(error(session.code, session.message), 401);

  const parsed = priceBreakSchema.safeParse(await safeJson(c));
  if (!parsed.success) {
    return c.json(
      error('BAD_REQUEST', parsed.error.issues[0]?.message ?? 'Check the price.'),
      400,
    );
  }

  const result = await setPriceBreak(c.env, ctx, parsed.data);
  return c.json(result.body, result.status as 200);
});

app.patch('/v1/price-book/products/:id', async (c) => {
  const ctx = c.get('auth');
  const session = await loadSession(c.env, ctx);
  if (!session.ok) return c.json(error(session.code, session.message), 401);

  const parsed = productPatchSchema.safeParse(await safeJson(c));
  if (!parsed.success) {
    return c.json(error('BAD_REQUEST', 'Nothing valid to change.'), 400);
  }

  const result = await updateProduct(c.env, ctx, c.req.param('id'), parsed.data);
  return c.json(result.body, result.status as 200);
});

app.post('/v1/price-book/bulk-adjust', async (c) => {
  const ctx = c.get('auth');
  const session = await loadSession(c.env, ctx);
  if (!session.ok) return c.json(error(session.code, session.message), 401);

  const parsed = bulkAdjustSchema.safeParse(await safeJson(c));
  if (!parsed.success) {
    return c.json(error('BAD_REQUEST', 'A percentage is required.'), 400);
  }

  const result = await bulkAdjust(c.env, ctx, parsed.data);
  return c.json(result.body, result.status as 200);
});

// --- reports (read-only) ---------------------------------------------------

app.get('/v1/settings', async (c) => {
  const ctx = c.get('auth');
  const session = await loadSession(c.env, ctx);
  if (!session.ok) return c.json(error(session.code, session.message), 401);

  // Everyone may read the shop's own details: documents need the name and TRN.
  return c.json(await loadSettings(c.env, ctx.tenantId));
});

app.put('/v1/settings', async (c) => {
  const ctx = c.get('auth');
  const session = await loadSession(c.env, ctx);
  if (!session.ok) return c.json(error(session.code, session.message), 401);
  if (!can(ctx.role as never, 'settings.manage')) {
    return c.json(error('PERMISSION_DENIED', 'Only an owner changes the shop settings.'), 403);
  }

  const parsed = settingsSchema.safeParse(await c.req.json().catch(() => null));
  if (!parsed.success) {
    return c.json(
      error('BAD_REQUEST', parsed.error.issues[0]?.message ?? 'Check the details.'),
      400,
    );
  }

  return c.json(await saveSettings(c.env, ctx.tenantId, ctx.userId, parsed.data));
});

app.get('/v1/staff', async (c) => {
  const ctx = c.get('auth');
  const session = await loadSession(c.env, ctx);
  if (!session.ok) return c.json(error(session.code, session.message), 401);
  if (!can(ctx.role as never, 'user.manage')) {
    return c.json(error('PERMISSION_DENIED', 'Only an owner manages staff.'), 403);
  }

  return c.json({ staff: await listStaff(c.env, ctx.tenantId) });
});

app.post('/v1/staff', async (c) => {
  const ctx = c.get('auth');
  const session = await loadSession(c.env, ctx);
  if (!session.ok) return c.json(error(session.code, session.message), 401);
  if (!can(ctx.role as never, 'user.manage')) {
    return c.json(error('PERMISSION_DENIED', 'Only an owner manages staff.'), 403);
  }

  const parsed = createStaffSchema.safeParse(await c.req.json().catch(() => null));
  if (!parsed.success) {
    return c.json(
      error('BAD_REQUEST', parsed.error.issues[0]?.message ?? 'Check the details.'),
      400,
    );
  }

  const result = await createStaff(c.env, ctx.tenantId, parsed.data);
  if (!result.ok) return c.json(error(result.code!, result.message!), 409);
  return c.json({ staff: result.staff }, 201);
});

app.patch('/v1/staff/:id', async (c) => {
  const ctx = c.get('auth');
  const session = await loadSession(c.env, ctx);
  if (!session.ok) return c.json(error(session.code, session.message), 401);
  if (!can(ctx.role as never, 'user.manage')) {
    return c.json(error('PERMISSION_DENIED', 'Only an owner manages staff.'), 403);
  }

  const parsed = updateStaffSchema.safeParse(await c.req.json().catch(() => null));
  if (!parsed.success) {
    return c.json(
      error('BAD_REQUEST', parsed.error.issues[0]?.message ?? 'Check the details.'),
      400,
    );
  }

  const result = await updateStaff(
    c.env,
    ctx.tenantId,
    ctx.userId,
    ctx.role as never,
    c.req.param('id'),
    parsed.data,
  );
  if (!result.ok) return c.json(error(result.code!, result.message!), 409);
  return c.json({ staff: result.staff });
});

app.get('/v1/reports/vat', async (c) => {
  const ctx = c.get('auth');
  const session = await loadSession(c.env, ctx);
  if (!session.ok) return c.json(error(session.code, session.message), 401);
  if (!can(ctx.role as never, 'report.view')) {
    return c.json(error('PERMISSION_DENIED', 'Reports need report.view.'), 403);
  }

  const to = c.req.query('to') ?? new Date().toISOString();
  const from = c.req.query('from') ?? to.slice(0, 8) + '01';
  // Only owner and accountant see every branch; everyone else sees their own.
  const branchId = ['owner', 'accountant'].includes(ctx.role) ? null : ctx.branchId;

  const summary = await vatSummary(c.env, ctx.tenantId, from, to, branchId);
  return c.json(summary);
});

app.get('/v1/reports/expenses', async (c) => {
  const ctx = c.get('auth');
  const session = await loadSession(c.env, ctx);
  if (!session.ok) return c.json(error(session.code, session.message), 401);
  if (!can(ctx.role as never, 'report.view')) {
    return c.json(error('PERMISSION_DENIED', 'Reports need report.view.'), 403);
  }

  const to = c.req.query('to') ?? new Date().toISOString();
  const from = c.req.query('from') ?? to.slice(0, 8) + '01';
  const branchId = ['owner', 'accountant'].includes(ctx.role) ? null : ctx.branchId;

  return c.json(await expensesByCategory(c.env, ctx.tenantId, from, to, branchId));
});

app.get('/v1/reports/tills', async (c) => {
  const ctx = c.get('auth');
  const session = await loadSession(c.env, ctx);
  if (!session.ok) return c.json(error(session.code, session.message), 401);
  if (!can(ctx.role as never, 'report.view')) {
    return c.json(error('PERMISSION_DENIED', 'Reports need report.view.'), 403);
  }

  const to = c.req.query('to') ?? new Date().toISOString();
  const from = c.req.query('from') ?? to.slice(0, 8) + '01';
  const branchId = ['owner', 'accountant'].includes(ctx.role) ? null : ctx.branchId;

  const history = await tillHistory(c.env, ctx.tenantId, from, to, branchId);
  return c.json(history);
});

app.get('/v1/reports/vat.csv', async (c) => {
  const ctx = c.get('auth');
  const session = await loadSession(c.env, ctx);
  if (!session.ok) return c.json(error(session.code, session.message), 401);
  if (!can(ctx.role as never, 'report.view')) {
    return c.json(error('PERMISSION_DENIED', 'Reports need report.view.'), 403);
  }

  const to = c.req.query('to') ?? new Date().toISOString();
  const from = c.req.query('from') ?? to.slice(0, 8) + '01';
  const branchId = ['owner', 'accountant'].includes(ctx.role) ? null : ctx.branchId;

  const csv = await vatExportCsv(c.env, ctx.tenantId, from, to, branchId);
  return new Response(csv, {
    headers: {
      'content-type': 'text/csv; charset=utf-8',
      'content-disposition': `attachment; filename="vat-${from.slice(0, 10)}-to-${to.slice(0, 10)}.csv"`,
    },
  });
});

app.get('/v1/reports/ageing', async (c) => {
  const ctx = c.get('auth');
  const session = await loadSession(c.env, ctx);
  if (!session.ok) return c.json(error(session.code, session.message), 401);
  if (!can(ctx.role as never, 'report.view')) {
    return c.json(error('PERMISSION_DENIED', 'Reports need report.view.'), 403);
  }

  const asOf = c.req.query('as_of') ?? new Date().toISOString();
  const report = await ageingReport(c.env, ctx, asOf);
  return c.json(report);
});

app.get('/v1/pull', async (c) => {
  const ctx = c.get('auth');
  const since = Number(c.req.query('since') ?? '0');
  const limit = Number(c.req.query('limit') ?? '200');

  const response = await pullChanges(
    c.env,
    ctx,
    Number.isFinite(since) ? Math.max(since, 0) : 0,
    Number.isFinite(limit) ? limit : 200,
  );
  return c.json(response);
});

/**
 * First install. Paged replay of the change log from zero: the device applies
 * rows in order, so a row touched several times converges to its latest state.
 * A snapshot-per-entity bootstrap is the optimisation for later; correctness
 * first.
 */
app.get('/v1/bootstrap', async (c) => {
  const ctx = c.get('auth');
  const page = Math.max(Number(c.req.query('page') ?? '0'), 0);
  const pageSize = 500;
  const response = await pullChanges(c.env, ctx, page * pageSize, pageSize);
  return c.json({
    ...response,
    page,
    done: response.rows.length < pageSize,
  });
});

const leaseSchema = z.object({
  series: z.string().min(3).max(32),
  size: z.number().int().min(1).max(1000).default(100),
});

app.post('/v1/number-blocks/lease', async (c) => {
  const ctx = c.get('auth');
  const parsed = leaseSchema.safeParse(await safeJson(c));
  if (!parsed.success) {
    return c.json(error('BAD_REQUEST', 'series is required.'), 400);
  }

  const block = await leaseBlock(
    c.env,
    ctx.tenantId,
    ctx.deviceId,
    parsed.data.series,
    parsed.data.size,
  );
  return c.json({ series: parsed.data.series, start: block.start, end: block.end });
});

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

async function safeJson(c: { req: { json: () => Promise<unknown> } }): Promise<unknown> {
  try {
    return await c.req.json();
  } catch {
    return {};
  }
}

function rejectLargeBody(contentLength: string | undefined): Response | null {
  if (!contentLength) return null;
  const size = Number(contentLength);
  if (Number.isFinite(size) && size > MAX_BODY_BYTES) {
    return Response.json(
      error('PAYLOAD_TOO_LARGE', 'Send at most 100 mutations per batch.'),
      { status: 413 },
    );
  }
  return null;
}

export default app;
