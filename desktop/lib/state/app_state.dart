import 'dart:io';
import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../models/gallery.dart';
import '../models/order.dart';
import '../services/auth_service.dart';
import '../services/gallery_service.dart';
import '../services/order_service.dart';

class AppState extends ChangeNotifier {
  final AuthService _authService;
  final GalleryService _galleryService;
  final OrderService _orderService;

  bool _isLoading = true;
  String? _error;
  List<Gallery> _galleries = [];
  Gallery? _selectedGallery;
  Order? _currentOrder;
  List<MatchedFile>? _matchedFiles;

  AppState({
    required AuthService authService,
    required GalleryService galleryService,
    required OrderService orderService,
  })  : _authService = authService,
        _galleryService = galleryService,
        _orderService = orderService;

  // Getters
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _authService.isAuthenticated;
  User? get currentUser => _authService.currentUser;
  String? get error => _error;
  List<Gallery> get galleries => _galleries;
  Gallery? get selectedGallery => _selectedGallery;
  Order? get currentOrder => _currentOrder;
  List<MatchedFile>? get matchedFiles => _matchedFiles;

  // Auth actions
  Future<void> restoreSession() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.restoreSession();
      if (isAuthenticated) {
        await loadGalleries();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.login(email, password);
      await loadGalleries();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      _galleries = [];
      _selectedGallery = null;
      _currentOrder = null;
      _matchedFiles = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Gallery actions
  Future<void> loadGalleries() async {
    if (currentUser == null) return;

    try {
      // Sync with server first (removes locally deleted galleries)
      await syncGalleries();

      // Then load local galleries
      _galleries = await _galleryService.getGalleriesForUser(currentUser!.id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Sync local galleries with the web server.
  /// Removes local galleries that have been deleted on the server.
  Future<int> syncGalleries() async {
    if (currentUser == null) return 0;

    try {
      return await _galleryService.syncGalleries(currentUser!.id);
    } catch (e) {
      // Sync failure is not critical - just continue with local data
      return 0;
    }
  }

  Future<void> selectGallery(int galleryId) async {
    try {
      _selectedGallery = await _galleryService.getGalleryWithPictures(galleryId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearSelectedGallery() {
    _selectedGallery = null;
    notifyListeners();
  }

  Future<Gallery> importGallery({
    required String name,
    required String folderPath,
    required List<dynamic> images,
    void Function(int current, int total)? onProgress,
  }) async {
    if (currentUser == null) {
      throw Exception('Not authenticated');
    }

    final gallery = await _galleryService.importGallery(
      userId: currentUser!.id,
      name: name,
      folderPath: folderPath,
      images: images.cast(),
      onProgress: onProgress,
    );

    await loadGalleries();
    return gallery;
  }

  Future<Gallery> submitGallery(
    int galleryId, {
    void Function(int current, int total, String status)? onProgress,
  }) async {
    final gallery = await _galleryService.submitGallery(
      galleryId,
      onProgress: onProgress,
    );

    await loadGalleries();

    if (_selectedGallery?.id == galleryId) {
      _selectedGallery = gallery;
      notifyListeners();
    }

    return gallery;
  }

  Future<void> deleteGallery(int galleryId) async {
    await _galleryService.deleteGallery(galleryId);

    if (_selectedGallery?.id == galleryId) {
      _selectedGallery = null;
    }

    await loadGalleries();
  }

  Future<void> addPicturesToGallery({
    required int galleryId,
    required List<File> images,
    void Function(int current, int total)? onProgress,
  }) async {
    final gallery = await _galleryService.addPicturesToGallery(
      galleryId: galleryId,
      images: images,
      onProgress: onProgress,
    );

    if (_selectedGallery?.id == galleryId) {
      _selectedGallery = gallery;
      notifyListeners();
    }

    await loadGalleries();
  }

  Future<void> removePictureFromGallery({
    required int galleryId,
    required int pictureId,
  }) async {
    final gallery = await _galleryService.removePictureFromGallery(
      galleryId: galleryId,
      pictureId: pictureId,
    );

    if (_selectedGallery?.id == galleryId) {
      _selectedGallery = gallery;
      notifyListeners();
    }

    await loadGalleries();
  }

  // Order actions
  Future<void> loadOrderFromJson(String jsonPath) async {
    try {
      _currentOrder = await _orderService.loadOrderFromJson(jsonPath);
      _matchedFiles = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<Gallery?> findMatchingGallery() async {
    if (_currentOrder == null || currentUser == null) return null;

    try {
      final gallery = await _orderService.findMatchingGallery(
        _currentOrder!,
        currentUser!.id,
      );
      return gallery;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> matchOrderToGallery(Gallery gallery) async {
    if (_currentOrder == null) return;

    try {
      _matchedFiles = await _orderService.matchOrderToGallery(
        _currentOrder!,
        gallery,
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<String> createOrderZip({
    required String outputPath,
    void Function(int current, int total)? onProgress,
  }) async {
    if (_currentOrder == null || _matchedFiles == null) {
      throw Exception('No order or matched files');
    }

    final zipFile = await _orderService.createZipFromOrder(
      order: _currentOrder!,
      matchedFiles: _matchedFiles!,
      outputPath: outputPath,
      onProgress: onProgress,
    );

    return zipFile.path;
  }

  void clearOrder() {
    _currentOrder = null;
    _matchedFiles = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
