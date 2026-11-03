/**
 * Vendor jobs: work handed to an outside shop.
 *
 * The state machine is deliberately short. A vendor job is only interesting at
 * four moments — written, sent, back, costed — and inventing more states gives
 * the shop something to maintain that nobody asked for.
 *
 * Timestamps are the server's: `sent_at` and `received_at` are recorded here, not
 * sent up by the device, for the same reason task time is — a tablet with a wrong
 * clock must not be able to claim a job came back on time.
 */


type Row = Record<string, unknown>;

export type VendorJobStatus = 'draft' | 'sent' | 'received' | 'closed' | 'cancelled';

export const VENDOR_JOB_TRANSITIONS: Record<VendorJobStatus, VendorJobStatus[]> = {
  draft: ['sent', 'cancelled'],
  sent: ['received', 'cancelled'],
  // Back but wrong? It goes out again: that is a real thing that happens daily.
  received: ['closed', 'sent', 'cancelled'],
  closed: [],
  cancelled: [],
};

export interface VendorMutation {
  fields: Row;
  existing: Row;
  now: string;
  userId: string;
}

export type VendorPatchResult =
  | { fields: Row; error?: never }
  | { error: { code: string; message: string }; fields?: never };

export function prepareVendorJobPatch(input: VendorMutation): VendorPatchResult {
  const fields: Row = { ...input.fields };
  const from = String(input.existing['status'] ?? 'draft');

  if (fields['status'] == null) {
    // Editing the description or the cost of an open job is allowed; editing a
    // closed one is not, because it has already been costed.
    if (from === 'closed') {
      return {
        error: {
          code: 'VENDOR_JOB_CLOSED',
          message: 'This vendor job is closed. Raise a new one if something changed.',
        },
      };
    }
    return { fields };
  }

  const to = String(fields['status']) as VendorJobStatus;
  const allowed = VENDOR_JOB_TRANSITIONS[from as VendorJobStatus] ?? [];
  if (!allowed.includes(to)) {
    return {
      error: {
        code: 'ILLEGAL_TRANSITION',
        message: `A vendor job cannot go from ${from} to ${to}.`,
      },
    };
  }

  if (to === 'sent') {
    fields['sent_at'] = input.now;
    fields['received_at'] = null;
  }
  if (to === 'received') {
    fields['received_at'] = input.now;
  }
  if (to === 'closed' && fields['received_at'] == null) {
    fields['received_at'] = input.existing['received_at'] ?? input.now;
  }

  return { fields };
}
