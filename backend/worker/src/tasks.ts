/**
 * Production tasks: the state machine, the server-side rules, and the cascade.
 *
 * Three rules live here rather than in the UI, because the UI is not the only
 * writer: an offline device can push anything it likes.
 *
 *  1. A task may only move along an edge of the state machine (see
 *     packages/domain/lib/src/status.dart — one table, two languages, so a
 *     button the device offers is a transition the server accepts).
 *  2. Pause, rework and cancel require a reason; a silent stop is what a
 *     manager cannot act on later.
 *  3. Finishing a stage opens the next one. That cascade is written into the
 *     change log so every other device sees it on the next pull.
 */

import type { AuthContext, Env } from './types';

type Row = Record<string, unknown>;

interface TransitionRule {
  requiresReason?: boolean;
  managerOnly?: boolean;
}

/** Mirrors `_taskTransitions` in packages/domain/lib/src/status.dart. */
export const TASK_TRANSITIONS: Record<string, Record<string, TransitionRule>> = {
  waiting: {
    available: {},
    cancelled: { managerOnly: true },
  },
  available: {
    assigned: {},
    cancelled: { managerOnly: true },
  },
  assigned: {
    in_progress: {},
    available: {}, // released back to the pool
    cancelled: { managerOnly: true },
  },
  in_progress: {
    paused: { requiresReason: true },
    done: {},
    rework: { requiresReason: true },
    cancelled: { managerOnly: true },
  },
  paused: {
    in_progress: {},
    rework: { requiresReason: true },
    cancelled: { managerOnly: true },
  },
  done: {
    rework: { requiresReason: true, managerOnly: true },
  },
  rework: {
    in_progress: {},
    cancelled: { managerOnly: true },
  },
  cancelled: {},
};

const MANAGERS: ReadonlySet<string> = new Set(['owner', 'manager']);

export interface TaskMutationError {
  code: string;
  message: string;
}

/**
 * Validates and completes a task patch. Returns the fields to write (with
 * server-owned timestamps added) or an error. Pure enough to unit test.
 */
export function prepareTaskPatch(
  fields: Row,
  existing: Row,
  ctx: AuthContext,
): { fields: Row } | { error: TaskMutationError } {
  const next: Row = { ...fields };
  const from = String(existing['status'] ?? 'waiting');
  const to = next['status'] === undefined ? from : String(next['status']);

  if (next['status'] !== undefined && to !== from) {
    const rule = TASK_TRANSITIONS[from]?.[to];
    if (!rule) {
      return {
        error: {
          code: 'ILLEGAL_TRANSITION',
          message: `A task cannot move from ${from} to ${to}.`,
        },
      };
    }
    if (rule.managerOnly && !MANAGERS.has(ctx.role)) {
      return {
        error: {
          code: 'PERMISSION_DENIED',
          message: `Only a manager can move a task from ${from} to ${to}.`,
        },
      };
    }
    if (rule.requiresReason) {
      const reason = String(next['reason'] ?? existing['reason'] ?? '').trim();
      if (reason.length < 3) {
        return {
          error: {
            code: 'REASON_REQUIRED',
            message: 'Say why before pausing, sending back or cancelling.',
          },
        };
      }
    }

    // Server-owned timestamps: the client's clock is not trusted for these.
    const now = new Date().toISOString();
    if (to === 'in_progress' && !existing['started_at']) {
      next['started_at'] = now;
    }
    if (to === 'done') {
      next['done_at'] = now;
      if (!existing['started_at']) next['started_at'] = now;
    }
    if (to === 'rework') {
      next['done_at'] = null;
      next['rework_count'] = Number(existing['rework_count'] ?? 0) + 1;
    }
    if (to === 'available') {
      next['assigned_to'] = null;
    }
    if (to === 'assigned' && !next['assigned_to'] && !existing['assigned_to']) {
      next['assigned_to'] = ctx.userId;
    }
  }

  // Claiming an unassigned task is allowed for the person doing the work;
  // handing it to somebody else needs `task.assign`.
  if (next['assigned_to'] !== undefined) {
    const target = next['assigned_to'] === null ? null : String(next['assigned_to']);
    const selfClaim = target === ctx.userId;
    if (!selfClaim && !MANAGERS.has(ctx.role)) {
      return {
        error: {
          code: 'PERMISSION_DENIED',
          message: 'Only a manager can assign work to somebody else.',
        },
      };
    }
  }

  return { fields: next };
}

/**
 * When a task is finished or reopened, the successor in the same order must
 * follow: `waiting` opens on done, `available` goes back to `waiting` on rework.
 * Writes the change-log row itself so other devices receive the cascade.
 */
export async function cascadeStage(
  env: Env,
  ctx: AuthContext,
  orderId: string,
  sequence: number,
  toStatus: string,
): Promise<void> {
  if (toStatus !== 'done' && toStatus !== 'rework') return;

  const next = await env.DB.prepare(
    `SELECT * FROM tasks
      WHERE tenant_id = ? AND order_id = ? AND sequence > ? AND deleted_at IS NULL
        AND status IN ('waiting', 'available')
      ORDER BY sequence ASC LIMIT 1`,
  )
    .bind(ctx.tenantId, orderId, sequence)
    .first<Row>();
  if (!next) return;

  const now = new Date().toISOString();
  const wantStatus = toStatus === 'done' ? 'available' : 'waiting';
  if (String(next['status']) === wantStatus) return;

  const nextVersion = Number(next['version'] ?? 0) + 1;
  const row: Row = { ...next, status: wantStatus, version: nextVersion, updated_at: now, updated_by: ctx.userId };

  await env.DB.batch([
    env.DB.prepare(
      `UPDATE tasks SET status = ?, version = ?, updated_at = ?, updated_by = ?
        WHERE id = ? AND tenant_id = ?`,
    ).bind(wantStatus, nextVersion, now, ctx.userId, next['id'], ctx.tenantId),
    env.DB.prepare(
      `INSERT INTO change_log (
          tenant_id, entity, row_id, op, branch_id, assignee_id, job_id,
          actor_id, device_id, row_version, changed_fields_json, row_json, server_ts
       ) VALUES (?, 'tasks', ?, 'patch', ?, ?, NULL, ?, ?, ?, '["status"]', ?, ?)`,
    ).bind(
      ctx.tenantId,
      next['id'],
      (row['branch_id'] as string | null) ?? null,
      (row['assigned_to'] as string | null) ?? null,
      ctx.userId,
      ctx.deviceId,
      nextVersion,
      JSON.stringify(row),
      now,
    ),
  ]);
}

/** One row of the audit trail per status change, in the same batch as the task. */
export function taskEventStatement(
  env: Env,
  ctx: AuthContext,
  taskId: string,
  from: string | null,
  to: string,
  reason: string | null,
): D1PreparedStatement {
  return env.DB.prepare(
    `INSERT INTO task_events (id, tenant_id, task_id, from_status, to_status, actor_id, reason, created_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
  ).bind(
    crypto.randomUUID(),
    ctx.tenantId,
    taskId,
    from,
    to,
    ctx.userId,
    reason,
    new Date().toISOString(),
  );
}
