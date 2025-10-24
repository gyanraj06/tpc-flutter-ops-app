import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../../domain/entities/user.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/utils/logger.dart';

class AuthRepository {
  final SharedPreferences _prefs;

  AuthRepository(this._prefs);

  // Mock user data
  static const _mockUser = {
    'id': 'user_001',
    'name': 'John Doe',
    'email': 'admin@tpc.com',
    'role': 'Scanner Operator',
    'scannerId': 'SCAN-001',
  };

  /// Mock login - simulates network delay
  Future<User> login(String email, String password) async {
    AppLogger.info('Attempting login for: $email');

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // Check credentials
    if (email == AppConstants.mockEmail && password == AppConstants.mockPassword) {
      final userModel = UserModel.fromJson(_mockUser);

      // Save to shared preferences
      await _prefs.setBool(StorageKeys.isLoggedIn, true);
      await _prefs.setString(StorageKeys.userId, userModel.id);
      await _prefs.setString(StorageKeys.userEmail, userModel.email);
      await _prefs.setString(StorageKeys.userName, userModel.name);

      AppLogger.info('Login successful');
      return userModel.toEntity();
    }

    AppLogger.warning('Login failed: Invalid credentials');
    throw Exception('Invalid email or password');
  }

  /// Logout and clear session
  Future<void> logout() async {
    AppLogger.info('Logging out');
    await Future.delayed(const Duration(milliseconds: 500));

    await _prefs.remove(StorageKeys.isLoggedIn);
    await _prefs.remove(StorageKeys.userId);
    await _prefs.remove(StorageKeys.userEmail);
    await _prefs.remove(StorageKeys.userName);

    AppLogger.info('Logout complete');
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    return _prefs.getBool(StorageKeys.isLoggedIn) ?? false;
  }

  /// Get current user from stored data
  Future<User?> getCurrentUser() async {
    final isLoggedIn = await this.isLoggedIn();
    if (!isLoggedIn) return null;

    final userId = _prefs.getString(StorageKeys.userId);
    final userEmail = _prefs.getString(StorageKeys.userEmail);
    final userName = _prefs.getString(StorageKeys.userName);

    if (userId == null || userEmail == null || userName == null) {
      return null;
    }

    // Return mock user with stored data
    final userModel = UserModel.fromJson({
      ..._mockUser,
      'id': userId,
      'email': userEmail,
      'name': userName,
    });

    return userModel.toEntity();
  }
}
