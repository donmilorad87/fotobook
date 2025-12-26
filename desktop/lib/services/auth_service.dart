import '../database/database_service.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  final DatabaseService _databaseService;
  final ApiService _apiService;

  User? _currentUser;

  AuthService({
    required DatabaseService databaseService,
    required ApiService apiService,
  })  : _databaseService = databaseService,
        _apiService = apiService;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Future<User?> restoreSession() async {
    final user = await _databaseService.users.getCurrentUser();
    if (user != null) {
      _currentUser = user;
      _apiService.setToken(user.token);
    }
    return user;
  }

  Future<User> login(String email, String password) async {
    final response = await _apiService.login(email, password);

    final token = response['token'] as String;
    final userData = response['user'] as Map<String, dynamic>;

    final user = User(
      id: userData['id'] as int,
      email: userData['email'] as String,
      name: userData['name'] as String,
      token: token,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save user to local database
    await _databaseService.users.saveUser(user);

    // Set token for API service
    _apiService.setToken(token);

    _currentUser = user;
    return user;
  }

  Future<void> logout() async {
    // Clear local data
    await _databaseService.clearAll();

    // Clear token from API service
    _apiService.setToken(null);

    _currentUser = null;
  }

  Future<void> updateToken(String newToken) async {
    if (_currentUser == null) return;

    await _databaseService.users.updateToken(_currentUser!.id, newToken);
    _apiService.setToken(newToken);

    _currentUser = _currentUser!.copyWith(
      token: newToken,
      updatedAt: DateTime.now(),
    );
  }
}
