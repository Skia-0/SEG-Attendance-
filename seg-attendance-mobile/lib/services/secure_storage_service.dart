import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  static const _tokenKey = 'access_token';
  static const _coordIdKey = 'coordinator_id';
  static const _coordNameKey = 'coordinator_name';
  static const _hubIdKey = 'hub_id';

  Future<void> saveAuthData({
    required String token,
    required String coordinatorId,
    required String coordinatorName,
    required String hubId,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _coordIdKey, value: coordinatorId);
    await _storage.write(key: _coordNameKey, value: coordinatorName);
    await _storage.write(key: _hubIdKey, value: hubId);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<String?> getCoordinatorId() async {
    return await _storage.read(key: _coordIdKey);
  }

  Future<String?> getCoordinatorName() async {
    return await _storage.read(key: _coordNameKey);
  }

  Future<String?> getHubId() async {
    return await _storage.read(key: _hubIdKey);
  }

  Future<void> clearAuthData() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _coordIdKey);
    await _storage.delete(key: _coordNameKey);
    await _storage.delete(key: _hubIdKey);
  }
}
