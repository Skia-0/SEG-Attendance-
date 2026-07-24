import 'package:flutter/material.dart';
import '../models/cohort.dart';
import '../services/api_service.dart';

class CohortProvider extends ChangeNotifier {
  final _api = ApiService();

  List<Cohort> _cohorts = [];
  bool _loading = false;
  String? _error;

  List<Cohort> get cohorts => _cohorts;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadCohorts() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.getMyCohorts('');
      final List<dynamic> data = response.data;
      _cohorts = data.map((json) => Cohort.fromJson(json)).toList();
    } catch (e) {
      _error = 'Failed to load cohorts';
      _cohorts = [];
    }

    _loading = false;
    notifyListeners();
  }

  Future<Cohort?> createCohort({
    required String name,
    required String startDate,
    String? endDate,
    required int minAttendancePercent,
  }) async {
    try {
      final response = await _api.createCohort(
        name: name,
        hubId: '',
        startDate: startDate,
        endDate: endDate ?? '',
        minAttendancePercent: minAttendancePercent,
      );
      final cohort = Cohort.fromJson(response.data);
      _cohorts.insert(0, cohort);
      notifyListeners();
      return cohort;
    } catch (e) {
      return null;
    }
  }
}