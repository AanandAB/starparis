import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../app_config.dart';

/// The public, no-login approval page for a proof. The token is the customer's
/// only credential, so the link must be treated as a secret — anyone with it
/// can approve or request changes.
String approvalLink(String token) => '${AppConfig.apiBaseUrl}/approve/$token';

/// A minimal extension→MIME map for the file types a proof can be. Enough for
/// the upload to know whether to compress an image or refuse a big PDF; no
/// full MIME registry needed.
String? mimeTypeForPath(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.gif')) return 'image/gif';
  if (lower.endsWith('.bmp')) return 'image/bmp';
  if (lower.endsWith('.pdf')) return 'application/pdf';
  return null;
}

/// Uploads a proof's actual file to the Worker, which stores it in D1 and
/// returns the approval link the customer opens.
///
/// The network is required by design: the file is the authoritative copy of
/// what the customer approved, so it lives next to the approval record on the
/// server, not only on the designer's machine.
class ProofService {
  ProofService({
    required this.baseUrl,
    required this.tokenProvider,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final Future<String?> Function() tokenProvider;
  final http.Client _client;

  static const int _maxImageBytes = 600 * 1024; // 600 KB, the agreed image ceiling
  static const int _maxPdfBytes = 600 * 1024; // no PDF recompression in v1
  static const int _chunkBytes = 256 * 1024; // one D1 chunk, decoded
  static const int _maxThumbnailBytes = 20 * 1024; // the approval page's preview

  /// Uploads [bytes] for [proofId] and returns the approval link. Images are
  /// downscaled so the PNG re-encode stays under 600 KB; PDFs are passed
  /// through as-is but refused over 600 KB (no PDF recompression in v1).
  Future<String> uploadProof({
    required String proofId,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    var uploadBytes = bytes;
    var uploadType = mimeType;
    Uint8List? thumbnail;

    if (mimeType == 'application/pdf') {
      if (bytes.length > _maxPdfBytes) {
        throw StateError(
          'PDFs over 600 KB cannot be uploaded yet. Compress the PDF or send the link instead.',
        );
      }
    } else if (mimeType.startsWith('image/')) {
      final compressed = await _compressImage(bytes, mimeType);
      uploadBytes = compressed.bytes;
      uploadType = compressed.mimeType;
      thumbnail = await _makeThumbnail(bytes);
    }

    final digest = sha256.convert(uploadBytes).toString();
    final chunks = <String>[];
    for (var offset = 0; offset < uploadBytes.length; offset += _chunkBytes) {
      final end = offset + _chunkBytes < uploadBytes.length
          ? offset + _chunkBytes
          : uploadBytes.length;
      chunks.add(base64Encode(uploadBytes.sublist(offset, end)));
    }

    final body = <String, Object?>{
      'mime_type': uploadType,
      'sha256': digest,
      'chunks': chunks,
      if (thumbnail != null) 'thumbnail': base64Encode(thumbnail),
    };

    final token = await tokenProvider();
    if (token == null) {
      throw StateError('Sign in again to upload a proof.');
    }

    final request = http.Request(
      'POST',
      Uri.parse('$baseUrl/v1/proofs/$proofId/file'),
    )
      ..headers['content-type'] = 'application/json'
      ..headers['authorization'] = 'Bearer $token'
      ..body = jsonEncode(body);

    final response = await http.Response.fromStream(
      // Larger timeout than other calls: a 600 KB image split into chunks and
      // re-assembled server-side takes a moment.
      await _client.send(request).timeout(const Duration(seconds: 60)),
    );

    final decoded = (jsonDecode(response.body) as Map).cast<String, Object?>();
    if (response.statusCode >= 400) {
      final error = (decoded['error'] as Map?)?.cast<String, Object?>();
      throw StateError(
        error?['message'] as String? ?? 'Upload refused (${response.statusCode}).',
      );
    }

    final approvalToken = decoded['approval_token'] as String?;
    if (approvalToken == null) {
      throw StateError('The upload succeeded but no approval link came back.');
    }
    return approvalLink(approvalToken);
  }

  void dispose() => _client.close();

  /// Downscales an image until its PNG re-encode fits 600 KB. PNG because
  /// dart:ui has no JPEG encoder and adding an image package would be a new
  /// dependency; photos therefore shrink more than they would as JPEG, which is
  /// an accepted v1 trade-off.
  Future<({Uint8List bytes, String mimeType})> _compressImage(
    Uint8List bytes,
    String originalType,
  ) async {
    if (bytes.length <= _maxImageBytes) {
      return (bytes: bytes, mimeType: originalType);
    }

    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final width = frame.image.width;
    frame.image.dispose();
    codec.dispose();

    var scale = 1.0;
    while (scale > 0.02) {
      final encoded = await _encodePng(bytes, targetWidth: (width * scale).round());
      if (encoded.length <= _maxImageBytes) {
        return (bytes: encoded, mimeType: 'image/png');
      }
      scale *= 0.75;
    }
    return (bytes: await _encodePng(bytes, targetWidth: 128), mimeType: 'image/png');
  }

  /// A small preview for the approval page, downscaled until it fits 20 KB.
  Future<Uint8List> _makeThumbnail(Uint8List bytes) async {
    var width = 320;
    while (width >= 64) {
      final encoded = await _encodePng(bytes, targetWidth: width);
      if (encoded.length <= _maxThumbnailBytes) return encoded;
      width = width ~/ 2;
    }
    return _encodePng(bytes, targetWidth: 64);
  }

  /// Re-encodes [bytes] as a PNG at the given width, preserving aspect ratio.
  Future<Uint8List> _encodePng(Uint8List bytes, {required int targetWidth}) async {
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: targetWidth);
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    frame.image.dispose();
    codec.dispose();
    return data!.buffer.asUint8List();
  }
}
