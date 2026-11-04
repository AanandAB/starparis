import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starparis_design/starparis_design.dart';
import 'package:starparis_sync/starparis_sync.dart';

import '../app_config.dart';
import '../auth/session.dart';
import '../providers.dart';
import 'proof_service.dart';
import 'whatsapp.dart';

/// Proof versions for one order: what the customer was shown and what they said.
///
/// Files are never uploaded. The shop already keeps artwork in WhatsApp or
/// Drive; this keeps the part that goes missing — which version was sent, when,
/// and whether it was approved.
class ProofsSection extends ConsumerStatefulWidget {
  const ProofsSection({required this.order, super.key});

  final Order order;

  @override
  ConsumerState<ProofsSection> createState() => _ProofsSectionState();
}

class _ProofsSectionState extends ConsumerState<ProofsSection> {
  bool _busy = false;

  /// Files attached to proofs that have not been uploaded yet, keyed by proof
  /// id. The proof row itself holds only a link/empty url; the bytes wait here
  /// until the proof is sent, then go up to the server.
  final Map<String, ({Uint8List bytes, String mimeType})> _files = {};

  Session? get _session => ref.read(sessionProvider);

  Future<void> _add() async {
    final result = await showDialog<_ProofDraft>(
      context: context,
      builder: (_) => const _AddProofDialog(),
    );
    if (result == null || !mounted) return;

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final session = _session;
      if (session == null) throw StateError('Session expired');
      final db = ref.read(bootstrapProvider).db;
      final id = await db.addProofLocal(
        orderId: widget.order.id,
        tenantId: session.tenantId,
        branchId: session.branchId,
        userId: session.userId,
        label: result.label,
        url: result.url,
        note: result.note,
      );
      if (result.fileBytes != null) {
        _files[id] = (bytes: result.fileBytes!, mimeType: result.mimeType!);
      }
      unawaited(ref.read(bootstrapProvider).engine?.syncNow());
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Proof saved. Send it when you are ready.'),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send(Proof proof) async {
    final session = _session;
    if (session == null) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bootstrap = ref.read(bootstrapProvider);
      final file = _files[proof.id];

      // A file-backed proof is uploaded before it is marked sent: a failed
      // upload leaves it in draft, not stranded as "sent" with no link shared.
      var shareUrl = proof.url;
      if (file != null) {
        await bootstrap.engine?.syncNow(); // the row must exist server-side first
        final service = ProofService(
          baseUrl: AppConfig.apiBaseUrl,
          tokenProvider: bootstrap.auth.accessToken,
        );
        try {
          shareUrl = await service.uploadProof(
            proofId: proof.id,
            bytes: file.bytes,
            mimeType: file.mimeType,
          );
        } finally {
          service.dispose();
        }
        _files.remove(proof.id);
      }

      await bootstrap.db.setProofStatus(
        proof: proof,
        status: 'sent',
        userId: session.userId,
      );
      unawaited(bootstrap.engine?.syncNow());

      final phone = await bootstrap.db.primaryPhoneFor(widget.order.customerId);
      if (phone == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Proof marked sent. No phone saved, so send the link yourself.',
            ),
          ),
        );
        return;
      }
      final message = file != null
          ? WhatsApp.approvalMessage(revision: proof.revision, link: shareUrl)
          : WhatsApp.proofMessage(
              customerName: widget.order.customerName ?? 'there',
              jobNumber: widget.order.numberDisplay,
              revision: proof.revision,
              url: shareUrl,
              shopName: AppConfig.company.name,
            );
      final opened = await WhatsApp.open(
        phoneE164: phone,
        message: message,
      );
      if (!opened && mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('WhatsApp did not open. Is it installed?'),
          ),
        );
      }
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decide(Proof proof, String status) async {
    final session = _session;
    if (session == null) return;

    String? note;
    if (status == 'rejected') {
      note = await showDialog<String>(
        context: context,
        builder: (_) => const _RejectProofDialog(),
      );
      if (note == null || !mounted) return;
    }

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bootstrap = ref.read(bootstrapProvider);
      await bootstrap.db.setProofStatus(
        proof: proof,
        status: status,
        userId: session.userId,
        note: note,
      );
      unawaited(bootstrap.engine?.syncNow());
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            status == 'approved' ? 'Proof marked approved.' : 'Proof marked rejected. Send the design back from Production.',
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final db = ref.watch(bootstrapProvider).db;

    return StreamBuilder<List<Proof>>(
      stream: db.watchProofs(widget.order.id),
      builder: (context, snapshot) {
        final proofs = snapshot.data ?? const <Proof>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text('Proofs', style: theme.textTheme.titleSmall),
                ),
                TextButton.icon(
                  onPressed: _busy ? null : _add,
                  icon: const Icon(Icons.add_link, size: 18),
                  label: const Text('Add proof'),
                ),
              ],
            ),
            if (proofs.isEmpty)
              Text(
                'No proof yet. Add the link you sent the customer.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            for (final proof in proofs)
              _ProofRow(
                key: ValueKey<String>(proof.id),
                proof: proof,
                busy: _busy,
                onSend: () => _send(proof),
                onApprove: () => _decide(proof, 'approved'),
                onReject: () => _decide(proof, 'rejected'),
              ),
          ],
        );
      },
    );
  }
}

class _ProofRow extends StatelessWidget {
  const _ProofRow({
    required this.proof,
    required this.busy,
    required this.onSend,
    required this.onApprove,
    required this.onReject,
    super.key,
  });

  final Proof proof;
  final bool busy;
  final VoidCallback onSend;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: StarSpace.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 34,
            child: Text(
              'v${proof.revision}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(proof.label, style: theme.textTheme.bodyMedium),
                if (proof.decidedNote != null && proof.decidedNote!.isNotEmpty)
                  Text(
                    proof.decidedNote!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: StarSpace.sm),
          _chip(proof.status),
          const SizedBox(width: StarSpace.sm),
          if (proof.status == 'draft')
            TextButton(
              onPressed: busy ? null : onSend,
              child: const Text('Send'),
            ),
          if (proof.status == 'sent') ...<Widget>[
            TextButton(
              onPressed: busy ? null : onApprove,
              child: const Text('Approved'),
            ),
            TextButton(
              onPressed: busy ? null : onReject,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              child: const Text('Rejected'),
            ),
          ],
        ],
      ),
    );
  }

  static Widget _chip(String status) => switch (status) {
    'sent' => const StatusChip(label: 'Sent', tone: StatusTone.active),
    'approved' => const StatusChip(label: 'Approved', tone: StatusTone.done),
    'rejected' => const StatusChip(label: 'Rejected', tone: StatusTone.problem),
    'superseded' => const StatusChip(label: 'Superseded'),
    _ => const StatusChip(label: 'Draft'),
  };
}

class _ProofDraft {
  const _ProofDraft({
    required this.label,
    required this.url,
    this.note,
    this.fileBytes,
    this.mimeType,
  });

  final String label;
  /// The link the proof points at; empty for a file-backed proof (the file is
  /// uploaded to D1 and served from the approval page instead).
  final String url;
  final String? note;
  final Uint8List? fileBytes;
  final String? mimeType;
}

class _AddProofDialog extends StatefulWidget {
  const _AddProofDialog();

  @override
  State<_AddProofDialog> createState() => _AddProofDialogState();
}

class _AddProofDialogState extends State<_AddProofDialog> {
  final TextEditingController _label = TextEditingController(text: 'Proof');
  final TextEditingController _url = TextEditingController();
  final TextEditingController _filePath = TextEditingController();
  final TextEditingController _note = TextEditingController();
  String? _error;
  bool _reading = false;

  @override
  void dispose() {
    _label.dispose();
    _url.dispose();
    _filePath.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_reading) return;
    final label = _label.text.trim().isEmpty ? 'Proof' : _label.text.trim();
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();
    final url = _url.text.trim();
    final filePath = _filePath.text.trim();

    // A local file takes precedence over a link: the file becomes the
    // authoritative copy the customer approves, served from the approval page.
    if (filePath.isNotEmpty) {
      setState(() => _reading = true);
      try {
        final bytes = await File(filePath).readAsBytes();
        final mime = mimeTypeForPath(filePath);
        if (mime == null) {
          setState(() => _error = 'Unsupported file type. Use an image or a PDF.');
          return;
        }
        if (!mounted) return;
        Navigator.of(context).pop(
          _ProofDraft(
            label: label,
            url: '',
            note: note,
            fileBytes: bytes,
            mimeType: mime,
          ),
        );
      } on FileSystemException {
        setState(() => _error = 'Could not read that file. Check the path.');
      } finally {
        if (mounted) setState(() => _reading = false);
      }
      return;
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      setState(
        () => _error = 'Paste a link that starts with https://, or attach a file.',
      );
      return;
    }
    Navigator.of(context).pop(_ProofDraft(label: label, url: url, note: note));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add a proof'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: _label,
                decoration: const InputDecoration(labelText: 'What is it?'),
              ),
              const SizedBox(height: StarSpace.sm),
              TextField(
                controller: _url,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Link to the file',
                  hintText: 'https://drive.google.com/…',
                ),
              ),
              const SizedBox(height: StarSpace.sm),
              TextField(
                controller: _filePath,
                decoration: const InputDecoration(
                  labelText: 'Or attach a file (path on this PC)',
                  hintText: r'C:\designs\business-card-front.png',
                ),
              ),
              const SizedBox(height: StarSpace.sm),
              TextField(
                controller: _note,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'Front only, back follows',
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: StarSpace.sm),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _reading ? null : _save, child: const Text('Save')),
      ],
    );
  }
}

class _RejectProofDialog extends StatefulWidget {
  const _RejectProofDialog();

  @override
  State<_RejectProofDialog> createState() => _RejectProofDialogState();
}

class _RejectProofDialogState extends State<_RejectProofDialog> {
  final TextEditingController _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('What did the customer ask to change?'),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: _note,
          autofocus: true,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Logo too close to the trim on the back',
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final text = _note.text.trim();
            if (text.length < 3) return;
            Navigator.of(context).pop(text);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
