import 'dart:io';
import 'package:path/path.dart' as path;

import '../database/database_service.dart';
import '../models/gallery.dart';
import '../models/picture.dart';
import 'api_service.dart';
import 'image_service.dart';

class GalleryService {
  final DatabaseService _databaseService;
  final ApiService _apiService;
  final ImageService _imageService;

  GalleryService({
    required DatabaseService databaseService,
    required ApiService apiService,
    required ImageService imageService,
  })  : _databaseService = databaseService,
        _apiService = apiService,
        _imageService = imageService;

  Future<List<Gallery>> getGalleriesForUser(int userId) async {
    return await _databaseService.galleries.getAllForUser(userId);
  }

  Future<Gallery?> getGallery(int id) async {
    return await _databaseService.galleries.getById(id);
  }

  Future<Gallery?> getGalleryWithPictures(int id) async {
    return await _databaseService.galleries.getByIdWithPictures(id);
  }

  Future<Gallery> importGallery({
    required int userId,
    required String name,
    required String folderPath,
    required List<File> images,
    void Function(int current, int total)? onProgress,
  }) async {
    final now = DateTime.now();
    final pictures = <Picture>[];

    // Process images and collect info
    for (int i = 0; i < images.length; i++) {
      final image = images[i];
      final info = await _imageService.getImageInfo(image);

      pictures.add(Picture(
        id: 0, // Will be assigned by database
        galleryId: 0, // Will be assigned after gallery creation
        filePath: image.path,
        fileName: path.basename(image.path),
        fileSize: info.fileSize,
        width: info.width,
        height: info.height,
        createdAt: now,
      ));

      onProgress?.call(i + 1, images.length);
    }

    // Create gallery in database
    final gallery = Gallery(
      id: 0, // Will be assigned by database
      userId: userId,
      name: name,
      folderPath: folderPath,
      pictureCount: pictures.length,
      createdAt: now,
      updatedAt: now,
    );

    final galleryId = await _databaseService.galleries.create(gallery);

    // Update pictures with gallery ID and insert
    final picturesWithGalleryId = pictures
        .map((p) => Picture(
              id: 0,
              galleryId: galleryId,
              filePath: p.filePath,
              fileName: p.fileName,
              fileSize: p.fileSize,
              width: p.width,
              height: p.height,
              createdAt: p.createdAt,
            ))
        .toList();

    await _databaseService.pictures.createMany(picturesWithGalleryId);

    // Return the created gallery
    return gallery.copyWith(
      id: galleryId,
      pictures: picturesWithGalleryId,
    );
  }

  Future<Gallery> submitGallery(
    int galleryId, {
    void Function(int current, int total, String status)? onProgress,
  }) async {
    final gallery = await _databaseService.galleries.getByIdWithPictures(galleryId);
    if (gallery == null) {
      throw Exception('Gallery not found');
    }

    if (gallery.isSubmitted) {
      throw Exception('Gallery already submitted');
    }

    final pictures = gallery.pictures ?? [];
    if (pictures.isEmpty) {
      throw Exception('Gallery has no pictures');
    }

    onProgress?.call(0, pictures.length, 'Preparing images...');

    // Create temp directory for compressed images
    final tempDir = await _imageService.createTempCompressedDir(gallery.name);

    try {
      // Compress images
      final compressedFiles = <File>[];
      for (int i = 0; i < pictures.length; i++) {
        final picture = pictures[i];
        onProgress?.call(i + 1, pictures.length, 'Compressing: ${picture.fileName}');

        final sourceFile = File(picture.filePath);
        if (!await sourceFile.exists()) {
          throw Exception('Source file not found: ${picture.filePath}');
        }

        final compressedFile = await _imageService.compressImage(
          sourceFile,
          tempDir.path,
        );
        compressedFiles.add(compressedFile);
      }

      // Upload to web with per-image progress
      // Pass local gallery ID for automatic order matching
      final response = await _apiService.uploadGalleryWithProgress(
        name: gallery.name,
        images: compressedFiles,
        localGalleryId: galleryId,
        onProgress: (uploaded, total) {
          onProgress?.call(uploaded, total, 'Uploading $uploaded of $total');
        },
      );

      final webGalleryId = response['gallery_id'] as int;
      final webSlug = response['slug'] as String;

      // Mark gallery as submitted
      await _databaseService.galleries.markAsSubmitted(
        galleryId,
        webGalleryId,
        webSlug,
      );

      // Return updated gallery
      return gallery.copyWith(
        submittedAt: DateTime.now(),
        webGalleryId: webGalleryId,
        webSlug: webSlug,
      );
    } finally {
      // Cleanup temp directory
      await _imageService.cleanupTempDir(tempDir);
    }
  }

  /// Deletes gallery from LOCAL DATABASE ONLY.
  /// NEVER deletes files from disk - the original photos remain untouched.
  Future<void> deleteGallery(int galleryId) async {
    await _databaseService.galleries.delete(galleryId);
  }

  Future<List<Picture>> getPicturesForGallery(int galleryId) async {
    return await _databaseService.pictures.getAllForGallery(galleryId);
  }

  /// Syncs local galleries with the web server.
  /// Removes local galleries that have been deleted on the server.
  /// Returns the number of galleries removed.
  Future<int> syncGalleries(int userId) async {
    try {
      // Get galleries from web server
      final webGalleries = await _apiService.getGalleries();
      final webGalleryIds = webGalleries
          .map((g) => g['id'] as int)
          .toSet();

      // Get local submitted galleries
      final localGalleries = await _databaseService.galleries.getSubmittedForUser(userId);

      int removedCount = 0;

      // Remove local galleries that no longer exist on server
      for (final localGallery in localGalleries) {
        if (localGallery.webGalleryId != null &&
            !webGalleryIds.contains(localGallery.webGalleryId)) {
          await _databaseService.galleries.delete(localGallery.id);
          removedCount++;
        }
      }

      return removedCount;
    } catch (e) {
      // If sync fails (e.g., network error), just return 0
      return 0;
    }
  }
}
