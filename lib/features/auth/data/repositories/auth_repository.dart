import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../../domain/entities/user.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/constants/app_config.dart';
import '../../../../core/utils/logger.dart';

class AuthRepository {
  final SharedPreferences _prefs;

  AuthRepository(this._prefs);

  /// Login using vendor portal API
  Future<User> login(String username, String password) async {
    AppLogger.info('Attempting login for: $username');
    AppLogger.info('API URL: ${AppConfig.apiBaseUrl}/api/scanner-members/verify-login');

    try {
      // Call vendor portal login API
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/scanner-members/verify-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout. Please check if the server is running.');
        },
      );

      AppLogger.info('Login API response status: ${response.statusCode}');
      AppLogger.info('Login API response body: ${response.body}');

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // Handle error responses (401, 400, etc.)
      if (response.statusCode != 200 || data['success'] == false) {
        final errorMessage = data['error'] ?? data['message'] ?? 'Login failed';
        AppLogger.warning('Login failed: $errorMessage');
        throw Exception(errorMessage);
      }

      final memberData = data['member'] as Map<String, dynamic>;
      AppLogger.info('User found: ${memberData['username']}');

      // Map API response to UserModel
      final userModel = UserModel(
        id: memberData['id'],
        name: memberData['fullName'] ?? 'Scanner User',
        email: memberData['email'] ?? '',
        role: 'Scanner Member',
        scannerId: memberData['id'], // Using member ID as scanner ID
        vendorId: memberData['vendorId'],
        phoneNumber: memberData['phoneNumber'],
        username: memberData['username'],
        isActive: memberData['isActive'] ?? true,
      );

      // Save to shared preferences
      await _prefs.setBool(StorageKeys.isLoggedIn, true);
      await _prefs.setString(StorageKeys.userId, userModel.id);
      await _prefs.setString(StorageKeys.userEmail, userModel.email);
      await _prefs.setString(StorageKeys.userName, userModel.name);
      await _prefs.setString(StorageKeys.vendorId, userModel.vendorId);
      await _prefs.setString(StorageKeys.username, userModel.username);
      if (userModel.phoneNumber != null) {
        await _prefs.setString(StorageKeys.phoneNumber, userModel.phoneNumber!);
      }
      await _prefs.setBool(StorageKeys.isActive, userModel.isActive);

      AppLogger.info('Login successful - Vendor ID: ${userModel.vendorId}');
      return userModel.toEntity();
    } catch (e, stackTrace) {
      AppLogger.error('Login error', error: e, stackTrace: stackTrace);
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  /// Logout and clear session
  Future<void> logout() async {
    AppLogger.info('Logging out');
    await Future.delayed(const Duration(milliseconds: 500));

    await _prefs.remove(StorageKeys.isLoggedIn);
    await _prefs.remove(StorageKeys.userId);
    await _prefs.remove(StorageKeys.userEmail);
    await _prefs.remove(StorageKeys.userName);
    await _prefs.remove(StorageKeys.vendorId);
    await _prefs.remove(StorageKeys.username);
    await _prefs.remove(StorageKeys.phoneNumber);
    await _prefs.remove(StorageKeys.isActive);

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
    final vendorId = _prefs.getString(StorageKeys.vendorId);
    final username = _prefs.getString(StorageKeys.username);
    final phoneNumber = _prefs.getString(StorageKeys.phoneNumber);
    final isActive = _prefs.getBool(StorageKeys.isActive);

    if (userId == null || userEmail == null || userName == null || vendorId == null || username == null) {
      return null;
    }

    // Return user with stored data
    final userModel = UserModel(
      id: userId,
      email: userEmail,
      name: userName,
      role: 'Scanner Member',
      scannerId: userId,
      vendorId: vendorId,
      username: username,
      phoneNumber: phoneNumber,
      isActive: isActive ?? true,
    );

    return userModel.toEntity();
  }

  /// Check if current user is still active (call periodically)
  Future<bool> checkUserActiveStatus() async {
    // For now, just return the stored value
    // In the future, you could add an API endpoint to check status
    return _prefs.getBool(StorageKeys.isActive) ?? false;
  }
}
