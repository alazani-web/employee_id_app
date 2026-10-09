import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Creates and restores a portable JSON backup of the app's local preferences.
/// Authentication/session tokens and backup bookkeeping are deliberately excluded.
class LocalBackupService {
  LocalBackupService._();

  static final LocalBackupService instance = LocalBackupService._();

  static const String _lastBackupKey = 'last_local_backup_at';
  static const String _formatName = 'employee_id_app_local_backup';
  static const int _currentVersion = 1;

  bool _isExcludedKey(String key) {
    final lower = key.toLowerCase();
    if (key.startsWith('flutter.')) return true;
    if (key == _lastBackupKey) return true;

    // Do not export or overwrite Supabase authentication/session material.
    if (lower.startsWith('sb-') ||
        lower.contains('supabase.auth') ||
        lower.contains('auth-token') ||
        lower.contains('refresh-token')) {
      return true;
    }
    return false;
  }

  bool _isSupportedValue(Object? value) =>
      value is String ||
      value is bool ||
      value is int ||
      value is double ||
      (value is List<String> && value.every((item) => item is String));

  Future<Uint8List> createBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final values = <String, dynamic>{};

    for (final key in prefs.getKeys()) {
      if (_isExcludedKey(key)) continue;
      final value = prefs.get(key);
      if (_isSupportedValue(value)) values[key] = value;
    }

    final payload = <String, dynamic>{
      'format': _formatName,
      'version': _currentVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'data': values,
    };

    return Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(payload)),
    );
  }

  Future<bool> saveBackupFile() async {
    final bytes = await createBackup();
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'حفظ النسخة الاحتياطية',
      fileName: 'employee_id_backup_${_fileDate(DateTime.now())}.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: bytes,
    );

    if (path == null || path.isEmpty) return false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastBackupKey, DateTime.now().toIso8601String());
    return true;
  }

  Future<bool> restoreBackupFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return false;
    final bytes = result.files.first.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw Exception('تعذر قراءة ملف النسخة الاحتياطية.');
    }
    return restoreBackupBytes(bytes);
  }

  Future<bool> restoreBackupBytes(Uint8List bytes) async {
    if (bytes.isEmpty) throw Exception('ملف النسخة الاحتياطية فارغ.');
    dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      throw Exception('ملف النسخة تالف أو ليس بتنسيق JSON صالح.');
    }

    if (decoded is! Map || decoded['format'] != _formatName) {
      throw Exception('هذا الملف ليس نسخة احتياطية صالحة للتطبيق.');
    }
    if (decoded['version'] != _currentVersion) {
      throw Exception('إصدار النسخة الاحتياطية غير مدعوم في هذا الإصدار من التطبيق.');
    }

    final rawData = decoded['data'];
    if (rawData is! Map || rawData.keys.any((key) => key is! String)) {
      throw Exception('بيانات النسخة الاحتياطية غير مكتملة أو غير صالحة.');
    }

    // Validate the entire payload before changing any current data.
    final data = <String, Object?>{};
    for (final entry in rawData.entries) {
      final key = entry.key as String;
      final value = entry.value;
      if (key.trim().isEmpty || _isExcludedKey(key)) {
        throw Exception('تحتوي النسخة على مفتاح بيانات غير مسموح به.');
      }
      final validList = value is List && value.every((item) => item is String);
      if (!(value is String || value is bool || value is int || value is double || validList)) {
        throw Exception('تحتوي النسخة على نوع بيانات غير مدعوم للمفتاح: $key');
      }
      data[key] = value;
    }

    final prefs = await SharedPreferences.getInstance();
    final oldValues = <String, Object?>{};
    for (final key in prefs.getKeys()) {
      if (_isExcludedKey(key)) continue;
      oldValues[key] = prefs.get(key);
    }

    try {
      // Replace restorable app data, while retaining protected/system values.
      for (final key in oldValues.keys) {
        if (!data.containsKey(key)) await prefs.remove(key);
      }
      for (final entry in data.entries) {
        await _writeValue(prefs, entry.key, entry.value);
      }
    } catch (error) {
      // Best-effort rollback if a write fails midway through restoration.
      try {
        for (final key in prefs.getKeys()) {
          if (!_isExcludedKey(key) && !oldValues.containsKey(key)) {
            await prefs.remove(key);
          }
        }
        for (final entry in oldValues.entries) {
          await _writeValue(prefs, entry.key, entry.value);
        }
      } catch (_) {
        throw Exception('فشلت الاستعادة ولم يكتمل التراجع عن التغييرات. يُرجى عدم إغلاق التطبيق ومحاولة الاستعادة مرة أخرى.');
      }
      throw Exception('تعذرت استعادة النسخة؛ تمت إعادة البيانات المحلية السابقة. التفاصيل: $error');
    }

    // Record restore time only after all restored values have been written.
    await prefs.setString(_lastBackupKey, DateTime.now().toIso8601String());
    return true;
  }

  Future<void> _writeValue(
    SharedPreferences prefs,
    String key,
    Object? value,
  ) async {
    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is List && value.every((item) => item is String)) {
      await prefs.setStringList(key, value.cast<String>());
    } else {
      throw Exception('نوع بيانات غير مدعوم للمفتاح: $key');
    }
  }

  Future<String?> lastBackupDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastBackupKey);
  }

  String _fileDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}_'
        '${date.hour.toString().padLeft(2, '0')}'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}
