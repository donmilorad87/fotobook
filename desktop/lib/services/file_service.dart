import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

class FileService {
  static const List<String> _imageExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
    '.bmp',
  ];

  Future<String?> pickFolder() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Photo Folder',
    );
    return result;
  }

  Future<String?> pickJsonFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      dialogTitle: 'Select Order JSON File',
    );

    if (result != null && result.files.isNotEmpty) {
      return result.files.first.path;
    }
    return null;
  }

  Future<String?> pickSaveLocation(String defaultFileName) async {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Save As',
      fileName: defaultFileName,
    );
    return result;
  }

  Future<List<File>> scanFolderForImages(String folderPath) async {
    final dir = Directory(folderPath);
    if (!await dir.exists()) {
      return [];
    }

    final images = <File>[];

    await for (final entity in dir.list(recursive: false)) {
      if (entity is File) {
        final ext = path.extension(entity.path).toLowerCase();
        if (_imageExtensions.contains(ext)) {
          images.add(entity);
        }
      }
    }

    // Sort by filename
    images.sort((a, b) => path.basename(a.path).compareTo(path.basename(b.path)));

    return images;
  }

  Future<Map<String, dynamic>> getFileInfo(File file) async {
    final stat = await file.stat();
    return {
      'path': file.path,
      'name': path.basename(file.path),
      'size': stat.size,
      'modified': stat.modified,
    };
  }

  Future<String> readJsonFile(String filePath) async {
    final file = File(filePath);
    return await file.readAsString();
  }

  Future<void> writeFile(String filePath, List<int> bytes) async {
    final file = File(filePath);
    await file.writeAsBytes(bytes);
  }

  Future<bool> fileExists(String filePath) async {
    return await File(filePath).exists();
  }

  Future<bool> directoryExists(String dirPath) async {
    return await Directory(dirPath).exists();
  }

  String getFileName(String filePath) {
    return path.basename(filePath);
  }

  String getFileExtension(String filePath) {
    return path.extension(filePath);
  }
}
