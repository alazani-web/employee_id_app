import 'package:flutter/foundation.dart';
import 'employee_provider.dart';
import 'visit_provider.dart';

class AlertProvider with ChangeNotifier {
  final EmployeeProvider _employeeProvider;
  final VisitProvider _visitProvider;

  AlertProvider(this._employeeProvider, this._visitProvider) {
    _employeeProvider.addListener(_onDataChanged);
    _visitProvider.addListener(_onDataChanged);
  }

  void _onDataChanged() {
    notifyListeners();
  }

  int get alertCount {
    int count = 0;
    final now = DateTime.now();

    for (var emp in _employeeProvider.employees) {
      if (emp.expiryDate.isNotEmpty) {
        try {
          final expiry = DateTime.parse(emp.expiryDate);
          final difference = expiry.difference(now).inDays;
          if (difference <= 30) {
            count++;
          }
        } catch (_) {}
      }
    }

    for (var visit in _visitProvider.visits) {
      if (visit.expiryDate.isNotEmpty) {
        try {
          final expiry = DateTime.parse(visit.expiryDate);
          final difference = expiry.difference(now).inDays;
          if (difference <= 30) {
            count++;
          }
        } catch (_) {}
      }
    }

    return count;
  }

  @override
  void dispose() {
    _employeeProvider.removeListener(_onDataChanged);
    _visitProvider.removeListener(_onDataChanged);
    super.dispose();
  }
}