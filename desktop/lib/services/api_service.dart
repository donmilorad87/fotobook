import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

class ApiService {
  static String get _baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://192.168.0.107/api';

  late final http.Client _client;
  String? _token;

  ApiService() {
    // Create HTTP client that accepts self-signed certificates (for development)
    final httpClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;
    _client = IOClient(httpClient);
  }

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    return _handleResponse(response);
  }

  /// Create a new gallery (without images).
  /// Returns gallery_id and folder_id for subsequent image uploads.
  Future<Map<String, dynamic>> createGallery({
    required String name,
    required int totalImages,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/galleries'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'total_images': totalImages,
      }),
    );

    return _handleResponse(response);
  }

  /// Upload a single image to an existing gallery.
  /// Returns progress information (uploaded count, total, completed flag).
  Future<Map<String, dynamic>> uploadGalleryImage({
    required int galleryId,
    required File image,
    required int totalImages,
    required int imageIndex,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/galleries/$galleryId/images'),
    );

    request.headers.addAll({
      'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    });

    request.fields['total_images'] = totalImages.toString();
    request.fields['image_index'] = imageIndex.toString();

    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        image.path,
        filename: image.path.split(Platform.pathSeparator).last,
      ),
    );

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    return _handleResponse(response);
  }

  /// Finalize gallery upload and get full gallery info.
  Future<Map<String, dynamic>> finalizeGallery(int galleryId) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/galleries/$galleryId/finalize'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  /// Upload gallery with progress callback.
  /// [onProgress] is called after each image upload with (uploaded, total).
  Future<Map<String, dynamic>> uploadGalleryWithProgress({
    required String name,
    required List<File> images,
    required void Function(int uploaded, int total) onProgress,
  }) async {
    final totalImages = images.length;

    // Step 1: Create gallery
    final createResult = await createGallery(
      name: name,
      totalImages: totalImages,
    );

    final galleryId = createResult['gallery_id'] as int;

    // Step 2: Upload each image
    for (int i = 0; i < images.length; i++) {
      await uploadGalleryImage(
        galleryId: galleryId,
        image: images[i],
        totalImages: totalImages,
        imageIndex: i,
      );

      // Report progress after each upload
      onProgress(i + 1, totalImages);
    }

    // Step 3: Finalize and return gallery info
    return await finalizeGallery(galleryId);
  }

  Future<List<Map<String, dynamic>>> getOrders() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/orders'),
      headers: _headers,
    );

    final data = _handleResponse(response);
    return (data['orders'] as List<dynamic>)
        .map((o) => o as Map<String, dynamic>)
        .toList();
  }

  /// Get all galleries from the web server.
  /// Used to sync local galleries with the server.
  Future<List<Map<String, dynamic>>> getGalleries() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/galleries'),
      headers: _headers,
    );

    final data = _handleResponse(response);
    return (data['galleries'] as List<dynamic>)
        .map((g) => g as Map<String, dynamic>)
        .toList();
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body as Map<String, dynamic>;
    }

    final message = body['message'] ?? body['error'] ?? 'Unknown error';
    throw ApiException(message as String, statusCode: response.statusCode);
  }
}
