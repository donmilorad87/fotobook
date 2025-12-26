import 'picture.dart';

class Gallery {
  final int id;
  final int userId;
  final String name;
  final String folderPath;
  final int pictureCount;
  final DateTime? submittedAt;
  final int? webGalleryId;
  final String? webSlug;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Picture>? pictures;

  Gallery({
    required this.id,
    required this.userId,
    required this.name,
    required this.folderPath,
    required this.pictureCount,
    this.submittedAt,
    this.webGalleryId,
    this.webSlug,
    required this.createdAt,
    required this.updatedAt,
    this.pictures,
  });

  bool get isSubmitted => submittedAt != null;

  String get publicUrl {
    if (webSlug == null) return '';
    return 'http://localhost:8000/gallery/$webSlug';
  }

  factory Gallery.fromMap(Map<String, dynamic> map) {
    return Gallery(
      id: map['id'] as int,
      userId: map['user_id'] as int,
      name: map['name'] as String,
      folderPath: map['folder_path'] as String,
      pictureCount: map['picture_count'] as int,
      submittedAt: map['submitted_at'] != null
          ? DateTime.parse(map['submitted_at'] as String)
          : null,
      webGalleryId: map['web_gallery_id'] as int?,
      webSlug: map['web_slug'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'folder_path': folderPath,
      'picture_count': pictureCount,
      'submitted_at': submittedAt?.toIso8601String(),
      'web_gallery_id': webGalleryId,
      'web_slug': webSlug,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Gallery copyWith({
    int? id,
    int? userId,
    String? name,
    String? folderPath,
    int? pictureCount,
    DateTime? submittedAt,
    int? webGalleryId,
    String? webSlug,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Picture>? pictures,
  }) {
    return Gallery(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      folderPath: folderPath ?? this.folderPath,
      pictureCount: pictureCount ?? this.pictureCount,
      submittedAt: submittedAt ?? this.submittedAt,
      webGalleryId: webGalleryId ?? this.webGalleryId,
      webSlug: webSlug ?? this.webSlug,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pictures: pictures ?? this.pictures,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Gallery && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
