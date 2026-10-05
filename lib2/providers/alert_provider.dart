import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'employee_provider.dart';
import 'visit_provider.dart';

class AlertProvider with ChangeNotifier {
  final EmployeeProvider _employeeProvider;
  final VisitProvider _visitProvider;

  static const String _documentsStorageKey =
      'employee_id_app_documents_v2';

  // الوثائق محفوظة محلياً في SharedPreferences من شاشة الوثائق،
  // لذلك نخزن نسخة مؤقتة هنا ونحدثها عند أي تغيير.
  List<Map<String, dynamic>> _documents = <Map<String, dynamic>>[];

  AlertProvider(this._employeeProvider, this._visitProvider) {
    _employeeProvider.addListener(_onDataChanged);
    _visitProvider.addListener(_onDataChanged);
    _loadDocuments();
  }

  void _onDataChanged() {
    notifyListeners();
  }

  Future<void> _loadDocuments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_documentsStorageKey);

      if (raw == null || raw.isEmpty) {
        _documents = <Map<String, dynamic>>[];
      } else {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _documents = decoded
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        } else {
          _documents = <Map<String, dynamic>>[];
        }
      }

      notifyListeners();
    } catch (_) {
      // لا نوقف التطبيق إذا كانت بيانات الوثائق غير قابلة للقراءة.
    }
  }

  /// تستدعى بعد إضافة/تعديل/تجديد/حذف أي وثيقة.
  Future<void> refreshDocuments() async {
    await _loadDocuments();
  }

  DateTime? _parseDate(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return null;

    final iso = DateTime.tryParse(text);
    if (iso != null) return iso;

    final normalized = text.replaceAll('/', '-');
    final parts = normalized.split('-');

    if (parts.length == 3) {
      // يدعم DD-MM-YYYY
      final first = int.tryParse(parts[0]);
      final second = int.tryParse(parts[1]);
      final third = int.tryParse(parts[2]);

      if (first != null && second != null && third != null) {
        if (first > 31) {
          return DateTime.tryParse(
            '${first.toString().padLeft(4, '0')}-'
            '${second.toString().padLeft(2, '0')}-'
            '${third.toString().padLeft(2, '0')}',
          );
        }

        return DateTime.tryParse(
          '${third.toString().padLeft(4, '0')}-'
          '${second.toString().padLeft(2, '0')}-'
          '${first.toString().padLeft(2, '0')}',
        );
      }
    }

    return null;
  }

  int? _daysRemaining(dynamic value) {
    final date = _parseDate(value);
    if (date == null) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    return target.difference(today).inDays;
  }

  bool _needsAlert(dynamic value) {
    final days = _daysRemaining(value);

    // نفس قاعدة حالة الوثيقة:
    // منتهية أو تحتاج متابعة خلال 30 يوماً.
    return days != null && days <= 30;
  }

  int get alertCount {
    int count = 0;

    // الموظفون
    for (final emp in _employeeProvider.employees) {
      if (_needsAlert(emp.expiryDate)) {
        count++;
      }
    }

    // الزيارات
    for (final visit in _visitProvider.visits) {
      if (_needsAlert(visit.expiryDate)) {
        count++;
      }
    }

    // وثائق المنشأة
    for (final document in _documents) {
      final expiry = document['expiry'];
      if (_needsAlert(expiry)) {
        count++;
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
