/**
 * Authentication: password login, refresh rotation, device registration.
 *
 * Access tokens are 15-minute HS256 JWTs carrying role, branch, permission
 * version and device id, so the hot paths (head, pull) verify them without
 * touching the database. Refresh tokens are opaque, single-use and stored only
 * as a SHA-256 hash; a reused token revokes the whole device chain, which is
 * what turns a stolen refresh token into a detectable event instead of a
 * silent impersonation.
 */

import { z } from 'zod';
import type { AuthContext, Env } from './types';
import { DEFAULT_ROLE_PERMISSIONS, type RoleKey } from './policy';
import {
  newRefreshToken,
  normalisePhone,
  sha256Hex,
  signAccessToken,
  verifyPassword,
} from './crypto';

export const loginSchema = z.object({
  phone: z.string().min(4).max(24),
  password: z.string().min(1).max(200),
  device: z.object({
    id: z.string().min(8).optional(),
    name: z.string().min(1).max(80).default('Device'),
    platform: z.enum(['windows', 'android']),
    app_version: z.string().max(32).optional(),
  }),
});

export type LoginInput = z.infer<typeof loginSchema>;

export interface AuthResult {
  status: number;
  body: Record<string, unknown>;
}

const REFRESH_TTL_DAYS = 30;
const ACCESS_TTL_SECONDS = 900;

interface UserRow {
  id: string;
  tenant_id: string;
  branch_id: string | null;
  role_id: string;
  role_key: string;
  name: string;
  phone_e164: string;
  email: string | null;
  password_hash: string;
  locale: string;
  permission_version: number;
  active: number;
  deleted_at: string | null;
}

export async function login(env: Env, input: LoginInput): Promise<AuthResult> {
  const { e164 } = normalisePhone(input.phone);

  const { results } = await env.DB.prepare(
    `SELECT u.*, r.role_key
       FROM users u
       JOIN roles r ON r.id = u.role_id
      WHERE u.phone_e164 = ? AND u.active = 1 AND u.deleted_at IS NULL
      LIMIT 2`,
  )
    .bind(e164)
    .all<UserRow>();

  const matches = results ?? [];
  if (matches.length === 0) {
    return { status: 401, body: error('INVALID_CREDENTIALS', 'Phone number or password is not correct.') };
  }
  if (matches.length > 1) {
    return {
      status: 409,
      body: error('TENANT_REQUIRED', 'This number belongs to more than one shop. Sign in with the shop code.'),
    };
  }

  const user = matches[0]!;

  // --- Brute-force brake ---------------------------------------------------
  // Eight wrong passwords in fifteen minutes lock the account for the rest of
  // that window. The count comes from the audit trail, which already records
  // every failed sign-in and every success: a successful login therefore clears
  // the count without ever rewriting history, and the log stays append-only.
  if ((await recentFailureCount(env, user)) >= MAX_FAILED_ATTEMPTS) {
    await audit(env, user.tenant_id, user.id, null, 'auth.login_throttled', 'users', user.id);
    return {
      status: 429,
      body: error(
        'TOO_MANY_ATTEMPTS',
        'Too many attempts. Try again in 15 minutes, or ask your manager to reset the password.',
      ),
    };
  }

  const valid = await verifyPassword(input.password, user.password_hash);
  if (!valid) {
    await audit(env, user.tenant_id, user.id, null, 'auth.login_failed', 'users', user.id);
    return { status: 401, body: error('INVALID_CREDENTIALS', 'Phone number or password is not correct.') };
  }

  const device = await resolveDevice(env, user, input);
  const tokens = await issueTokens(env, user, device.id);

  await env.DB.prepare(
    'UPDATE devices SET last_seen_at = ?, app_version = ? WHERE id = ?',
  )
    .bind(new Date().toISOString(), input.device.app_version ?? null, device.id)
    .run();

  await audit(env, user.tenant_id, user.id, device.id, 'auth.login', 'users', user.id);

  const branches = await env.DB.prepare(
    'SELECT id, code, name FROM branches WHERE tenant_id = ? AND active = 1 AND deleted_at IS NULL ORDER BY code',
  )
    .bind(user.tenant_id)
    .all<{ id: string; code: string; name: string }>();

  return {
    status: 200,
    body: {
      ...tokens,
      user: {
        id: user.id,
        tenant_id: user.tenant_id,
        branch_id: user.branch_id,
        role: user.role_key,
        name: user.name,
        phone: user.phone_e164,
        email: user.email,
        locale: user.locale,
        permission_version: Number(user.permission_version),
      },
      permissions: DEFAULT_ROLE_PERMISSIONS[user.role_key as RoleKey] ?? {},
      branches: branches.results ?? [],
      server_time: new Date().toISOString(),
      min_app_version: env.MIN_APP_VERSION,
    },
  };
}

interface DeviceRow {
  id: string;
}

async function resolveDevice(
  env: Env,
  user: UserRow,
  input: LoginInput,
): Promise<DeviceRow> {
  if (input.device.id) {
    const existing = await env.DB.prepare(
      'SELECT id FROM devices WHERE id = ? AND user_id = ? AND tenant_id = ? AND revoked_at IS NULL',
    )
      .bind(input.device.id, user.id, user.tenant_id)
      .first<DeviceRow>();
    if (existing) return existing;
  }

  const id = crypto.randomUUID();
  await env.DB.prepare(
    `INSERT INTO devices (id, tenant_id, user_id, name, platform, app_version, created_at, last_seen_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
  )
    .bind(
      id,
      user.tenant_id,
      user.id,
      input.device.name,
      input.device.platform,
      input.device.app_version ?? null,
      new Date().toISOString(),
      new Date().toISOString(),
    )
    .run();
  return { id };
}

async function issueTokens(
  env: Env,
  user: UserRow,
  deviceId: string,
): Promise<Record<string, unknown>> {
  const accessToken = await signAccessToken(
    {
      userId: user.id,
      tenantId: user.tenant_id,
      branchId: user.branch_id,
      role: user.role_key,
      permissionVersion: Number(user.permission_version),
      deviceId,
    },
    env.JWT_SECRET,
    ACCESS_TTL_SECONDS,
  );

  const refresh = await newRefreshToken();
  const now = new Date();
  const expires = new Date(now.getTime() + REFRESH_TTL_DAYS * 24 * 60 * 60 * 1000);

  await env.DB.prepare(
    `INSERT INTO refresh_tokens (id, tenant_id, device_id, user_id, token_hash, issued_at, expires_at)
     VALUES (?, ?, ?, ?, ?, ?, ?)`,
  )
    .bind(
      crypto.randomUUID(),
      user.tenant_id,
      deviceId,
      user.id,
      refresh.hash,
      now.toISOString(),
      expires.toISOString(),
    )
    .run();

  return {
    access_token: accessToken,
    refresh_token: refresh.token,
    expires_in: ACCESS_TTL_SECONDS,
    refresh_expires_in: REFRESH_TTL_DAYS * 24 * 60 * 60,
    device_id: deviceId,
  };
}

export const refreshSchema = z.object({
  refresh_token: z.string().min(20),
});

export async function refreshSession(
  env: Env,
  refreshToken: string,
): Promise<AuthResult> {
  const hash = await sha256Hex(refreshToken);

  const row = await env.DB.prepare(
    `SELECT rt.id AS refresh_id,
            rt.device_id AS refresh_device_id,
            rt.expires_at AS refresh_expires_at,
            rt.revoked_at AS refresh_revoked_at,
            u.*,
            r.role_key
       FROM refresh_tokens rt
       JOIN users u ON u.id = rt.user_id
       JOIN roles r ON r.id = u.role_id
      WHERE rt.token_hash = ?`,
  )
    .bind(hash)
    .first<
      UserRow & {
        refresh_id: string;
        refresh_device_id: string;
        refresh_expires_at: string;
        refresh_revoked_at: string | null;
      }
    >();

  if (!row) {
    return { status: 401, body: error('INVALID_TOKEN', 'Session expired. Please sign in again.') };
  }
  if (row.refresh_revoked_at) {
    // Reuse of a rotated token: assume theft and kill the device's sessions.
    await env.DB.prepare(
      'UPDATE refresh_tokens SET revoked_at = ? WHERE device_id = ? AND revoked_at IS NULL',
    )
      .bind(new Date().toISOString(), row.refresh_device_id)
      .run();
    return { status: 401, body: error('TOKEN_REUSED', 'Session revoked. Please sign in again.') };
  }
  if (new Date(row.refresh_expires_at).getTime() < Date.now()) {
    return { status: 401, body: error('TOKEN_EXPIRED', 'Session expired. Please sign in again.') };
  }
  if (row.active !== 1 || row.deleted_at !== null) {
    return { status: 401, body: error('USER_DISABLED', 'This account is no longer active.') };
  }

  const now = new Date();
  await env.DB.prepare('UPDATE refresh_tokens SET revoked_at = ? WHERE id = ?')
    .bind(now.toISOString(), row.refresh_id)
    .run();

  const tokens = await issueTokens(env, row, row.refresh_device_id);

  // Keep the rotation chain so a reuse can be traced back through devices.
  await env.DB.prepare('UPDATE refresh_tokens SET rotated_from = ? WHERE token_hash = ?')
    .bind(row.refresh_id, await sha256Hex(String(tokens['refresh_token'])))
    .run();

  await env.DB.prepare('UPDATE devices SET last_seen_at = ? WHERE id = ?')
    .bind(now.toISOString(), row.refresh_device_id)
    .run();

  return {
    status: 200,
    body: {
      ...tokens,
      user: {
        id: row.id,
        tenant_id: row.tenant_id,
        branch_id: row.branch_id,
        role: row.role_key,
        name: row.name,
        locale: row.locale,
        permission_version: Number(row.permission_version),
      },
      permissions: DEFAULT_ROLE_PERMISSIONS[row.role_key as RoleKey] ?? {},
      server_time: now.toISOString(),
    },
  };
}

/**
 * One query decides whether a request may proceed: is the user still active,
 * and has this device been revoked? The permission version rides along so a
 * role change invalidates tokens without a blacklist table.
 */
export async function loadSession(
  env: Env,
  ctx: AuthContext,
): Promise<{ ok: true; permissionVersion: number } | { ok: false; code: string; message: string }> {
  const row = await env.DB.prepare(
    `SELECT u.permission_version AS pv, u.active AS active, d.revoked_at AS revoked_at
       FROM users u
       JOIN devices d ON d.user_id = u.id
      WHERE u.id = ? AND d.id = ? AND u.tenant_id = ?`,
  )
    .bind(ctx.userId, ctx.deviceId, ctx.tenantId)
    .first<{ pv: number; active: number; revoked_at: string | null }>();

  if (!row) {
    return { ok: false, code: 'DEVICE_UNKNOWN', message: 'This device is not registered.' };
  }
  if (row.revoked_at) {
    return { ok: false, code: 'DEVICE_REVOKED', message: 'This device has been signed out remotely.' };
  }
  if (row.active !== 1) {
    return { ok: false, code: 'USER_DISABLED', message: 'This account is no longer active.' };
  }
  if (Number(row.pv) !== ctx.permissionVersion) {
    return { ok: false, code: 'PERMISSION_STALE', message: 'Your access changed. Refresh and try again.' };
  }
  return { ok: true, permissionVersion: Number(row.pv) };
}

export async function revokeDevice(env: Env, ctx: AuthContext): Promise<void> {
  const now = new Date().toISOString();
  await env.DB.batch([
    env.DB.prepare('UPDATE devices SET revoked_at = ? WHERE id = ?').bind(now, ctx.deviceId),
    env.DB.prepare('UPDATE refresh_tokens SET revoked_at = ? WHERE device_id = ? AND revoked_at IS NULL').bind(now, ctx.deviceId),
  ]);
  await audit(env, ctx.tenantId, ctx.userId, ctx.deviceId, 'auth.logout', 'devices', ctx.deviceId);
}

const MAX_FAILED_ATTEMPTS = 8;
const ATTEMPT_WINDOW_MS = 15 * 60 * 1000;

/// How many times this account has failed since its last successful sign-in, and
/// only inside the lockout window. Both bounds matter: without the success bound
/// a fat-fingered morning would lock the account for the day.
async function recentFailureCount(env: Env, user: UserRow): Promise<number> {
  const cutoff = new Date(Date.now() - ATTEMPT_WINDOW_MS).toISOString();
  const row = await env.DB.prepare(
    `SELECT COUNT(*) AS n
       FROM audit_log
      WHERE tenant_id = ? AND entity = 'users' AND row_id = ?
        AND action = 'auth.login_failed'
        AND at > ?
        AND at > COALESCE(
          (SELECT MAX(at) FROM audit_log
            WHERE tenant_id = ? AND entity = 'users' AND row_id = ?
              AND action = 'auth.login'), '')`,
  )
    .bind(user.tenant_id, user.id, cutoff, user.tenant_id, user.id)
    .first<{ n: number }>();
  return Number(row?.n ?? 0);
}

async function audit(
  env: Env,
  tenantId: string,
  actorId: string,
  deviceId: string | null,
  action: string,
  entity: string,
  rowId: string,
): Promise<void> {
  await env.DB.prepare(
    `INSERT INTO audit_log (id, tenant_id, actor_id, device_id, action, entity, row_id, at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
  )
    .bind(crypto.randomUUID(), tenantId, actorId, deviceId, action, entity, rowId, new Date().toISOString())
    .run();
}

export function error(code: string, message: string): Record<string, unknown> {
  return { error: { code, message } };
}
