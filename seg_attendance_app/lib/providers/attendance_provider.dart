import 'dart:async';
import 'package:flutter/material.dart';
import '../models/attendance_record.dart';
import '../models/session.dart';
import '../services/api_service.dart';

class AttendanceProvider extends ChangeNotifier {
  final _api = ApiService();

  SessionModel? _session;
  List<AttendanceRecord> _records = [];
  bool _loading = false;
  Timer? _pollTimer;

  SessionModel? get session => _session;
  List<AttendanceRecord> get records => _records;
  bool get loading => _loading;

  int get checkedInCount =>
      _records.where((r) => r.hasCheckedIn).length;
  int get completeCount =>
      _records.where((r) => r.isComplete).length;
  int get totalLearners => _records.length;

  Future<void> loadSession(String sessionId) async {
    _loading = true;
    notifyListeners();

    try {
      final sessionRes = await _api.getSession(sessionId);
      _session = SessionModel.fromJson(sessionRes.data);
      await loadAttendance();
    } catch (e) {
      _session = null;
      _records = [];
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> loadAttendance() async {
    if (_session == null) return;
    try {
      final res = await _api.getAttendance(_session!.sessionId);
      final List<dynamic> data = res.data;
      _records =
          data.map((j) => AttendanceRecord.fromJson(j)).toList();
      notifyListeners();
    } catch (_) {}
  }

  void startPolling() {
    stopPolling();
    _pollTimer =
        Timer.periodic(const Duration(seconds: 4), (_) {
      loadAttendance();
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<bool> openCheckin() async {
    if (_session == null) return false;
    try {
      final res = await _api.openCheckin(_session!.sessionId);
      _session = SessionModel.fromJson(res.data);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> openCheckout() async {
    if (_session == null) return false;
    try {
      final res = await _api.openCheckout(_session!.sessionId);
      _session = SessionModel.fromJson(res.data);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> endSession() async {
    if (_session == null) return false;
    try {
      final res = await _api.endSession(_session!.sessionId);
      _session = SessionModel.fromJson(res.data);
      stopPolling();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> checkIn({
    required String learnerId,
    required String method,
  }) async {
    if (_session == null) return 'No session';
    try {
      await _api.checkIn(
        sessionId: _session!.sessionId,
        learnerId: learnerId,
        verificationMethod: method,
      );
      await loadAttendance();
      return null;
    } catch (e) {
      return _parseError(e);
    }
  }

  Future<String?> checkOut({
    required String learnerId,
    required String method,
  }) async {
    if (_session == null) return 'No session';
    try {
      await _api.checkOut(
        sessionId: _session!.sessionId,
        learnerId: learnerId,
        verificationMethod: method,
      );
      await loadAttendance();
      return null;
    } catch (e) {
      return _parseError(e);
    }
  }

  String _parseError(dynamic e) {
    try {
      final err = e.response?.data?['error'];
      if (err != null) return err.toString();
    } catch (_) {}
    return 'Something went wrong';
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}