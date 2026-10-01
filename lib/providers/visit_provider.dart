import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/visit.dart';

class VisitProvider extends ChangeNotifier {
  static const String _storageKey = 'saved_visits';

  final List<Visit> _visits = [];
  late final Future<void> _initialization;

  VisitProvider() {
    _initialization = _loadVisits();
  }

  List<Visit> get visits => List.unmodifiable(_visits);
  int get visitCount => _visits.length;

  Future<void> addVisit(Visit visit) async {
    await _initialization;

    final visa = visit.visaNumber.trim();
    final border = visit.borderNumber.trim();

    if ((visa.isNotEmpty && _visits.any((v) => v.visaNumber.trim() == visa)) ||
        (border.isNotEmpty &&
            _visits.any((v) => v.borderNumber.trim() == border))) {
      return;
    }

    visit.logs.add('تمت إضافة الزيارة بتاريخ ${_today()}');
    _visits.add(visit);
    notifyListeners();
    await _saveVisits();
  }

  Future<int> addVisitsBatch(List<Visit> newVisits) async {
    await _initialization;
    if (newVisits.isEmpty) return 0;

    final visas = _visits
        .map((v) => v.visaNumber.trim())
        .where((v) => v.isNotEmpty)
        .toSet();

    final borders = _visits
        .map((v) => v.borderNumber.trim())
        .where((v) => v.isNotEmpty)
        .toSet();

    int added = 0;

    for (final visit in newVisits) {
      final visa = visit.visaNumber.trim();
      final border = visit.borderNumber.trim();

      if ((visa.isNotEmpty && visas.contains(visa)) ||
          (border.isNotEmpty && borders.contains(border))) {
        continue;
      }

      visit.logs.add('تمت إضافة الزيارة بتاريخ ${_today()}');
      _visits.add(visit);
      added++;

      if (visa.isNotEmpty) visas.add(visa);
      if (border.isNotEmpty) borders.add(border);
    }

    if (added > 0) {
      notifyListeners();
      await _saveVisits();
    }

    return added;
  }

  Future<void> updateVisit(Visit updatedVisit) async {
    await _initialization;

    final index = _visits.indexWhere((v) => v.id == updatedVisit.id);
    if (index == -1) return;

    updatedVisit.logs.add('تم تعديل بيانات الزيارة بتاريخ ${_today()}');
    _visits[index] = updatedVisit;
    notifyListeners();
    await _saveVisits();
  }

  Future<void> renewVisit(
    String id, {
    required String newExpiryDate,
    String? newInsuranceExpiryDate,
    String? notes,
  }) async {
    await _initialization;

    final index = _visits.indexWhere((v) => v.id == id);
    if (index == -1) return;

    final old = _visits[index];

    old.logs.add(
      'تم تجديد الزيارة حتى $newExpiryDate بتاريخ ${_today()}',
    );

    _visits[index] = old.copyWith(
      expiryDate: newExpiryDate,
      insuranceExpiryDate:
          newInsuranceExpiryDate ?? old.insuranceExpiryDate,
      notes: notes ?? old.notes,
      status: 'سارية',
    );

    notifyListeners();
    await _saveVisits();
  }

  Future<void> removeVisit(String id) async {
    await _initialization;

    final oldLength = _visits.length;
    _visits.removeWhere((v) => v.id == id);

    if (_visits.length == oldLength) return;

    notifyListeners();
    await _saveVisits();
  }

  Future<void> clearVisits() async {
    await _initialization;
    _visits.clear();
    notifyListeners();
    await _saveVisits();
  }

  Future<void> _saveVisits() async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = _visits
        .map((visit) => jsonEncode(visit.toJson()))
        .toList();

    await prefs.setStringList(_storageKey, encoded);
  }

  Future<void> _loadVisits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_storageKey);

      _visits.clear();

      if (saved != null && saved.isNotEmpty) {
        for (final item in saved) {
          try {
            final decoded = jsonDecode(item);

            if (decoded is Map<String, dynamic>) {
              _visits.add(Visit.fromJson(decoded));
            } else if (decoded is Map) {
              _visits.add(
                Visit.fromJson(Map<String, dynamic>.from(decoded)),
              );
            }
          } catch (e) {
            debugPrint('Visit load item error: $e');
          }
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Visit storage error: $e');
      debugPrint(stackTrace.toString());
      _visits.clear();
    }

    notifyListeners();
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
