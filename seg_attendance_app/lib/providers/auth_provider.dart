import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/secure_storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final _api = ApiService();
  final _storage = SecureStorageService();

  String? _token;
  String? _coordinatorName;
  String? _coordinatorId;
  String? _email;
  String? _hubId;
  String? _hubName;

  bool get isLoggedIn => _token != null;
  String? get token => _token;
  String? get coordinatorName => _coordinatorName;
  String? get coordinatorId => _coordinatorId;
  String? get email => _email;
  String? get hubId => _hubId;
  String? get hubName => _hubName;

  AuthProvider() {
    _api.onSessionExpired = () async {
      await logout();
    };
  }

  Future<void> loadFromStorage() async {
    _token = await _storage.getToken();
    _coordinatorName = await _storage.getValue('coordinator_name');
    _coordinatorId = await _storage.getValue('coordinator_id');
    _email = await _storage.getValue('email');
    _hubId = await _storage.getValue('hub_id');
    _hubName = await _storage.getValue('hub_name');
    if (_token != null) {
      _api.setToken(_token!);
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>?> _saveSession(dynamic data) async {
    _token = data['access_token'];
    final refreshToken = data['refresh_token'];
    _coordinatorName = data['coordinator_name'];
    _coordinatorId = data['coordinator_id']?.toString();
    _email = data['email']?.toString();
    _hubId = data['hub_id']?.toString();
    _hubName = data['hub_name']?.toString();

    await _storage.saveToken(_token!);
    if (refreshToken != null) {
      await _storage.saveRefreshToken(refreshToken);
    }
    await _storage.saveValue(
        'coordinator_name', _coordinatorName ?? '');
    await _storage.saveValue(
        'coordinator_id', _coordinatorId ?? '');
    await _storage.saveValue('email', _email ?? '');
    await _storage.saveValue('hub_id', _hubId ?? '');
    await _storage.saveValue('hub_name', _hubName ?? '');

    _api.setToken(_token!);
    notifyListeners();
    return null;
  }

  Future<String?> login(String email, String password) async {
    try {
      final response = await _api.login(email, password);
      await _saveSession(response.data);
      return null;
    } catch (e) {
      final error = e.toString();
      String? backendMessage;
      try {
        final resp = (e as dynamic).response;
        final msg = resp?.data?['error'];
        if (msg != null) backendMessage = msg.toString();

        // Special case — unverified email
        if (resp?.data?['requires_verification'] == true) {
          return 'UNVERIFIED:${resp?.data?['email']}';
        }
      } catch (_) {}

      if (error.contains('SocketException') ||
          error.contains('Failed host lookup')) {
        return 'No internet connection. Check your network.';
      }
      if (error.contains('TimeoutException') ||
          error.contains('timeout')) {
        return 'Server is waking up. Please try again in 30 seconds.';
      }
      if (error.contains('423')) {
        return backendMessage ??
            'Account locked. Try again later.';
      }
      if (error.contains('429')) {
        return 'Too many login attempts. Wait 1 minute and try again.';
      }
      if (error.contains('403')) {
        return backendMessage ?? 'Email not verified.';
      }
      if (error.contains('401')) {
        return backendMessage ??
            'Invalid email or password.';
      }
      return 'Login failed. Please try again.';
    }
  }

  Future<String?> verifyEmailAndLogin(
      String email, String code) async {
    try {
      final response = await _api.verifyEmail(
        email: email,
        code: code,
      );
      await _saveSession(response.data);
      return null;
    } catch (e) {
      try {
        final resp = (e as dynamic).response;
        final msg = resp?.data?['error'];
        if (msg != null) return msg.toString();
      } catch (_) {}
      return 'Verification failed. Try again.';
    }
  }

  Future<void> logout() async {
    _token = null;
    _coordinatorName = null;
    _coordinatorId = null;
    _email = null;
    _hubId = null;
    _hubName = null;
    _api.clearToken();
    await _storage.clearAll();
    notifyListeners();
  }
}