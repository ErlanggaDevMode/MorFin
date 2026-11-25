import 'dart:io';
import 'dart:typed_data';

Future<String> saveExportFileImpl({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) async {
  final file = File('${Directory.systemTemp.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
