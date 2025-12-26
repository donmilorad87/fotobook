import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../models/gallery.dart';
import '../../models/picture.dart';

class GalleryRepository {
  final Database _db;

  GalleryRepository(this._db);

  Future<List<Gallery>> getAllForUser(int userId) async {
    final results = await _db.query(
      'galleries',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return results.map((map) => Gallery.fromMap(map)).toList();
  }

  Future<Gallery?> getById(int id) async {
    final results = await _db.query(
      'galleries',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Gallery.fromMap(results.first);
  }

  Future<Gallery?> getByIdWithPictures(int id) async {
    final galleryResults = await _db.query(
      'galleries',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (galleryResults.isEmpty) return null;

    final gallery = Gallery.fromMap(galleryResults.first);

    final pictureResults = await _db.query(
      'pictures',
      where: 'gallery_id = ?',
      whereArgs: [id],
      orderBy: 'file_name ASC',
    );

    final pictures = pictureResults.map((map) => Picture.fromMap(map)).toList();

    return gallery.copyWith(pictures: pictures);
  }

  Future<int> create(Gallery gallery) async {
    final now = DateTime.now().toIso8601String();
    final id = await _db.insert('galleries', {
      'user_id': gallery.userId,
      'name': gallery.name,
      'folder_path': gallery.folderPath,
      'picture_count': gallery.pictureCount,
      'submitted_at': gallery.submittedAt?.toIso8601String(),
      'web_gallery_id': gallery.webGalleryId,
      'web_slug': gallery.webSlug,
      'created_at': now,
      'updated_at': now,
    });
    return id;
  }

  Future<void> update(Gallery gallery) async {
    await _db.update(
      'galleries',
      {
        'name': gallery.name,
        'folder_path': gallery.folderPath,
        'picture_count': gallery.pictureCount,
        'submitted_at': gallery.submittedAt?.toIso8601String(),
        'web_gallery_id': gallery.webGalleryId,
        'web_slug': gallery.webSlug,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [gallery.id],
    );
  }

  Future<void> markAsSubmitted(int id, int webGalleryId, String webSlug) async {
    await _db.update(
      'galleries',
      {
        'submitted_at': DateTime.now().toIso8601String(),
        'web_gallery_id': webGalleryId,
        'web_slug': webSlug,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(int id) async {
    // Delete pictures first (cascade handled by FK, but explicit is clearer)
    await _db.delete('pictures', where: 'gallery_id = ?', whereArgs: [id]);
    await _db.delete('galleries', where: 'id = ?', whereArgs: [id]);
  }

  /// Delete gallery by web gallery ID (for sync with server)
  Future<void> deleteByWebGalleryId(int webGalleryId) async {
    final results = await _db.query(
      'galleries',
      columns: ['id'],
      where: 'web_gallery_id = ?',
      whereArgs: [webGalleryId],
    );
    if (results.isNotEmpty) {
      final localId = results.first['id'] as int;
      await delete(localId);
    }
  }

  /// Get all submitted galleries for user (have web_gallery_id)
  Future<List<Gallery>> getSubmittedForUser(int userId) async {
    final results = await _db.query(
      'galleries',
      where: 'user_id = ? AND web_gallery_id IS NOT NULL',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return results.map((map) => Gallery.fromMap(map)).toList();
  }

  Future<void> deleteAllForUser(int userId) async {
    // Get all gallery IDs for user
    final galleries = await _db.query(
      'galleries',
      columns: ['id'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    for (final gallery in galleries) {
      final galleryId = gallery['id'] as int;
      await _db.delete('pictures', where: 'gallery_id = ?', whereArgs: [galleryId]);
    }

    await _db.delete('galleries', where: 'user_id = ?', whereArgs: [userId]);
  }

  Future<int> getCountForUser(int userId) async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM galleries WHERE user_id = ?',
      [userId],
    );
    return result.first['count'] as int;
  }

  Future<int> getTotalPicturesForUser(int userId) async {
    final result = await _db.rawQuery(
      'SELECT SUM(picture_count) as total FROM galleries WHERE user_id = ?',
      [userId],
    );
    return (result.first['total'] as int?) ?? 0;
  }
}
