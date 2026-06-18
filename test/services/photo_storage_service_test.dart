import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:xiaogui_xunwu/services/photo_storage_service.dart';

void main() {
  test('saves original photo and thumbnail in app-owned directory', () async {
    final tempDir = await Directory.systemTemp.createTemp('xunwu-photo-test');
    addTearDown(() => tempDir.delete(recursive: true));

    final sourceImage = img.Image(width: 40, height: 40);
    img.fill(sourceImage, color: img.ColorRgb8(20, 120, 80));
    final jpegBytes = img.encodeJpg(sourceImage);

    final storage = PhotoStorageService(rootDirectory: tempDir);
    final result = await storage.saveJpegBytes(
      recordId: 'record-photo',
      jpegBytes: jpegBytes,
    );

    expect(File(result.photoPath).existsSync(), isTrue);
    expect(File(result.thumbnailPath).existsSync(), isTrue);
    expect(result.photoPath.contains('memory_photos'), isTrue);
    expect(result.thumbnailPath.contains('memory_thumbnails'), isTrue);
  });
}
