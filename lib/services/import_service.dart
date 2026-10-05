import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart' as excel_lib;

import '../models/employee.dart';

typedef ImportProgressCallback = void Function(ImportProgress progress);
typedef SaveEmployeesCallback = Future<int> Function(List<Employee> employees);

class ImportProgress {
  final double progress;
  final String stage;
  final int processed;
  final int total;
  final int imported;
  final int skipped;

  const ImportProgress({
    required this.progress,
    required this.stage,
    this.processed = 0,
    this.total = 0,
    this.imported = 0,
    this.skipped = 0,
  });
}

class EmployeeImportResult {
  final String fileName;
  final int totalRecords;
  final int importedCount;
  final int skippedCount;

  const EmployeeImportResult({
    required this.fileName,
    required this.totalRecords,
    required this.importedCount,
    required this.skippedCount,
  });
}

class ImportService {
  static Future<EmployeeImportResult> importEmployees({
    required String fileName,
    required Uint8List bytes,
    required List<Employee> existingEmployees,
    required SaveEmployeesCallback saveEmployees,
    ImportProgressCallback? onProgress,
  }) async {
    if (bytes.isEmpty) {
      throw Exception('ملف الاستيراد فارغ أو غير قابل للقراءة.');
    }

    final existingIds = existingEmployees
        .map((e) => _normalizeId(e.idNumber))
        .where((e) => e.isNotEmpty)
        .toSet();

    final existingNames = existingEmployees
        .map((e) => _normalizeName(e.name))
        .where((e) => e.isNotEmpty)
        .toSet();

    final employees = <Employee>[];
    int skipped = 0;
    int processed = 0;
    int total = 0;
    bool foundRequiredColumns = false;

    void report(String stage, {double? progress}) {
      onProgress?.call(
        ImportProgress(
          progress: progress ?? 0,
          stage: stage,
          processed: processed,
          total: total,
          imported: employees.length,
          skipped: skipped,
        ),
      );
    }

    void addEmployee(String name, String idNumber, String expiryDate) {
      name = name.trim();
      idNumber = idNumber.trim();
      expiryDate = expiryDate.trim();

      if (name.isEmpty) return;

      final idKey = _normalizeId(idNumber);
      final nameKey = _normalizeName(name);

      final duplicateById =
          idKey.isNotEmpty && existingIds.contains(idKey);
      final duplicateByName =
          idKey.isEmpty &&
          nameKey.isNotEmpty &&
          existingNames.contains(nameKey);

      if (duplicateById || duplicateByName) {
        skipped++;
        return;
      }

      employees.add(
        Employee(
          id: '${DateTime.now().microsecondsSinceEpoch}_${employees.length}',
          name: name,
          idNumber: idNumber,
          expiryDate: expiryDate,
          status: _calculateStatus(expiryDate),
        ),
      );

      if (idKey.isNotEmpty) existingIds.add(idKey);
      if (nameKey.isNotEmpty) existingNames.add(nameKey);
    }

    report('قراءة الملف', progress: 0.08);
    await Future<void>.delayed(Duration.zero);

    final lowerName = fileName.toLowerCase();

    if (lowerName.endsWith('.xlsx')) {
      final workbook = excel_lib.Excel.decodeBytes(bytes);

      for (final sheetName in workbook.tables.keys) {
        final sheet = workbook.tables[sheetName];
        if (sheet == null || sheet.maxRows == 0) continue;

        final headerRow = sheet.rows.first;
        int nameIndex = -1;
        int idIndex = -1;
        int expiryIndex = -1;

        for (int i = 0; i < headerRow.length; i++) {
          final header = _cellValue(headerRow[i]);

          if (nameIndex == -1 && _isNameHeader(header)) {
            nameIndex = i;
          }
          if (idIndex == -1 && _isIdHeader(header)) {
            idIndex = i;
          }
          if (expiryIndex == -1 && _isExpiryHeader(header)) {
            expiryIndex = i;
          }
        }

        if (nameIndex == -1 ||
            idIndex == -1 ||
            expiryIndex == -1) {
          continue;
        }

        foundRequiredColumns = true;
        total += sheet.maxRows - 1;
      }

      report('تحليل البيانات', progress: 0.30);

      int completedRows = 0;

      for (final sheetName in workbook.tables.keys) {
        final sheet = workbook.tables[sheetName];
        if (sheet == null || sheet.maxRows <= 1) continue;

        final headerRow = sheet.rows.first;
        int nameIndex = -1;
        int idIndex = -1;
        int expiryIndex = -1;

        for (int i = 0; i < headerRow.length; i++) {
          final header = _cellValue(headerRow[i]);

          if (nameIndex == -1 && _isNameHeader(header)) {
            nameIndex = i;
          }
          if (idIndex == -1 && _isIdHeader(header)) {
            idIndex = i;
          }
          if (expiryIndex == -1 && _isExpiryHeader(header)) {
            expiryIndex = i;
          }
        }

        if (nameIndex == -1 ||
            idIndex == -1 ||
            expiryIndex == -1) {
          continue;
        }

        for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
          final row = sheet.rows[rowIndex];

          addEmployee(
            _cellValue(
              nameIndex < row.length ? row[nameIndex] : null,
            ),
            _cellValue(
              idIndex < row.length ? row[idIndex] : null,
            ),
            _cellValue(
              expiryIndex < row.length ? row[expiryIndex] : null,
            ),
          );

          completedRows++;
          processed = completedRows;

          if (completedRows % 20 == 0 || completedRows == total) {
            final ratio =
                total == 0 ? 0.45 : completedRows / total;
            report(
              'التحقق من التكرار',
              progress: 0.30 + (ratio.clamp(0.0, 1.0) * 0.35),
            );
            await Future<void>.delayed(Duration.zero);
          }
        }
      }
    } else {
      final csvText = utf8.decode(bytes, allowMalformed: true);
      final lines = csvText
          .split(RegExp(r'\r?\n'))
          .where((line) => line.trim().isNotEmpty)
          .toList();

      if (lines.isNotEmpty) {
        final delimiter =
            lines.first.contains(';') && !lines.first.contains(',')
                ? ';'
                : ',';

        final headers = _parseCsvLine(
          lines.first,
          delimiter: delimiter,
        );

        int nameIndex = -1;
        int idIndex = -1;
        int expiryIndex = -1;

        for (int i = 0; i < headers.length; i++) {
          if (nameIndex == -1 && _isNameHeader(headers[i])) {
            nameIndex = i;
          }
          if (idIndex == -1 && _isIdHeader(headers[i])) {
            idIndex = i;
          }
          if (expiryIndex == -1 &&
              _isExpiryHeader(headers[i])) {
            expiryIndex = i;
          }
        }

        if (nameIndex != -1 &&
            idIndex != -1 &&
            expiryIndex != -1) {
          foundRequiredColumns = true;
          total = lines.length - 1;

          report('تحليل البيانات', progress: 0.30);

          for (int rowIndex = 1; rowIndex < lines.length; rowIndex++) {
            final row = _parseCsvLine(
              lines[rowIndex],
              delimiter: delimiter,
            );

            if (row.isNotEmpty) {
              addEmployee(
                _csvCell(row, nameIndex),
                _csvCell(row, idIndex),
                _csvCell(row, expiryIndex),
              );
            }

            processed++;

            if (processed % 20 == 0 || processed == total) {
              final ratio =
                  total == 0 ? 0.45 : processed / total;
              report(
                'التحقق من التكرار',
                progress: 0.30 + (ratio.clamp(0.0, 1.0) * 0.35),
              );
              await Future<void>.delayed(Duration.zero);
            }
          }
        }
      }
    }

    if (!foundRequiredColumns) {
      throw Exception(
        'لم يتم العثور على الأعمدة المطلوبة: اسم الموظف، رقم الهوية/الإقامة، تاريخ انتهاء الهوية.',
      );
    }

    report('إضافة الموظفين', progress: 0.78);
    await Future<void>.delayed(Duration.zero);

    final importedCount = employees.isEmpty
        ? 0
        : await saveEmployees(employees);

    report('اكتمل الاستيراد', progress: 1.0);

    return EmployeeImportResult(
      fileName: fileName,
      totalRecords: total,
      importedCount: importedCount,
      skippedCount: skipped,
    );
  }

  static String _normalizeHeader(String value) {
    return value
        .replaceAll('\ufeff', '')
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s_\-/:\\]+'), '')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي');
  }

  static String _normalizeId(String value) {
    var result = value.trim();
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    const western = '0123456789';

    for (int i = 0; i < arabic.length; i++) {
      result = result.replaceAll(arabic[i], western[i]);
    }

    return result
        .replaceAll(RegExp(r'\.0+$'), '')
        .replaceAll(RegExp(r'[\s\-_/+,]+'), '');
  }

  static String _normalizeName(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه');
  }

  static bool _isNameHeader(String value) {
    return const [
      'الاسم',
      'الاسمالكامل',
      'اسمالكامل',
      'اسمالموظف',
      'الاسمبالكامل',
      'الاسمرباعي',
      'الاسمالرباعي',
      'name',
      'fullname',
      'employeename',
    ].contains(_normalizeHeader(value));
  }

  static bool _isIdHeader(String value) {
    return const [
      'رقمالهويه',
      'رقمالهوية',
      'رقمالهويهالاقامه',
      'رقمالهويةالاقامة',
      'رقمالاقامه',
      'رقمالاقامة',
      'الهوية',
      'الهويه',
      'الاقامه',
      'الاقامة',
      'id',
      'idnumber',
      'iqama',
      'iqamanumber',
      'residencenumber',
    ].contains(_normalizeHeader(value));
  }

  static bool _isExpiryHeader(String value) {
    return const [
      'تاريخانتهاءالهويه',
      'تاريخانتهاءالهوية',
      'تاريخانتهاءالاقامه',
      'تاريخانتهاءالاقامة',
      'انتهاءالهويه',
      'انتهاءالهوية',
      'انتهاءالاقامه',
      'انتهاءالاقامة',
      'expirydate',
      'identityexpiry',
      'residenceexpiry',
    ].contains(_normalizeHeader(value));
  }

  static String _cellValue(dynamic cell) {
    if (cell == null || cell.value == null) return '';

    final value = cell.value;

    if (value is excel_lib.TextCellValue) {
      return value.value.text?.trim() ?? '';
    }

    if (value is excel_lib.IntCellValue) {
      return value.value.toString();
    }

    if (value is excel_lib.DoubleCellValue) {
      final number = value.value;
      return number == number.truncateToDouble()
          ? number.toInt().toString()
          : number.toString();
    }

    if (value is excel_lib.DateCellValue) {
      return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
    }

    return value.toString().trim();
  }

  static String _csvCell(List<String> row, int index) {
    return index >= 0 && index < row.length
        ? row[index].trim()
        : '';
  }

  static List<String> _parseCsvLine(
    String line, {
    String delimiter = ',',
  }) {
    final result = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        if (inQuotes &&
            i + 1 < line.length &&
            line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
        continue;
      }

      if (char == delimiter && !inQuotes) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }

    result.add(buffer.toString());
    return result;
  }

  static String _calculateStatus(String expiryDate) {
    final parsed = _parseDate(expiryDate);

    if (parsed == null) return 'سارية';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(parsed.year, parsed.month, parsed.day);
    final days = date.difference(today).inDays;

    if (days < 0) return 'منتهية';
    if (days <= 30) return 'تحتاج متابعة';
    return 'سارية';
  }

  static DateTime? _parseDate(String value) {
    final normalized = value.trim().replaceAll('/', '-');
    if (normalized.isEmpty) return null;

    final direct = DateTime.tryParse(normalized);
    if (direct != null) return direct;

    final parts = normalized.split('-');
    if (parts.length != 3) return null;

    final a = int.tryParse(parts[0]);
    final b = int.tryParse(parts[1]);
    final c = int.tryParse(parts[2]);

    if (a == null || b == null || c == null) return null;

    if (a > 31) {
      return DateTime.tryParse(
        '${a.toString().padLeft(4, '0')}-'
        '${b.toString().padLeft(2, '0')}-'
        '${c.toString().padLeft(2, '0')}',
      );
    }

    return DateTime.tryParse(
      '${c.toString().padLeft(4, '0')}-'
      '${b.toString().padLeft(2, '0')}-'
      '${a.toString().padLeft(2, '0')}',
    );
  }
}
