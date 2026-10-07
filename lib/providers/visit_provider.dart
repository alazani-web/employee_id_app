import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/visit.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';
import '../utils/renewal_calculator.dart';

class VisitProvider extends ChangeNotifier {
  static const String _storageKey = 'saved_visits';

  final List<Visit> _visits = [];
  late final Future<void> _initialization;

  VisitProvider() {
    _initialization = _loadVisits();
  }

  // ============================================================
  // Helpers
  // ============================================================

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

  String _normalizeName(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll(RegExp(r'\s+'), '');
  }

  String _todayWithTime() {
    final now = DateTime.now();

    return '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year} - '
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';
  }

  List<Visit> get visits => List.unmodifiable(_visits);

  int get visitCount => _visits.length;

  // ============================================================
  // Supabase
  // ============================================================

  Future<User?> _ensureSupabaseUser() async {
    try {
      final service = SupabaseService.instance;

      if (service.currentUser != null) {
        return service.currentUser;
      }

      // لا توجد شاشة تسجيل دخول حالياً، لذلك نستخدم Anonymous Auth.
      final response = await service.client.auth.signInAnonymously();
      return response.user;
    } catch (e) {
      debugPrint('Supabase authentication error (visits): $e');
      return null;
    }
  }

  DateTime? _parseSupabaseDate(String value) {
    if (value.trim().isEmpty) return null;

    final parsed = DateTime.tryParse(value.trim());
    if (parsed == null) return null;

    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  Map<String, dynamic> _visitToSupabaseRow(
    Visit visit,
    String userId,
  ) {
    return {
      'user_id': userId,
      'id': visit.id,
      'visitor_name': visit.visitorName,
      'passport_number': visit.passportNumber,
      'visa_number': visit.visaNumber,
      'border_number': visit.borderNumber,
      'expiry_date': _parseSupabaseDate(visit.expiryDate)
          ?.toIso8601String()
          .split('T')
          .first,
      'insurance_expiry_date': _parseSupabaseDate(visit.insuranceExpiryDate)
          ?.toIso8601String()
          .split('T')
          .first,
      'notes': visit.notes,
      'status': visit.status,
      'logs': visit.logs,
    };
  }

  Future<void> _upsertVisitToSupabase(Visit visit) async {
    try {
      final user = await _ensureSupabaseUser();

      if (user == null) {
        debugPrint(
          'Supabase visit sync skipped: no authenticated user.',
        );
        return;
      }

      await SupabaseService.instance.client
          .from('visits')
          .upsert(
            _visitToSupabaseRow(visit, user.id),
            onConflict: 'user_id,id',
          );
    } catch (e, stackTrace) {
      // السحابة ثانوية؛ لا نمنع الحفظ المحلي إذا فشلت.
      debugPrint('Supabase visit upsert error: $e');
      debugPrint(stackTrace.toString());
    }
  }

  Future<void> _deleteVisitFromSupabase(String id) async {
    try {
      final user = await _ensureSupabaseUser();

      if (user == null) return;

      await SupabaseService.instance.client
          .from('visits')
          .delete()
          .eq('id', id)
          .eq('user_id', user.id);
    } catch (e, stackTrace) {
      debugPrint('Supabase visit delete error: $e');
      debugPrint(stackTrace.toString());
    }
  }

  /// رفع جميع الزيارات المحفوظة محلياً إلى Supabase.
  ///
  /// لا يحذف أو يستبدل البيانات المحلية.
  Future<int> syncLocalVisitsToSupabase() async {
    await _initialization;

    if (_visits.isEmpty) return 0;

    try {
      final user = await _ensureSupabaseUser();

      if (user == null) {
        debugPrint(
          'Supabase bulk visit sync skipped: no authenticated user.',
        );
        return 0;
      }

      final rows = _visits
          .map((visit) => _visitToSupabaseRow(visit, user.id))
          .toList();

      await SupabaseService.instance.client
          .from('visits')
          .upsert(
            rows,
            onConflict: 'user_id,id',
          );

      return rows.length;
    } catch (e, stackTrace) {
      debugPrint('Supabase bulk visit sync error: $e');
      debugPrint(stackTrace.toString());
      return 0;
    }
  }

  // ============================================================
  // Notifications
  // ============================================================

  Future<void> _syncVisitNotifications(Visit visit) async {
    if (visit.id.trim().isEmpty) return;

    try {
      final visitExpiry =
          RenewalCalculator.parseDate(visit.expiryDate);

      if (visitExpiry != null) {
        await NotificationService.instance.scheduleVisit(
          visitId: visit.id,
          visitName: visit.visitorName,
          visitDate: visitExpiry,
        );
      }

      final insuranceExpiry =
          RenewalCalculator.parseDate(visit.insuranceExpiryDate);

      if (insuranceExpiry != null) {
        await NotificationService.instance.scheduleInsurance(
          insuranceId: visit.id,
          insuranceName: visit.visitorName,
          expiryDate: insuranceExpiry,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Visit notification sync error: $e');
      debugPrint(stackTrace.toString());
    }
  }

  Future<void> _cancelVisitNotifications(String visitId) async {
    if (visitId.trim().isEmpty) return;

    try {
      await NotificationService.instance.cancelItemNotifications(
        type: NotificationType.visit,
        itemId: visitId,
      );
    } catch (e, stackTrace) {
      debugPrint('Cancel visit notification error: $e');
      debugPrint(stackTrace.toString());
    }

    try {
      await NotificationService.instance.cancelItemNotifications(
        type: NotificationType.insurance,
        itemId: visitId,
      );
    } catch (e, stackTrace) {
      debugPrint('Cancel insurance notification error: $e');
      debugPrint(stackTrace.toString());
    }
  }

  // ============================================================
  // Add
  // ============================================================

  Future<void> addVisit(Visit visit) async {
    await _initialization;

    final passport = _normalizeIdentifier(visit.passportNumber);
    final visa = _normalizeIdentifier(visit.visaNumber);
    final border = _normalizeIdentifier(visit.borderNumber);
    final name = _normalizeName(visit.visitorName);

    final duplicate = _visits.any((existing) {
      final existingName = _normalizeName(existing.visitorName);
      final existingPassport =
          _normalizeIdentifier(existing.passportNumber);
      final existingVisa =
          _normalizeIdentifier(existing.visaNumber);
      final existingBorder =
          _normalizeIdentifier(existing.borderNumber);

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

    if (duplicate) return;

    visit.logs.add(
      'تمت إضافة الزيارة بتاريخ ${_todayWithTime()}',
    );

    _visits.add(visit);

    notifyListeners();

    await _saveVisits();

    // السحابة ثانوية ولا تمنع الحفظ المحلي.
    await _upsertVisitToSupabase(visit);

    // جدولة إشعارات السجل الجديد فقط.
    await _syncVisitNotifications(visit);
  }

  // ============================================================
  // Batch Import
  // ============================================================

  Future<int> addVisitsBatch(List<Visit> newVisits) async {
    await _initialization;

    if (newVisits.isEmpty) return 0;

    int added = 0;

    for (final visit in newVisits) {
      final name = _normalizeName(visit.visitorName);
      final passport = _normalizeIdentifier(visit.passportNumber);
      final visa = _normalizeIdentifier(visit.visaNumber);
      final border = _normalizeIdentifier(visit.borderNumber);

      final duplicate = _visits.any((existing) {
        final existingName = _normalizeName(existing.visitorName);
        final existingPassport =
            _normalizeIdentifier(existing.passportNumber);
        final existingVisa =
            _normalizeIdentifier(existing.visaNumber);
        final existingBorder =
            _normalizeIdentifier(existing.borderNumber);

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

      if (duplicate) continue;

      visit.logs.add(
        'تمت إضافة الزيارة عبر الاستيراد بتاريخ ${_todayWithTime()}',
      );

      _visits.add(visit);
      added++;
    }

    if (added > 0) {
      notifyListeners();
      await _saveVisits();

      // رفع السجلات التي تمت إضافتها فعليًا إلى Supabase.
      final addedVisits = <Visit>[];
      for (final visit in newVisits) {
        final wasAdded = _visits.any(
          (item) => item.id == visit.id,
        );

        if (wasAdded) {
          addedVisits.add(visit);
        }
      }

      if (addedVisits.isNotEmpty) {
        try {
          final user = await _ensureSupabaseUser();

          if (user != null) {
            final rows = addedVisits
                .map((visit) => _visitToSupabaseRow(visit, user.id))
                .toList();

            await SupabaseService.instance.client
                .from('visits')
                .upsert(
                  rows,
                  onConflict: 'user_id,id',
                );
          }
        } catch (e, stackTrace) {
          debugPrint('Supabase batch visit sync error: $e');
          debugPrint(stackTrace.toString());
        }
      }

      // جدولة إشعارات السجلات التي تمت إضافتها فعليًا فقط.
      for (final visit in addedVisits) {
        await _syncVisitNotifications(visit);
      }
    }

    return added;
  }

  // ============================================================
  // Update
  // ============================================================

  Future<void> updateVisit(Visit updatedVisit) async {
    await _initialization;

    final index = _visits.indexWhere(
      (v) => v.id == updatedVisit.id,
    );

    if (index == -1) return;

    // إلغاء الجدولة القديمة أولًا حتى لا يبقى إشعار بالتاريخ القديم.
    await _cancelVisitNotifications(updatedVisit.id);

    updatedVisit.logs.add(
      'تم تعديل بيانات الزيارة بتاريخ ${_todayWithTime()}',
    );

    _visits[index] = updatedVisit;

    notifyListeners();

    await _saveVisits();

    await _upsertVisitToSupabase(updatedVisit);

    // إنشاء الجدولة الجديدة حسب التواريخ الجديدة فقط.
    await _syncVisitNotifications(updatedVisit);
  }

  // ============================================================
  // Renew
  // ============================================================

  Future<void> renewVisit(
    String id, {
    required String newExpiryDate,
    String? newInsuranceExpiryDate,
    String? notes,
    int? renewalMonths,
  }) async {
    await _initialization;

    final index = _visits.indexWhere(
      (v) => v.id == id,
    );

    if (index == -1) return;

    final old = _visits[index];
    final oldExpiry = old.expiryDate;

    final durationText = renewalMonths == null
        ? 'غير محددة'
        : renewalMonths == 1
            ? 'شهر واحد'
            : '$renewalMonths أشهر';

    // إلغاء الإشعارات القديمة قبل إنشاء الجدولة الجديدة.
    await _cancelVisitNotifications(id);

    old.logs.add(
      'تم تجديد الزيارة بتاريخ ${_todayWithTime()}\n'
      'مدة التجديد: $durationText\n'
      'من تاريخ: $oldExpiry\n'
      'إلى تاريخ: $newExpiryDate'
      '${newInsuranceExpiryDate != null &&
              newInsuranceExpiryDate.isNotEmpty
          ? '\nانتهاء التأمين الجديد: $newInsuranceExpiryDate'
          : ''}',
    );

    final updated = old.copyWith(
      expiryDate: newExpiryDate,
      insuranceExpiryDate:
          newInsuranceExpiryDate ?? old.insuranceExpiryDate,
      notes: notes ?? old.notes,
      status: 'سارية',
    );

    _visits[index] = updated;

    notifyListeners();

    await _saveVisits();

    await _upsertVisitToSupabase(updated);

    await _syncVisitNotifications(updated);
  }

  // ============================================================
  // Remove Single Visit
  // ============================================================

  Future<void> removeVisit(String id) async {
    await _initialization;

    final index = _visits.indexWhere(
      (visit) => visit.id == id,
    );

    if (index == -1) return;

    final removedVisit = _visits[index];

    // مهم جدًا:
    // نلغي إشعارات السجل قبل حذفه من الذاكرة.
    await _cancelVisitNotifications(removedVisit.id);

    _visits.removeAt(index);

    notifyListeners();

    // نحفظ القائمة بعد الحذف مباشرة.
    // لا توجد هنا أي عملية تعيد جدولة الإشعارات.
    await _saveVisits();
    await _deleteVisitFromSupabase(id);
  }

  // ============================================================
  // Clear All Visits
  // ============================================================

  Future<void> clearVisits() async {
    await _initialization;

    if (_visits.isEmpty) return;

    // إلغاء إشعارات كل زيارة قبل مسح السجلات.
    final visitIds = _visits
        .map((visit) => visit.id)
        .where((id) => id.trim().isNotEmpty)
        .toList();

    for (final id in visitIds) {
      await _cancelVisitNotifications(id);
    }

    _visits.clear();

    notifyListeners();

    await _saveVisits();

    // حذف الزيارات من Supabase بعد حذفها محلياً.
    for (final id in visitIds) {
      await _deleteVisitFromSupabase(id);
    }
  }

  // ============================================================
  // Storage
  // ============================================================

  Future<void> _saveVisits() async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = _visits
        .map((visit) => jsonEncode(visit.toJson()))
        .toList();

    await prefs.setStringList(
      _storageKey,
      encoded,
    );
  }

  Future<void> reloadFromStorage() async {
    await _loadVisits();
  }

  Future<void> _loadVisits() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final saved = prefs.getStringList(
        _storageKey,
      );

      _visits.clear();

      if (saved != null && saved.isNotEmpty) {
        for (final item in saved) {
          try {
            final decoded = jsonDecode(item);

            if (decoded is Map<String, dynamic>) {
              _visits.add(
                Visit.fromJson(decoded),
              );
            } else if (decoded is Map) {
              _visits.add(
                Visit.fromJson(
                  Map<String, dynamic>.from(decoded),
                ),
              );
            }
          } catch (e) {
            debugPrint(
              'Visit load item error: $e',
            );
          }
        }
      }
    } catch (e, stackTrace) {
      debugPrint(
        'Visit storage error: $e',
      );
      debugPrint(
        stackTrace.toString(),
      );

      _visits.clear();
    }

    notifyListeners();
  }
}
