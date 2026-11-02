/**
 * Password hashing and token signing, using only what the Workers runtime has.
 *
 * PBKDF2-SHA256 at 600,000 iterations, via WebCrypto. Argon2id would be nicer
 * but needs WASM and a CPU budget the Worker cannot spare; PBKDF2 with a high
 * iteration count is the defensible choice, and the parameter is stored inside
 * the hash string so it can be raised later without breaking old logins.
 *
 * Format: pbkdf2$sha256$<iterations>$<saltBase64>$<hashBase64>
 */

import { SignJWT, jwtVerify } from 'jose';

const encoder = new TextEncoder();

export const DEFAULT_ITERATIONS = 600_000;

export function toBase64(bytes: Uint8Array): string {
  let binary = '';
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary);
}

export function fromBase64(value: string): Uint8Array {
  const binary = atob(value);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

async function pbkdf2(
  password: string,
  salt: Uint8Array,
  iterations: number,
): Promise<Uint8Array> {
  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(password),
    'PBKDF2',
    false,
    ['deriveBits'],
  );
  const bits = await crypto.subtle.deriveBits(
    { name: 'PBKDF2', salt: salt as BufferSource, iterations, hash: 'SHA-256' },
    key,
    256,
  );
  return new Uint8Array(bits);
}

export async function hashPassword(
  password: string,
  iterations: number = DEFAULT_ITERATIONS,
): Promise<string> {
  const salt = crypto.getRandomValues(new Uint8Array(16));
  const hash = await pbkdf2(password, salt, iterations);
  return `pbkdf2$sha256$${iterations}$${toBase64(salt)}$${toBase64(hash)}`;
}

export async function verifyPassword(
  password: string,
  stored: string,
): Promise<boolean> {
  const parts = stored.split('$');
  if (parts.length !== 5 || parts[0] !== 'pbkdf2' || parts[1] !== 'sha256') {
    return false;
  }
  const iterations = Number(parts[2]);
  if (!Number.isFinite(iterations) || iterations <= 0) return false;
  const salt = fromBase64(parts[3]!);
  const expected = fromBase64(parts[4]!);
  const actual = await pbkdf2(password, salt, iterations);
  return constantTimeEqual(actual, expected);
}

/** Compares two byte arrays without leaking where they differ. */
export function constantTimeEqual(a: Uint8Array, b: Uint8Array): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a[i]! ^ b[i]!;
  return diff === 0;
}

export interface AccessTokenInput {
  userId: string;
  tenantId: string;
  branchId: string | null;
  role: string;
  permissionVersion: number;
  deviceId: string;
}

export async function signAccessToken(
  input: AccessTokenInput,
  secret: string,
  ttlSeconds = 900,
): Promise<string> {
  const key = encoder.encode(secret);
  const now = Math.floor(Date.now() / 1000);
  return new SignJWT({
    tid: input.tenantId,
    bid: input.branchId,
    role: input.role,
    pv: input.permissionVersion,
    dv: input.deviceId,
  })
    .setProtectedHeader({ alg: 'HS256', typ: 'JWT' })
    .setSubject(input.userId)
    .setIssuedAt(now)
    .setExpirationTime(now + ttlSeconds)
    .sign(key);
}

export async function verifyAccessToken(
  token: string,
  secret: string,
): Promise<AccessTokenInput | null> {
  try {
    const { payload } = await jwtVerify(token, encoder.encode(secret), {
      algorithms: ['HS256'],
    });
    const sub = payload.sub;
    const tid = payload.tid;
    const role = payload.role;
    const dv = payload.dv;
    if (typeof sub !== 'string' || typeof tid !== 'string') return null;
    if (typeof role !== 'string' || typeof dv !== 'string') return null;
    return {
      userId: sub,
      tenantId: tid,
      branchId: typeof payload.bid === 'string' ? payload.bid : null,
      role,
      permissionVersion: typeof payload.pv === 'number' ? payload.pv : 0,
      deviceId: dv,
    };
  } catch {
    return null;
  }
}

/** Opaque refresh token: 32 random bytes, base64url, stored only as a hash. */
export async function newRefreshToken(): Promise<{ token: string; hash: string }> {
  const bytes = crypto.getRandomValues(new Uint8Array(32));
  const token = base64Url(bytes);
  return { token, hash: await sha256Hex(token) };
}

export async function sha256Hex(value: string): Promise<string> {
  const digest = await crypto.subtle.digest('SHA-256', encoder.encode(value));
  return [...new Uint8Array(digest)]
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

export function base64Url(bytes: Uint8Array): string {
  return toBase64(bytes)
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

/** Normalises a phone number to +<digits>, keeping the last nine for search. */
export function normalisePhone(input: string): { e164: string; last9: string } {
  const digits = input.replace(/\D/g, '');
  return {
    e164: `+${digits}`,
    last9: digits.slice(-9),
  };
}
