import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../models/user.dart';

class UserRepository {
  final Database _db;

  UserRepository(this._db);

  Future<User?> getCurrentUser() async {
    final results = await _db.query('users', limit: 1);
    if (results.isEmpty) return null;
    return User.fromMap(results.first);
  }

  Future<void> saveUser(User user) async {
    // Delete any existing user first (single user app)
    await _db.delete('users');

    await _db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateToken(int userId, String token) async {
    await _db.update(
      'users',
      {
        'token': token,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> deleteUser() async {
    await _db.delete('users');
  }

  Future<String?> getToken() async {
    final results = await _db.query(
      'users',
      columns: ['token'],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return results.first['token'] as String?;
  }
}
