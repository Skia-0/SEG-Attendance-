import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/attendance_record.dart';
import '../models/learner.dart';

class AttendanceProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  String? _errorMessage;
  List<AttendanceRecord> _records = [];
  List<Map<String, dynamic>> _summaryList = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<AttendanceRecord> get records => _records;
  List<Map<String, dynamic>> get summaryList => _summaryList;

  Future<void> loadAttendanceRecords(String sessionId) async {
    try {
      final response = await _apiService.get('/attendance/$sessionId');
      final list = (response.data as List)
          .map((item) => AttendanceRecord.fromJson(item))
          .toList();
      _records = list;
      notifyListeners();
    } catch (e) {
      // Background loading ignore or handle gracefully
    }
  }

  Future<bool> checkInLearner({
    required String sessionId,
    required String learnerId,
    required String verificationMethod,
  }) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.post(
        '/attendance/checkin',
        data: {
          'session_id': sessionId,
          'learner_id': learnerId,
          'verification_method': verificationMethod,
        },
      );
      await loadAttendanceRecords(sessionId);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkOutLearner({
    required String sessionId,
    required String learnerId,
    required String verificationMethod,
  }) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.post(
        '/attendance/checkout',
        data: {
          'session_id': sessionId,
          'learner_id': learnerId,
          'verification_method': verificationMethod,
        },
      );
      await loadAttendanceRecords(sessionId);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<Learner?> registerLearner({
    required String fullName,
    String? phone,
    required String cohortId,
    String? nfcUid,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        '/learners',
        data: {
          'full_name': fullName,
          'phone': phone,
          'cohort_id': cohortId,
          'nfc_uid': nfcUid,
        },
      );
      _isLoading = false;
      notifyListeners();
      return Learner.fromJson(response.data);
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<Learner?> lookupLearnerByNfc(String uid) async {
    _errorMessage = null;
    try {
      final response = await _apiService.get('/learners/nfc/$uid');
      return Learner.fromJson(response.data);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<bool> loadSummary(String cohortId) async {
    _isLoading = true;
    _errorMessage = null;
    _summaryList = [];
    notifyListeners();

    try {
      final response = await _apiService.get('/cohorts/$cohortId/summary');
      _summaryList = List<Map<String, dynamic>>.from(response.data);
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

  Future<bool> assignNfcCard({
    required String uid,
    required String learnerId,
    required String cohortId,
  }) async {
    _errorMessage = null;
    try {
      await _apiService.post(
        '/nfc-cards/assign',
        data: {
          'uid': uid,
          'learner_id': learnerId,
          'cohort_id': cohortId,
        },
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
