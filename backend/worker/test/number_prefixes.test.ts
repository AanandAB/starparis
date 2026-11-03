/**
 * Number prefixes come from Settings, not from code.
 *
 * The bug this covers: a shop renamed `INV` to `BILL` in Settings and its next
 * invoice still said `INV-…`, because the lease endpoint took the series string
 * from the device and never looked at Settings at all. The endpoint now resolves
 * the prefix at lease time, so the block — and the number it hands out — carries
 * the prefix the owner typed.
 *
 * Its own tenant is seeded rather than shared with the sync suite: these tests
 * change the shop's prefixes, and a fixture shared with tests that assert the
 * default `INV` would make the suite order-dependent. workerd gives every test
 * file its own D1, so nothing here can leak into `api.test.ts`.
 */

import { SELF, env } from 'cloudflare:test';
import { beforeAll, describe, expect, it } from 'vitest';

import { hashPassword } from '../src/crypto';
import { leaseBlock } from '../src/numbers';

const TENANT = '0193f0b1-0000-7000-8000-0000000000e1';
const BRANCH = '0193f0b1-0000-7000-8000-0000000000eb';
const ROLE_OWNER = '0193f0b1-0000-7000-8000-0000000000e2';
const USER_OWNER = '0193f0b1-0000-7000-8000-0000000000e3';

// Stored already normalised: login looks the user up by `normalisePhone`, so a
// fixture with spaces would never match and the failure would look like a wrong
// password.
const OWNER_PHONE = '+971501110001';
const PASSWORD = 'prefixes-pass-123';

interface Session {
  access_token: string;
  device_id: string;
}

let owner: Session;

async function api(path: string, init: RequestInit = {}): Promise<Response> {
  return SELF.fetch(`https://api.test${path}`, init);
}

function authed(token: string, body?: unknown, method?: string): RequestInit {
  return {
    method: method ?? (body === undefined ? 'GET' : 'POST'),
    headers: {
      authorization: `Bearer ${token}`,
      'content-type': 'application/json',
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  };
}

/** The series recorded on the lease row, which is what the counter really is. */
async function leasedSeries(deviceId: string): Promise<string[]> {
  const { results } = await env.DB.prepare(
    'SELECT series FROM number_blocks WHERE tenant_id = ? AND device_id = ? ORDER BY start_no',
  )
    .bind(TENANT, deviceId)
    .all<{ series: string }>();
  return (results ?? []).map((row) => row.series);
}

beforeAll(async () => {
  const passwordHash = await hashPassword(PASSWORD, 1000);
  const now = new Date().toISOString();

  await env.DB.batch([
    env.DB.prepare('INSERT INTO tenants (id, name, created_at, updated_at) VALUES (?, ?, ?, ?)')
      .bind(TENANT, 'Prefix Test Printing LLC', now, now),
    env.DB.prepare(
      'INSERT INTO branches (id, tenant_id, code, name, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)',
    ).bind(BRANCH, TENANT, 'SHJ1', 'Sharjah — Industrial Area', now, now),
    env.DB.prepare(
      'INSERT INTO roles (id, tenant_id, role_key, name, is_system, created_at, updated_at) VALUES (?, ?, ?, ?, 1, ?, ?)',
    ).bind(ROLE_OWNER, TENANT, 'owner', 'Owner', now, now),
    env.DB.prepare(
      `INSERT INTO users (id, tenant_id, branch_id, role_id, name, phone_e164, password_hash, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    ).bind(USER_OWNER, TENANT, BRANCH, ROLE_OWNER, 'Owner', OWNER_PHONE, passwordHash, now, now),
  ]);

  const login = await api('/v1/auth/login', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      phone: OWNER_PHONE,
      password: PASSWORD,
      device: { name: 'Prefix test PC', platform: 'windows', app_version: '0.1.0' },
    }),
  });
  expect(login.status).toBe(200);
  owner = (await login.json()) as Session;
});

describe('number prefixes from Settings', () => {
  it('leases the invoice series under the prefix the owner saved', async () => {
    // 1. The owner renames the invoice prefix, exactly as the settings screen
    //    does. Only the numbers block is sent, so the rest of the settings are
    //    proven to survive a partial write.
    const saved = await api(
      '/v1/settings',
      authed(owner.access_token, { numbers: { invoice_prefix: 'BILL' } }, 'PUT'),
    );
    expect(saved.status).toBe(200);

    // 2. The device reads the prefix from the settings payload — this is the
    //    value the client composes the printed number from.
    const read = await api('/v1/settings', authed(owner.access_token));
    const settings = (await read.json()) as { numbers: { invoice_prefix: string } };
    expect(settings.numbers.invoice_prefix).toBe('BILL');

    // 3. A device that has not refreshed its settings still asks for the old
    //    series. The lease must land in the renamed one, otherwise the shop
    //    keeps issuing numbers under a prefix it no longer prints.
    const stale = await api(
      '/v1/number-blocks/lease',
      authed(owner.access_token, { series: 'INV-SHJ1-PC1', size: 100 }),
    );
    expect(stale.status).toBe(200);
    const staleBody = (await stale.json()) as { start: number; end: number };
    expect(staleBody.start).toBe(1);
    expect(staleBody.end).toBe(100);

    // The row is the proof: it says BILL even though INV was asked for.
    expect(await leasedSeries(owner.device_id)).toEqual(['BILL-SHJ1-PC1']);

    // 4. A device that HAS refreshed asks for the new series and continues the
    //    same counter — a rename must not restart numbering at 1 while old
    //    invoices are still in the book.
    const fresh = await api(
      '/v1/number-blocks/lease',
      authed(owner.access_token, { series: 'BILL-SHJ1-PC1', size: 100 }),
    );
    expect(fresh.status).toBe(200);
    const freshBody = (await fresh.json()) as { start: number; end: number };
    expect(freshBody.start).toBe(101);
    expect(freshBody.end).toBe(200);

    // 5. Renaming invoices must not touch quotes: each prefix is its own series.
    const quote = await api(
      '/v1/number-blocks/lease',
      authed(owner.access_token, { series: 'QT-SHJ1-PC1', size: 10 }),
    );
    expect(quote.status).toBe(200);
    // Ordered by start_no, so the series interleave; compare as a multiset.
    expect((await leasedSeries(owner.device_id)).sort()).toEqual([
      'BILL-SHJ1-PC1',
      'BILL-SHJ1-PC1',
      'QT-SHJ1-PC1',
    ]);
  });

  it('hands the resolved series back to the caller', async () => {
    // The HTTP route echoes the series the device sent (it is not this module's
    // response to shape), so the resolved name is asserted where it is decided.
    const block = await leaseBlock(env, TENANT, owner.device_id, 'INV-SHJ1-PC1', 10);
    expect(block.series).toBe('BILL-SHJ1-PC1');
    expect(block.start).toBe(201);
    expect(block.end).toBe(210);
  });

  it('leaves a series it does not recognise exactly as it was sent', async () => {
    // The endpoint is generic; guessing at an unknown string would move a
    // counter nobody asked to move.
    const block = await leaseBlock(env, TENANT, owner.device_id, 'LAYOUT-A1-X9', 5);
    expect(block.series).toBe('LAYOUT-A1-X9');
  });

  it('refuses a prefix that is not a prefix', async () => {
    const bad = await api(
      '/v1/settings',
      authed(owner.access_token, { numbers: { invoice_prefix: 'X' } }, 'PUT'),
    );
    expect(bad.status).toBe(400);
  });
});
