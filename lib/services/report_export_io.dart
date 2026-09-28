import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

const String reportMimeType =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

/// Native target: writes the workbook to a temp file and opens the platform
/// share sheet. Used for Android, iOS and desktop.
Future<String> deliverReport(Uint8List bytes, String name) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$name');
  await file.writeAsBytes(bytes, flush: true);
  await Share.shareXFiles([
    XFile(file.path, mimeType: reportMimeType),
  ], text: 'PennyPal spending report');
  return 'Report ready to share';
}
