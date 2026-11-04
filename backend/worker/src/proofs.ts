/**
 * Proofs: the record of what the customer was shown, and what they said.
 *
 * The file itself lives wherever the shop already keeps artwork (WhatsApp,
 * Drive, the RIP hot folder) and the row holds a link. That is not a shortcut —
 * it is what makes the feature usable on day one, with no upload, no storage
 * bill and no 2 MB D1 row limit. What the system owns is the trail: version,
 * who sent it, when, and the decision.
 */

import type { AuthContext, Env } from './types';

type Row = Record<string, unknown>;

interface TransitionRule {
  requiresNote?: boolean;
  managerOnly?: boolean;
}

/** draft → sent → approved | rejected, rejected → superseded (a new version). */
export const PROOF_TRANSITIONS: Record<string, Record<string, TransitionRule>> = {
  draft: {
    sent: {},
    superseded: {},
  },
  sent: {
    approved: {},
    rejected: { requiresNote: true },
    superseded: { managerOnly: true },
  },
  approved: {
    superseded: { managerOnly: true },
  },
  rejected: {
    superseded: {},
  },
  superseded: {},
};

const MANAGERS: ReadonlySet<string> = new Set(['owner', 'manager']);

export interface ProofMutationError {
  code: string;
  message: string;
}

/**
 * Validates a proof patch. Two rules matter:
 *  - a decision needs a proof that was actually sent (no approving a draft);
 *  - a rejection needs a note, because "customer said no" with no reason is not
 *    something a designer can work from.
 */
export function prepareProofPatch(
  fields: Row,
  existing: Row,
  ctx: AuthContext,
): { fields: Row } | { error: ProofMutationError } {
  const next: Row = { ...fields };
  const from = String(existing['status'] ?? 'draft');
  const to = next['status'] === undefined ? from : String(next['status']);

  if (next['status'] !== undefined && to !== from) {
    const rule = PROOF_TRANSITIONS[from]?.[to];
    if (!rule) {
      return {
        error: {
          code: 'ILLEGAL_TRANSITION',
          message: `A proof cannot move from ${from} to ${to}.`,
        },
      };
    }
    if (rule.managerOnly && !MANAGERS.has(ctx.role)) {
      return {
        error: {
          code: 'PERMISSION_DENIED',
          message: `Only a manager can supersede a proof that is ${from}.`,
        },
      };
    }
    if (rule.requiresNote && String(next['decided_note'] ?? existing['decided_note'] ?? '').trim().length < 3) {
      return {
        error: {
          code: 'NOTE_REQUIRED',
          message: 'Write what the customer asked to change before rejecting.',
        },
      };
    }

    const now = new Date().toISOString();
    if (to === 'sent') next['sent_at'] = now;
    if (to === 'approved' || to === 'rejected') next['decided_at'] = now;
  }

  return { fields: next };
}

/**
 * When a task leaves in_progress, write the stretch of work that just ended.
 * Minutes are computed from the server's own `started_at` and its own clock, so
 * the billable number cannot be forged by a device.
 *
 * Returns the insert plus its change-log row: time is written by the server and
 * still has to reach every device, which only happens through the log.
 */
export function recordTimeEntry(
  env: Env,
  ctx: AuthContext,
  task: Row,
): D1PreparedStatement[] {
  const startedAt = task['started_at'] ? String(task['started_at']) : null;
  if (!startedAt) return [];

  const start = Date.parse(startedAt);
  if (Number.isNaN(start)) return [];

  const now = Date.now();
  // A minute is the smallest unit that means anything on a shop floor, and a
  // negative duration (clock skew) would be worse than useless.
  const minutes = Math.max(1, Math.round((now - start) / 60000));
  const id = crypto.randomUUID();
  const endedAt = new Date(now).toISOString();

  const row: Row = {
    id,
    tenant_id: ctx.tenantId,
    branch_id: (task['branch_id'] as string | null) ?? null,
    task_id: task['id'],
    order_id: task['order_id'],
    user_id: (task['assigned_to'] as string | null) ?? null,
    started_at: new Date(start).toISOString(),
    ended_at: endedAt,
    minutes,
    auto: 1,
    created_at: endedAt,
    version: 1,
  };

  return [
    env.DB.prepare(
      `INSERT INTO time_entries (
          id, tenant_id, branch_id, task_id, order_id, user_id,
          started_at, ended_at, minutes, auto, created_at, version
       ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?, 1)`,
    ).bind(
      id,
      row['tenant_id'],
      row['branch_id'],
      row['task_id'],
      row['order_id'],
      row['user_id'],
      row['started_at'],
      endedAt,
      minutes,
      endedAt,
    ),
    env.DB.prepare(
      `INSERT INTO change_log (
          tenant_id, entity, row_id, op, branch_id, assignee_id, job_id,
          actor_id, device_id, row_version, changed_fields_json, row_json, server_ts
       ) VALUES (?, 'time_entries', ?, 'insert', ?, ?, NULL, ?, ?, 1, NULL, ?, ?)`,
    ).bind(
      ctx.tenantId,
      id,
      row['branch_id'],
      row['user_id'],
      ctx.userId,
      ctx.deviceId,
      JSON.stringify(row),
      endedAt,
    ),
  ];
}

// ---------------------------------------------------------------------------
// Proof files, approval tokens, and the approval record.
//
// The approval token is the customer's only credential: minted when a proof is
// sent (or when its file is uploaded), carried in the link, and checked on the
// no-login approval page. The file itself is stored in `file_chunks` (see
// migration 0016) and reassembled on demand.
// ---------------------------------------------------------------------------

const MAX_CHUNK_BYTES = 256 * 1024; // 256 KB — one chunk never exceeds this decoded
const MAX_FILE_BYTES = 1_536_000; // 1.5 MB — the upload ceiling (3× the chunk cap, with headroom)
const MAX_THUMBNAIL_BYTES = 20 * 1024; // 20 KB — the approval page's preview

/** Who may push a proof file up. A proof is design work: its maker, the manager. */
const PROOF_UPLOADERS: ReadonlySet<string> = new Set(['owner', 'manager', 'designer']);

/**
 * The row-level gate on upload. Reuses the branch-scope rule the rest of the
 * shop already applies: the owner crosses branches, everyone else stays in
 * their own. A proof without a branch (legacy link rows) is editable by anyone
 * who may upload, because there is no branch to guard against.
 */
export function canUploadProof(ctx: AuthContext, proof: Row): boolean {
  if (!PROOF_UPLOADERS.has(ctx.role)) return false;
  if (ctx.role === 'owner') return true;
  const branch = (proof['branch_id'] as string | null) ?? null;
  return branch === null || branch === ctx.branchId;
}

/** A proof looked up by its approval token, or null when the link is dead. */
export async function getProofByToken(env: Env, token: string): Promise<Row | null> {
  return (await env.DB.prepare(
    'SELECT * FROM proofs WHERE approval_token = ? AND deleted_at IS NULL',
  )
    .bind(token)
    .first()) as Row | null;
}

/**
 * Mints the proof's approval token on first need and returns it. Idempotent and
 * safe to call from both the send path (sync) and the upload path: the second
 * call finds the token already set and returns it, so a link minted at upload
 * time is the same link the customer still uses after the proof is sent.
 */
export async function ensureApprovalToken(env: Env, proof: Row): Promise<string> {
  const id = String(proof['id']);
  const existing = await env.DB.prepare('SELECT approval_token FROM proofs WHERE id = ?')
    .bind(id)
    .first<{ approval_token: string | null }>();
  if (existing?.approval_token) return existing.approval_token;

  const token = crypto.randomUUID();
  await env.DB.prepare(
    'UPDATE proofs SET approval_token = ?, updated_at = ? WHERE id = ? AND approval_token IS NULL',
  )
    .bind(token, new Date().toISOString(), id)
    .run();

  // Re-read so a concurrent mint is never shadowed by an uncommitted one.
  const after = await env.DB.prepare('SELECT approval_token FROM proofs WHERE id = ?')
    .bind(id)
    .first<{ approval_token: string | null }>();
  return after?.approval_token ?? token;
}

export interface ApproveInput {
  decision?: unknown;
  note?: unknown;
  deciderName?: unknown;
}

export type ApproveResult =
  | { ok: true; status: string; decidedAt: string }
  | { ok: false; code: string; message: string };

/**
 * Records a customer decision from the approval page. The token is the only
 * auth, so the state machine is the guard: a decision must be a legal move
 * (sent → approved | rejected), a rejection still needs its reason, and a
 * proof that was already decided is final — changing it means a new version.
 */
export async function approveByToken(
  env: Env,
  token: string,
  input: ApproveInput,
): Promise<ApproveResult> {
  const proof = await getProofByToken(env, token);
  if (!proof) {
    return { ok: false, code: 'NOT_FOUND', message: 'This approval link is not valid.' };
  }

  const decision = input.decision === 'approved' || input.decision === 'rejected' ? input.decision : '';
  if (!decision) {
    return { ok: false, code: 'BAD_REQUEST', message: 'Choose approve or request changes.' };
  }

  const from = String(proof['status'] ?? 'draft');
  if (from === 'approved' || from === 'rejected') {
    return {
      ok: false,
      code: 'ALREADY_DECIDED',
      message: `This proof was already ${from}. Send a new version if anything must change.`,
    };
  }

  // Validate against the same transition table the sync path uses, so the two
  // ways into a decision can never disagree.
  const rule = PROOF_TRANSITIONS[from]?.[decision];
  if (!rule) {
    return {
      ok: false,
      code: 'ILLEGAL_TRANSITION',
      message: `A proof cannot move from ${from} to ${decision}.`,
    };
  }

  const note = String(input.note ?? '').trim();
  if (rule.requiresNote && note.length < 3) {
    return {
      ok: false,
      code: 'NOTE_REQUIRED',
      message: 'Tell us what to change before requesting changes.',
    };
  }

  const deciderName = String(input.deciderName ?? '').trim();
  const decidedAt = new Date().toISOString();
  const proofId = String(proof['id']);
  const tenantId = String(proof['tenant_id']);
  const version = Number(proof['version'] ?? 0) + 1;

  await env.DB.batch([
    env.DB.prepare(
      `INSERT INTO proof_approvals (id, tenant_id, proof_id, decision, note, channel, decider_name, decided_at)
       VALUES (?, ?, ?, ?, ?, 'web', ?, ?)`,
    ).bind(
      crypto.randomUUID(),
      tenantId,
      proofId,
      decision,
      note || null,
      deciderName || null,
      decidedAt,
    ),
    env.DB.prepare(
      `UPDATE proofs SET status = ?, decided_at = ?, decided_note = ?, updated_at = ?, version = ?
       WHERE id = ? AND tenant_id = ?`,
    ).bind(decision, decidedAt, note || null, decidedAt, version, proofId, tenantId),
  ]);

  return { ok: true, status: decision, decidedAt };
}

export interface ProofFile {
  bytes: Uint8Array;
  mimeType: string;
  sha256: string;
}

/** Reassembles a proof's chunks in seq order. Returns null when there is no file. */
export async function getProofFile(env: Env, token: string): Promise<ProofFile | null> {
  const proof = await getProofByToken(env, token);
  if (!proof || !proof['file_size']) return null;

  const { results } = await env.DB.prepare(
    'SELECT seq, data FROM file_chunks WHERE proof_id = ? ORDER BY seq ASC',
  )
    .bind(String(proof['id']))
    .all<{ seq: number; data: unknown }>();

  const chunks = results ?? [];
  if (chunks.length === 0) return null;

  let total = 0;
  for (const chunk of chunks) total += toBytes(chunk.data).length;
  const bytes = new Uint8Array(total);
  let offset = 0;
  for (const chunk of chunks) {
    const part = toBytes(chunk.data);
    bytes.set(part, offset);
    offset += part.length;
  }

  return {
    bytes,
    mimeType: String(proof['mime_type'] ?? 'application/octet-stream'),
    sha256: String(proof['file_sha256'] ?? ''),
  };
}

export interface StoreProofFileInput {
  mimeType: string;
  sha256: string;
  chunks: Uint8Array[];
  thumbnail: Uint8Array | null;
}

export type StoreProofFileResult =
  | { ok: true; fileSize: number }
  | { ok: false; code: string; message: string };

/**
 * Writes a proof's chunks and its file metadata in one atomic batch, replacing
 * any earlier upload. The file's SHA-256 is recomputed from the reassembled
 * bytes and must match what the uploader claimed, so a corrupt upload is
 * refused rather than stored as the record.
 */
export async function storeProofFile(
  env: Env,
  proof: Row,
  input: StoreProofFileInput,
): Promise<StoreProofFileResult> {
  const proofId = String(proof['id']);
  const tenantId = String(proof['tenant_id']);

  let total = 0;
  for (const chunk of input.chunks) {
    if (chunk.length === 0 || chunk.length > MAX_CHUNK_BYTES) {
      return { ok: false, code: 'CHUNK_TOO_LARGE', message: 'Each chunk must be at most 256 KB.' };
    }
    total += chunk.length;
  }
  if (total > MAX_FILE_BYTES) {
    return {
      ok: false,
      code: 'FILE_TOO_LARGE',
      message: 'The proof file is over 1.5 MB. Compress it before uploading.',
    };
  }
  if (input.thumbnail && input.thumbnail.length > MAX_THUMBNAIL_BYTES) {
    return {
      ok: false,
      code: 'THUMBNAIL_TOO_LARGE',
      message: 'The thumbnail must be at most 20 KB.',
    };
  }

  const combined = new Uint8Array(total);
  let offset = 0;
  for (const chunk of input.chunks) {
    combined.set(chunk, offset);
    offset += chunk.length;
  }
  const actual = await sha256Bytes(combined);
  if (actual !== input.sha256.toLowerCase()) {
    return { ok: false, code: 'SHA_MISMATCH', message: 'The file did not arrive intact. Try again.' };
  }

  const now = new Date().toISOString();
  const statements: D1PreparedStatement[] = [
    env.DB.prepare('DELETE FROM file_chunks WHERE proof_id = ?').bind(proofId),
  ];
  for (let seq = 0; seq < input.chunks.length; seq++) {
    statements.push(
      env.DB.prepare(
        `INSERT INTO file_chunks (id, tenant_id, proof_id, seq, sha256, data, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
      ).bind(
        crypto.randomUUID(),
        tenantId,
        proofId,
        seq,
        await sha256Bytes(input.chunks[seq]!),
        input.chunks[seq],
        now,
      ),
    );
  }
  statements.push(
    env.DB.prepare(
      `UPDATE proofs SET file_sha256 = ?, file_size = ?, mime_type = ?, thumbnail = ?, updated_at = ?
       WHERE id = ? AND tenant_id = ?`,
    ).bind(
      input.sha256.toLowerCase(),
      total,
      input.mimeType,
      input.thumbnail,
      now,
      proofId,
      tenantId,
    ),
  );

  await env.DB.batch(statements);
  return { ok: true, fileSize: total };
}

/** SHA-256 of raw bytes, hex-encoded, matching the app's own digest. */
async function sha256Bytes(bytes: Uint8Array): Promise<string> {
  const digest = await crypto.subtle.digest('SHA-256', bytes as BufferSource);
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, '0')).join('');
}

/**
 * D1 returns BLOBs as ArrayBuffer, Uint8Array, or a plain array-like object
 * depending on the runtime (workerd vs. the vitest harness). Normalise all
 * three to Uint8Array so reassembly works in tests and production alike.
 */
function toBytes(value: unknown): Uint8Array {
  if (value instanceof Uint8Array) return value;
  if (value instanceof ArrayBuffer) return new Uint8Array(value);
  if (Array.isArray(value)) return Uint8Array.from(value as number[]);
  if (typeof value === 'object' && value !== null && 'length' in (value as object)) {
    return Uint8Array.from(value as ArrayLike<number>);
  }
  return new Uint8Array(0);
}
