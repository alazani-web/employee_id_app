import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/visit.dart';

class VisitProvider extends ChangeNotifier {
  static const String _storageKey = 'saved_visits';

  final List<Visit> _visits = [];
  late final Future<void> _initialization;

  String _normalizeIdentifier(String value) {
    var result = value.trim();

    const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
    const westernDigits = '0123456789';
    for (int i = 0; i < arabicDigits.length; i++) {
      result = result.replaceAll(arabicDigits[i], westernDigits[i]);
    }

    result = result.replaceAll(RegExp(r'(?<=\d)\.0+$'), '');
    result = result.replaceAll(RegExp(r'[\s\-_/+,]+'), '');
    return result;
  }

  VisitProvider() {
    _initialization = _loadVisits();
  }

  String _normalizeName(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll(RegExp(r'\\s+'), '');
  }

  List<Visit> get visits => List.unmodifiable(_visits);
  int get visitCount => _visits.length;

  Future<void> addVisit(Visit visit) async {
    await _initialization;

    final passport = _normalizeIdentifier(visit.passportNumber);
    final visa = _normalizeIdentifier(visit.visaNumber);
    final border = _normalizeIdentifier(visit.borderNumber);

    final name = _normalizeName(visit.visitorName);
    final duplicate = _visits.any((existing) {
      final existingName = _normalizeName(existing.visitorName);
      final existingPassport = _normalizeIdentifier(existing.passportNumber);
      final existingVisa = _normalizeIdentifier(existing.visaNumber);
      final existingBorder = _normalizeIdentifier(existing.borderNumber);

      final sameNameAndIdentifier =
          name.isNotEmpty &&
          name == existingName &&
          (
            (passport.isNotEmpty && passport == existingPassport) ||
            (visa.isNotEmpty && visa == existingVisa) ||
            (border.isNotEmpty && border == existingBorder)
          );

      final allExistingIdentifiersMatch =
          passport.isNotEmpty &&
          visa.isNotEmpty &&
          border.isNotEmpty &&
          passport == existingPassport &&
          visa == existingVisa &&
          border == existingBorder;

      return sameNameAndIdentifier || allExistingIdentifiersMatch;
    });

    if (duplicate) {
      return;
    }

    visit.logs.add(
      'تمت إضافة الزيارة بتاريخ ${_todayWithTime()}',
    );
    _visits.add(visit);
    notifyListeners();
    await _saveVisits();
  }

  Future<int> addVisitsBatch(List<Visit> newVisits) async {
    await _initialization;
    if (newVisits.isEmpty) return 0;

    final passports = _visits
        .map((v) => _normalizeIdentifier(v.passportNumber))
        .where((v) => v.isNotEmpty)
        .toSet();

    final visas = _visits
        .map((v) => _normalizeIdentifier(v.visaNumber))
        .where((v) => v.isNotEmpty)
        .toSet();

    final borders = _visits
        .map((v) => _normalizeIdentifier(v.borderNumber))
        .where((v) => v.isNotEmpty)
        .toSet();

    int added = 0;

    for (final visit in newVisits) {
      final name = _normalizeName(visit.visitorName);
      final passport = _normalizeIdentifier(visit.passportNumber);
      final visa = _normalizeIdentifier(visit.visaNumber);
      final border = _normalizeIdentifier(visit.borderNumber);

      // لا نعتبر الزيارة مكررة لمجرد تطابق رقم واحد مع شخص آخر.
      // التكرار الحقيقي يكون عندما يكون الاسم نفسه ومعه معرف متطابق،
      // أو عندما تتطابق جميع المعرفات الموجودة في السجلين.
      final duplicate = _visits.any((existing) {
        final existingName = _normalizeName(existing.visitorName);
        final existingPassport = _normalizeIdentifier(existing.passportNumber);
        final existingVisa = _normalizeIdentifier(existing.visaNumber);
        final existingBorder = _normalizeIdentifier(existing.borderNumber);

        final sameNameAndIdentifier =
            name.isNotEmpty &&
            name == existingName &&
            (
              (passport.isNotEmpty && passport == existingPassport) ||
              (visa.isNotEmpty && visa == existingVisa) ||
              (border.isNotEmpty && border == existingBorder)
            );

        final allExistingIdentifiersMatch =
            passport.isNotEmpty &&
            visa.isNotEmpty &&
            border.isNotEmpty &&
            passport == existingPassport &&
            visa == existingVisa &&
            border == existingBorder;

        return sameNameAndIdentifier || allExistingIdentifiersMatch;
      });

      if (duplicate) {
        continue;
      }

      visit.logs.add(
        'تمت إضافة الزيارة عبر الاستيراد بتاريخ ${_todayWithTime()}',
      );
      _visits.add(visit);
      added++;
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

    updatedVisit.logs.add(
      'تم تعديل بيانات الزيارة بتاريخ ${_todayWithTime()}',
    );
    _visits[index] = updatedVisit;
    notifyListeners();
    await _saveVisits();
  }

  Future<void> renewVisit(
    String id, {
    required String newExpiryDate,
    String? newInsuranceExpiryDate,
    String? notes,
    int? renewalMonths,
  }) async {
    await _initialization;

    final index = _visits.indexWhere((v) => v.id == id);
    if (index == -1) return;

    final old = _visits[index];
    final oldExpiry = old.expiryDate;
    final durationText = renewalMonths == null
        ? 'غير محددة'
        : renewalMonths == 1
            ? 'شهر واحد'
            : '$renewalMonths أشهر';

    old.logs.add(
      'تم تجديد الزيارة بتاريخ ${_todayWithTime()}\n'
      'مدة التجديد: $durationText\n'
      'من تاريخ: $oldExpiry\n'
      'إلى تاريخ: $newExpiryDate'
      '${newInsuranceExpiryDate != null && newInsuranceExpiryDate.isNotEmpty ? '\nانتهاء التأمين الجديد: $newInsuranceExpiryDate' : ''}',
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

  String _todayWithTime() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year} - '
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';
  }
}
