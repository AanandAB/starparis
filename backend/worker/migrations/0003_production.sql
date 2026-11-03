-- Production (Phase 3A): workflow templates and the task pool.
--
-- Tasks are the unit of work every role sees. An order creates one task per
-- stage in its product's workflow; only the first stage starts `available`,
-- the rest wait in sequence. That is what makes "where is my job?" answerable
-- without asking anyone.
--
-- workflow_stages is reference data (like products): it rides on /v1/catalogue,
-- so a device that has never synced still knows the stages.

ALTER TABLE products ADD COLUMN workflow_key TEXT NOT NULL DEFAULT 'print_std';

CREATE TABLE workflow_stages (
  id            TEXT PRIMARY KEY,
  tenant_id     TEXT NOT NULL,
  workflow_key  TEXT NOT NULL,
  stage_key     TEXT NOT NULL,
  name_en       TEXT NOT NULL,
  name_ar       TEXT,
  sequence      INTEGER NOT NULL,
  required_role TEXT NOT NULL,
  -- Stage waits for its predecessor to finish (normal) or opens at order time.
  waits_for_previous INTEGER NOT NULL DEFAULT 1,
  created_at    TEXT NOT NULL,
  updated_at    TEXT NOT NULL,
  version       INTEGER NOT NULL DEFAULT 1,
  deleted_at    TEXT
);
CREATE UNIQUE INDEX idx_workflow_stage ON workflow_stages (tenant_id, workflow_key, stage_key);
CREATE INDEX idx_workflow_seq ON workflow_stages (tenant_id, workflow_key, sequence);

CREATE TABLE tasks (
  id            TEXT PRIMARY KEY,
  tenant_id     TEXT NOT NULL,
  branch_id     TEXT,
  order_id      TEXT NOT NULL,
  order_item_id TEXT,
  stage_key     TEXT NOT NULL,
  stage_name    TEXT NOT NULL,
  sequence      INTEGER NOT NULL,
  title         TEXT NOT NULL,
  status        TEXT NOT NULL
                  CHECK (status IN ('waiting', 'available', 'assigned', 'in_progress',
                                    'paused', 'done', 'rework', 'cancelled')),
  assigned_to   TEXT,
  required_role TEXT NOT NULL,
  qty           INTEGER NOT NULL DEFAULT 0,
  priority      TEXT NOT NULL DEFAULT 'normal',
  due_at        TEXT,
  started_at    TEXT,
  done_at       TEXT,
  -- Last explanation given with a pause, rework or cancel. Kept on the row so
  -- the board can show it without joining the event log.
  reason        TEXT,
  rework_count  INTEGER NOT NULL DEFAULT 0,
  notes         TEXT,
  created_at    TEXT NOT NULL,
  updated_at    TEXT NOT NULL,
  created_by    TEXT,
  updated_by    TEXT,
  version       INTEGER NOT NULL DEFAULT 1,
  deleted_at    TEXT
);
CREATE INDEX idx_tasks_board ON tasks (tenant_id, branch_id, status, stage_key);
CREATE INDEX idx_tasks_order ON tasks (order_id, sequence);
CREATE INDEX idx_tasks_assignee ON tasks (tenant_id, assigned_to, status);

-- Append-only history. The task row says where a job is now; this says how it
-- got there, which is the question asked after a complaint.
CREATE TABLE task_events (
  id          TEXT PRIMARY KEY,
  tenant_id   TEXT NOT NULL,
  task_id     TEXT NOT NULL,
  from_status TEXT,
  to_status   TEXT NOT NULL,
  actor_id    TEXT,
  reason      TEXT,
  created_at  TEXT NOT NULL
);
CREATE INDEX idx_task_events_task ON task_events (task_id, created_at);
