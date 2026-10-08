import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionInfo {
  final bool active;
  final String activationKeyId;
  final String maskedKey;
  final String plan;
  final DateTime activatedAt;
  final DateTime expiresAt;
  final int remainingDays;

  const SubscriptionInfo({
    required this.active,
    required this.activationKeyId,
    required this.maskedKey,
    required this.plan,
    required this.activatedAt,
    required this.expiresAt,
    required this.remainingDays,
  });
}

class TrialInfo {
  final DateTime trialStart;
  final DateTime trialEnd;
  final bool active;
  final int remainingDays;
  final int remainingSeconds;

  const TrialInfo({
    required this.trialStart,
    required this.trialEnd,
    required this.active,
    required this.remainingDays,
    required this.remainingSeconds,
  });
}

class ActivationResult {
  final bool success;
  final String message;
  final String? activationKeyId;
  final String? plan;
  final int? durationDays;
  final DateTime? expiresAt;

  const ActivationResult({
    required this.success,
    required this.message,
    this.activationKeyId,
    this.plan,
    this.durationDays,
    this.expiresAt,
  });
}

class SupabaseService {
  SupabaseService._();

  static final SupabaseService instance = SupabaseService._();

  static const String _activationKeyIdStorage = 'active_activation_key_id';
  static const String _activationActivatedAtStorage = 'active_activation_activated_at';
  static const String _activationDurationStorage = 'active_activation_duration_days';
  static const String _activationMaskedKeyStorage = 'active_activation_key_masked';

  SupabaseClient get client => Supabase.instance.client;

  User? get currentUser => client.auth.currentUser;
  bool get isSignedIn => client.auth.currentSession != null;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    // The values are intentionally read lazily; this method exists so main.dart
    // can initialize the service before the app starts.
    await prefs.reload();
  }

  Future<void> ensureSignedIn() async {
    if (client.auth.currentSession != null) return;
    await client.auth.signInAnonymously();
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Gets a stable device identifier and hashes it before sending it to Supabase.
  /// Android uses ANDROID_ID, which normally survives app reinstall on the same
  /// device. iOS uses identifierForVendor.
  Future<String> _trialDeviceHash() async {
    final plugin = DeviceInfoPlugin();
    String raw;

    if (kIsWeb) {
      final info = await plugin.webBrowserInfo;
      raw = [
        'web',
        info.browserName.name,
        info.userAgent ?? '',
        info.platform ?? '',
      ].join('|');
    } else {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final info = await plugin.androidInfo;
          raw = 'android|${info.id}|${info.model}|${info.brand}';
          break;
        case TargetPlatform.iOS:
          final info = await plugin.iosInfo;
          raw = 'ios|${info.identifierForVendor ?? ''}|${info.model}';
          break;
        case TargetPlatform.windows:
          final info = await plugin.windowsInfo;
          raw = 'windows|${info.deviceId}|${info.computerName}';
          break;
        case TargetPlatform.macOS:
          final info = await plugin.macOsInfo;
          raw = 'macos|${info.systemGUID ?? ''}|${info.model}';
          break;
        case TargetPlatform.linux:
          final info = await plugin.linuxInfo;
          raw = 'linux|${info.machineId ?? ''}|${info.name}';
          break;
        case TargetPlatform.fuchsia:
          raw = 'fuchsia';
          break;
      }
    }

    return sha256.convert(utf8.encode(raw)).toString();
  }

  Future<TrialInfo?> get trialInfo async {
    try {
      await ensureSignedIn();
      final deviceHash = await _trialDeviceHash();

      final response = await client.rpc(
        'start_or_get_trial',
        params: {'p_device_id_hash': deviceHash},
      );

      final data = Map<String, dynamic>.from(response as Map);
      if (data['success'] != true) {
        return null;
      }

      final start = DateTime.tryParse(
        data['trial_start']?.toString() ?? '',
      );
      final end = DateTime.tryParse(
        data['trial_end']?.toString() ?? '',
      );

      if (start == null || end == null) return null;

      final seconds = int.tryParse(
            data['remaining_seconds']?.toString() ?? '',
          ) ??
          end.difference(DateTime.now()).inSeconds;

      final safeSeconds = seconds < 0 ? 0 : seconds;
      final active = safeSeconds > 0 &&
          (data['status']?.toString() ?? '') == 'active';

      final days = active
          ? ((safeSeconds + 86399) ~/ 86400).clamp(0, 7)
          : 0;

      return TrialInfo(
        trialStart: start.toLocal(),
        trialEnd: end.toLocal(),
        active: active,
        remainingDays: days,
        remainingSeconds: safeSeconds,
      );
    } on PostgrestException catch (e) {
      debugPrint('TRIAL RPC ERROR => ${e.message}');
      return null;
    } catch (e) {
      debugPrint('TRIAL ERROR => $e');
      return null;
    }
  }

  Future<void> saveActivationKey({
    required String activationKeyId,
    required DateTime activatedAt,
    required int durationDays,
    String? maskedKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activationKeyIdStorage, activationKeyId);
    await prefs.setString(
      _activationActivatedAtStorage,
      activatedAt.toIso8601String(),
    );
    await prefs.setInt(_activationDurationStorage, durationDays);
    if (maskedKey != null && maskedKey.isNotEmpty) {
      await prefs.setString(_activationMaskedKeyStorage, maskedKey);
    }
  }

  Future<void> clearSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activationKeyIdStorage);
    await prefs.remove(_activationActivatedAtStorage);
    await prefs.remove(_activationDurationStorage);
    await prefs.remove(_activationMaskedKeyStorage);
    await prefs.remove('active_activation_plan');
  }

  /// Releases the currently active subscription key on Supabase.
  ///
  /// This must be called before clearSubscription(), because clearSubscription()
  /// only removes the local subscription cache. The RPC changes the server-side
  /// activation_keys row back to an available state.
  Future<void> deactivateSubscription() async {
    try {
      final response = await client.rpc('deactivate_subscription');

      final data = Map<String, dynamic>.from(response as Map);
      final success = data['success'] == true;
      final message = (data['message'] ??
              (success
                  ? 'تم إلغاء تفعيل الاشتراك بنجاح'
                  : 'تعذر إلغاء تفعيل الاشتراك'))
          .toString();

      if (!success) {
        throw Exception(message);
      }
    } on PostgrestException catch (e) {
      throw Exception(
        e.message.isNotEmpty
            ? e.message
            : 'تعذر الاتصال بخدمة الاشتراك.',
      );
    }
  }

  Future<SubscriptionInfo?> get subscriptionInfo async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_activationKeyIdStorage);
    final activatedAtRaw = prefs.getString(_activationActivatedAtStorage);
    final durationDays = prefs.getInt(_activationDurationStorage);

    if (id == null || id.isEmpty || activatedAtRaw == null || durationDays == null) {
      return null;
    }

    final activatedAt = DateTime.tryParse(activatedAtRaw);
    if (activatedAt == null) return null;

    final expiresAt = activatedAt.add(Duration(days: durationDays));
    final now = DateTime.now();
    final remaining = expiresAt.difference(now).inDays;
    final active = now.isBefore(expiresAt);
    final masked = prefs.getString(_activationMaskedKeyStorage) ?? 'محفوظ بشكل آمن';

    return SubscriptionInfo(
      active: active,
      activationKeyId: id,
      maskedKey: masked,
      plan: prefs.getString('active_activation_plan') ?? 'premium',
      activatedAt: activatedAt,
      expiresAt: expiresAt,
      remainingDays: active ? (remaining < 0 ? 0 : remaining) : 0,
    );
  }

  Future<bool> get hasActiveSubscription async {
    final info = await subscriptionInfo;
    return info?.active == true;
  }

  Future<ActivationResult> activateSubscription(String inputKey) async {
    final key = inputKey.trim();
    if (key.isEmpty) {
      return const ActivationResult(
        success: false,
        message: 'أدخل مفتاح الاشتراك أولاً',
      );
    }

    try {
      final response = await client.rpc(
        'activate_subscription',
        params: {'input_key': key},
      );

      final data = Map<String, dynamic>.from(response as Map);
      final success = data['success'] == true;
      final message = (data['message'] ??
              (success ? 'تم تفعيل الاشتراك بنجاح' : 'تعذر تفعيل مفتاح الاشتراك'))
          .toString();

      if (!success) {
        return ActivationResult(success: false, message: message);
      }

      final id = data['activation_key_id']?.toString();
      final plan = data['plan']?.toString();
      final duration = _toInt(data['duration_days']);

      if (id == null || id.isEmpty || duration == null || duration <= 0) {
        return const ActivationResult(
          success: false,
          message: 'تم التحقق من المفتاح لكن بيانات الاشتراك غير مكتملة.',
        );
      }

      final activatedAt = DateTime.tryParse(
            (data['activated_at'] ?? '').toString(),
          ) ??
          DateTime.now();
      final expiresAt = activatedAt.add(Duration(days: duration));

      final maskedKey = _maskKey(key);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_activation_plan', plan ?? 'premium');

      await saveActivationKey(
        activationKeyId: id,
        activatedAt: activatedAt,
        durationDays: duration,
        maskedKey: maskedKey,
      );

      return ActivationResult(
        success: true,
        message: message,
        activationKeyId: id,
        plan: plan,
        durationDays: duration,
        expiresAt: expiresAt,
      );
    } on PostgrestException catch (e) {
      return ActivationResult(
        success: false,
        message: e.message.isNotEmpty ? e.message : 'تعذر الاتصال بخدمة الاشتراك.',
      );
    } catch (_) {
      return const ActivationResult(
        success: false,
        message: 'حدث خطأ أثناء التحقق من مفتاح الاشتراك.',
      );
    }
  }

  String _maskKey(String key) {
    final cleaned = key.trim();
    if (cleaned.length <= 4) return '••••';
    return '••••-••••-••••-${cleaned.substring(cleaned.length - 4).toUpperCase()}';
  }


  // ============================
  // تسجيل دخول المدير
  // ============================

  Future<bool> adminSignIn({
    required String email,
    required String password,
  }) async {
    try {
      await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      return await isAdmin;
    } catch (e) {
      debugPrint('ADMIN LOGIN ERROR => $e');
      return false;
    }
  }

  Future<void> adminSignOut() async {
    await client.auth.signOut();
  }


  // ============================
  // إدارة صلاحيات المدير
  // ============================

  Future<String?> get currentUserRole async {
    try {
      final user = client.auth.currentUser;
      if (user == null || user.email == null) return null;

      final result = await client
          .from('app_users')
          .select('role')
          .eq('email', user.email!)
          .maybeSingle();

      return result?['role']?.toString();
    } catch (e) {
      debugPrint('ROLE ERROR => $e');
      return null;
    }
  }

  Future<bool> get isAdmin async {
    final role = await currentUserRole;
    return role == 'admin';
  }

  Future<bool> canManageLicenses() async {
    return await isAdmin;
  }


  // ============================
  // إنشاء مفتاح اشتراك من لوحة الإدارة
  // ============================

  Future<String> createLicenseKey({
    required String customerName,
    required String plan,
    required int days,
  }) async {
    try {
      final rawKey =
          'EMP-${DateTime.now().millisecondsSinceEpoch}';

      final hash = sha256
          .convert(utf8.encode(rawKey))
          .toString();

      await client.from('activation_keys').insert({
        'customer_name': customerName,
        'key_hash': hash,
        'plan': plan,
        'duration_days': days,
        'status': 'available',
      });

      return rawKey;
    } catch (e) {
      debugPrint('CREATE LICENSE ERROR => $e');
      rethrow;
    }
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }
}
