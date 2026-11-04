/**
 * Shared types for the Worker.
 *
 * The Env interface is deliberately small: D1 plus three bindings. Everything
 * else — permissions, pricing, numbering — is code, so a mis-set binding fails
 * at deploy time rather than in a shop at 9am.
 */

export interface Env {
  DB: D1Database;
  JWT_SECRET: string;
  MIN_APP_VERSION: string;
  ENVIRONMENT: string;
  /** The vendor's platform-admin token. Optional so tests don't need it. */
  PLATFORM_TOKEN?: string;
  /** Applied by the test harness only; never present in production. */
  TEST_MIGRATIONS?: unknown;
}

/** The signed-in caller, reconstructed from the access token on every request. */
export interface AuthContext {
  userId: string;
  tenantId: string;
  branchId: string | null;
  role: string;
  permissionVersion: number;
  deviceId: string;
}

export interface TokenClaims {
  sub: string;
  tid: string;
  bid: string | null;
  role: string;
  pv: number;
  dv: string;
}

export type MutationOp = 'insert' | 'patch' | 'delete';

export interface Mutation {
  mutation_id: string;
  entity: string;
  row_id: string;
  op: MutationOp;
  fields?: Record<string, unknown>;
  base_version: number;
  device_ts: string;
  job_id?: string | null;
}

export type MutationStatus = 'applied' | 'merged' | 'rejected' | 'duplicate';

export interface MutationResult {
  mutation_id: string;
  status: MutationStatus;
  row_id: string;
  server_version?: number;
  row?: Record<string, unknown>;
  error?: { code: string; message: string };
}
