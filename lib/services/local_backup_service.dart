import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalBackupService {
  LocalBackupService._();

  static final LocalBackupService instance = LocalBackupService._();

  static const String _lastBackupKey = 'last_local_backup_at';

  Future<Uint8List> createBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final values = <String, dynamic>{};

    for (final key in prefs.getKeys()) {
      // لا ننسخ مفاتيح Flutter الداخلية إن وجدت.
      if (key.startsWith('flutter.')) continue;

      final value = prefs.get(key);

      if (value is String ||
          value is bool ||
          value is int ||
          value is double ||
          value is List<String>) {
        values[key] = value;
      }
    }

    final payload = <String, dynamic>{
      'format': 'employee_id_app_local_backup',
      'version': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'data': values,
    };

    return Uint8List.fromList(
      utf8.encode(
        const JsonEncoder.withIndent('  ').convert(payload),
      ),
    );
  }

  Future<bool> saveBackupFile() async {
    final bytes = await createBackup();

    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'حفظ النسخة الاحتياطية',
      fileName:
          'employee_id_backup_${_fileDate(DateTime.now())}.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: bytes,
    );

    if (path == null || path.isEmpty) return false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _lastBackupKey,
      DateTime.now().toIso8601String(),
    );

    return true;
  }

  Future<bool> restoreBackupFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return false;

    final file = result.files.first;
    final bytes = file.bytes;

    if (bytes == null || bytes.isEmpty) {
      throw Exception('تعذر قراءة ملف النسخة الاحتياطية.');
    }

    final decoded = jsonDecode(utf8.decode(bytes));

    if (decoded is! Map ||
        decoded['format'] != 'employee_id_app_local_backup') {
      throw Exception('ملف النسخة الاحتياطية غير صالح.');
    }

    final data = decoded['data'];
    if (data is! Map) {
      throw Exception('بيانات النسخة الاحتياطية غير مكتملة.');
    }

    final prefs = await SharedPreferences.getInstance();

    for (final entry in data.entries) {
      final key = entry.key.toString();
      final value = entry.value;

      if (value is String) {
        await prefs.setString(key, value);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is List) {
        await prefs.setStringList(
          key,
          value.map((item) => item.toString()).toList(),
        );
      }
    }

    return true;
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
