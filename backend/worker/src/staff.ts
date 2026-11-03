/**
 * Staff: the people who sign in.
 *
 * Two rules shape this file.
 *
 * 1. A password or PIN is never returned, and never stored in the clear. The
 *    hash goes into the same column the login path already reads, so a person
 *    created here can sign in immediately, on any device.
 * 2. The shop can never be locked out of itself: the last active owner cannot
 *    be deactivated or demoted, and nobody can demote or deactivate their own
 *    account. That is a real support incident avoided, not a nicety.
 */
import { z } from 'zod';
import { can, type RoleKey } from './policy';
import { hashPassword } from './crypto';
import type { Env } from './types';

export const ROLES: RoleKey[] = [
  'owner',
  'manager',
  'counter',
  'designer',
  'operator',
  'accountant',
  'vendor_coordinator',
  'driver',
];

export const createStaffSchema = z.object({
  name: z.string().trim().min(2).max(80),
  phone: z.string().trim().min(8).max(20),
  role: z.enum(ROLES as [RoleKey, ...RoleKey[]]),
  branch_id: z.string().uuid().nullable().optional(),
  // Long enough to matter, short enough to type at a counter.
  password: z.string().min(8).max(200),
  pin: z
    .string()
    .regex(/^\d{4}$/, 'A PIN is four digits.')
    .nullable()
    .optional(),
});

export const updateStaffSchema = z.object({
  name: z.string().trim().min(2).max(80).optional(),
  role: z.enum(ROLES as [RoleKey, ...RoleKey[]]).optional(),
  active: z.boolean().optional(),
  password: z.string().min(8).max(200).optional(),
  pin: z.string().regex(/^\d{4}$/, 'A PIN is four digits.').nullable().optional(),
});

export interface StaffRow {
  id: string;
  name: string;
  phone_e164: string;
  role_key: RoleKey;
  branch_id: string | null;
  branch_name: string | null;
  active: number;
  has_pin: number;
  created_at: string;
}

export async function listStaff(env: Env, tenantId: string): Promise<StaffRow[]> {
  const result = await env.DB.prepare(
    `SELECT u.id, u.name, u.phone_e164, r.role_key, u.branch_id, b.name AS branch_name,
            u.active, CASE WHEN u.pin_hash IS NULL THEN 0 ELSE 1 END AS has_pin,
            u.created_at
       FROM users u
       JOIN roles r ON r.id = u.role_id
       LEFT JOIN branches b ON b.id = u.branch_id
      WHERE u.tenant_id = ?
      ORDER BY u.active DESC, u.name`,
  )
    .bind(tenantId)
    .all<StaffRow>();

  return result.results ?? [];
}

const ROLE_NAMES: Record<RoleKey, string> = {
  owner: 'Owner',
  manager: 'Manager',
  counter: 'Sales / Counter',
  designer: 'Designer',
  operator: 'Operator',
  accountant: 'Accountant',
  vendor_coordinator: 'Vendor Coordinator',
  driver: 'Driver',
};

/**
 * The role row for a key. A role is created on first use rather than seeded by
 * hand: the task workflow already names designers and drivers, and a shop that
 * cannot create the person the workflow expects is stuck for no good reason.
 */
async function roleIdFor(env: Env, tenantId: string, key: RoleKey): Promise<string | null> {
  const row = await env.DB.prepare(
    'SELECT id FROM roles WHERE tenant_id = ? AND role_key = ?',
  )
    .bind(tenantId, key)
    .first<{ id: string }>();
  if (row) return row.id;

  const id = crypto.randomUUID();
  const now = new Date().toISOString();
  await env.DB.prepare(
    `INSERT INTO roles (id, tenant_id, role_key, name, is_system, created_at, updated_at)
     VALUES (?, ?, ?, ?, 1, ?, ?)`,
  )
    .bind(id, tenantId, key, ROLE_NAMES[key], now, now)
    .run();

  return id;
}

export interface StaffResult {
  ok: boolean;
  code?: string;
  message?: string;
  staff?: StaffRow;
}

export async function createStaff(
  env: Env,
  tenantId: string,
  input: z.infer<typeof createStaffSchema>,
): Promise<StaffResult> {
  const normalised = input.phone.replace(/[^\d+]/g, '');
  const phone = normalised.startsWith('+') ? normalised : `+${normalised}`;

  const existing = await env.DB.prepare(
    'SELECT 1 AS present FROM users WHERE phone_e164 = ?',
  )
    .bind(phone)
    .first<{ present: number }>();
  if (existing) {
    return {
      ok: false,
      code: 'PHONE_IN_USE',
      message: 'That phone number already has an account.',
    };
  }

  const roleId = await roleIdFor(env, tenantId, input.role);
  if (roleId == null) {
    return {
      ok: false,
      code: 'UNKNOWN_ROLE',
      message: `The role ${input.role} is not set up for this shop yet.`,
    };
  }

  const now = new Date().toISOString();
  const id = crypto.randomUUID();
  const passwordHash = await hashPassword(input.password);
  const pinHash = input.pin ? await hashPassword(input.pin) : null;

  await env.DB.prepare(
    `INSERT INTO users (id, tenant_id, branch_id, role_id, name, phone_e164,
                        password_hash, pin_hash, active, permission_version,
                        created_at, updated_at, created_by)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, 1, ?, ?, ?)`,
  )
    .bind(
      id,
      tenantId,
      input.branch_id ?? null,
      roleId,
      input.name,
      phone,
      passwordHash,
      pinHash,
      now,
      now,
      id,
    )
    .run();

  const staff = (await listStaff(env, tenantId)).find((row) => row.id === id);
  return { ok: true, staff };
}

export async function updateStaff(
  env: Env,
  tenantId: string,
  actingUserId: string,
  actingRole: RoleKey,
  targetId: string,
  input: z.infer<typeof updateStaffSchema>,
): Promise<StaffResult> {
  const target = await env.DB.prepare(
    `SELECT u.id, u.role_id, u.active, r.role_key
       FROM users u JOIN roles r ON r.id = u.role_id
      WHERE u.id = ? AND u.tenant_id = ?`,
  )
    .bind(targetId, tenantId)
    .first<{ id: string; role_id: string; active: number; role_key: RoleKey }>();

  if (target == null) {
    return { ok: false, code: 'NOT_FOUND', message: 'That person is not in this shop.' };
  }

  const demoting = input.role != null && input.role !== target.role_key;
  const deactivating = input.active === false;
  if ((demoting || deactivating) && target.id === actingUserId) {
    return {
      ok: false,
      code: 'NOT_YOURSELF',
      message: 'You cannot change your own role or switch yourself off.',
    };
  }

  // The last owner keeps the keys: a shop with no owner cannot be recovered
  // from inside the app, only from the database.
  if ((demoting || deactivating) && target.role_key === 'owner') {
    const owners = await env.DB.prepare(
      `SELECT COUNT(*) AS total FROM users u JOIN roles r ON r.id = u.role_id
        WHERE u.tenant_id = ? AND r.role_key = 'owner' AND u.active = 1`,
    )
      .bind(tenantId)
      .first<{ total: number }>();
    if (Number(owners?.total ?? 0) <= 1) {
      return {
        ok: false,
        code: 'LAST_OWNER',
        message: 'This is the only active owner. Give someone else the role first.',
      };
    }
  }

  if (!can(actingRole, 'user.manage')) {
    return { ok: false, code: 'PERMISSION_DENIED', message: 'Not allowed.' };
  }

  const sets: string[] = [];
  const values: unknown[] = [];
  const now = new Date().toISOString();

  if (input.name != null) {
    sets.push('name = ?');
    values.push(input.name);
  }
  if (input.role != null) {
    const roleId = await roleIdFor(env, tenantId, input.role);
    if (roleId == null) {
      return { ok: false, code: 'UNKNOWN_ROLE', message: 'That role does not exist.' };
    }
    sets.push('role_id = ?');
    values.push(roleId);
  }
  if (input.active != null) {
    sets.push('active = ?');
    values.push(input.active ? 1 : 0);
  }
  if (input.password != null) {
    sets.push('password_hash = ?');
    values.push(await hashPassword(input.password));
  }
  if (input.pin !== undefined) {
    sets.push('pin_hash = ?');
    values.push(input.pin == null ? null : await hashPassword(input.pin));
  }

  if (sets.length === 0) {
    return { ok: false, code: 'NOTHING_TO_CHANGE', message: 'Nothing to change.' };
  }

  // Bumping permission_version tells every signed-in device that this person's
  // rights changed, without waiting for a full re-login.
  sets.push('updated_at = ?', 'permission_version = permission_version + 1');
  values.push(now);

  await env.DB.prepare(`UPDATE users SET ${sets.join(', ')} WHERE id = ? AND tenant_id = ?`)
    .bind(...values, targetId, tenantId)
    .run();

  const staff = (await listStaff(env, tenantId)).find((row) => row.id === targetId);
  return { ok: true, staff };
}
