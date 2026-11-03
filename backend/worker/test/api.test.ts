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
