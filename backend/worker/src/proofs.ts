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
