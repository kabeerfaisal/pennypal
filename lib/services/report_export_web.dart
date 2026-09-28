import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

const String reportMimeType =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

/// Web target: the browser has no file system, so the workbook is turned into
/// a blob URL and handed to a synthetic anchor click, which starts a normal
/// download.
Future<String> deliverReport(Uint8List bytes, String name) async {
  final blob = web.Blob(
    <JSAny>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: reportMimeType),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = name
    ..style.display = 'none';
  web.document.body!.appendChild(anchor);
  anchor.click();
  anchor.remove();
  // Revoking immediately can cancel the download in some browsers.
  await Future<void>.delayed(
    const Duration(seconds: 1),
    () => web.URL.revokeObjectURL(url),
  );
  return 'Report downloaded ($name)';
}
