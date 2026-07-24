import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/secure_storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final _api = ApiService();
  final _storage = SecureStorageService();

  String? _token;
  String? _coordinatorName;
  String? _coordinatorId;
  String? _hubId;
  String? _hubName;

  bool get isLoggedIn => _token != null;
  String? get token => _token;
  String? get coordinatorName => _coordinatorName;
  String? get coordinatorId => _coordinatorId;
  String? get hubId => _hubId;
  String? get hubName => _hubName;

  Future<void> loadFromStorage() async {
    _token = await _storage.getToken();
    _coordinatorName = await _storage.getValue('coordinator_name');
    _coordinatorId = await _storage.getValue('coordinator_id');
    _hubId = await _storage.getValue('hub_id');
    _hubName = await _storage.getValue('hub_name');
    if (_token != null) {
      _api.setToken(_token!);
    }
    notifyListeners();
  }

  Future<String?> login(String phone, String password) async {
  try {
    final response = await _api.login(phone, password);
    final data = response.data;

    _token = data['access_token'];
    _coordinatorName = data['coordinator_name'];
    _coordinatorId = data['coordinator_id']?.toString();
    _hubId = data['hub_id']?.toString();
    _hubName = data['hub_name']?.toString();

    await _storage.saveToken(_token!);
    await _storage.saveValue(
        'coordinator_name', _coordinatorName ?? '');
    await _storage.saveValue(
        'coordinator_id', _coordinatorId ?? '');
    await _storage.saveValue('hub_id', _hubId ?? '');
    await _storage.saveValue('hub_name', _hubName ?? '');

    _api.setToken(_token!);
    notifyListeners();
    return null;
  } catch (e) {
    // Better error messages
    final error = e.toString();
    if (error.contains('SocketException') ||
        error.contains('Failed host lookup')) {
      return 'No internet connection. Check your network.';
    }
    if (error.contains('TimeoutException') ||
        error.contains('timeout')) {
      return 'Server is waking up. Please try again in 30 seconds.';
    }
    if (error.contains('401')) {
      return 'Invalid phone number or password.';
    }
    if (error.contains('404')) {
      return 'Server not found. Contact admin.';
    }
    return 'Login failed: ${error.split(":").first}';
  }
}

  Future<void> logout() async {
    _token = null;
    _coordinatorName = null;
    _coordinatorId = null;
    _hubId = null;
    _hubName = null;
    _api.clearToken();
    await _storage.clearAll();
    notifyListeners();
  }
}