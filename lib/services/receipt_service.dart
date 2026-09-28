import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class ReceiptException implements Exception {
  final String message;
  const ReceiptException(this.message);

  @override
  String toString() => message;
}

class ReceiptResult {
  /// Base64 JPEG, or empty when the user backed out of the picker.
  final String data;
  final int byteSize;
  final double aspectRatio;

  const ReceiptResult({
    required this.data,
    required this.byteSize,
    this.aspectRatio = 1,
  });

  bool get isEmpty => data.isEmpty;
}

/// Prepares receipt photos for storage inside the Firestore transaction
/// document.
///
/// Cloud Storage needs the Blaze billing plan, which is not available here, so
/// the image is downscaled and base64 encoded and kept in Firestore alongside
/// the transaction. Firestore caps a document at 1 MiB, so the encoded size is
/// held well under that.
class ReceiptService {
  ReceiptService._();
  static final ReceiptService instance = ReceiptService._();

  final _picker = ImagePicker();

  /// Base64 budget. Firestore's limit is 1 MiB for the whole document, and the
  /// rest of the transaction fields need room too.
  static const int maxEncodedChars = 700 * 1024;

  /// Longest edge after resizing. A receipt only has to be legible, not
  /// printable, and this keeps the encoded size predictable.
  static const int maxEdge = 1000;

  /// Tried in order until the encoded result fits the budget. Lower quality
  /// costs legibility, so it is only reached for busy receipts.
  static const List<int> _qualityLadder = [70, 60, 50, 40, 30];

  static const int _pickMaxEdge = 1600;

  /// Receipt capture needs a camera or gallery: phones, or a browser which
  /// exposes a file picker. Desktop has neither, so the UI hides the button.
  static bool get isSupported {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Picks a photo and returns it as a base64 JPEG sized for Firestore.
  Future<ReceiptResult> pick(ImageSource source) async {
    if (!isSupported) {
      throw const ReceiptException(
        'Receipt photos need a phone or browser. On desktop, use a mobile build.',
      );
    }

    final file = await _pickSafely(source);
    if (file == null) {
      return const ReceiptResult(data: '', byteSize: 0);
    }

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw const ReceiptException('That image could not be read.');
    }

    // Decoding can be slow for a large photo, so keep it off the UI thread.
    final encoded = await compute(_encode, bytes);

    if (encoded.data.length > maxEncodedChars) {
      throw const ReceiptException(
        'That receipt is too busy to store. Try a closer, simpler photo.',
      );
    }
    return encoded;
  }

  /// Pure function so it can run in an isolate via [compute].
  static ReceiptResult _encode(Uint8List raw) {
    final decoded = img.decodeImage(raw);
    if (decoded == null) {
      throw const ReceiptException(
        'Unsupported image format. Use a JPEG or PNG.',
      );
    }

    final resized =
        decoded.width >= decoded.height && decoded.width > maxEdge ||
            decoded.height > maxEdge
        ? (decoded.width >= decoded.height
              ? img.copyResize(decoded, width: maxEdge)
              : img.copyResize(decoded, height: maxEdge))
        : decoded;

    final aspect = resized.width / resized.height;

    for (final quality in _qualityLadder) {
      final jpg = img.encodeJpg(resized, quality: quality);
      final b64 = base64Encode(jpg);
      if (b64.length <= maxEncodedChars) {
        return ReceiptResult(
          data: b64,
          byteSize: jpg.length,
          aspectRatio: aspect,
        );
      }
    }

    // Fall through with the smallest attempt; pick() rejects it if too big.
    final jpg = img.encodeJpg(resized, quality: _qualityLadder.last);
    return ReceiptResult(
      data: base64Encode(jpg),
      byteSize: jpg.length,
      aspectRatio: aspect,
    );
  }

  /// Wraps the picker so a missing native registration produces a readable
  /// message instead of a MissingPluginException on screen.
  Future<XFile?> _pickSafely(ImageSource source) async {
    try {
      return await _picker.pickImage(
        source: source,
        maxWidth: _pickMaxEdge.toDouble(),
        maxHeight: _pickMaxEdge.toDouble(),
        imageQuality: 90,
      );
    } on MissingPluginException {
      throw const ReceiptException(
        'The image picker is not registered in this build.\n'
        'Stop the app completely and run it again — a hot reload is not '
        'enough after adding a plugin.',
      );
    } on PlatformException catch (e) {
      if (e.code == 'photo_access_denied') {
        throw const ReceiptException(
          'PennyPal needs photo permission. Enable it in Settings.',
        );
      }
      if (e.code == 'camera_access_denied') {
        throw const ReceiptException(
          'PennyPal needs camera permission. Enable it in Settings.',
        );
      }
      throw ReceiptException('Could not open the picker (${e.code}).');
    }
  }

  /// Decodes stored base64 for display. Returns null when unusable so callers
  /// can fall back to an icon instead of throwing.
  static Uint8List? decode(String base64Data) {
    if (base64Data.isEmpty) return null;
    try {
      return base64Decode(base64Data);
    } catch (_) {
      return null;
    }
  }

  /// Human readable size, e.g. "84 KB".
  static String readableSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
