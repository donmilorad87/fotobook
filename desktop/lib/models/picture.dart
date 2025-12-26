class Picture {
  final int id;
  final int galleryId;
  final String filePath;
  final String fileName;
  final int fileSize;
  final int width;
  final int height;
  final int? webPictureId;
  final DateTime createdAt;

  Picture({
    required this.id,
    required this.galleryId,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.width,
    required this.height,
    this.webPictureId,
    required this.createdAt,
  });

  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get dimensions => '${width}x$height';

  factory Picture.fromMap(Map<String, dynamic> map) {
    return Picture(
      id: map['id'] as int,
      galleryId: map['gallery_id'] as int,
      filePath: map['file_path'] as String,
      fileName: map['file_name'] as String,
      fileSize: map['file_size'] as int,
      width: map['width'] as int,
      height: map['height'] as int,
      webPictureId: map['web_picture_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'gallery_id': galleryId,
      'file_path': filePath,
      'file_name': fileName,
      'file_size': fileSize,
      'width': width,
      'height': height,
      'web_picture_id': webPictureId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Picture copyWith({
    int? id,
    int? galleryId,
    String? filePath,
    String? fileName,
    int? fileSize,
    int? width,
    int? height,
    int? webPictureId,
    DateTime? createdAt,
  }) {
    return Picture(
      id: id ?? this.id,
      galleryId: galleryId ?? this.galleryId,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      width: width ?? this.width,
      height: height ?? this.height,
      webPictureId: webPictureId ?? this.webPictureId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
