import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/secure_storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final SecureStorageService _secureStorageService = SecureStorageService();

  bool _isLoading = false;
  String? _errorMessage;
  String? _coordinatorName;
  String? _coordinatorId;
  String? _hubId;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get coordinatorName => _coordinatorName;
  String? get coordinatorId => _coordinatorId;
  String? get hubId => _hubId;
  bool get isAuthenticated => _coordinatorId != null;

  AuthProvider() {
    _loadAuthData();
  }

  Future<void> _loadAuthData() async {
    _coordinatorId = await _secureStorageService.getCoordinatorId();
    _coordinatorName = await _secureStorageService.getCoordinatorName();
    _hubId = await _secureStorageService.getHubId();
    notifyListeners();
  }

  Future<bool> login(String phone, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        '/auth/login',
        data: {'phone': phone, 'password': password},
      );

      final data = response.data;
      final token = data['access_token'];
      _coordinatorName = data['coordinator_name'];
      _coordinatorId = data['coordinator_id'];
      _hubId = data['hub_id'];

      await _secureStorageService.saveAuthData(
        token: token,
        coordinatorId: _coordinatorId!,
        coordinatorName: _coordinatorName!,
        hubId: _hubId!,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _secureStorageService.clearAuthData();
    _coordinatorId = null;
    _coordinatorName = null;
    _hubId = null;
    notifyListeners();
  }
}
