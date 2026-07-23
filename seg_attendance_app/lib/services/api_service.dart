import 'package:dio/dio.dart';
import '../config/api_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ),
  );

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

  Future<Response> getMyCohorts(String hubId) {
    return _dio.get('/cohorts?hub_id=$hubId');
  }

  Future<Response> getCohortSummary(String cohortId) {
    return _dio.get('/cohorts/$cohortId/summary');
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

  Future<Response> getLearnerByNfc(String uid) {
    return _dio.get('/learners/nfc/$uid');
  }

  Future<Response> updateFingerprintStatus(String learnerId) {
    return _dio.patch(
      '/learners/$learnerId/fingerprint',
      data: {'fingerprint_enrolled': true},
    );
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

  Future<Response> getSessionsByCohor(String cohortId) {
    return _dio.get('/sessions?cohort_id=$cohortId');
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
}