import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'local_backup_service.dart';

/// Private per-account cloud backup stored in Supabase Storage.
class CloudBackupService {
  CloudBackupService._();
  static final CloudBackupService instance = CloudBackupService._();

  static const String bucketName = 'user-backups';
  SupabaseClient get _client => Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  bool get hasAccount => currentUser != null && currentUser!.isAnonymous != true;

  Future<void> createAccount({required String email, required String password}) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw Exception('أدخل بريدًا إلكترونيًا صحيحًا.');
    }
    if (password.length < 8) throw Exception('كلمة المرور يجب أن تكون 8 أحرف على الأقل.');

    final user = _client.auth.currentUser;
    if (user != null && user.isAnonymous) {
      // Link the current anonymous account to email/password to preserve its UID.
      await _client.auth.updateUser(UserAttributes(email: cleanEmail, password: password));
      return;
    }

    final response = await _client.auth.signUp(email: cleanEmail, password: password);
    if (response.user == null) throw Exception('لم يتم إنشاء الحساب. تحقق من إعدادات البريد في Supabase.');
    if (response.session == null) {
      throw Exception('تم إنشاء الحساب، لكن يلزم تأكيد البريد الإلكتروني ثم تسجيل الدخول.');
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    if (response.user == null || response.user!.isAnonymous) {
      throw Exception('تعذر تسجيل الدخول بحساب بريد إلكتروني.');
    }
  }

  Future<void> uploadBackup() async {
    final user = currentUser;
    if (user == null || user.isAnonymous) {
      throw Exception('سجّل الدخول بحسابك أولًا لاستخدام النسخ السحابي.');
    }
    final bytes = await LocalBackupService.instance.createBackup();
    final path = '${user.id}/backup.json';
    await _client.storage.from(bucketName).uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(
        upsert: true,
        contentType: 'application/json',
        cacheControl: '0',
      ),
    );
  }

  Future<void> restoreBackup() async {
    final user = currentUser;
    if (user == null || user.isAnonymous) {
      throw Exception('سجّل الدخول بالحساب المرتبط بالنسخة السحابية أولًا.');
    }
    final path = '${user.id}/backup.json';
    final Uint8List bytes = await _client.storage.from(bucketName).download(path);
    await LocalBackupService.instance.restoreBackupBytes(bytes);
  }
}
