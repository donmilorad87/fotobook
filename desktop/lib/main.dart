import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app.dart';
import 'database/database_service.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/file_service.dart';
import 'services/image_service.dart';
import 'services/gallery_service.dart';
import 'services/order_service.dart';
import 'state/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize FFI for desktop SQLite
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Initialize database
  final databaseService = DatabaseService();
  await databaseService.initialize();

  // Initialize services
  final apiService = ApiService();
  final authService = AuthService(
    databaseService: databaseService,
    apiService: apiService,
  );
  final fileService = FileService();
  final imageService = ImageService();
  final galleryService = GalleryService(
    databaseService: databaseService,
    apiService: apiService,
    imageService: imageService,
  );
  final orderService = OrderService(
    databaseService: databaseService,
    fileService: fileService,
  );

  // Initialize state
  final appState = AppState(
    authService: authService,
    galleryService: galleryService,
    orderService: orderService,
  );

  // Try to restore session
  await appState.restoreSession();

  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseService>.value(value: databaseService),
        Provider<ApiService>.value(value: apiService),
        Provider<AuthService>.value(value: authService),
        Provider<FileService>.value(value: fileService),
        Provider<ImageService>.value(value: imageService),
        Provider<GalleryService>.value(value: galleryService),
        Provider<OrderService>.value(value: orderService),
        ChangeNotifierProvider<AppState>.value(value: appState),
      ],
      child: const FotobookApp(),
    ),
  );
}
