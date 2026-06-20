import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class StoredPhoto {
  const StoredPhoto({required this.photoPath, required this.thumbnailPath});

  final String photoPath;
  final String thumbnailPath;
}

class PhotoStorageService {
  PhotoStorageService({Directory? rootDirectory})
    : _rootDirectory = rootDirectory;

  final Directory? _rootDirectory;

  Future<Directory> _root() async {
    return _rootDirectory ?? getApplicationDocumentsDirectory();
  }

  Future<StoredPhoto> saveJpegBytes({
    required String recordId,
    required List<int> jpegBytes,
  }) async {
    final root = await _root();
    final photosDir = Directory(p.join(root.path, 'memory_photos'));
    final thumbsDir = Directory(p.join(root.path, 'memory_thumbnails'));
    await photosDir.create(recursive: true);
    await thumbsDir.create(recursive: true);

    final photoPath = p.join(photosDir.path, '$recordId.jpg');
    final thumbnailPath = p.join(thumbsDir.path, '$recordId.jpg');

    await File(photoPath).writeAsBytes(jpegBytes, flush: true);
    final thumbnailBytes = await compute(_makeThumbnail, jpegBytes);
    await File(thumbnailPath).writeAsBytes(thumbnailBytes, flush: true);

    return StoredPhoto(photoPath: photoPath, thumbnailPath: thumbnailPath);
  }

  Future<void> deleteStoredPhoto({
    required String photoPath,
    required String thumbnailPath,
  }) async {
    await Future.wait([
      _deleteIfExists(photoPath),
      _deleteIfExists(thumbnailPath),
    ]);
  }

  Future<void> _deleteIfExists(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

Uint8List _makeThumbnail(List<int> jpegBytes) {
  final decoded = img.decodeImage(Uint8List.fromList(jpegBytes));
  if (decoded == null) return Uint8List.fromList(jpegBytes);

  final thumb = img.copyResize(decoded, width: 480);
  return Uint8List.fromList(img.encodeJpg(thumb, quality: 82));
}
