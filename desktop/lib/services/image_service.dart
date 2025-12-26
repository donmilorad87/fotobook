import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

class ImageInfo {
  final int width;
  final int height;
  final int fileSize;

  ImageInfo({
    required this.width,
    required this.height,
    required this.fileSize,
  });
}

class ImageService {
  static const int _maxWidth = 1920;
  static const int _maxHeight = 1080;
  static const int _quality = 75;

  Future<ImageInfo> getImageInfo(File file) async {
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    return ImageInfo(
      width: image.width,
      height: image.height,
      fileSize: bytes.length,
    );
  }

  Future<File> compressImage(File sourceFile, String outputDir) async {
    final bytes = await sourceFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    int targetWidth = image.width;
    int targetHeight = image.height;

    // Calculate new dimensions maintaining aspect ratio
    if (targetWidth > _maxWidth || targetHeight > _maxHeight) {
      final widthRatio = _maxWidth / targetWidth;
      final heightRatio = _maxHeight / targetHeight;
      final ratio = widthRatio < heightRatio ? widthRatio : heightRatio;

      targetWidth = (targetWidth * ratio).round();
      targetHeight = (targetHeight * ratio).round();
    }

    // If image is already small enough, just copy it
    if (targetWidth == image.width && targetHeight == image.height) {
      final outputPath = path.join(outputDir, path.basename(sourceFile.path));
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(bytes);
      return outputFile;
    }

    // For actual compression, we need to use platform-specific methods
    // Since flutter_image_compress may not work on all desktop platforms,
    // we'll use a fallback approach
    final compressedBytes = await _compressImageBytes(bytes, targetWidth, targetHeight);

    final fileName = path.basename(sourceFile.path);
    final outputPath = path.join(outputDir, fileName);
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(compressedBytes);

    return outputFile;
  }

  Future<Uint8List> _compressImageBytes(
    Uint8List bytes,
    int targetWidth,
    int targetHeight,
  ) async {
    // Decode the image
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;

    // Encode as PNG (JPEG encoding requires native plugins)
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw Exception('Failed to encode image');
    }

    return byteData.buffer.asUint8List();
  }

  Future<Directory> createTempCompressedDir(String galleryName) async {
    final tempDir = Directory.systemTemp;
    final compressedDir = Directory(
      path.join(tempDir.path, 'fotobook_compressed_${DateTime.now().millisecondsSinceEpoch}'),
    );
    await compressedDir.create(recursive: true);
    return compressedDir;
  }

  Future<void> cleanupTempDir(Directory dir) async {
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}
