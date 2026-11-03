/**
 * Integration tests for the sync API.
 *
 * These run inside workerd against a real D1 database with the real
 * migrations — the same engine as production. Every test that says "rejected"
 * is asserting a security rule, so a regression here is a security regression.
 */

import { SELF, env } from 'cloudflare:test';
import { beforeAll, describe, expect, it } from 'vitest';

import { hashPassword } from '../src/crypto';

const TENANT = '0193f0b1-0000-7000-8000-000000000001';
const BRANCH_SHJ = '0193f0b1-0000-7000-8000-0000000000b1';
const BRANCH_DXB = '0193f0b1-0000-7000-8000-0000000000b2';
const ROLE_OWNER = '0193f0b1-0000-7000-8000-0000000000c1';
const ROLE_COUNTER = '0193f0b1-0000-7000-8000-0000000000c2';
const ROLE_DESIGNER = '0193f0b1-0000-7000-8000-0000000000c3';
const USER_OWNER = '0193f0b1-0000-7000-8000-0000000000d1';
const USER_COUNTER = '0193f0b1-0000-7000-8000-0000000000d2';
const USER_DESIGNER = '0193f0b1-0000-7000-8000-0000000000d3';

const PASSWORD = 'counter-pass-123';

interface Session {
  access_token: string;
  device_id: string;
  refresh_token: string;
}

let owner: Session;
let counter: Session;
let designer: Session;

async function api(path: string, init: RequestInit = {}): Promise<Response> {
  return SELF.fetch(`https://api.test${path}`, init);
}

function authed(token: string, body?: unknown): RequestInit {
  return {
    method: body === undefined ? 'GET' : 'POST',
    headers: {
      authorization: `Bearer ${token}`,
      'content-type': 'application/json',
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  };
}

function patchRequest(token: string, body: unknown): RequestInit {
  return {
    method: 'PATCH',
    headers: {
      authorization: `Bearer ${token}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify(body),
  };
}

async function loginAs(phone: string, deviceName: string): Promise<Session> {
  const response = await api('/v1/auth/login', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      phone,
      password: PASSWORD,
      device: { name: deviceName, platform: 'windows', app_version: '0.1.0' },
    }),
  });
  expect(response.status).toBe(200);
  return (await response.json()) as Session;
}

function mutation(overrides: Record<string, unknown>): Record<string, unknown> {
  return {
    entity: 'customers',
    op: 'insert',
    base_version: 0,
    device_ts: new Date().toISOString(),
    fields: { name: 'Ahmed Traders', tier: 'retail' },
    ...overrides,
  };
}

beforeAll(async () => {
  const passwordHash = await hashPassword(PASSWORD, 1000);
  const now = new Date().toISOString();

  await env.DB.batch([
    env.DB.prepare('INSERT INTO tenants (id, name, created_at, updated_at) VALUES (?, ?, ?, ?)')
      .bind(TENANT, 'Star Paris Graphic LLC', now, now),

    env.DB.prepare(
      'INSERT INTO branches (id, tenant_id, code, name, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)',
    ).bind(BRANCH_SHJ, TENANT, 'SHJ1', 'Sharjah — Industrial Area', now, now),

    env.DB.prepare(
      'INSERT INTO branches (id, tenant_id, code, name, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)',
    ).bind(BRANCH_DXB, TENANT, 'DXB1', 'Dubai — Deira', now, now),

    env.DB.prepare(
      'INSERT INTO roles (id, tenant_id, role_key, name, is_system, created_at, updated_at) VALUES (?, ?, ?, ?, 1, ?, ?)',
    ).bind(ROLE_OWNER, TENANT, 'owner', 'Owner', now, now),

    env.DB.prepare(
      'INSERT INTO roles (id, tenant_id, role_key, name, is_system, created_at, updated_at) VALUES (?, ?, ?, ?, 1, ?, ?)',
    ).bind(ROLE_COUNTER, TENANT, 'counter', 'Counter', now, now),

    env.DB.prepare(
      'INSERT INTO roles (id, tenant_id, role_key, name, is_system, created_at, updated_at) VALUES (?, ?, ?, ?, 1, ?, ?)',
    ).bind(ROLE_DESIGNER, TENANT, 'designer', 'Designer', now, now),

    env.DB.prepare(
      `INSERT INTO users (id, tenant_id, branch_id, role_id, name, phone_e164, password_hash, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    ).bind(USER_OWNER, TENANT, BRANCH_SHJ, ROLE_OWNER, 'Owner', '+971500000001', passwordHash, now, now),

    env.DB.prepare(
      `INSERT INTO users (id, tenant_id, branch_id, role_id, name, phone_e164, password_hash, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    ).bind(USER_COUNTER, TENANT, BRANCH_SHJ, ROLE_COUNTER, 'Counter', '+971500000002', passwordHash, now, now),

    env.DB.prepare(
      `INSERT INTO users (id, tenant_id, branch_id, role_id, name, phone_e164, password_hash, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    ).bind(USER_DESIGNER, TENANT, BRANCH_SHJ, ROLE_DESIGNER, 'Designer', '+971500000003', passwordHash, now, now),

    // --- catalogue -----------------------------------------------------
    env.DB.prepare(
      `INSERT INTO products (id, tenant_id, code, name_en, kind, pricing_mode,
                             sheet_width_mm, sheet_height_mm, material_code, print_rate_fils,
                             markup_bps, sizes_json, finishes_json, quantity_presets_json,
                             created_at, updated_at)
       VALUES (?, ?, ?, ?, 'sheet', 'cost_plus', 320, 450, 'art_card_350', 35, 6500,
               ?, ?, ?, ?, ?)`,
    ).bind(
      'prod_cards',
      TENANT,
      'business_cards',
      'Business cards',
      '[{"code":"90x55","label":"90 × 55 mm","width_mm":90,"height_mm":55}]',
      '[{"code":"matt_lamination","label":"Matt lamination"}]',
      '[100,250,500,1000]',
      now,
      now,
    ),

    env.DB.prepare(
      `INSERT INTO materials (id, tenant_id, code, name, type, gsm, sheet_width_mm, sheet_height_mm,
                              cost_per_sheet_fils, created_at, updated_at)
       VALUES (?, ?, ?, ?, 'card', 350, 320, 450, 60, ?, ?)`,
    ).bind('mat_art_card_350', TENANT, 'art_card_350', 'Art card 350 gsm', now, now),

    env.DB.prepare(
      `INSERT INTO price_rules (id, tenant_id, price_book_version, product_id, label, phase, basis,
                                rate_fils, min_charge_fils, priority, when_json, created_at, updated_at)
       VALUES (?, ?, 1, NULL, ?, 'finishing', 'per_sheet', 80, 0, 40, ?, ?, ?)`,
    ).bind(
      'rule_lamination_matt',
      TENANT,
      'Matt lamination (both sides)',
      '[{"field":"finish","op":"contains","value":"matt_lamination"}]',
      now,
      now,
    ),
  ]);

  owner = await loginAs('+971500000001', 'Owner PC');
  counter = await loginAs('+971500000002', 'Counter PC');
  designer = await loginAs('+971500000003', 'Designer Laptop');
});

describe('health', () => {
  it('reports the environment without authentication', async () => {
    const response = await api('/v1/health');
    expect(response.status).toBe(200);
    const body = (await response.json()) as { ok: boolean };
    expect(body.ok).toBe(true);
  });
});

describe('authentication', () => {
  it('rejects a wrong password', async () => {
    const response = await api('/v1/auth/login', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        phone: '+971500000002',
        password: 'not-the-password',
        device: { name: 'Test', platform: 'windows' },
      }),
    });
    expect(response.status).toBe(401);
    const body = (await response.json()) as { error: { code: string } };
    expect(body.error.code).toBe('INVALID_CREDENTIALS');
  });

  it('issues a token bound to a device, with the role matrix', async () => {
    const response = await api('/v1/auth/login', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        phone: '971500000002',
        password: PASSWORD,
        device: { name: 'Second counter PC', platform: 'windows' },
      }),
    });
    expect(response.status).toBe(200);
    const body = (await response.json()) as {
      user: { role: string };
      permissions: Record<string, string>;
      device_id: string;
    };
    expect(body.user.role).toBe('counter');
    expect(body.device_id).toBeTruthy();
    // The counter may sell, but never sees cost or edits prices.
    expect(body.permissions['order.create']).toBe('branch');
    expect(body.permissions['cost.view']).toBeUndefined();
    expect(body.permissions['price.edit']).toBeUndefined();
  });

  it('refuses a request without a token', async () => {
    const response = await api('/v1/head');
    expect(response.status).toBe(401);
  });
});

describe('head', () => {
  it('returns a number and supports ETag revalidation', async () => {
    const first = await api('/v1/head', authed(counter.access_token));
    expect(first.status).toBe(200);
    const body = (await first.json()) as { head: number; pv: number };
    expect(typeof body.head).toBe('number');
    expect(body.pv).toBe(1);

    const etag = first.headers.get('etag');
    expect(etag).toBeTruthy();

    const second = await api('/v1/head', {
      method: 'GET',
      headers: {
        authorization: `Bearer ${counter.access_token}`,
        'if-none-match': etag!,
      },
    });
    expect(second.status).toBe(304);
  });
});

describe('push and pull', () => {
  const customerId = '0193f0b1-0000-7000-8000-0000000000e1';
  const mutationId = 'm-0193f0b1-0000-7000-8000-0000000000e1';

  it('applies an insert and records it in the change log', async () => {
    const response = await api(
      '/v1/push',
      authed(counter.access_token, {
        device_id: counter.device_id,
        mutations: [
          mutation({
            mutation_id: mutationId,
            row_id: customerId,
            fields: { name: 'Ahmed Traders', company: 'Ahmed Traders LLC', tier: 'retail' },
          }),
        ],
      }),
    );

    expect(response.status).toBe(200);
    const body = (await response.json()) as {
      head: number;
      results: Array<{ status: string; server_version: number; row: { branch_id: string } }>;
    };
    expect(body.results[0]!.status).toBe('applied');
    expect(body.results[0]!.server_version).toBe(1);
    // The branch is taken from the token, not from the client.
    expect(body.results[0]!.row.branch_id).toBe(BRANCH_SHJ);
    expect(body.head).toBeGreaterThan(0);
  });

  it('is idempotent: replaying the same mutation changes nothing', async () => {
    const before = (await (await api('/v1/head', authed(counter.access_token))).json()) as {
      head: number;
    };

    const response = await api(
      '/v1/push',
      authed(counter.access_token, {
        device_id: counter.device_id,
        mutations: [mutation({ mutation_id: mutationId, row_id: customerId })],
      }),
    );
    const body = (await response.json()) as { head: number; results: Array<{ status: string }> };

    expect(body.results[0]!.status).toBe('duplicate');
    expect(body.head).toBe(before.head);
  });

  it('pulls the row back with its data intact', async () => {
    const response = await api('/v1/pull?since=0&limit=100', authed(counter.access_token));
    expect(response.status).toBe(200);
    const body = (await response.json()) as {
      rows: Array<{ entity: string; row_id: string; data: { name: string } }>;
      next_cursor: number;
    };
    const row = body.rows.find((candidate) => candidate.row_id === customerId);
    expect(row).toBeDefined();
    expect(row!.data.name).toBe('Ahmed Traders');
    expect(body.next_cursor).toBeGreaterThan(0);
  });

  it('merges a stale patch on a mergeable entity and files a conflict', async () => {
    const response = await api(
      '/v1/push',
      authed(counter.access_token, {
        device_id: counter.device_id,
        mutations: [
          mutation({
            mutation_id: 'm-0193f0b1-0000-7000-8000-0000000000e2',
            row_id: customerId,
            op: 'patch',
            base_version: 99, // deliberately stale
            fields: { notes: 'Called to confirm the proof.' },
          }),
        ],
      }),
    );

    const body = (await response.json()) as {
      results: Array<{ status: string; server_version: number }>;
    };
    expect(body.results[0]!.status).toBe('merged');
    expect(body.results[0]!.server_version).toBe(2);

    const conflicts = await env.DB.prepare(
      'SELECT COUNT(*) AS total FROM conflicts WHERE row_id = ?',
    )
      .bind(customerId)
      .first<{ total: number }>();
    expect(Number(conflicts!.total)).toBe(1);
  });

  it('refuses an unknown field instead of silently ignoring it', async () => {
    const response = await api(
      '/v1/push',
      authed(counter.access_token, {
        device_id: counter.device_id,
        mutations: [
          mutation({
            mutation_id: 'm-0193f0b1-0000-7000-8000-0000000000e3',
            row_id: customerId,
            op: 'patch',
            base_version: 2,
            fields: { credit_limit_fils_typo: 100 },
          }),
        ],
      }),
    );
    const body = (await response.json()) as { results: Array<{ status: string; error: { code: string } }> };
    expect(body.results[0]!.status).toBe('rejected');
    expect(body.results[0]!.error.code).toBe('UNKNOWN_FIELD');
  });

  it('accepts a phone number row for a table without a branch column', async () => {
    const response = await api(
      '/v1/push',
      authed(counter.access_token, {
        device_id: counter.device_id,
        mutations: [
          mutation({
            mutation_id: 'm-phone-1',
            entity: 'customer_phones',
            row_id: '0193f0b1-0000-7000-8000-0000000000e9',
            fields: {
              customer_id: customerId,
              e164: '+971501234567',
              phone_last9: '501234567',
              is_primary: 1,
            },
          }),
        ],
      }),
    );
    const body = (await response.json()) as {
      results: Array<{ status: string; error?: { code: string; message: string } }>;
    };
    expect(body.results[0]!.error?.message ?? '').toBe('');
    expect(body.results[0]!.status).toBe('applied');
  });

  it('rejects a device that is not the token holder', async () => {
    const response = await api(
      '/v1/push',
      authed(counter.access_token, {
        device_id: 'some-other-device-id',
        mutations: [mutation({ mutation_id: 'm-00000000-0000-7000-8000-000000000000', row_id: customerId })],
      }),
    );
    expect(response.status).toBe(403);
  });
});

describe('permissions', () => {
  it('stops a designer creating a customer', async () => {
    const response = await api(
      '/v1/push',
      authed(designer.access_token, {
        device_id: designer.device_id,
        mutations: [
          mutation({
            mutation_id: 'm-0193f0b1-0000-7000-8000-0000000000f1',
            row_id: '0193f0b1-0000-7000-8000-0000000000f2',
            fields: { name: 'Should Not Exist' },
          }),
        ],
      }),
    );
    const body = (await response.json()) as {
      results: Array<{ status: string; error: { code: string } }>;
    };
    expect(body.results[0]!.status).toBe('rejected');
    expect(body.results[0]!.error.code).toBe('PERMISSION_DENIED');
  });

  it('hides another branch from a counter clerk', async () => {
    // The owner creates a Dubai customer.
    const dubaiCustomer = '0193f0b1-0000-7000-8000-0000000000f3';
    const push = await api(
      '/v1/push',
      authed(owner.access_token, {
        device_id: owner.device_id,
        mutations: [
          mutation({
            mutation_id: 'm-0193f0b1-0000-7000-8000-0000000000f4',
            row_id: dubaiCustomer,
            fields: { name: 'Dubai Only Customer', branch_id: BRANCH_DXB },
          }),
        ],
      }),
    );
    expect(push.status).toBe(200);

    const pull = await api('/v1/pull?since=0&limit=200', authed(counter.access_token));
    const body = (await pull.json()) as { rows: Array<{ row_id: string }> };
    expect(body.rows.some((row) => row.row_id === dubaiCustomer)).toBe(false);

    // …and the owner does see it.
    const ownerPull = await api('/v1/pull?since=0&limit=200', authed(owner.access_token));
    const ownerBody = (await ownerPull.json()) as { rows: Array<{ row_id: string }> };
    expect(ownerBody.rows.some((row) => row.row_id === dubaiCustomer)).toBe(true);
  });
});

describe('catalogue', () => {
  it('returns the products, materials, rules and VAT rate', async () => {
    const response = await api('/v1/catalogue', authed(counter.access_token));
    expect(response.status).toBe(200);
    const body = (await response.json()) as {
      price_book_version: number;
      products: Array<{ code: string; kind: string }>;
      materials: Array<{ code: string; cost_per_sheet_fils: number }>;
      rules: Array<{ label: string; basis: string; rate_fils: number }>;
      tax: { vat_bps: number };
    };

    expect(body.price_book_version).toBe(1);
    expect(body.tax.vat_bps).toBe(500);
    expect(body.products.map((product) => product.code)).toContain('business_cards');
    expect(body.materials[0]!.cost_per_sheet_fils).toBe(60);
    expect(body.rules.some((rule) => rule.label === 'Matt lamination (both sides)')).toBe(true);
  });
});

describe('orders', () => {
  const orderId = '0193f0b1-0000-7000-8000-0000000000aa';
  const itemId = '0193f0b1-0000-7000-8000-0000000000ab';

  it('accepts an order and its item from the counter', async () => {
    const response = await api(
      '/v1/push',
      authed(counter.access_token, {
        device_id: counter.device_id,
        mutations: [
          mutation({
            mutation_id: 'm-order-1',
            entity: 'orders',
            row_id: orderId,
            fields: {
              'number': 10452,
              'number_display': '10452',
              'customer_id': '0193f0b1-0000-7000-8000-0000000000e1',
              'customer_name': 'Ahmed Traders',
              'status': 'confirmed',
              'priority': 'normal',
              'subtotal_fils': 12200,
              'vat_fils': 610,
              'total_fils': 12810,
              'item_count': 1,
            },
          }),
          mutation({
            mutation_id: 'm-order-item-1',
            entity: 'order_items',
            row_id: itemId,
            fields: {
              'order_id': orderId,
              'product_id': 'prod_cards',
              'description': 'Business cards · 500 · 90×55 · matt',
              'options_json': '{"quantity":500}',
              'quantity': 500,
              'price_book_version': 1,
              'breakdown_json': '{"total_fils":12200,"vat_fils":610,"grand_total_fils":12810}',
              'subtotal_fils': 12200,
              'vat_fils': 610,
              'total_fils': 12810,
            },
          }),
        ],
      }),
    );

    const body = (await response.json()) as { results: Array<{ status: string }> };
    expect(body.results.map((result) => result.status)).toEqual(['applied', 'applied']);
  });

  it('pulls the order back with its branch assigned by the server', async () => {
    const response = await api('/v1/pull?since=0&limit=200', authed(counter.access_token));
    const body = (await response.json()) as {
      rows: Array<{ entity: string; row_id: string; data: { branch_id: string } }>;
    };
    const order = body.rows.find((row) => row.entity === 'orders' && row.row_id === orderId);
    expect(order).toBeDefined();
    expect(order!.data.branch_id).toBe(BRANCH_SHJ);
  });

  it('refuses an order missing its display number', async () => {
    const response = await api(
      '/v1/push',
      authed(counter.access_token, {
        device_id: counter.device_id,
        mutations: [
          mutation({
            mutation_id: 'm-order-bad',
            entity: 'orders',
            row_id: '0193f0b1-0000-7000-8000-0000000000ac',
            fields: {
              'customer_id': '0193f0b1-0000-7000-8000-0000000000e1',
            },
          }),
        ],
      }),
    );
    const body = (await response.json()) as {
      results: Array<{ status: string; error: { code: string } }>;
    };
    expect(body.results[0]!.status).toBe('rejected');
    expect(body.results[0]!.error.code).toBe('MISSING_FIELD');
  });
});

describe('tasks', () => {
  const designTask = '0193f0b1-0000-7000-8000-0000000000ba';
  const printTask = '0193f0b1-0000-7000-8000-0000000000bb';
  const ORDER = '0193f0b1-0000-7000-8000-0000000000aa';

  async function taskRow(id: string): Promise<Record<string, unknown>> {
    return (await env.DB.prepare('SELECT * FROM tasks WHERE id = ?').bind(id).first()) as Record<
      string,
      unknown
    >;
  }

  async function pushTask(
    session: Session,
    id: string,
    status: string,
    baseVersion: number,
    extra: Record<string, unknown> = {},
  ) {
    const response = await api(
      '/v1/push',
      authed(session.access_token, {
        device_id: session.device_id,
        mutations: [
          mutation({
            mutation_id: `m-${id}-${status}-${baseVersion}`,
            entity: 'tasks',
            op: 'patch',
            row_id: id,
            base_version: baseVersion,
            fields: { status, ...extra },
          }),
        ],
      }),
    );
    return (await response.json()) as {
      results: Array<{ status: string; error?: { code: string }; row?: Record<string, unknown> }>;
    };
  }

  it('takes the stage tasks that the device generated', async () => {
    const response = await api(
      '/v1/push',
      authed(designer.access_token, {
        device_id: designer.device_id,
        mutations: [
          mutation({
            mutation_id: 'm-task-design',
            entity: 'tasks',
            row_id: designTask,
            fields: {
              order_id: ORDER,
              stage_key: 'design',
              stage_name: 'Design',
              sequence: 10,
              title: '10452 - Ahmed Traders - Design',
              status: 'available',
              required_role: 'designer',
              qty: 500,
              priority: 'normal',
            },
          }),
          mutation({
            mutation_id: 'm-task-print',
            entity: 'tasks',
            row_id: printTask,
            fields: {
              order_id: ORDER,
              stage_key: 'print',
              stage_name: 'Print',
              sequence: 20,
              title: '10452 - Ahmed Traders - Print',
              status: 'waiting',
              required_role: 'operator',
              qty: 500,
              priority: 'normal',
            },
          }),
        ],
      }),
    );
    const body = (await response.json()) as { results: Array<{ status: string }> };
    expect(body.results.map((result) => result.status)).toEqual(['applied', 'applied']);

    const design = await taskRow(designTask);
    expect(design['branch_id']).toBe(BRANCH_SHJ);
    expect(design['version']).toBe(1);
  });

  it('refuses a jump from waiting straight to done', async () => {
    const body = await pushTask(designer, printTask, 'done', 1);
    expect(body.results[0]!.status).toBe('rejected');
    expect(body.results[0]!.error!.code).toBe('ILLEGAL_TRANSITION');
    expect((await taskRow(printTask))['status']).toBe('waiting');
  });

  it('lets the designer claim and start their own task', async () => {
    const claim = await pushTask(designer, designTask, 'assigned', 1);
    expect(claim.results[0]!.status).toBe('applied');
    expect((await taskRow(designTask))['assigned_to']).toBe(USER_DESIGNER);

    const start = await pushTask(designer, designTask, 'in_progress', 2);
    expect(start.results[0]!.status).toBe('applied');

    const row = await taskRow(designTask);
    expect(row['started_at']).toBeTruthy();
  });

  it('needs a reason to pause', async () => {
    const body = await pushTask(designer, designTask, 'paused', 3);
    expect(body.results[0]!.status).toBe('rejected');
    expect(body.results[0]!.error!.code).toBe('REASON_REQUIRED');

    const withReason = await pushTask(designer, designTask, 'paused', 3, {
      reason: 'Waiting for the customer to send the logo',
    });
    expect(withReason.results[0]!.status).toBe('applied');

    const back = await pushTask(designer, designTask, 'in_progress', 4);
    expect(back.results[0]!.status).toBe('applied');
  });

  it('finishing a stage opens the next one on the server too', async () => {
    const body = await pushTask(designer, designTask, 'done', 5);
    expect(body.results[0]!.status).toBe('applied');

    const design = await taskRow(designTask);
    expect(design['done_at']).toBeTruthy();

    const print = await taskRow(printTask);
    expect(print['status']).toBe('available');
    expect(print['version']).toBe(2);
  });

  it('does not let a designer cancel work', async () => {
    const print = await taskRow(printTask);
    const body = await pushTask(
      designer,
      printTask,
      'cancelled',
      Number(print['version']),
      { reason: 'not needed' },
    );
    expect(body.results[0]!.status).toBe('rejected');
    expect(body.results[0]!.error!.code).toBe('PERMISSION_DENIED');
  });

  it('lets a manager cancel work, with the reason kept', async () => {
    const print = await taskRow(printTask);
    const body = await pushTask(
      owner,
      printTask,
      'cancelled',
      Number(print['version']),
      { reason: 'Customer cancelled the job' },
    );
    expect(body.results[0]!.status).toBe('applied');

    const row = await taskRow(printTask);
    expect(row['status']).toBe('cancelled');
    expect(row['reason']).toBe('Customer cancelled the job');

    const events = await env.DB.prepare(
      'SELECT * FROM task_events WHERE task_id = ? ORDER BY created_at',
    )
      .bind(printTask)
      .all<{ to_status: string }>();
    expect(events.results.map((event) => event.to_status)).toContain('cancelled');
  });
});

describe('proofs', () => {
  const proofId = '0193f0b1-0000-7000-8000-0000000000ca';
  const ORDER = '0193f0b1-0000-7000-8000-0000000000aa';

  async function proofRow(): Promise<Record<string, unknown>> {
    return (await env.DB.prepare('SELECT * FROM proofs WHERE id = ?').bind(proofId).first()) as Record<
      string,
      unknown
    >;
  }

  async function pushProof(
    session: Session,
    status: string,
    baseVersion: number,
    extra: Record<string, unknown> = {},
  ) {
    const response = await api(
      '/v1/push',
      authed(session.access_token, {
        device_id: session.device_id,
        mutations: [
          mutation({
            mutation_id: `m-proof-${status}-${baseVersion}-${Math.random().toString(36).slice(2, 8)}`,
            entity: 'proofs',
            op: 'patch',
            row_id: proofId,
            base_version: baseVersion,
            fields: { status, ...extra },
          }),
        ],
      }),
    );
    return (await response.json()) as {
      results: Array<{ status: string; error?: { code: string } }>;
    };
  }

  it('takes a proof link from the counter', async () => {
    const response = await api(
      '/v1/push',
      authed(counter.access_token, {
        device_id: counter.device_id,
        mutations: [
          mutation({
            mutation_id: 'm-proof-1',
            entity: 'proofs',
            row_id: proofId,
            fields: {
              order_id: ORDER,
              revision: 1,
              kind: 'proof',
              label: 'Business cards front',
              url: 'https://drive.example/proof-10452-v1.pdf',
              note: 'Sent on WhatsApp as well',
            },
          }),
        ],
      }),
    );
    const body = (await response.json()) as { results: Array<{ status: string }> };
    expect(body.results[0]!.status).toBe('applied');
    expect((await proofRow())['revision']).toBe(1);
  });

  it('will not let a draft be approved before it was sent', async () => {
    const body = await pushProof(counter, 'approved', 1);
    expect(body.results[0]!.status).toBe('rejected');
    expect(body.results[0]!.error!.code).toBe('ILLEGAL_TRANSITION');
  });

  it('records the send, then the rejection and its reason', async () => {
    const sent = await pushProof(counter, 'sent', 1);
    expect(sent.results[0]!.status).toBe('applied');
    expect((await proofRow())['sent_at']).toBeTruthy();

    const noNote = await pushProof(counter, 'rejected', 2);
    expect(noNote.results[0]!.status).toBe('rejected');
    expect(noNote.results[0]!.error!.code).toBe('NOTE_REQUIRED');

    const rejected = await pushProof(counter, 'rejected', 2, {
      decided_note: 'Logo is too close to the trim on the back',
    });
    expect(rejected.results[0]!.status).toBe('applied');

    const row = await proofRow();
    expect(row['status']).toBe('rejected');
    expect(row['decided_at']).toBeTruthy();
    expect(row['decided_note']).toContain('trim');
  });

  it('lets a new version supersede a rejected one', async () => {
    const body = await pushProof(counter, 'superseded', 3);
    expect(body.results[0]!.status).toBe('applied');
    expect((await proofRow())['status']).toBe('superseded');
  });
});

describe('time tracking', () => {
  const timeTask = '0193f0b1-0000-7000-8000-0000000000cc';

  it('writes a time entry when a task leaves in_progress', async () => {
    const now = new Date().toISOString();
    await env.DB.prepare(
      `INSERT INTO tasks (id, tenant_id, branch_id, order_id, stage_key, stage_name, sequence,
                          title, status, assigned_to, required_role, qty, priority,
                          created_at, updated_at, version)
       VALUES (?, ?, ?, ?, 'qc', 'Quality check', 40, 'Time test', 'assigned', ?, 'manager',
               100, 'normal', ?, ?, 1)`,
    )
      .bind(timeTask, TENANT, BRANCH_SHJ, '0193f0b1-0000-7000-8000-0000000000aa', USER_OWNER, now, now)
      .run();

    const start = await api(
      '/v1/push',
      authed(owner.access_token, {
        device_id: owner.device_id,
        mutations: [
          mutation({
            mutation_id: 'm-time-start',
            entity: 'tasks',
            op: 'patch',
            row_id: timeTask,
            base_version: 1,
            fields: { status: 'in_progress' },
          }),
        ],
      }),
    );
    expect(((await start.json()) as { results: Array<{ status: string }> }).results[0]!.status).toBe(
      'applied',
    );

    // Move the clock back so the stretch is a measurable number of minutes
    // rather than the one-minute floor.
    await env.DB.prepare('UPDATE tasks SET started_at = ? WHERE id = ?')
      .bind(new Date(Date.now() - 12 * 60000).toISOString(), timeTask)
      .run();

    const finish = await api(
      '/v1/push',
      authed(owner.access_token, {
        device_id: owner.device_id,
        mutations: [
          mutation({
            mutation_id: 'm-time-done',
            entity: 'tasks',
            op: 'patch',
            row_id: timeTask,
            base_version: 2,
            fields: { status: 'done' },
          }),
        ],
      }),
    );
    expect(((await finish.json()) as { results: Array<{ status: string }> }).results[0]!.status).toBe(
      'applied',
    );

    const entries = await env.DB.prepare('SELECT * FROM time_entries WHERE task_id = ?')
      .bind(timeTask)
      .all<{ minutes: number; started_at: string; ended_at: string }>();
    expect(entries.results).toHaveLength(1);
    expect(entries.results[0]!.minutes).toBeGreaterThanOrEqual(10);
    expect(entries.results[0]!.minutes).toBeLessThanOrEqual(20);

    // The live timer stops: the duration now lives in time_entries.
    const task = (await env.DB.prepare('SELECT started_at, done_at FROM tasks WHERE id = ?')
      .bind(timeTask)
      .first()) as { started_at: string | null; done_at: string | null };
    expect(task.started_at).toBeNull();
    expect(task.done_at).toBeTruthy();

    const logged = await env.DB.prepare(
      "SELECT COUNT(*) AS n FROM change_log WHERE entity = 'time_entries'",
    ).first<{ n: number }>();
    expect(Number(logged?.n ?? 0)).toBeGreaterThan(0);
  });
});

describe('invoices and payments', () => {
  const invoiceId = '0193f0b1-0000-7000-8000-0000000000da';
  const lineId = '0193f0b1-0000-7000-8000-0000000000db';
  const ORDER = '0193f0b1-0000-7000-8000-0000000000aa';

  async function invoiceRow(): Promise<Record<string, unknown>> {
    return (await env.DB.prepare('SELECT * FROM invoices WHERE id = ?')
      .bind(invoiceId)
      .first()) as Record<string, unknown>;
  }

  async function push(session: Session, mutations: Array<Record<string, unknown>>) {
    const response = await api(
      '/v1/push',
      authed(session.access_token, {
        device_id: session.device_id,
        mutations,
      }),
    );
    return (await response.json()) as {
      results: Array<{ status: string; error?: { code: string; message?: string } }>;
    };
  }

  function pay(mutationId: string, amountFils: number, method = 'cash') {
    return mutation({
      mutation_id: mutationId,
      entity: 'payments',
      row_id: crypto.randomUUID(),
      fields: { invoice_id: invoiceId, amount_fils: amountFils, method },
    });
  }

  it('issues one invoice for the order and refuses a second', async () => {
    const first = await push(counter, [
      mutation({
        mutation_id: 'm-invoice-1',
        entity: 'invoices',
        row_id: invoiceId,
        fields: {
          order_id: ORDER,
          number: 'INV-SHJ1-PC1-00001',
          issued_at: new Date().toISOString(),
          customer_id: '0193f0b1-0000-7000-8000-0000000000e1',
          customer_name: 'Ahmed Traders',
          subtotal_fils: 12200,
          vat_bps: 500,
          vat_fils: 610,
          total_fils: 12810,
        },
      }),
      mutation({
        mutation_id: 'm-invoice-line-1',
        entity: 'invoice_lines',
        row_id: lineId,
        fields: {
          invoice_id: invoiceId,
          line_no: 1,
          description: 'Business cards - 500 - matt lamination',
          quantity: 500,
          unit_fils: 244,
          amount_fils: 12200,
          vat_bps: 500,
        },
      }),
    ]);
    expect(first.results.map((result) => result.status)).toEqual(['applied', 'applied']);

    const row = await invoiceRow();
    expect(row['status']).toBe('issued');
    expect(row['paid_fils']).toBe(0);
    expect(row['branch_id']).toBe(BRANCH_SHJ);

    const second = await push(counter, [
      mutation({
        mutation_id: 'm-invoice-2',
        entity: 'invoices',
        row_id: '0193f0b1-0000-7000-8000-0000000000dc',
        fields: {
          order_id: ORDER,
          number: 'INV-SHJ1-PC1-00002',
          customer_id: '0193f0b1-0000-7000-8000-0000000000e1',
          customer_name: 'Ahmed Traders',
          subtotal_fils: 12200,
          vat_fils: 610,
          total_fils: 12810,
        },
      }),
    ]);
    expect(second.results[0]!.status).toBe('rejected');
    expect(second.results[0]!.error!.code).toBe('DUPLICATE_INVOICE');
  });

  it('will not let an issued invoice be edited', async () => {
    const body = await push(counter, [
      mutation({
        mutation_id: 'm-invoice-edit',
        entity: 'invoices',
        op: 'patch',
        row_id: invoiceId,
        base_version: 1,
        fields: { total_fils: 10000 },
      }),
    ]);
    expect(body.results[0]!.status).toBe('rejected');
    expect(body.results[0]!.error!.code).toBe('INVOICE_IMMUTABLE');
    expect((await invoiceRow())['total_fils']).toBe(12810);
  });

  it('takes a part payment and moves the invoice to part paid', async () => {
    const body = await push(counter, [pay('m-payment-1', 5000)]);
    expect(body.results[0]!.status).toBe('applied');

    const row = await invoiceRow();
    expect(row['paid_fils']).toBe(5000);
    expect(row['status']).toBe('part_paid');

    const payments = await env.DB.prepare('SELECT * FROM payments WHERE invoice_id = ?')
      .bind(invoiceId)
      .all<{ amount_fils: number; method: string; taken_by: string }>();
    expect(payments.results).toHaveLength(1);
    expect(payments.results[0]!.amount_fils).toBe(5000);
    expect(payments.results[0]!.taken_by).toBe(USER_COUNTER);
  });

  it('refuses to take more than is outstanding', async () => {
    const body = await push(counter, [pay('m-pay-over', 99999)]);
    expect(body.results[0]!.status).toBe('rejected');
    expect(body.results[0]!.error!.code).toBe('OVERPAYMENT');
    expect((await invoiceRow())['paid_fils']).toBe(5000);
  });

  it('closes the invoice when the balance reaches zero', async () => {
    const body = await push(counter, [pay('m-payment-2', 7810)]);
    expect(body.results[0]!.status).toBe('applied');

    const row = await invoiceRow();
    expect(row['paid_fils']).toBe(12810);
    expect(row['status']).toBe('paid');
  });

  it('refuses to void an invoice that has payments', async () => {
    const row = await invoiceRow();
    const body = await push(owner, [
      mutation({
        mutation_id: 'm-invoice-void',
        entity: 'invoices',
        op: 'patch',
        row_id: invoiceId,
        base_version: Number(row['version']),
        fields: { status: 'void', void_reason: 'Wrong customer' },
      }),
    ]);
    expect(body.results[0]!.status).toBe('rejected');
    expect(body.results[0]!.error!.code).toBe('HAS_PAYMENTS');
  });

  it('keeps a payment immutable', async () => {
    const payments = await env.DB.prepare('SELECT id FROM payments WHERE invoice_id = ?')
      .bind(invoiceId)
      .all<{ id: string }>();
    const body = await push(counter, [
      mutation({
        mutation_id: 'm-pay-edit',
        entity: 'payments',
        op: 'patch',
        row_id: payments.results[0]!.id,
        base_version: 1,
        fields: { amount_fils: 1 },
      }),
    ]);
    expect(body.results[0]!.status).toBe('rejected');
    expect(body.results[0]!.error!.code).toBe('PAYMENT_IMMUTABLE');
  });

  it('only lets a manager void a clean invoice, with a reason', async () => {
    const cleanId = '0193f0b1-0000-7000-8000-0000000000dd';
    const created = await push(counter, [
      mutation({
        mutation_id: 'm-invoice-clean',
        entity: 'invoices',
        row_id: cleanId,
        fields: {
          order_id: '0193f0b1-0000-7000-8000-0000000000ac',
          number: 'INV-SHJ1-PC1-00003',
          customer_id: '0193f0b1-0000-7000-8000-0000000000e1',
          customer_name: 'Ahmed Traders',
          subtotal_fils: 10000,
          vat_fils: 500,
          total_fils: 10500,
        },
      }),
    ]);
    expect(created.results[0]!.status).toBe('applied');

    const byCounter = await push(counter, [
      mutation({
        mutation_id: 'm-void-by-counter',
        entity: 'invoices',
        op: 'patch',
        row_id: cleanId,
        base_version: 1,
        fields: { status: 'void', void_reason: 'Duplicate' },
      }),
    ]);
    expect(byCounter.results[0]!.error!.code).toBe('PERMISSION_DENIED');

    const noReason = await push(owner, [
      mutation({
        mutation_id: 'm-void-no-reason',
        entity: 'invoices',
        op: 'patch',
        row_id: cleanId,
        base_version: 1,
        fields: { status: 'void' },
      }),
    ]);
    expect(noReason.results[0]!.error!.code).toBe('REASON_REQUIRED');

    const byOwner = await push(owner, [
      mutation({
        mutation_id: 'm-void-by-owner',
        entity: 'invoices',
        op: 'patch',
        row_id: cleanId,
        base_version: 1,
        fields: { status: 'void', void_reason: 'Duplicate of INV-00001' },
      }),
    ]);
    expect(byOwner.results[0]!.status).toBe('applied');
  });
});

describe('credit notes and refunds', () => {
  const invoiceId = '0193f0b1-0000-7000-8000-0000000000da';
  const creditNoteId = '0193f0b1-0000-7000-8000-0000000000ea';

  function creditNote(amountFils: number, extra: Record<string, unknown> = {}) {
    return mutation({
      mutation_id: `m-cn-${amountFils}-${Math.random().toString(36).slice(2, 8)}`,
      entity: 'credit_notes',
      row_id: creditNoteId,
      fields: {
        invoice_id: invoiceId,
        number: 'CN-SHJ1-PC1-00001',
        total_fils: amountFils,
        reason: 'Customer returned 100 cards damaged in finishing',
        ...extra,
      },
    });
  }

  async function push(session: Session, mutations: Array<Record<string, unknown>>) {
    const response = await api(
      '/v1/push',
      authed(session.access_token, { device_id: session.device_id, mutations }),
    );
    return (await response.json()) as {
      results: Array<{ status: string; error?: { code: string } }>;
    };
  }

  it('does not let the counter issue a credit note', async () => {
    const body = await push(counter, [creditNote(5000)]);
    expect(body.results[0]!.status).toBe('rejected');
    expect(body.results[0]!.error!.code).toBe('PERMISSION_DENIED');
  });

  it('needs a reason before crediting', async () => {
    const body = await push(owner, [creditNote(5000, { reason: '' })]);
    expect(body.results[0]!.status).toBe('rejected');
    expect(body.results[0]!.error!.code).toBe('REASON_REQUIRED');
  });

  it('credits the invoice without touching what was paid', async () => {
    const body = await push(owner, [creditNote(5000)]);
    expect(body.results[0]!.status).toBe('applied');

    const invoice = (await env.DB.prepare('SELECT * FROM invoices WHERE id = ?')
      .bind(invoiceId)
      .first()) as Record<string, unknown>;
    expect(invoice['credited_fils']).toBe(5000);
    expect(invoice['paid_fils']).toBe(12810);

    const note = (await env.DB.prepare('SELECT * FROM credit_notes WHERE id = ?')
      .bind(creditNoteId)
      .first()) as Record<string, unknown>;
    // 50.00 credited at 5% VAT is 47.62 net + 2.38 VAT.
    expect(note['total_fils']).toBe(5000);
    expect(note['subtotal_fils']).toBe(4762);
    expect(note['vat_fils']).toBe(238);
    expect(note['refunded_fils']).toBe(0);
  });

  it('refuses to credit more than the invoice is worth', async () => {
    const body = await push(owner, [creditNote(99999, { number: 'CN-SHJ1-PC1-00002' })]);
    expect(body.results[0]!.status).toBe('rejected');
    expect(body.results[0]!.error!.code).toBe('OVER_CREDIT');
  });

  it('refunds cash against the note, once, and only by a manager', async () => {
    const refund = (session: Session, amount: number, id = crypto.randomUUID()) =>
      push(session, [
        mutation({
          mutation_id: `m-refund-${id.slice(0, 8)}`,
          entity: 'refunds',
          row_id: id,
          fields: {
            credit_note_id: creditNoteId,
            invoice_id: invoiceId,
            amount_fils: amount,
            method: 'cash',
          },
        }),
      ]);

    const byCounter = await refund(counter, 1000);
    expect(byCounter.results[0]!.error!.code).toBe('PERMISSION_DENIED');

    const tooMuch = await refund(owner, 99999);
    expect(tooMuch.results[0]!.error!.code).toBe('OVER_REFUND');

    const paid = await refund(owner, 5000);
    expect(paid.results[0]!.status).toBe('applied');

    const note = (await env.DB.prepare('SELECT * FROM credit_notes WHERE id = ?')
      .bind(creditNoteId)
      .first()) as Record<string, unknown>;
    expect(note['refunded_fils']).toBe(5000);

    const again = await refund(owner, 100);
    expect(again.results[0]!.error!.code).toBe('OVER_REFUND');
  });
});

describe('reports', () => {
  const today = new Date();
  const range = `from=2020-01-01&to=${new Date(today.getTime() + 86_400_000).toISOString()}`;

  it('summarises output VAT, credits and cash for a period', async () => {
    const response = await api(`/v1/reports/vat?${range}`, authed(owner.access_token));
    expect(response.status).toBe(200);

    const body = (await response.json()) as {
      sales_net_fils: number;
      output_vat_fils: number;
      credited_vat_fils: number;
      net_vat_due_fils: number;
      collected_fils: number;
      refunded_fils: number;
      collected_by_method: Record<string, number>;
    };

    // One invoice: 122.00 net + 6.10 VAT. One credit note: 47.62 + 2.38.
    expect(body.sales_net_fils).toBeGreaterThanOrEqual(12200);
    expect(body.output_vat_fils).toBeGreaterThanOrEqual(610);
    expect(body.credited_vat_fils).toBe(238);
    expect(body.net_vat_due_fils).toBe(body.output_vat_fils - 238);
    expect(body.collected_fils).toBeGreaterThanOrEqual(12810);
    expect(body.refunded_fils).toBe(5000);
    expect(body.collected_by_method['cash']).toBeGreaterThanOrEqual(5000);
  });

  it('buckets what customers still owe by age', async () => {
    const old = new Date(today.getTime() - 45 * 86_400_000).toISOString();
    await env.DB.prepare(
      `INSERT INTO invoices (id, tenant_id, branch_id, order_id, number, issued_at,
                             customer_id, customer_name, subtotal_fils, vat_bps, vat_fils,
                             total_fils, paid_fils, credited_fils, status,
                             created_at, updated_at, version)
       VALUES (?, ?, ?, ?, 'INV-SHJ1-PC1-09999', ?, 'cust-ageing', 'Ageing Customer',
               10000, 500, 500, 10500, 0, 0, 'issued', ?, ?, 1)`,
    )
      .bind(
        '0193f0b1-0000-7000-8000-0000000000fb',
        TENANT,
        BRANCH_SHJ,
        '0193f0b1-0000-7000-8000-0000000000ac',
        old,
        old,
        old,
      )
      .run();

    const response = await api(
      `/v1/reports/ageing?as_of=${new Date().toISOString()}`,
      authed(owner.access_token),
    );
    expect(response.status).toBe(200);

    const body = (await response.json()) as {
      buckets: Array<{ customer_name: string; days_31_60_fils: number; total_fils: number }>;
      totals: { days_31_60_fils: number };
    };
    const row = body.buckets.find((bucket) => bucket.customer_name === 'Ageing Customer');
    expect(row).toBeDefined();
    expect(row!.days_31_60_fils).toBe(10500);
    expect(row!.total_fils).toBe(10500);
    expect(body.totals.days_31_60_fils).toBeGreaterThanOrEqual(10500);
  });

  it('does not let the counter read the books', async () => {
    const vat = await api(`/v1/reports/vat?${range}`, authed(counter.access_token));
    expect(vat.status).toBe(403);

    const ageing = await api('/v1/reports/ageing', authed(counter.access_token));
    expect(ageing.status).toBe(403);
  });
});

describe('till', () => {
  const tillId = '0193f0b1-0000-7000-8000-0000000000fa';
  const invoiceForTill = '0193f0b1-0000-7000-8000-0000000000fc';

  async function tillRow(): Promise<Record<string, unknown>> {
    return (await env.DB.prepare('SELECT * FROM till_sessions WHERE id = ?')
      .bind(tillId)
      .first()) as Record<string, unknown>;
  }

  it('opens a till with a float and refuses a second open one on the same device', async () => {
    const open = await api(
      '/v1/push',
      authed(counter.access_token, {
        device_id: counter.device_id,
        mutations: [
          mutation({
            mutation_id: 'm-till-open',
            entity: 'till_sessions',
            row_id: tillId,
            fields: { opening_float_fils: 20000, notes: 'Morning shift' },
          }),
        ],
      }),
    );
    expect(((await open.json()) as { results: Array<{ status: string }> }).results[0]!.status).toBe(
      'applied',
    );

    const row = await tillRow();
    expect(row['status']).toBe('open');
    expect(row['device_id']).toBe(counter.device_id);
    expect(row['opened_by']).toBe(USER_COUNTER);

    const second = await api(
      '/v1/push',
      authed(counter.access_token, {
        device_id: counter.device_id,
        mutations: [
          mutation({
            mutation_id: 'm-till-open-2',
            entity: 'till_sessions',
            row_id: '0193f0b1-0000-7000-8000-0000000000f9',
            fields: { opening_float_fils: 1000 },
          }),
        ],
      }),
    );
    const body = (await second.json()) as {
      results: Array<{ status: string; error?: { code: string } }>;
    };
    expect(body.results[0]!.status).toBe('rejected');
    expect(body.results[0]!.error!.code).toBe('TILL_ALREADY_OPEN');
  });

  it('attaches a cash payment to the open till and closes on the count', async () => {
    // An invoice with something outstanding to pay.
    await api(
      '/v1/push',
      authed(counter.access_token, {
        device_id: counter.device_id,
        mutations: [
          mutation({
            mutation_id: 'm-till-invoice',
            entity: 'invoices',
            row_id: invoiceForTill,
            fields: {
              order_id: '0193f0b1-0000-7000-8000-0000000000ad',
              number: 'INV-SHJ1-PC1-00050',
              customer_id: '0193f0b1-0000-7000-8000-0000000000e1',
              customer_name: 'Ahmed Traders',
              subtotal_fils: 4762,
              vat_fils: 238,
              total_fils: 5000,
            },
          }),
        ],
      }),
    );

    const pay = await api(
      '/v1/push',
      authed(counter.access_token, {
        device_id: counter.device_id,
        mutations: [
          mutation({
            mutation_id: 'm-till-pay',
            entity: 'payments',
            row_id: crypto.randomUUID(),
            fields: { invoice_id: invoiceForTill, amount_fils: 5000, method: 'cash' },
          }),
        ],
      }),
    );
    expect(((await pay.json()) as { results: Array<{ status: string }> }).results[0]!.status).toBe(
      'applied',
    );

    const payment = (await env.DB.prepare(
      'SELECT till_session_id FROM payments WHERE invoice_id = ?',
    )
      .bind(invoiceForTill)
      .first()) as { till_session_id: string | null };
    expect(payment.till_session_id).toBe(tillId);

    // 200.00 float + 50.00 cash = 250.00 expected; counted 250.00.
    const close = await api(
      '/v1/push',
      authed(counter.access_token, {
        device_id: counter.device_id,
        mutations: [
          mutation({
            mutation_id: 'm-till-close',
            entity: 'till_sessions',
            op: 'patch',
            row_id: tillId,
            base_version: 1,
            fields: { status: 'closed', counted_fils: 25000 },
          }),
        ],
      }),
    );
    expect(((await close.json()) as { results: Array<{ status: string }> }).results[0]!.status).toBe(
      'applied',
    );

    const row = await tillRow();
    expect(row['status']).toBe('closed');
    expect(row['expected_fils']).toBe(25000);
    expect(row['variance_fils']).toBe(0);
    expect(row['closed_at']).toBeTruthy();
  });

  it('records a short drawer as a variance and refuses a second close', async () => {
    const again = await api(
      '/v1/push',
      authed(counter.access_token, {
        device_id: counter.device_id,
        mutations: [
          mutation({
            mutation_id: 'm-till-close-2',
            entity: 'till_sessions',
            op: 'patch',
            row_id: tillId,
            base_version: 2,
            fields: { status: 'closed', counted_fils: 24000 },
          }),
        ],
      }),
    );
    const body = (await again.json()) as {
      results: Array<{ status: string; error?: { code: string } }>;
    };
    expect(body.results[0]!.status).toBe('rejected');
    expect(body.results[0]!.error!.code).toBe('TILL_ALREADY_CLOSED');
  });
});

describe('expenses and the VAT export', () => {
  const tillId = '0193f0b1-0000-7000-8000-0000000000fe';

  async function push(session: Session, mutations: Array<Record<string, unknown>>) {
    const response = await api(
      '/v1/push',
      authed(session.access_token, { device_id: session.device_id, mutations }),
    );
    return (await response.json()) as {
      results: Array<{ status: string; error?: { code: string } }>;
    };
  }

  function expense(
    id: string,
    amountFils: number,
    method = 'cash',
    extra: Record<string, unknown> = {},
  ) {
    return mutation({
      mutation_id: `m-exp-${id.slice(-6)}`,
      entity: 'expenses',
      row_id: id,
      fields: {
        category: 'Courier',
        description: 'Delivery to Al Nahda',
        amount_fils: amountFils,
        method,
        ...extra,
      },
    });
  }

  it('takes a cash expense out of the drawer and leaves card expenses out', async () => {
    const opened = await push(counter, [
      mutation({
        mutation_id: 'm-exp-till-open',
        entity: 'till_sessions',
        row_id: tillId,
        fields: { opening_float_fils: 10000 },
      }),
    ]);
    expect(opened.results[0]!.status).toBe('applied');

    const cash = await push(counter, [
      expense('0193f0b1-0000-7000-8000-0000000000f1', 2500, 'cash'),
      expense('0193f0b1-0000-7000-8000-0000000000f2', 4000, 'card'),
    ]);
    expect(cash.results.map((result) => result.status)).toEqual(['applied', 'applied']);

    const rows = await env.DB.prepare(
      'SELECT id, till_session_id FROM expenses WHERE tenant_id = ? ORDER BY id',
    )
      .bind(TENANT)
      .all<{ id: string; till_session_id: string | null }>();
    const byId = new Map(rows.results.map((row) => [row.id, row.till_session_id]));
    expect(byId.get('0193f0b1-0000-7000-8000-0000000000f1')).toBe(tillId);
    expect(byId.get('0193f0b1-0000-7000-8000-0000000000f2')).toBeNull();

    // 100.00 float - 25.00 cash courier = 75.00 expected.
    const close = await push(counter, [
      mutation({
        mutation_id: 'm-exp-till-close',
        entity: 'till_sessions',
        op: 'patch',
        row_id: tillId,
        base_version: 1,
        fields: { status: 'closed', counted_fils: 7500 },
      }),
    ]);
    expect(close.results[0]!.status).toBe('applied');

    const till = (await env.DB.prepare('SELECT expected_fils, variance_fils FROM till_sessions WHERE id = ?')
      .bind(tillId)
      .first()) as { expected_fils: number; variance_fils: number };
    expect(till.expected_fils).toBe(7500);
    expect(till.variance_fils).toBe(0);
  });

  it('refuses an expense of nothing', async () => {
    const body = await push(counter, [
      expense('0193f0b1-0000-7000-8000-0000000000f3', 0),
    ]);
    expect(body.results[0]!.status).toBe('rejected');
    expect(body.results[0]!.error!.code).toBe('INVALID_AMOUNT');
  });

  it('exports the period as CSV with credits signed negative', async () => {
    const response = await api(
      '/v1/reports/vat.csv?from=2020-01-01&to=2030-01-01',
      authed(owner.access_token),
    );
    expect(response.status).toBe(200);
    expect(response.headers.get('content-type')).toContain('text/csv');

    const csv = await response.text();
    expect(csv.split('\n')[0]).toContain('type,number,issued_at,customer');
    expect(csv).toContain('TOTAL');
    expect(csv).toContain('credit_note');
    expect(csv).toContain('-2.38'); // the credit note's VAT, signed
    expect(csv).toContain('VAT due (AED)');
  });

  it('lists the closed shifts with their variance', async () => {
    const response = await api(
      '/v1/reports/tills?from=2020-01-01&to=2030-01-01',
      authed(owner.access_token),
    );
    expect(response.status).toBe(200);

    const body = (await response.json()) as {
      sessions: Array<Record<string, unknown>>;
      variance_fils: number;
      short_fils: number;
    };
    expect(body.sessions.length).toBeGreaterThanOrEqual(2);
    const closed = body.sessions.filter((row) => row['status'] === 'closed');
    expect(closed.length).toBeGreaterThanOrEqual(2);
    expect(closed[0]!['expected_fils']).toBeTypeOf('number');
    // Every probe drawer was counted exactly, so nothing nets out either way.
    expect(body.variance_fils).toBe(0);
    expect(body.short_fils).toBe(0);
  });

  it('keeps the counter out of the export', async () => {
    const response = await api('/v1/reports/vat.csv', authed(counter.access_token));
    expect(response.status).toBe(403);
  });
});

describe('price book editing', () => {
  it('lets the owner change a rate and the catalogue reflects it', async () => {
    const response = await api(
      '/v1/price-book/rules/rule_lamination_matt',
      patchRequest(owner.access_token, { rate_fils: 95 }),
    );
    expect(response.status).toBe(200);
    const body = (await response.json()) as { rule: { rate_fils: number } };
    expect(body.rule.rate_fils).toBe(95);

    const catalogue = await api('/v1/catalogue', authed(owner.access_token));
    const catalogueBody = (await catalogue.json()) as {
      rules: Array<{ id: string; rate_fils: number }>;
    };
    const rule = catalogueBody.rules.find((item) => item.id === 'rule_lamination_matt');
    expect(rule!.rate_fils).toBe(95);
  });

  it('writes an audit row with the old and the new value', async () => {
    const audit = await env.DB.prepare(
      "SELECT old_json, new_json FROM audit_log WHERE action = 'price.rule.update' ORDER BY at DESC LIMIT 1",
    ).first<{ old_json: string; new_json: string }>();
    expect(audit).toBeTruthy();
    expect(audit!.old_json).toContain('"rate_fils":80');
    expect(audit!.new_json).toContain('"rate_fils":95');
  });

  it('refuses a counter clerk', async () => {
    const response = await api(
      '/v1/price-book/rules/rule_lamination_matt',
      patchRequest(counter.access_token, { rate_fils: 1 }),
    );
    expect(response.status).toBe(403);
    const body = (await response.json()) as { error: { code: string } };
    expect(body.error.code).toBe('PERMISSION_DENIED');
  });

  it('previews a bulk adjust without changing anything', async () => {
    const response = await api(
      '/v1/price-book/bulk-adjust',
      authed(owner.access_token, { percent_bps: 1000, dry_run: true }),
    );
    expect(response.status).toBe(200);
    const body = (await response.json()) as {
      applied: boolean;
      changes: Array<{ id: string; rate_fils: number; new_rate_fils: number }>;
    };
    expect(body.applied).toBe(false);
    const lamination = body.changes.find((change) => change.id === 'rule_lamination_matt');
    expect(lamination!.rate_fils).toBe(95);
    expect(lamination!.new_rate_fils).toBe(105); // 95 + 10%, rounded

    const catalogue = await api('/v1/catalogue', authed(owner.access_token));
    const catalogueBody = (await catalogue.json()) as {
      rules: Array<{ id: string; rate_fils: number }>;
    };
    expect(
      catalogueBody.rules.find((item) => item.id === 'rule_lamination_matt')!.rate_fils,
    ).toBe(95);
  });

  it('applies a bulk adjust and audits it once', async () => {
    const response = await api(
      '/v1/price-book/bulk-adjust',
      authed(owner.access_token, {
        product_id: 'prod_cards',
        percent_bps: 1000,
        dry_run: false,
      }),
    );
    expect(response.status).toBe(200);
    const body = (await response.json()) as {
      applied: boolean;
      changes: Array<{ new_rate_fils: number }>;
    };
    expect(body.applied).toBe(true);

    const catalogue = await api('/v1/catalogue', authed(owner.access_token));
    const catalogueBody = (await catalogue.json()) as {
      rules: Array<{ id: string; rate_fils: number }>;
    };
    expect(
      catalogueBody.rules.find((item) => item.id === 'rule_lamination_matt')!.rate_fils,
    ).toBe(105);

    const audit = await env.DB.prepare(
      "SELECT COUNT(*) AS total FROM audit_log WHERE action = 'price.bulk_adjust'",
    ).first<{ total: number }>();
    expect(Number(audit!.total)).toBe(1);
  });

  it('lets the owner change a markup and refuses nonsense', async () => {
    const ok = await api(
      '/v1/price-book/products/prod_cards',
      patchRequest(owner.access_token, { markup_bps: 7000 }),
    );
    if (ok.status !== 200) {
      console.log('PATCH product failed:', ok.status, await ok.text());
    }
    expect(ok.status).toBe(200);

    const bad = await api(
      '/v1/price-book/products/prod_business_cards',
      patchRequest(owner.access_token, { markup_bps: -5 }),
    );
    expect(bad.status).toBe(400);
  });
});

describe('number blocks', () => {
  it('leases sequential ranges per series without overlap', async () => {
    const first = await api(
      '/v1/number-blocks/lease',
      authed(counter.access_token, { series: 'INV-SHJ1-PC1', size: 100 }),
    );
    const firstBody = (await first.json()) as { start: number; end: number };
    expect(firstBody.start).toBe(1);
    expect(firstBody.end).toBe(100);

    const second = await api(
      '/v1/number-blocks/lease',
      authed(counter.access_token, { series: 'INV-SHJ1-PC1', size: 100 }),
    );
    const secondBody = (await second.json()) as { start: number; end: number };
    expect(secondBody.start).toBe(101);
    expect(secondBody.end).toBe(200);
  });

  it('keeps series independent', async () => {
    const quote = await api(
      '/v1/number-blocks/lease',
      authed(counter.access_token, { series: 'QT-SHJ1-PC1', size: 50 }),
    );
    const body = (await quote.json()) as { start: number; end: number };
    expect(body.start).toBe(1);
    expect(body.end).toBe(50);
  });
});
