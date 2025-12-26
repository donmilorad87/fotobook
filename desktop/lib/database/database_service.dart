import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'repositories/user_repository.dart';
import 'repositories/gallery_repository.dart';
import 'repositories/picture_repository.dart';

class DatabaseService {
  static const int _version = 1;
  static const String _dbName = 'fotobook.db';

  Database? _database;
  late UserRepository users;
  late GalleryRepository galleries;
  late PictureRepository pictures;

  Database get database {
    if (_database == null) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
    return _database!;
  }

  Future<void> initialize() async {
    final dbPath = await _getDatabasePath();

    _database = await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _version,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );

    // Initialize repositories
    users = UserRepository(_database!);
    galleries = GalleryRepository(_database!);
    pictures = PictureRepository(_database!);
  }

  Future<String> _getDatabasePath() async {
    String dbFolder;

    if (Platform.isWindows) {
      dbFolder = path.join(
        Platform.environment['APPDATA'] ?? '',
        'Fotobook',
      );
    } else if (Platform.isMacOS) {
      dbFolder = path.join(
        Platform.environment['HOME'] ?? '',
        'Library',
        'Application Support',
        'Fotobook',
      );
    } else {
      // Linux
      dbFolder = path.join(
        Platform.environment['HOME'] ?? '',
        '.local',
        'share',
        'fotobook',
      );
    }

    final dir = Directory(dbFolder);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return path.join(dbFolder, _dbName);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY,
        email TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        token TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE galleries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        folder_path TEXT NOT NULL,
        picture_count INTEGER NOT NULL DEFAULT 0,
        submitted_at TEXT,
        web_gallery_id INTEGER,
        web_slug TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE pictures (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        gallery_id INTEGER NOT NULL,
        file_path TEXT NOT NULL,
        file_name TEXT NOT NULL,
        file_size INTEGER NOT NULL,
        width INTEGER NOT NULL,
        height INTEGER NOT NULL,
        web_picture_id INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (gallery_id) REFERENCES galleries(id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for performance
    await db.execute('CREATE INDEX idx_galleries_user_id ON galleries(user_id)');
    await db.execute('CREATE INDEX idx_pictures_gallery_id ON pictures(gallery_id)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future migrations here
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  Future<void> clearAll() async {
    await _database?.delete('pictures');
    await _database?.delete('galleries');
    await _database?.delete('users');
  }
}
