import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../models/picture.dart';

class PictureRepository {
  final Database _db;

  PictureRepository(this._db);

  Future<List<Picture>> getAllForGallery(int galleryId) async {
    final results = await _db.query(
      'pictures',
      where: 'gallery_id = ?',
      whereArgs: [galleryId],
      orderBy: 'file_name ASC',
    );
    return results.map((map) => Picture.fromMap(map)).toList();
  }

  Future<Picture?> getById(int id) async {
    final results = await _db.query(
      'pictures',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Picture.fromMap(results.first);
  }

  Future<Picture?> getByFileName(int galleryId, String fileName) async {
    final results = await _db.query(
      'pictures',
      where: 'gallery_id = ? AND file_name = ?',
      whereArgs: [galleryId, fileName],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Picture.fromMap(results.first);
  }

  Future<int> create(Picture picture) async {
    final id = await _db.insert('pictures', {
      'gallery_id': picture.galleryId,
      'file_path': picture.filePath,
      'file_name': picture.fileName,
      'file_size': picture.fileSize,
      'width': picture.width,
      'height': picture.height,
      'web_picture_id': picture.webPictureId,
      'created_at': DateTime.now().toIso8601String(),
    });
    return id;
  }

  Future<void> createMany(List<Picture> pictures) async {
    final batch = _db.batch();
    final now = DateTime.now().toIso8601String();

    for (final picture in pictures) {
      batch.insert('pictures', {
        'gallery_id': picture.galleryId,
        'file_path': picture.filePath,
        'file_name': picture.fileName,
        'file_size': picture.fileSize,
        'width': picture.width,
        'height': picture.height,
        'web_picture_id': picture.webPictureId,
        'created_at': now,
      });
    }

    await batch.commit(noResult: true);
  }

  Future<void> updateWebId(int id, int webPictureId) async {
    await _db.update(
      'pictures',
      {'web_picture_id': webPictureId},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(int id) async {
    await _db.delete('pictures', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllForGallery(int galleryId) async {
    await _db.delete('pictures', where: 'gallery_id = ?', whereArgs: [galleryId]);
  }

  Future<int> getCountForGallery(int galleryId) async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM pictures WHERE gallery_id = ?',
      [galleryId],
    );
    return result.first['count'] as int;
  }

  Future<int> getTotalSizeForGallery(int galleryId) async {
    final result = await _db.rawQuery(
      'SELECT SUM(file_size) as total FROM pictures WHERE gallery_id = ?',
      [galleryId],
    );
    return (result.first['total'] as int?) ?? 0;
  }
}
