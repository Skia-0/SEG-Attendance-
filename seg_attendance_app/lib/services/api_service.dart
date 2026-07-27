import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'secure_storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ),
  );

  final _storage = SecureStorageService();
  bool _isRefreshing = false;
  Function()? onSessionExpired;

  ApiService._internal() {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401 &&
              !_isRefreshing &&
              error.requestOptions.path != '/auth/login' &&
              error.requestOptions.path != '/auth/refresh') {
            _isRefreshing = true;

            try {
              final refreshToken = await _storage.getRefreshToken();
              if (refreshToken == null) {
                _isRefreshing = false;
                _handleSessionExpired();
                return handler.next(error);
              }

              final refreshDio = Dio(
                BaseOptions(baseUrl: ApiConfig.baseUrl),
              );
              refreshDio.options.headers['Authorization'] =
                  'Bearer $refreshToken';

              final refreshResponse =
                  await refreshDio.post('/auth/refresh');
              final newAccessToken =
                  refreshResponse.data['access_token'];

              await _storage.saveToken(newAccessToken);
              setToken(newAccessToken);

              error.requestOptions.headers['Authorization'] =
                  'Bearer $newAccessToken';
              final retryResponse =
                  await _dio.fetch(error.requestOptions);
              _isRefreshing = false;
              return handler.resolve(retryResponse);
            } catch (_) {
              _isRefreshing = false;
              _handleSessionExpired();
              return handler.next(error);
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  void _handleSessionExpired() {
    if (onSessionExpired != null) {
      onSessionExpired!();
    }
  }

  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearToken() {
    _dio.options.headers.remove('Authorization');
  }

  // ─── AUTH ───────────────────────────────────────────
  Future<Response> login(String phone, String password) {
    return _dio.post('/auth/login', data: {
      'phone': phone,
      'password': password,
    });
  }

  Future<Response> registerCoordinator({
    required String fullName,
    required String phone,
    required String password,
    required String hubId,
  }) {
    return _dio.post('/auth/register', data: {
      'full_name': fullName,
      'phone': phone,
      'password': password,
      'hub_id': hubId,
    });
  }

  // ─── HUBS ────────────────────────────────────────────
  Future<Response> createHub({
    required String name,
    required String location,
  }) {
    return _dio.post('/hubs', data: {
      'name': name,
      'location': location,
    });
  }

  Future<Response> getHub(String hubId) {
    return _dio.get('/hubs/$hubId');
  }

  // ─── COHORTS ─────────────────────────────────────────
  Future<Response> createCohort({
    required String name,
    required String hubId,
    required String startDate,
    required String endDate,
    required int minAttendancePercent,
  }) {
    return _dio.post('/cohorts', data: {
      'name': name,
      'hub_id': hubId,
      'start_date': startDate,
      'end_date': endDate,
      'min_attendance_percent': minAttendancePercent,
    });
  }

  Future<Response> getCohort(String cohortId) {
    return _dio.get('/cohorts/$cohortId');
  }

  Future<Response> getCohortByCode(String code) {
    return _dio.get('/cohorts/code/$code');
  }

  Future<Response> getMyCohorts([String? hubId]) {
    return _dio.get('/cohorts');
  }

  Future<Response> getCohortSummary(String cohortId) {
    return _dio.get('/cohorts/$cohortId/summary');
  }

  Future<Response> getAtRiskLearners(String cohortId) {
    return _dio.get('/cohorts/$cohortId/at-risk');
  }

  Future<Response> deleteCohort(String cohortId) {
    return _dio.delete('/cohorts/$cohortId');
  }

  // ─── LEARNERS ────────────────────────────────────────
  Future<Response> registerLearner({
    required String fullName,
    String? phone,
    required String cohortId,
    String? nfcUid,
  }) {
    return _dio.post('/learners', data: {
      'full_name': fullName,
      'phone': phone,
      'cohort_id': cohortId,
      'nfc_uid': nfcUid,
    });
  }

  Future<Response> getLearnersBycohort(String cohortId) {
    return _dio.get('/learners?cohort_id=$cohortId');
  }

  Future<Response> getLearner(String learnerId) {
    return _dio.get('/learners/$learnerId');
  }

  Future<Response> getLearnerByNfc(String uid) {
    return _dio.get('/learners/nfc/$uid');
  }

  Future<Response> updateLearner({
    required String learnerId,
    String? fullName,
    String? phone,
    String? nfcUid,
  }) {
    final data = <String, dynamic>{};
    if (fullName != null) data['full_name'] = fullName;
    if (phone != null) data['phone'] = phone;
    if (nfcUid != null) data['nfc_uid'] = nfcUid;
    return _dio.patch('/learners/$learnerId', data: data);
  }

  Future<Response> updateFingerprintStatus(String learnerId) {
    return _dio.patch(
      '/learners/$learnerId/fingerprint',
      data: {'fingerprint_enrolled': true},
    );
  }

  Future<Response> deleteLearner(String learnerId) {
    return _dio.delete('/learners/$learnerId');
  }

  // ─── NFC CARDS ───────────────────────────────────────
  Future<Response> assignNfcCard({
    required String uid,
    required String learnerId,
    required String cohortId,
  }) {
    return _dio.post('/nfc-cards/assign', data: {
      'uid': uid,
      'learner_id': learnerId,
      'cohort_id': cohortId,
    });
  }

  Future<Response> clearCohortCards(String cohortId) {
    return _dio.post('/nfc-cards/clear/$cohortId');
  }

  // ─── SESSIONS ────────────────────────────────────────
  Future<Response> startSession({
    required String cohortId,
    required String title,
  }) {
    return _dio.post('/sessions', data: {
      'cohort_id': cohortId,
      'title': title,
    });
  }

  Future<Response> getSession(String sessionId) {
    return _dio.get('/sessions/$sessionId');
  }

  Future<Response> getSessionsByCohor(String cohortId) {
    return _dio.get('/sessions?cohort_id=$cohortId');
  }

  Future<Response> openCheckin(String sessionId) {
    return _dio.patch(
      '/sessions/$sessionId/checkin',
      data: {'open': true},
    );
  }

  Future<Response> closeCheckin(String sessionId) {
    return _dio.patch(
      '/sessions/$sessionId/checkin',
      data: {'open': false},
    );
  }

  Future<Response> openCheckout(String sessionId) {
    return _dio.patch(
      '/sessions/$sessionId/checkout',
      data: {'open': true},
    );
  }

  Future<Response> closeCheckout(String sessionId) {
    return _dio.patch(
      '/sessions/$sessionId/checkout',
      data: {'open': false},
    );
  }

  Future<Response> endSession(String sessionId) {
    return _dio.patch('/sessions/$sessionId/end');
  }

  // ─── ATTENDANCE ──────────────────────────────────────
  Future<Response> checkIn({
    required String sessionId,
    required String learnerId,
    required String verificationMethod,
  }) {
    return _dio.post('/attendance/checkin', data: {
      'session_id': sessionId,
      'learner_id': learnerId,
      'verification_method': verificationMethod,
    });
  }

  Future<Response> checkOut({
    required String sessionId,
    required String learnerId,
    required String verificationMethod,
  }) {
    return _dio.post('/attendance/checkout', data: {
      'session_id': sessionId,
      'learner_id': learnerId,
      'verification_method': verificationMethod,
    });
  }

  Future<Response> getAttendance(String sessionId) {
    return _dio.get('/attendance/$sessionId');
  }

  // ─── COORDINATOR PROFILE ─────────────────────────────
  Future<Response> getMe() {
    return _dio.get('/auth/me');
  }

  Future<Response> updateMe({required String fullName}) {
    return _dio.patch('/auth/me', data: {
      'full_name': fullName,
    });
  }

  Future<Response> changePassword({
    required String oldPassword,
    required String newPassword,
  }) {
    return _dio.post('/auth/change-password', data: {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
  }

  // ─── REPORTS ─────────────────────────────────────────
  Future<Response> submitSessionReport(String sessionId) {
    return _dio.post('/reports/session/$sessionId');
  }

  Future<Response> submitCohortFinalReport(String cohortId) {
    return _dio.post('/reports/cohort/$cohortId/final');
  }

  Future<Response> listReports({String? type}) {
    final params = <String, dynamic>{};
    if (type != null) params['type'] = type;
    return _dio.get('/reports', queryParameters: params);
  }

  Future<Response> getReport(String reportId) {
    return _dio.get('/reports/$reportId');
  }

  Future<Response> getAuditLog({int limit = 100}) {
    return _dio.get(
      '/reports/audit-log',
      queryParameters: {'limit': limit},
    );
  }
}