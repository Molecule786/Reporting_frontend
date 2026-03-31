import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DownloadHelper {
  static Future<void> download(Uint8List bytes, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);
  }
}
