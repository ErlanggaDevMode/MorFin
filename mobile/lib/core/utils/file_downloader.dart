import 'dart:typed_data';
import 'file_downloader_io.dart' if (dart.library.js_interop) 'file_downloader_web.dart' as impl;

Future<String> saveExportFile({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) {
  return impl.saveExportFileImpl(bytes: bytes, fileName: fileName, mimeType: mimeType);
}
