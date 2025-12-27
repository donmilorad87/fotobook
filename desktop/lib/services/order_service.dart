import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

import '../database/database_service.dart';
import '../models/order.dart';
import '../models/gallery.dart';
import 'file_service.dart';

class OrderService {
  final DatabaseService _databaseService;
  final FileService _fileService;

  OrderService({
    required DatabaseService databaseService,
    required FileService fileService,
  })  : _databaseService = databaseService,
        _fileService = fileService;

  Future<Order> loadOrderFromJson(String jsonPath) async {
    final jsonString = await _fileService.readJsonFile(jsonPath);
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return Order.fromJson(json);
  }

  /// Find matching gallery for an order.
  /// Uses localGalleryId for automatic matching (preferred).
  /// Falls back to name matching if localGalleryId not available.
  Future<Gallery?> findMatchingGallery(Order order, int userId) async {
    // First, try direct match using localGalleryId (most reliable)
    if (order.hasLocalGalleryId) {
      final gallery = await _databaseService.galleries.getById(order.localGalleryId!);
      if (gallery != null && gallery.userId == userId) {
        return gallery;
      }
    }

    // Fallback: try to find gallery by name
    final galleries = await _databaseService.galleries.getAllForUser(userId);
    for (final gallery in galleries) {
      if (gallery.name == order.galleryName) {
        return gallery;
      }
    }

    return null;
  }

  /// Check if an order can be automatically processed (has localGalleryId).
  bool canAutoProcess(Order order) => order.hasLocalGalleryId;

  Future<List<MatchedFile>> matchOrderToGallery(Order order, Gallery gallery) async {
    final pictures = await _databaseService.pictures.getAllForGallery(gallery.id);
    final matched = <MatchedFile>[];

    for (final orderItem in order.selectedPictures) {
      final picture = pictures.firstWhere(
        (p) => p.fileName == orderItem.filename,
        orElse: () => throw Exception('Picture not found: ${orderItem.filename}'),
      );

      final file = File(picture.filePath);
      final exists = await file.exists();

      matched.add(MatchedFile(
        filename: orderItem.filename,
        filePath: picture.filePath,
        exists: exists,
      ));
    }

    return matched;
  }

  Future<File> createZipFromOrder({
    required Order order,
    required List<MatchedFile> matchedFiles,
    required String outputPath,
    void Function(int current, int total)? onProgress,
  }) async {
    final archive = Archive();
    final validFiles = matchedFiles.where((f) => f.exists).toList();

    for (int i = 0; i < validFiles.length; i++) {
      final matchedFile = validFiles[i];
      onProgress?.call(i + 1, validFiles.length);

      final file = File(matchedFile.filePath);
      final bytes = await file.readAsBytes();

      archive.addFile(ArchiveFile(
        matchedFile.filename,
        bytes.length,
        bytes,
      ));
    }

    // Encode as ZIP
    final zipData = ZipEncoder().encode(archive);
    if (zipData == null) {
      throw Exception('Failed to create ZIP archive');
    }

    // Write to file
    final zipFile = File(outputPath);
    await zipFile.writeAsBytes(zipData);

    return zipFile;
  }

  String generateZipFileName(Order order) {
    final sanitizedGalleryName = order.galleryName
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    final sanitizedClientName = order.clientName
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_');

    return '${sanitizedGalleryName}_${sanitizedClientName}_order_${order.id}.zip';
  }

  Future<String?> pickSaveLocation(Order order) async {
    final defaultFileName = generateZipFileName(order);
    return await _fileService.pickSaveLocation(defaultFileName);
  }

  Future<String?> pickOrderJsonFile() async {
    return await _fileService.pickJsonFile();
  }
}

class MatchedFile {
  final String filename;
  final String filePath;
  final bool exists;

  MatchedFile({
    required this.filename,
    required this.filePath,
    required this.exists,
  });
}
