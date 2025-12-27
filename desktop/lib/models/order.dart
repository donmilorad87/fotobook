class Order {
  final int id;
  final int? localGalleryId; // Local Flutter DB gallery ID for automatic matching
  final String galleryName;
  final String clientName;
  final String clientEmail;
  final List<OrderItem> selectedPictures;
  final DateTime createdAt;

  Order({
    required this.id,
    this.localGalleryId,
    required this.galleryName,
    required this.clientName,
    required this.clientEmail,
    required this.selectedPictures,
    required this.createdAt,
  });

  int get selectedCount => selectedPictures.length;

  /// Check if this order can be automatically matched to a local gallery.
  bool get hasLocalGalleryId => localGalleryId != null;

  factory Order.fromJson(Map<String, dynamic> json) {
    final pictures = (json['selected_pictures'] as List<dynamic>?)
            ?.map((p) => OrderItem.fromJson(p as Map<String, dynamic>))
            .toList() ??
        [];

    return Order(
      id: json['order_id'] as int? ?? json['id'] as int,
      localGalleryId: json['local_gallery_id'] as int?,
      galleryName: json['gallery_name'] as String? ?? '',
      clientName: json['client_name'] as String? ?? '',
      clientEmail: json['client_email'] as String? ?? '',
      selectedPictures: pictures,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': id,
      'local_gallery_id': localGalleryId,
      'gallery_name': galleryName,
      'client_name': clientName,
      'client_email': clientEmail,
      'selected_pictures': selectedPictures.map((p) => p.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class OrderItem {
  final String filename;

  OrderItem({required this.filename});

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      filename: json['filename'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filename': filename,
    };
  }
}
