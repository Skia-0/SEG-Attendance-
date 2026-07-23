import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/cohort.dart';
import '../models/session.dart';

class SessionProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  String? _errorMessage;
  Cohort? _currentCohort;
  Session? _currentSession;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Cohort? get currentCohort => _currentCohort;
  Session? get currentSession => _currentSession;

  Future<bool> loadCohort(String cohortId) async {
    _isLoading = true;
    _errorMessage = null;
    _currentCohort = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/cohorts/$cohortId');
      _currentCohort = Cohort.fromJson(response.data);
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

  Future<bool> startSession(String cohortId, String title) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        '/sessions',
        data: {'cohort_id': cohortId, 'title': title},
      );
      _currentSession = Session.fromJson(response.data);
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

  Future<void> loadSession(String sessionId) async {
    try {
      final response = await _apiService.get('/sessions/$sessionId');
      _currentSession = Session.fromJson(response.data);
      notifyListeners();
    } catch (e) {
      // Ignore background errors
    }
  }

  Future<bool> updateCheckinState(bool open) async {
    if (_currentSession == null) return false;
    try {
      final response = await _apiService.patch(
        '/sessions/${_currentSession!.sessionId}/checkin',
        data: {'open': open},
      );
      _currentSession = Session.fromJson(response.data);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCheckoutState(bool open) async {
    if (_currentSession == null) return false;
    try {
      final response = await _apiService.patch(
        '/sessions/${_currentSession!.sessionId}/checkout',
        data: {'open': open},
      );
      _currentSession = Session.fromJson(response.data);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> endSession() async {
    if (_currentSession == null) return false;
    try {
      final response = await _apiService.patch(
        '/sessions/${_currentSession!.sessionId}/end',
      );
      _currentSession = Session.fromJson(response.data);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
