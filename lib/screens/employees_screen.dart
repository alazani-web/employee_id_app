import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel_lib;
import '../providers/employee_provider.dart';
import '../models/employee.dart';

enum _AppNotificationType {
  success,
  warning,
  error,
}

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  int selectedFilter = 0;
  final TextEditingController searchController = TextEditingController();

  final List<String> filters = [
    "الكل",
    "نشط",
    "تنتهي قريباً",
    "منتهي",
  ];

  Map<String, dynamic> _getCalculatedStatus(String expiryDateStr) {
    if (expiryDateStr.isEmpty) {
      return {'status': 'سارية', 'daysLeft': null};
    }

    try {
      final expiryDate = DateTime.parse(expiryDateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final expiryDay = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);

      final difference = expiryDay.difference(today).inDays;

      if (difference < 0) {
        return {'status': 'منتهية', 'daysLeft': difference};
      } else if (difference <= 30) {
        return {'status': 'تحتاج متابعة', 'daysLeft': difference};
      } else {
        return {'status': 'سارية', 'daysLeft': difference};
      }
    } catch (_) {
      return {'status': 'سارية', 'daysLeft': null};
    }
  }

  // دالة حساب تاريخ التجديد حسب نظام الجوازات السعودية (إضافة شهور مع الخصم يوماً واحداً)
  DateTime calculateSaudiRenewalDate(DateTime startDate, int monthsToAdd) {
    DateTime calculatedDate = DateTime(
      startDate.year + (monthsToAdd ~/ 12),
      startDate.month + (monthsToAdd % 12),
      startDate.day,
    );

    if (calculatedDate.month > (startDate.month + (monthsToAdd % 12)) % 12) {
      calculatedDate = DateTime(calculatedDate.year, calculatedDate.month, 0);
    }

    return calculatedDate.subtract(const Duration(days: 1));
  }

  Future<String?> _showCustomDatePicker(BuildContext context, {DateTime? initialDate}) async {
    DateTime selectedDate = initialDate ?? DateTime.now();
    DateTime displayedMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    bool isYearMonthPickerOpen = false;

    return await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (context, setPickerState) {
            final daysInMonth = DateUtils.getDaysInMonth(displayedMonth.year, displayedMonth.month);
            final firstDayOffset = DateTime(displayedMonth.year, displayedMonth.month, 1).weekday % 7;

            final monthNames = [
              "يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو",
              "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر"
            ];

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Dialog(
                insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          setPickerState(() {
                            isYearMonthPickerOpen = !isYearMonthPickerOpen;
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          color: const Color(0xff1565C0),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "تاريخ الاختيار (انقر لتغيير السنة والشهر)",
                                    style: TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                  Icon(Icons.unfold_more, color: Colors.white.withValues(alpha: 0.8), size: 16),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${monthNames[displayedMonth.month - 1]}، ${displayedMonth.year}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isYearMonthPickerOpen) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xffF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("اختر السنة:", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: displayedMonth.year,
                                    isExpanded: true,
                                    items: List.generate(20, (index) => 2020 + index).map((year) {
                                      return DropdownMenuItem<int>(
                                        value: year,
                                        child: Text("$year", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setPickerState(() {
                                          displayedMonth = DateTime(val, displayedMonth.month, 1);
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text("اختر الشهر:", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: 12,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  childAspectRatio: 2.2,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                ),
                                itemBuilder: (context, index) {
                                  final isSelected = displayedMonth.month == index + 1;
                                  return InkWell(
                                    onTap: () {
                                      setPickerState(() {
                                        displayedMonth = DateTime(displayedMonth.year, index + 1, 1);
                                        isYearMonthPickerOpen = false;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isSelected ? const Color(0xff1565C0) : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: isSelected ? const Color(0xff1565C0) : Colors.grey.shade200),
                                      ),
                                      child: Text(
                                        monthNames[index],
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                decoration: const BoxDecoration(color: Color(0xffF8FAFC), shape: BoxShape.circle),
                                child: IconButton(
                                  icon: const Icon(Icons.chevron_right, color: Colors.black87, size: 20),
                                  onPressed: () {
                                    setPickerState(() {
                                      displayedMonth = DateTime(displayedMonth.year, displayedMonth.month - 1, 1);
                                    });
                                  },
                                ),
                              ),
                              Text(
                                "${monthNames[displayedMonth.month - 1]} ${displayedMonth.year}",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Container(
                                decoration: const BoxDecoration(color: Color(0xffF8FAFC), shape: BoxShape.circle),
                                child: IconButton(
                                  icon: const Icon(Icons.chevron_left, color: Colors.black87, size: 20),
                                  onPressed: () {
                                    setPickerState(() {
                                      displayedMonth = DateTime(displayedMonth.year, displayedMonth.month + 1, 1);
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: const [
                              _DayLabel("ح"),
                              _DayLabel("ن"),
                              _DayLabel("ث"),
                              _DayLabel("ر"),
                              _DayLabel("خ"),
                              _DayLabel("ج"),
                              _DayLabel("س"),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: daysInMonth + firstDayOffset,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              mainAxisSpacing: 4,
                              crossAxisSpacing: 4,
                            ),
                            itemBuilder: (context, index) {
                              if (index < firstDayOffset) {
                                return const SizedBox.shrink();
                              }
                              final dayNumber = index - firstDayOffset + 1;
                              final isSelected = selectedDate.year == displayedMonth.year &&
                                  selectedDate.month == displayedMonth.month &&
                                  selectedDate.day == dayNumber;

                              return InkWell(
                                onTap: () {
                                  final picked = DateTime(displayedMonth.year, displayedMonth.month, dayNumber);
                                  final formatted = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                                  Navigator.pop(ctx, formatted);
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xffEBF3FE) : Colors.transparent,
                                    border: isSelected ? Border.all(color: const Color(0xff1565C0), width: 1.5) : null,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    "$dayNumber",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? const Color(0xff1565C0) : Colors.black87,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xffF1F5F9),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () => Navigator.pop(ctx, null),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.close, size: 16, color: Colors.black87),
                                SizedBox(width: 6),
                                Text("إلغاء", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _downloadExcelTemplate(BuildContext context) async {
    try {
      var excel = excel_lib.Excel.createExcel();
      excel_lib.Sheet sheetObject = excel['الموظفين'];
      excel.setDefaultSheet('الموظفين');

      sheetObject.appendRow([
        excel_lib.TextCellValue('الاسم الكامل'),
        excel_lib.TextCellValue('رقم الهوية / رقم الإقامة'),
        excel_lib.TextCellValue('تاريخ انتهاء الهوية'),
      ]);

      sheetObject.appendRow([
        excel_lib.TextCellValue('محمد علي أحمد'),
        excel_lib.TextCellValue('1023456789'),
        excel_lib.TextCellValue('2026-11-18'),
      ]);

      List<int>? fileBytes = excel.save();
      if (fileBytes == null) return;

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'اختر مكان حفظ قالب استيراد الموظفين',
        fileName: 'قالب_استيراد_الموظفين.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        bytes: Uint8List.fromList(fileBytes),
      );

      if (outputFile != null) {
        if (context.mounted) {
          _showAppNotification(
            context,
            title: 'تم تجهيز قالب الموظفين',
            message: 'تم حفظ قالب استيراد الموظفين بنجاح.',
            type: _AppNotificationType.success,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء تحميل القالب: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // دعم استيراد الملفات على الويب والمنصات الأخرى باستخدام withData: true و file.bytes
  // قراءة سطر CSV مع دعم القيم المحاطة بعلامات اقتباس والفواصل داخل النص.
  List<String> _parseCsvLine(String line) {
    final columns = <String>[];
    final buffer = StringBuffer();
    bool insideQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        if (insideQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          insideQuotes = !insideQuotes;
        }
      } else if (char == ',' && !insideQuotes) {
        columns.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }

    columns.add(buffer.toString());

    return columns;
  }

  Future<void> _pickAndImportExcelFile(
    BuildContext context, {
    BuildContext? dialogContext,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final pickedFile = result.files.first;
      final bytes = pickedFile.bytes;

      if (bytes == null || bytes.isEmpty) {
        if (context.mounted) {
          _showAppNotification(
            context,
            title: 'تعذر قراءة الملف',
            message: 'تأكد من اختيار ملف Excel أو CSV صالح.',
            type: _AppNotificationType.error,
          );
        }
        return;
      }

      // إغلاق نافذة الاستيراد نفسها فور اختيار الملف.
      // لا نغلق صفحة الموظفين.
      final importDialogContext = dialogContext;
      if (importDialogContext != null &&
          importDialogContext.mounted) {
        Navigator.of(importDialogContext).pop();
      }

      await Future<void>.delayed(Duration.zero);

      final provider = Provider.of<EmployeeProvider>(
        context,
        listen: false,
      );

      final fileName = pickedFile.name.toLowerCase();
      final List<Employee> importedEmployees = [];

      if (fileName.endsWith('.xlsx')) {
        final workbook = excel_lib.Excel.decodeBytes(bytes);

        for (final sheetName in workbook.tables.keys) {
          final sheet = workbook.tables[sheetName];
          if (sheet == null) continue;

          for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
            final row = sheet.rows[rowIndex];
            if (row.isEmpty) continue;

            String getCellValue(int index) {
              if (index >= row.length) return '';

              final cell = row[index];
              if (cell == null || cell.value == null) return '';

              final value = cell.value;

              if (value is excel_lib.TextCellValue) {
                return (value.value.text ?? '').trim();
              }

              if (value is excel_lib.IntCellValue) {
                return value.value.toString().trim();
              }

              if (value is excel_lib.DoubleCellValue) {
                final number = value.value;
                if (number == number.roundToDouble()) {
                  return number.toInt().toString();
                }
                return number.toString().trim();
              }

              if (value is excel_lib.DateCellValue) {
                return '${value.year}-'
                    '${value.month.toString().padLeft(2, '0')}-'
                    '${value.day.toString().padLeft(2, '0')}';
              }

              return value.toString().trim();
            }

            final name = getCellValue(0);
            final idNumber = getCellValue(1);
            var expiryDate = getCellValue(2);

            if (name.isEmpty) continue;

            if (expiryDate.isEmpty) {
              expiryDate = '2026-12-31';
            }

            importedEmployees.add(
              Employee(
                id: '${DateTime.now().microsecondsSinceEpoch}_$rowIndex',
                name: name,
                idNumber: idNumber,
                expiryDate: expiryDate,
                status: 'سارية',
              ),
            );
          }
        }
      } else if (fileName.endsWith('.csv')) {
        final csvText = utf8.decode(
          bytes,
          allowMalformed: true,
        );

        final lines = csvText
            .split(RegExp(r'\r?\n'))
            .where((line) => line.trim().isNotEmpty)
            .toList();

        for (int rowIndex = 1; rowIndex < lines.length; rowIndex++) {
          final columns = _parseCsvLine(lines[rowIndex]);
          if (columns.isEmpty) continue;

          final name = columns.isNotEmpty
              ? columns[0].trim()
              : '';

          final idNumber = columns.length > 1
              ? columns[1].trim()
              : '';

          var expiryDate = columns.length > 2
              ? columns[2].trim()
              : '';

          if (name.isEmpty) continue;

          if (expiryDate.isEmpty) {
            expiryDate = '2026-12-31';
          }

          importedEmployees.add(
            Employee(
              id: '${DateTime.now().microsecondsSinceEpoch}_$rowIndex',
              name: name,
              idNumber: idNumber,
              expiryDate: expiryDate,
              status: 'سارية',
            ),
          );
        }
      } else {
        if (context.mounted) {
          _showAppNotification(
            context,
            title: 'صيغة الملف غير مدعومة',
            message: 'استخدم ملف Excel بصيغة XLSX أو ملف CSV.',
            type: _AppNotificationType.error,
          );
        }
        return;
      }

      if (importedEmployees.isEmpty) {
        if (context.mounted) {
          _showAppNotification(
            context,
            title: 'لم يتم استيراد أي موظف',
            message: 'تأكد من أن الصف الأول عناوين وأن بيانات الموظفين موجودة في الملف.',
            type: _AppNotificationType.warning,
          );
        }
        return;
      }

      final addedCount = await provider.addEmployeesBatch(
        importedEmployees,
      );

      final skippedCount = importedEmployees.length - addedCount;

      if (!context.mounted) return;

      if (addedCount > 0) {
        String message = 'تمت إضافة $addedCount موظف إلى قائمة الموظفين';

        if (skippedCount > 0) {
          message += ' • تم تجاهل $skippedCount موظف مكرر';
        }

        _showAppNotification(
          context,
          title: 'تم الاستيراد بنجاح',
          message: message,
          type: _AppNotificationType.success,
        );
      } else {
        _showAppNotification(
          context,
          title: 'لم تتم إضافة موظفين',
          message: 'جميع الموظفين الموجودين في الملف مضافون مسبقًا.',
          type: _AppNotificationType.warning,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('IMPORT ERROR: $e');
      debugPrint(stackTrace.toString());

      if (!context.mounted) return;

      _showAppNotification(
        context,
        title: 'تعذر استيراد الملف',
        message: 'حدث خطأ أثناء قراءة الملف. تفاصيل الخطأ: $e',
        type: _AppNotificationType.error,
      );
    }
  }

  void _showAppNotification(
    BuildContext context, {
    required String title,
    required String message,
    required _AppNotificationType type,
  }) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    late OverlayEntry entry;

    final isSuccess = type == _AppNotificationType.success;
    final isWarning = type == _AppNotificationType.warning;

    final icon = isSuccess
        ? Icons.check_circle_outline
        : isWarning
            ? Icons.info_outline
            : Icons.error_outline;

    final iconColor = isSuccess
        ? const Color(0xff16A34A)
        : isWarning
            ? const Color(0xffD97706)
            : const Color(0xffDC2626);

    final iconBackground = isSuccess
        ? const Color(0xffECFDF5)
        : isWarning
            ? const Color(0xffFFFBEB)
            : const Color(0xffFEF2F2);

    entry = OverlayEntry(
      builder: (overlayContext) {
        return Positioned(
          top: 24,
          left: 24,
          right: 24,
          child: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Material(
                color: Colors.transparent,
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 220),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, -12 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      constraints: const BoxConstraints(
                        maxWidth: 520,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xffE5E7EB),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 18,
                            offset: Offset(0, 7),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: iconBackground,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              icon,
                              color: iconColor,
                              size: 23,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xff111827),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  message,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    height: 1.45,
                                    color: Color(0xff6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => entry.remove(),
                            child: const Padding(
                              padding: EdgeInsets.all(5),
                              child: Icon(
                                Icons.close,
                                size: 17,
                                color: Color(0xff9CA3AF),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(entry);

    Future<void>.delayed(
      const Duration(seconds: 4),
      () {
        if (entry.mounted) {
          entry.remove();
        }
      },
    );
  }


  void _showImportModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xffF8FAFC),
                      radius: 18,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                    const Text(
                      'استيراد الموظفين من Excel',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                const Center(
                  child: Text(
                    'قم بتحميل ملف Excel أو CSV يحتوي على بيانات الموظفين',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),

                Center(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xffEFF6FF),
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _downloadExcelTemplate(context),
                    icon: const Icon(Icons.file_download_outlined, color: Color(0xff2563EB), size: 18),
                    label: const Text(
                      'تحميل قالب استيراد الموظفين',
                      style: TextStyle(color: Color(0xff2563EB), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid, width: 1),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.file_upload_outlined, size: 40, color: Color(0xff2563EB)),
                      const SizedBox(height: 10),
                      const Text(
                        'اسحب وأفلت ملف الموظفين هنا',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      const Text('أو', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff2563EB),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _pickAndImportExcelFile(context, dialogContext: ctx),
                        icon: const Icon(Icons.badge_outlined, color: Colors.white, size: 18),
                        label: const Text('اختر ملف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xffF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'متطلبات ملف الموظفين:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                      ),
                      SizedBox(height: 6),
                      Text('•   الاسم الكامل (اسم الموظف)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      SizedBox(height: 3),
                      Text('•   رقم الهوية / رقم الإقامة', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      SizedBox(height: 3),
                      Text('•   تاريخ انتهاء الهوية (بالتنسيق الصحيح)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final employeeProvider = Provider.of<EmployeeProvider>(context);
    final allEmployees = employeeProvider.employees;

    final filteredEmployees = allEmployees.where((emp) {
      final matchesSearch = emp.name.contains(searchController.text) ||
          emp.idNumber.contains(searchController.text);
      if (!matchesSearch) return false;

      final statusData = _getCalculatedStatus(emp.expiryDate);
      final currentStatus = statusData['status'];

      if (selectedFilter == 0) return true;
      if (selectedFilter == 1) return currentStatus == "سارية" || currentStatus == "نشط";
      if (selectedFilter == 2) return currentStatus == "تحتاج متابعة" || currentStatus == "تنتهي قريباً";
      if (selectedFilter == 3) return currentStatus == "منتهية" || currentStatus == "منتهي";

      return true;
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            const SizedBox(height: 15),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: searchController,
                textAlign: TextAlign.right,
                onChanged: (val) => setState(() {}),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "البحث بالاسم أو رقم الهوية...",
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(filters.length, (index) {
                  bool active = selectedFilter == index;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: index == filters.length - 1 ? 0 : 6.0),
                      child: GestureDetector(
                        onTap: () => setState(() => selectedFilter = index),
                        child: Container(
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: active ? const Color(0xff1D4ED8) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: active ? const Color(0xff1D4ED8) : Colors.grey.shade200,
                            ),
                          ),
                          child: Text(
                            filters[index],
                            style: TextStyle(
                              color: active ? Colors.white : Colors.black87,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 15),

            Expanded(
              child: filteredEmployees.isEmpty
                  ? const Center(child: Text("لا يوجد موظفين مسجلين", style: TextStyle(color: Colors.grey)))
                  : ListView.separated(
                      itemCount: filteredEmployees.length,
                      separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
                      itemBuilder: (context, index) {
                        final emp = filteredEmployees[index];
                        final statusData = _getCalculatedStatus(emp.expiryDate);

                        return InkWell(
                          onTap: () => _showEmployeeActionsModal(context, emp),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        emp.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        textAlign: TextAlign.right,
                                      ),
                                      if (emp.expiryDate.isNotEmpty)
                                        Text(
                                          "الانتهاء: ${emp.expiryDate}",
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      emp.idNumber,
                                      style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 95,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildStatusBadge(statusData['status']),
                                      if (statusData['daysLeft'] != null && statusData['daysLeft'] >= 0) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          "متبقي ${statusData['daysLeft']} يوم",
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),

        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddActionChoiceDialog(context),
          backgroundColor: const Color(0xff0D2869),
          shape: const CircleBorder(),
          elevation: 3,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  void _showAddActionChoiceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xffF1F5F9),
                      radius: 18,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 18, color: Colors.black54),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                    const Text(
                      'اختر العملية',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    showAddEmployeeDialog(context);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xffF1F5F9), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xffEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.person_add_alt_1_outlined, color: Color(0xff2563EB), size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('إضافة موظف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                              SizedBox(height: 2),
                              Text('إضافة موظف جديد إلى النظام', style: TextStyle(color: Colors.grey, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    _showImportModal(context);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xffF1F5F9), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xffEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.file_upload_outlined, color: Color(0xff2563EB), size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('استيراد موظفين', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                              SizedBox(height: 2),
                              Text('استيراد موظفين من ملف بيانات', style: TextStyle(color: Colors.grey, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff0F172A),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('إغلاق', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = const Color(0xffE8F5E9);
    Color text = const Color(0xff2E7D32);

    if (status == "تحتاج متابعة" || status == "تنتهي قريباً") {
      bg = const Color(0xffFFF7ED);
      text = const Color(0xffD97706);
    } else if (status == "منتهية" || status == "منتهي") {
      bg = const Color(0xffFFEBEE);
      text = const Color(0xffC62828);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(status, style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  void _showEmployeeActionsModal(BuildContext context, Employee emp) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xffF3F4F6),
                      radius: 16,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xffEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.edit_note, color: Color(0xff2563EB), size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text("إجراءات الموظف", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(emp.name, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        label: "السجل",
                        icon: Icons.visibility_outlined,
                        color: const Color(0xff2563EB),
                        bgColor: const Color(0xffF0F5FF),
                        onTap: () {
                          Navigator.pop(ctx);
                          _showLogsDialog(context, emp);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _actionButton(
                        label: "تعديل",
                        icon: Icons.edit_outlined,
                        color: const Color(0xff2563EB),
                        bgColor: const Color(0xffF0F5FF),
                        onTap: () {
                          Navigator.pop(ctx);
                          _showEditEmployeeDialog(context, emp);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        label: "تجديد",
                        icon: Icons.autorenew,
                        color: const Color(0xff16A34A),
                        bgColor: const Color(0xffF0FDF4),
                        onTap: () {
                          Navigator.pop(ctx);
                          _showRenewDialog(context, emp);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _actionButton(
                        label: "حذف",
                        icon: Icons.delete_outline,
                        color: const Color(0xffDC2626),
                        bgColor: const Color(0xffFEF2F2),
                        onTap: () {
                          Navigator.pop(ctx);
                          _confirmDelete(context, emp);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffF3F4F6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("إغلاق", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 44,
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _showEditEmployeeDialog(BuildContext context, Employee emp) {
    final nameController = TextEditingController(text: emp.name);
    final idController = TextEditingController(text: emp.idNumber);
    final dateController = TextEditingController(text: emp.expiryDate);

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xffF3F4F6),
                      radius: 16,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                    const Text('تعديل بيانات الموظف', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('اسم الموظف', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(controller: nameController, decoration: _inputStyle('أدخل اسم الموظف...')),
                const SizedBox(height: 12),
                const Text('رقم الهوية / الإقامة', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(controller: idController, decoration: _inputStyle('أدخل رقم الهوية...')),
                const SizedBox(height: 12),
                const Text('تاريخ انتهاء الإقامة', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: dateController,
                  readOnly: true,
                  onTap: () async {
                    final pickedDate = await _showCustomDatePicker(context);
                    if (pickedDate != null) {
                      dateController.text = pickedDate;
                    }
                  },
                  decoration: _inputStyle('YYYY-MM-DD').copyWith(
                    prefixIcon: const Icon(Icons.calendar_today_outlined, color: Color(0xFF1D4ED8), size: 18),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D4ED8),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          final updated = emp.copyWith(
                            name: nameController.text,
                            idNumber: idController.text,
                            expiryDate: dateController.text,
                          );
                          Provider.of<EmployeeProvider>(context, listen: false).updateEmployee(updated);
                          Navigator.pop(ctx);
                        },
                        child: const Text('حفظ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xffF3F4F6),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('إلغاء', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void showAddEmployeeDialog(BuildContext context) {
    final nameController = TextEditingController();
    final idController = TextEditingController();
    final dateController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xffF3F4F6),
                      radius: 16,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                    const Text('إضافة موظف جديد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('اسم الموظف', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(controller: nameController, decoration: _inputStyle('أدخل اسم الموظف...')),
                const SizedBox(height: 12),
                const Text('رقم الهوية / الإقامة', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(controller: idController, decoration: _inputStyle('أدخل رقم الهوية...')),
                const SizedBox(height: 12),
                const Text('تاريخ انتهاء الإقامة', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: dateController,
                  readOnly: true,
                  onTap: () async {
                    final pickedDate = await _showCustomDatePicker(context);
                    if (pickedDate != null) {
                      dateController.text = pickedDate;
                    }
                  },
                  decoration: _inputStyle('YYYY-MM-DD').copyWith(
                    prefixIcon: const Icon(Icons.calendar_today_outlined, color: Color(0xFF1D4ED8), size: 18),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D4ED8),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          final name = nameController.text.trim();
                          final idNumber = idController.text.trim();

                          if (name.isEmpty) {
                            _showAppNotification(
                              context,
                              title: 'بيانات ناقصة',
                              message: 'يرجى إدخال اسم الموظف قبل الحفظ.',
                              type: _AppNotificationType.warning,
                            );
                            return;
                          }

                          final provider = Provider.of<EmployeeProvider>(
                            context,
                            listen: false,
                          );

                          // التحقق من وجود الموظف مسبقًا قبل الإضافة.
                          // رقم الهوية/الإقامة هو المعرف المستخدم لمنع التكرار.
                          final alreadyExists = idNumber.isNotEmpty &&
                              provider.employees.any(
                                (employee) =>
                                    employee.idNumber.trim() == idNumber,
                              );

                          if (alreadyExists) {
                            if (ctx.mounted) {
                              Navigator.of(ctx).pop();
                            }

                            if (!context.mounted) return;

                            _showAppNotification(
                              context,
                              title: 'تم تجاهل إضافة الموظف',
                              message:
                                  'الموظف مسجل مسبقًا بنفس رقم الهوية / الإقامة.',
                              type: _AppNotificationType.warning,
                            );
                            return;
                          }

                          final newEmployee = Employee(
                            id: DateTime.now()
                                .microsecondsSinceEpoch
                                .toString(),
                            name: name,
                            idNumber: idNumber,
                            expiryDate: dateController.text.isEmpty
                                ? '2026-10-01'
                                : dateController.text,
                            status: 'سارية',
                          );

                          try {
                            await provider.addEmployee(newEmployee);

                            if (ctx.mounted) {
                              Navigator.of(ctx).pop();
                            }

                            if (!context.mounted) return;

                            _showAppNotification(
                              context,
                              title: 'تمت إضافة الموظف',
                              message:
                                  'تم تسجيل $name في قائمة الموظفين بنجاح.',
                              type: _AppNotificationType.success,
                            );
                          } catch (e) {
                            if (ctx.mounted) {
                              Navigator.of(ctx).pop();
                            }

                            if (!context.mounted) return;

                            _showAppNotification(
                              context,
                              title: 'تعذر إضافة الموظف',
                              message: 'حدث خطأ أثناء حفظ بيانات الموظف: $e',
                              type: _AppNotificationType.error,
                            );
                          }
                        },
                        child: const Text('حفظ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xffF3F4F6),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('إلغاء', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // نافذة تأكيد التجديد النهائية
  void _confirmRenewalAction(BuildContext context, Employee emp, String formattedDate, int months) {
    showDialog(
      context: context,
      builder: (confirmCtx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xffF3F4F6),
                      radius: 16,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                        onPressed: () => Navigator.pop(confirmCtx),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xffF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.check_circle_outline, color: Color(0xff16A34A), size: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('تأكيد تجديد الهوية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  'هل أنت متأكد من تجديد هوية الموظف (${emp.name}) لمدة $months أشهر؟',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xffF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xffE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('تاريخ الانتهاء الجديد:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text(
                        formattedDate,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xff16A34A)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff16A34A),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Provider.of<EmployeeProvider>(context, listen: false).renewEmployeeId(emp.id, formattedDate);
                          Navigator.pop(confirmCtx); // إغلاق نافذة التأكيد
                          Navigator.pop(context);    // إغلاق نافذة التجديد الرئيسية

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('تم تجديد هوية الموظف ${emp.name} بنجاح حتى $formattedDate'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        child: const Text('نعم، تأكيد التجديد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xffF3F4F6),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Navigator.pop(confirmCtx),
                        child: const Text('إلغاء', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // نافذة التجديد وعرض تاريخ الانتهاء الجديد
  void _showRenewDialog(BuildContext context, Employee emp) {
    int selectedMonths = 12;
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          DateTime currentExpiry = DateTime.tryParse(emp.expiryDate) ?? DateTime.now();
          DateTime calculatedNewExpiry = calculateSaudiRenewalDate(currentExpiry, selectedMonths);
          String newExpiryString = "${calculatedNewExpiry.year}-${calculatedNewExpiry.month.toString().padLeft(2, '0')}-${calculatedNewExpiry.day.toString().padLeft(2, '0')}";

          return Directionality(
            textDirection: TextDirection.rtl,
            child: Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 360),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xffF3F4F6),
                          radius: 16,
                          child: IconButton(
                            icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xffF0FDF4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.autorenew, color: Color(0xff16A34A), size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Align(
                      alignment: Alignment.center,
                      child: Text('تجديد بيانات الموظف', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Text(emp.name, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ),
                    const SizedBox(height: 16),
                    const Text('مدة التجديد (بالأشهر)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      children: [3, 6, 9, 12].map((months) {
                        final isSelected = selectedMonths == months;
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSelected ? const Color(0xFF1D4ED8) : const Color(0xffF8FAFC),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => setDialogState(() => selectedMonths = months),
                              child: Text(
                                '$months أشهر',
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black87,
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 14),

                    // خانة التنبيه بعرض تاريخ الانتهاء الجديد
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xffF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xffBBF7D0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'تاريخ الانتهاء الجديد:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xff166534)),
                          ),
                          Text(
                            newExpiryString,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xff15803D),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                    const Text('ملاحظات التجديد', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(controller: notesController, decoration: _inputStyle('أدخل ملاحظات اختيارية...')),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1D4ED8),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              _confirmRenewalAction(context, emp, newExpiryString, selectedMonths);
                            },
                            child: const Text('تأكيد التجديد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xffF3F4F6),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('إلغاء', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showLogsDialog(BuildContext context, Employee emp) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xffF3F4F6),
                      radius: 16,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                    const Text('سجل الإجراءات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.maxFinite,
                  child: emp.logs.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text("لا يوجد سجلات حالية", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: emp.logs.length,
                          itemBuilder: (context, i) => ListTile(
                            leading: const Icon(Icons.history, size: 16, color: Color(0xff2563EB)),
                            title: Text(emp.logs[i], style: const TextStyle(fontSize: 12)),
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffF3F4F6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("إغلاق", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Employee emp) {
    showDialog(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 24,
          ),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 360,
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xffF3F4F6),
                      radius: 16,
                      child: IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xffFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xffDC2626),
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'تأكيد حذف الموظف',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff111827),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'هل أنت متأكد من حذف الموظف؟\n${emp.name}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xff6B7280),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffDC2626),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          try {
                            final provider =
                                Provider.of<EmployeeProvider>(
                              context,
                              listen: false,
                            );

                            await provider.removeEmployee(emp.id);

                            if (!dialogContext.mounted) return;
                            Navigator.of(dialogContext).pop();

                            if (!context.mounted) return;

                            _showAppNotification(
                              context,
                              title: 'تم حذف الموظف',
                              message:
                                  'تم حذف ${emp.name} من قائمة الموظفين بنجاح.',
                              type: _AppNotificationType.success,
                            );
                          } catch (e) {
                            if (!dialogContext.mounted) return;
                            Navigator.of(dialogContext).pop();

                            if (!context.mounted) return;

                            _showAppNotification(
                              context,
                              title: 'تعذر حذف الموظف',
                              message: 'حدث خطأ أثناء تنفيذ عملية الحذف: $e',
                              type: _AppNotificationType.error,
                            );
                          }
                        },
                        child: const Text(
                          'حذف نهائي',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xffF3F4F6),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                        child: const Text(
                          'إلغاء',
                          style: TextStyle(
                            color: Color(0xff111827),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  InputDecoration _inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
      filled: true,
      fillColor: const Color(0xffFAFAFA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1D4ED8)),
      ),
    );
  }
}

class _DayLabel extends StatelessWidget {
  final String label;
  const _DayLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}