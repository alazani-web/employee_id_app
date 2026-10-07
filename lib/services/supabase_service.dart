import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();

  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;

  /// هل يوجد اتصال بحساب Supabase؟
  bool get isSignedIn => client.auth.currentSession != null;

  /// المستخدم الحالي
  User? get currentUser => client.auth.currentUser;

  /// تسجيل خروج
  Future<void> signOut() async {
    await client.auth.signOut();
  }
}