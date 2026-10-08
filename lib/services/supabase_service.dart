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

  int? _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }
}
