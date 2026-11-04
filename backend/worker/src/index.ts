/**
 * HTTP surface. Small by design: five things the device actually needs —
 * sign in, push, pull, a cheap head check, and a number block.
 *
 * Everything else (lists, search, pricing, PDFs, Excel) happens on the device
 * against its local database, which is why the counter keeps working when the
 * internet does not.
 */

import { Hono, type Context } from 'hono';
import type { RoleKey } from './policy';
import { conflictForbidden, listConflicts, resolveConflict } from './conflicts';
import { z } from 'zod';

import { error, loadSession, login, loginSchema, refreshSchema, refreshSession, revokeDevice } from './auth';
import { canReadAudit, listAudit } from './audit';
import {
  listPlatformErrors,
  listTenants,
  recordPlatformError,
  requirePlatform,
  tenantAudit,
} from './platform';
import {
  approveByToken,
  canUploadProof,
  ensureApprovalToken,
  getProofByToken,
  getProofFile,
  storeProofFile,
} from './proofs';
import { loadCatalogue } from './catalogue';
import {
  createMachine,
  createMaterial,
  createOperation,
  deleteMachine,
  deleteMaterial,
  deleteOperation,
  listMachines,
  listMaterials,
  listOperations,
  machineCreateSchema,
  machinePatchSchema,
  materialCreateSchema,
  materialPatchSchema,
  operationCreateSchema,
  operationPatchSchema,
  updateMachine,
  updateMaterial,
  updateOperation,
} from './catalogue_admin';
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
import { verifyAccessToken, fromBase64 } from './crypto';
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
  // Record the failure for the platform admin (best effort: a logging error
  // must never mask the real response or take the request down with it).
  c.executionCtx.waitUntil(
    recordPlatformError(c.env, {
      code: 'INTERNAL',
      message: err.message,
      context: { path: c.req.path, method: c.req.method },
    }).catch(() => {}),
  );
  return c.json(
    error('INTERNAL', 'Something went wrong on the server. Please try again.'),
    500,
  );
});

app.notFound((c) => c.json(error('NOT_FOUND', 'No such endpoint.'), 404));

// ---------------------------------------------------------------------------
// Platform admin — the vendor's own cross-tenant view, gated by a token that
// is unrelated to tenant logins. Read-only: a fix is a code change, never a
// data write through these routes.
// ---------------------------------------------------------------------------

app.get('/platform/tenants', async (c) => {
  if (!requirePlatform(c.env, c)) {
    return c.json(error('FORBIDDEN', 'Platform token required.'), 403);
  }
  return c.json({ tenants: await listTenants(c.env) });
});

app.get('/platform/tenants/:id/audit', async (c) => {
  if (!requirePlatform(c.env, c)) {
    return c.json(error('FORBIDDEN', 'Platform token required.'), 403);
  }
  const limit = Math.min(Number(c.req.query('limit') ?? 100), 500);
  return c.json({ entries: await tenantAudit(c.env, c.req.param('id'), limit) });
});

app.get('/platform/errors', async (c) => {
  if (!requirePlatform(c.env, c)) {
    return c.json(error('FORBIDDEN', 'Platform token required.'), 403);
  }
  const tenantId = c.req.query('tenant_id') ?? null;
  const limit = Math.min(Number(c.req.query('limit') ?? 100), 500);
  return c.json({ errors: await listPlatformErrors(c.env, tenantId, limit) });
});

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

// --- Customer approval page (no login: the token in the URL is the auth) ----
// These routes are deliberately outside /v1/auth so the customer never needs an
// account. The token is unguessable (a UUID) and single-purpose: it can only
// open one proof and, once that proof is decided, cannot decide it again.

app.get('/approve/:token', async (c) => {
  const proof = await getProofByToken(c.env, c.req.param('token'));
  if (!proof) return c.json(error('NOT_FOUND', 'This approval link is not valid.'), 404);
  return c.html(approvalPage(proof, c.req.param('token')));
});

app.post('/approve/:token', async (c) => {
  const token = c.req.param('token');
  const contentType = c.req.header('content-type') ?? '';

  // The browser form posts urlencoded; API clients and tests post JSON. Both
  // land on the same decision path, so the record is the same either way.
  let decision: unknown;
  let note: unknown;
  let deciderName: unknown;
  if (contentType.includes('application/json')) {
    const body = (await safeJson(c)) as Record<string, unknown> | null;
    decision = body?.decision;
    note = body?.note;
    deciderName = body?.decider_name;
  } else {
    const form = await c.req.parseBody();
    decision = typeof form.decision === 'string' ? form.decision : undefined;
    note = typeof form.note === 'string' ? form.note : undefined;
    deciderName = typeof form.decider_name === 'string' ? form.decider_name : undefined;
  }

  const result = await approveByToken(c.env, token, { decision, note, deciderName });
  const wantsHtml = !contentType.includes('application/json');

  if (!result.ok) {
    const status = result.code === 'NOT_FOUND' ? 404 : 400;
    if (wantsHtml) return c.html(approvalResultPage(result.message, false), status);
    return c.json(error(result.code, result.message), status);
  }
  if (wantsHtml) {
    const message =
      result.status === 'approved'
        ? 'Approved — thank you! Your approval has been recorded.'
        : 'Thanks — your change request has been recorded. The shop will send a new version.';
    return c.html(approvalResultPage(message, true));
  }
  return c.json({ ok: true, status: result.status, decided_at: result.decidedAt });
});

app.get('/approve/:token/thumbnail', async (c) => {
  const proof = await getProofByToken(c.env, c.req.param('token'));
  if (!proof || proof['thumbnail'] == null) {
    return c.json(error('NOT_FOUND', 'No preview for this proof.'), 404);
  }
  return new Response(toUint8(proof['thumbnail']), {
    headers: {
      'content-type': 'image/png',
      'cache-control': 'public, max-age=86400, immutable',
    },
  });
});

app.get('/approve/:token/file', async (c) => {
  const file = await getProofFile(c.env, c.req.param('token'));
  if (!file) return c.json(error('NOT_FOUND', 'No file for this proof.'), 404);
  return new Response(file.bytes, {
    headers: {
      'content-type': file.mimeType,
      'content-length': String(file.bytes.length),
      'cache-control': 'private, max-age=86400',
    },
  });
});

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

// --- Conflicts inbox (§5.6, §5.10) -----------------------------------------
app.get('/v1/conflicts', async (c) => {
  const auth = c.get('auth');
  if (conflictForbidden(auth.role as RoleKey)) {
    return c.json(error('FORBIDDEN', 'Only a manager or the owner can open the conflicts inbox.'), 403);
  }
  const status = c.req.query('status');
  const conflicts = await listConflicts(c.env, auth, { status });
  return c.json({ conflicts });
});

app.post('/v1/conflicts/:id/resolve', async (c) => {
  const auth = c.get('auth');
  const body = (await safeJson(c)) as { status?: string } | null;
  const status = body?.status === 'dismissed' ? 'dismissed' : 'resolved';

  const outcome = await resolveConflict(c.env, auth, c.req.param('id'), status);
  if (!outcome.ok) {
    return c.json(error(outcome.code, outcome.message), outcome.status as 400);
  }
  return c.json({ conflict: outcome.conflict });
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

// --- catalogue editing: materials, machines, operations --------------------
// The three reference tables the pricing engine reads. Same contract as the
// price book: `price.edit` to write, audited old->new, and every write bumps
// catalogue_version so the change reaches every device on its next poll.

app.get('/v1/catalogue/materials', async (c) => {
  const ctx = c.get('auth');
  return c.json({ materials: await listMaterials(c.env, ctx.tenantId) });
});

app.post('/v1/catalogue/materials', async (c) => {
  const gate = await requirePriceEdit(c);
  if (!gate.ok) return gate.response;

  const parsed = materialCreateSchema.safeParse(await safeJson(c));
  if (!parsed.success) {
    return c.json(
      error('BAD_REQUEST', parsed.error.issues[0]?.message ?? 'Check the material.'),
      400,
    );
  }
  const result = await createMaterial(c.env, gate.ctx, parsed.data);
  return c.json(result.body, result.status as 201);
});

app.patch('/v1/catalogue/materials/:id', async (c) => {
  const gate = await requirePriceEdit(c);
  if (!gate.ok) return gate.response;

  const parsed = materialPatchSchema.safeParse(await safeJson(c));
  if (!parsed.success) {
    return c.json(error('BAD_REQUEST', 'Nothing valid to change.'), 400);
  }
  const result = await updateMaterial(c.env, gate.ctx, c.req.param('id'), parsed.data);
  return c.json(result.body, result.status as 200);
});

app.delete('/v1/catalogue/materials/:id', async (c) => {
  const gate = await requirePriceEdit(c);
  if (!gate.ok) return gate.response;

  const result = await deleteMaterial(c.env, gate.ctx, c.req.param('id'));
  return c.json(result.body, result.status as 200);
});

app.get('/v1/catalogue/machines', async (c) => {
  const ctx = c.get('auth');
  return c.json({ machines: await listMachines(c.env, ctx.tenantId) });
});

app.post('/v1/catalogue/machines', async (c) => {
  const gate = await requirePriceEdit(c);
  if (!gate.ok) return gate.response;

  const parsed = machineCreateSchema.safeParse(await safeJson(c));
  if (!parsed.success) {
    return c.json(
      error('BAD_REQUEST', parsed.error.issues[0]?.message ?? 'Check the machine.'),
      400,
    );
  }
  const result = await createMachine(c.env, gate.ctx, parsed.data);
  return c.json(result.body, result.status as 201);
});

app.patch('/v1/catalogue/machines/:id', async (c) => {
  const gate = await requirePriceEdit(c);
  if (!gate.ok) return gate.response;

  const parsed = machinePatchSchema.safeParse(await safeJson(c));
  if (!parsed.success) {
    return c.json(error('BAD_REQUEST', 'Nothing valid to change.'), 400);
  }
  const result = await updateMachine(c.env, gate.ctx, c.req.param('id'), parsed.data);
  return c.json(result.body, result.status as 200);
});

app.delete('/v1/catalogue/machines/:id', async (c) => {
  const gate = await requirePriceEdit(c);
  if (!gate.ok) return gate.response;

  const result = await deleteMachine(c.env, gate.ctx, c.req.param('id'));
  return c.json(result.body, result.status as 200);
});

app.get('/v1/catalogue/operations', async (c) => {
  const ctx = c.get('auth');
  return c.json({ operations: await listOperations(c.env, ctx.tenantId) });
});

app.post('/v1/catalogue/operations', async (c) => {
  const gate = await requirePriceEdit(c);
  if (!gate.ok) return gate.response;

  const parsed = operationCreateSchema.safeParse(await safeJson(c));
  if (!parsed.success) {
    return c.json(
      error('BAD_REQUEST', parsed.error.issues[0]?.message ?? 'Check the operation.'),
      400,
    );
  }
  const result = await createOperation(c.env, gate.ctx, parsed.data);
  return c.json(result.body, result.status as 201);
});

app.patch('/v1/catalogue/operations/:id', async (c) => {
  const gate = await requirePriceEdit(c);
  if (!gate.ok) return gate.response;

  const parsed = operationPatchSchema.safeParse(await safeJson(c));
  if (!parsed.success) {
    return c.json(error('BAD_REQUEST', 'Nothing valid to change.'), 400);
  }
  const result = await updateOperation(c.env, gate.ctx, c.req.param('id'), parsed.data);
  return c.json(result.body, result.status as 200);
});

app.delete('/v1/catalogue/operations/:id', async (c) => {
  const gate = await requirePriceEdit(c);
  if (!gate.ok) return gate.response;

  const result = await deleteOperation(c.env, gate.ctx, c.req.param('id'));
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

// --- audit trail -----------------------------------------------------------
// The same gate reports use, because the people who ask "who changed this
// price" are the people who ask for the VAT return. The filters ride straight
// through to the query; only the limit is clamped, inside listAudit.
app.get('/v1/audit', async (c) => {
  const ctx = c.get('auth');
  const session = await loadSession(c.env, ctx);
  if (!session.ok) return c.json(error(session.code, session.message), 401);
  if (!canReadAudit(ctx.role)) {
    return c.json(error('FORBIDDEN', 'Only a manager or the owner can read the audit trail.'), 403);
  }

  const entries = await listAudit(c.env, ctx, {
    action: c.req.query('action'),
    from: c.req.query('from'),
    to: c.req.query('to'),
    limit: c.req.query('limit'),
  });
  return c.json(entries);
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
  // Return the *resolved* series, not the one the device asked for: the device
  // may still be on a stale settings payload, and it should print the prefix
  // the shop actually uses now.
  return c.json({ series: block.series, start: block.start, end: block.end });
});

// --- proof file upload ------------------------------------------------------
// The designer pushes the actual artwork here, chunked and base64-encoded, and
// gets back the approval link. The caller compresses before upload (the app
// keeps images at or under 600 KB); the Worker only enforces the hard caps.
const proofFileSchema = z.object({
  mime_type: z.string().min(3).max(100),
  sha256: z.string().regex(/^[0-9a-fA-F]{64}$/, 'sha256 must be 64 hex characters'),
  chunks: z.array(z.string().min(1)).min(1).max(16),
  thumbnail: z.string().optional(),
});

app.post('/v1/proofs/:id/file', async (c) => {
  const ctx = c.get('auth');
  const session = await loadSession(c.env, ctx);
  if (!session.ok) return c.json(error(session.code, session.message), 401);

  const proof = await c.env.DB.prepare(
    'SELECT * FROM proofs WHERE id = ? AND tenant_id = ? AND deleted_at IS NULL',
  )
    .bind(c.req.param('id'), ctx.tenantId)
    .first<Record<string, unknown>>();
  if (!proof) return c.json(error('NOT_FOUND', 'No such proof.'), 404);

  if (!canUploadProof(ctx, proof)) {
    return c.json(error('PERMISSION_DENIED', 'Only a designer or manager uploads a proof file.'), 403);
  }

  const parsed = proofFileSchema.safeParse(await safeJson(c));
  if (!parsed.success) {
    return c.json(
      error('BAD_REQUEST', parsed.error.issues[0]?.message ?? 'Malformed upload.'),
      400,
    );
  }
  const { mime_type, sha256, chunks, thumbnail } = parsed.data;

  let decoded: Uint8Array[];
  let thumbBytes: Uint8Array | null = null;
  try {
    decoded = chunks.map((chunk) => fromBase64(chunk));
    thumbBytes = thumbnail ? fromBase64(thumbnail) : null;
  } catch {
    return c.json(error('BAD_REQUEST', 'A chunk was not valid base64.'), 400);
  }

  const stored = await storeProofFile(c.env, proof, {
    mimeType: mime_type,
    sha256,
    chunks: decoded,
    thumbnail: thumbBytes,
  });
  if (!stored.ok) return c.json(error(stored.code, stored.message), 400);

  // The upload is also the moment the approval link exists: mint the token now
  // (idempotent with the send path) so the app can open the link immediately.
  const token = await ensureApprovalToken(c.env, proof);
  return c.json({ ok: true, approval_token: token, file_size: stored.fileSize });
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

/**
 * The gate shared by every catalogue write: the token must still be a live
 * session AND hold `price.edit`. Returns the auth context or the response to
 * hand back, so a route is one check instead of three.
 */
async function requirePriceEdit(
  c: Context<{ Bindings: Env; Variables: Variables }>,
): Promise<{ ok: true; ctx: AuthContext } | { ok: false; response: Response }> {
  const ctx = c.get('auth');
  const session = await loadSession(c.env, ctx);
  if (!session.ok) return { ok: false, response: c.json(error(session.code, session.message), 401) };
  if (!can(ctx.role as never, 'price.edit')) {
    return {
      ok: false,
      response: c.json(error('PERMISSION_DENIED', 'Only an owner changes the catalogue.'), 403),
    };
  }
  return { ok: true, ctx };
}

// --- approval page rendering ------------------------------------------------
// A small, self-contained page with no build step and no external assets, so it
// works on any phone browser. It is plain HTML with inline CSS and one native
// form; there is no JavaScript to break.

/** D1 returns BLOBs as ArrayBuffer, Uint8Array, or a plain array-like object. */
function toUint8(value: unknown): Uint8Array {
  if (value instanceof Uint8Array) return value;
  if (value instanceof ArrayBuffer) return new Uint8Array(value);
  if (Array.isArray(value)) return Uint8Array.from(value as number[]);
  if (typeof value === 'object' && value !== null && 'length' in (value as object)) {
    return Uint8Array.from(value as ArrayLike<number>);
  }
  return new Uint8Array(0);
}

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function approvalPage(proof: Record<string, unknown>, token: string): string {
  const label = escapeHtml(String(proof['label'] ?? 'Proof'));
  const revision = Number(proof['revision'] ?? 1);
  const status = String(proof['status'] ?? 'draft');
  const hasFile = Number(proof['file_size'] ?? 0) > 0;
  const url = String(proof['url'] ?? '');

  let body: string;
  if (status === 'approved' || status === 'rejected') {
    body = `<p class="note">This proof was already ${escapeHtml(status)}. If anything must change, the shop will send a new version.</p>`;
  } else if (status === 'superseded') {
    body = `<p class="note">A newer version of this proof replaced this one.</p>`;
  } else if (status !== 'sent') {
    body = `<p class="note">This proof has not been sent yet. Check back once the shop sends it.</p>`;
  } else {
    const preview =
      proof['thumbnail'] != null
        ? `<div class="preview"><img src="/approve/${encodeURIComponent(token)}/thumbnail" alt="Proof preview"></div>`
        : `<div class="preview"><div class="placeholder">No preview available</div></div>`;
    const open =
      hasFile
        ? `<p><a class="link" href="/approve/${encodeURIComponent(token)}/file" target="_blank">Open the full proof</a></p>`
        : url
          ? `<p><a class="link" href="${escapeHtml(url)}" target="_blank" rel="noopener">Open the proof</a></p>`
          : '';
    body = `${preview}${open}
<form method="post" action="/approve/${encodeURIComponent(token)}">
  <div class="actions">
    <button class="btn btn-approve" type="submit" name="decision" value="approved" formnovalidate>Approve</button>
    <label for="note">What would you like changed? <span class="hint">(only if you request changes)</span></label>
    <textarea id="note" name="note" rows="3" required placeholder="e.g. Logo too close to the trim"></textarea>
    <label for="name">Your name <span class="hint">(optional)</span></label>
    <input id="name" name="decider_name" type="text" autocomplete="name" placeholder="Your name">
    <button class="btn btn-reject" type="submit" name="decision" value="rejected">Request changes</button>
  </div>
</form>`;
  }

  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Proof v${revision} — Star Paris Graphic</title>
<style>
  :root { color-scheme: light; }
  * { box-sizing: border-box; }
  body { margin: 0; font-family: system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif; background: #f4f5f7; color: #1a1d23; line-height: 1.5; }
  .wrap { max-width: 560px; margin: 0 auto; padding: 24px 16px 48px; }
  .brand { font-size: 13px; letter-spacing: .08em; text-transform: uppercase; color: #6b7280; }
  h1 { font-size: 22px; margin: 8px 0 4px; }
  .sub { color: #6b7280; margin: 0 0 20px; }
  .preview { background: #fff; border: 1px solid #e5e7eb; border-radius: 12px; overflow: hidden; margin-bottom: 20px; }
  .preview img { display: block; width: 100%; height: auto; }
  .placeholder { padding: 56px 16px; text-align: center; color: #9ca3af; font-size: 14px; }
  .actions { display: flex; flex-direction: column; gap: 12px; }
  .btn { display: block; width: 100%; padding: 16px; border: 0; border-radius: 12px; font-size: 17px; font-weight: 600; cursor: pointer; }
  .btn-approve { background: #16a34a; color: #fff; }
  .btn-reject { background: #fff; color: #b91c1c; border: 1px solid #fca5a5; }
  label { font-size: 14px; color: #374151; }
  .hint { color: #9ca3af; font-weight: 400; }
  textarea, input { width: 100%; padding: 12px; border: 1px solid #d1d5db; border-radius: 10px; font: inherit; }
  .note { background: #fff7ed; border: 1px solid #fdba74; color: #9a3412; border-radius: 10px; padding: 12px 14px; font-size: 14px; }
  .link { color: #2563eb; word-break: break-all; }
</style>
</head>
<body>
<div class="wrap">
  <div class="brand">Star Paris Graphic</div>
  <h1>You have a proof to review</h1>
  <p class="sub">${label} · v${revision}</p>
  ${body}
</div>
</body>
</html>`;
}

/** The confirmation or error shown after a customer submits a decision. */
function approvalResultPage(message: string, ok: boolean): string {
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Star Paris Graphic</title>
<style>
  body { margin: 0; font-family: system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif; background: #f4f5f7; color: #1a1d23; display: grid; place-items: center; min-height: 100vh; }
  .card { max-width: 420px; margin: 16px; padding: 28px; background: #fff; border: 1px solid #e5e7eb; border-radius: 14px; text-align: center; }
  .ok { color: #16a34a; font-size: 15px; margin: 0; }
  .bad { color: #b91c1c; font-size: 15px; margin: 0; }
  a { color: #2563eb; font-size: 14px; }
</style>
</head>
<body>
<div class="card">
  <p class="${ok ? 'ok' : 'bad'}">${escapeHtml(message)}</p>
  ${ok ? '' : '<p><a href="#" onclick="history.back(); return false;">Go back</a></p>'}
</div>
</body>
</html>`;
}

export default app;
