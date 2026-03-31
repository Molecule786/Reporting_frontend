import 'dart:typed_data';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

class DownloadHelper {
  static Future<void> download(Uint8List bytes, String fileName) async {
    final blob = web.Blob([bytes.toJS].toJS);
    final url = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = url;
    anchor.download = fileName;
    web.document.body?.appendChild(anchor);
    anchor.click();
    web.document.body?.removeChild(anchor);
    web.URL.revokeObjectURL(url);
  }
}
