import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart' as excel_lib;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html;

import '../providers/employee_provider.dart';
import '../providers/visit_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static const Color primaryBlue = Color(0xff2563EB);
  static const Color pageBackground = Color(0xffF7F8FC);

  int selectedTab = 0; // 0 الموظفين - 1 الزيارات - 2 التجديدات
  int _documentCount = 0;

  final List<String> tabs = const ['الموظفين', 'الزيارات', 'التجديدات'];
  final List<IconData> tabIcons = const [
    LucideIcons.users,
    LucideIcons.plane,
    LucideIcons.refreshCw,
  ];

  @override
  void initState() {
    super.initState();
    _loadDocumentCount();
  }

  Future<void> _loadDocumentCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('employee_id_app_documents_v2');
      if (raw == null || raw.isEmpty) {
        if (mounted) setState(() => _documentCount = 0);
        return;
      }

      final decoded = jsonDecode(raw);
      final count = decoded is List ? decoded.length : 0;
      if (mounted) setState(() => _documentCount = count);
    } catch (_) {
      if (mounted) setState(() => _documentCount = 0);
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    // Firestore Timestamp أو أي كائن يملك toDate().
    try {
      final dynamic converted = value.toDate();
      if (converted is DateTime) {
        return DateTime(converted.year, converted.month, converted.day);
      }
    } catch (_) {}

    if (value is DateTime) {
      return DateTime(value.year, value.month, value.day);
    }

    var text = value.toString().trim();
    if (text.isEmpty) return null;

    // إزالة الوقت والأقواس والعلامات غير الضرورية.
    text = text.replaceAll('T', ' ').split(' ').first.trim();
    text = text.replaceAll('\\', '/').replaceAll('.', '/');
    text = text.replaceAll(RegExp(r'[^0-9/\-]'), '');

    // yyyy-MM-dd أو yyyy/MM/dd
    final ymd = RegExp(r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})$').firstMatch(text);
    if (ymd != null) {
      final y = int.parse(ymd.group(1)!);
      final m = int.parse(ymd.group(2)!);
      final d = int.parse(ymd.group(3)!);
      if (m < 1 || m > 12 || d < 1 || d > 31) return null;
      final date = DateTime(y, m, d);
      if (date.year != y || date.month != m || date.day != d) return null;
      return date;
    }

    // dd-MM-yyyy أو dd/MM/yyyy
    final dmy = RegExp(r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})$').firstMatch(text);
    if (dmy != null) {
      final d = int.parse(dmy.group(1)!);
      final m = int.parse(dmy.group(2)!);
      final y = int.parse(dmy.group(3)!);
      if (m < 1 || m > 12 || d < 1 || d > 31) return null;
      final date = DateTime(y, m, d);
      if (date.year != y || date.month != m || date.day != d) return null;
      return date;
    }

    final parsed = DateTime.tryParse(value.toString().trim());
    if (parsed != null) {
      return DateTime(parsed.year, parsed.month, parsed.day);
    }

    return null;
  }

  int? _daysRemaining(dynamic value) {
    final date = _parseDate(value);
    if (date == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.difference(today).inDays;
  }

  String _formatDate(dynamic value) {
    final date = _parseDate(value);
    if (date == null) return '-';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _status(dynamic expiry, dynamic storedStatus) {
    final days = _daysRemaining(expiry);
    if (days != null) {
      if (days < 0) return 'منتهية';
      if (days <= 30) return 'تنتهي قريباً';
      return 'سارية المفعول';
    }

    final saved = storedStatus?.toString().trim() ?? '';
    return saved.isNotEmpty ? saved : '-';
  }

  int _renewalCount(dynamic item) {
    try {
      final logs = item.logs;
      if (logs is Iterable) {
        return logs
            .map((e) => e.toString())
            .where((e) => e.contains('تجديد'))
            .length;
      }
    } catch (_) {}
    return 0;
  }

  String _daysText(dynamic expiry) {
    final days = _daysRemaining(expiry);
    if (days == null) return '-';
    if (days < 0) return 'منتهية ${days.abs()} يوم';
    return '$days يوم';
  }

  // نقرأ رقم التأشيرة من أكثر من اسم محتمل في موديل الزيارات.
  String _visitVisaNumber(dynamic visit) {
    try {
      final value = visit.visaNumber;
      if (value != null && value.toString().trim().isNotEmpty) return value.toString().trim();
    } catch (_) {}
    try {
      final value = visit.visaNo;
      if (value != null && value.toString().trim().isNotEmpty) return value.toString().trim();
    } catch (_) {}
    try {
      final value = visit.visa;
      if (value != null && value.toString().trim().isNotEmpty) return value.toString().trim();
    } catch (_) {}
    try {
      final value = visit.visaNumberValue;
      if (value != null && value.toString().trim().isNotEmpty) return value.toString().trim();
    } catch (_) {}
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    final employees = context.watch<EmployeeProvider>().employees;
    final visits = context.watch<VisitProvider>().visits;
    final renewalCount = employees.fold<int>(0, (sum, e) => sum + _renewalCount(e)) +
        visits.fold<int>(0, (sum, v) => sum + _renewalCount(v));

    final reportCount = selectedTab == 0
        ? employees.length
        : selectedTab == 1
            ? visits.length
            : renewalCount;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: pageBackground,
        body: SafeArea(
          child: RefreshIndicator(
            color: primaryBlue,
            onRefresh: _loadDocumentCount,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 12),
                  _buildTabs(),
                  const SizedBox(height: 12),
                  _buildStats(
                    employeeCount: employees.length,
                    visitCount: visits.length,
                    documentCount: _documentCount,
                    reportCount: reportCount,
                  ),
                  const SizedBox(height: 12),
                  if (selectedTab == 0)
                    _buildEmployeesReport(employees)
                  else if (selectedTab == 1)
                    _buildVisitsReport(visits)
                  else
                    _buildRenewalsReport(employees, visits),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffE5E7EB)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'التقارير',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xff111827)),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'تصدير ومراجعة تقارير الموظفين والزيارات والتجديدات',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 11, height: 1.3, color: Color(0xff6B7280)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xffEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.fileText, color: primaryBlue, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _exportButton(
                  label: 'Excel',
                  icon: LucideIcons.download,
                  foreground: const Color(0xff16A34A),
                  background: const Color(0xffF0FDF4),
                  border: Colors.transparent,
                  onPressed: _exportExcel,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _exportButton(
                  label: 'PDF',
                  icon: LucideIcons.fileDown,
                  foreground: const Color(0xffDC2626),
                  background: const Color(0xffFEF2F2),
                  border: Colors.transparent,
                  onPressed: _exportPdf,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _exportButton({
    required String label,
    required IconData icon,
    required Color foreground,
    required Color background,
    required Color border,
    required Future<void> Function() onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: () async {
          await onPressed();
        },
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: foreground,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Row(
      children: List.generate(tabs.length, (index) {
        final active = selectedTab == index;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: index == tabs.length - 1 ? 0 : 7),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => setState(() => selectedTab = index),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: active ? primaryBlue : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: active ? primaryBlue : const Color(0xffE5E7EB)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(tabIcons[index], size: 19, color: active ? Colors.white : const Color(0xff4B5563)),
                    const SizedBox(width: 7),
                    Text(
                      tabs[index],
                      style: TextStyle(
                        color: active ? Colors.white : const Color(0xff4B5563),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStats({
    required int employeeCount,
    required int visitCount,
    required int documentCount,
    required int reportCount,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _statCard('الموظفين', '$employeeCount', LucideIcons.users, const Color(0xff2563EB), const Color(0xffEFF6FF))),
            const SizedBox(width: 8),
            Expanded(child: _statCard('الزيارات', '$visitCount', LucideIcons.plane, const Color(0xff16A34A), const Color(0xffF0FDF4))),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _statCard('الوثائق', '$documentCount', LucideIcons.folderOpen, const Color(0xffEA580C), const Color(0xffFFF7ED))),
            const SizedBox(width: 8),
            Expanded(child: _statCard('نتائج التقرير', '$reportCount', LucideIcons.fileText, const Color(0xff7C3AED), const Color(0xffF5F3FF))),
          ],
        ),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color, Color background) {
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffE5E7EB)),
      ),
      child: Row(
        textDirection: TextDirection.ltr,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: Color(0xff6B7280), fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 25, height: 1, color: color, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportCard({required String title, required int count, required Widget child}) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xff111827))),
                const SizedBox(height: 4),
                Text('عدد النتائج: $count', style: const TextStyle(fontSize: 12, color: Color(0xff6B7280))),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _table({required List<DataColumn> columns, required List<DataRow> rows}) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 44,
        dataRowMinHeight: 46,
        dataRowMaxHeight: 56,
        horizontalMargin: 9,
        columnSpacing: 22,
        headingRowColor: WidgetStateProperty.all(const Color(0xffEFF6FF)),
        columns: columns,
        rows: rows,
      ),
    );
  }

  Text _headerText(String text) => Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      );

  Text _cellText(dynamic value) => Text(
        value?.toString() ?? '-',
        style: const TextStyle(fontSize: 12),
      );

  Widget _buildEmployeesReport(List<dynamic> employees) {
    if (employees.isEmpty) return _emptyReport('تقرير الموظفين');

    return _reportCard(
      title: 'تقرير الموظفين',
      count: employees.length,
      child: _table(
        columns: [
          DataColumn(label: _headerText('اسم الموظف')),
          DataColumn(label: _headerText('رقم الهوية')),
          DataColumn(label: _headerText('تاريخ انتهاء الهوية')),
          DataColumn(label: _headerText('الحالة')),
          DataColumn(label: _headerText('الأيام المتبقية')),
          DataColumn(label: _headerText('عدد التجديدات')),
        ],
        rows: employees.map<DataRow>((employee) {
          final days = _daysRemaining(employee.expiryDate);
          final status = _status(employee.expiryDate, employee.status);
          return DataRow(cells: [
            DataCell(_cellText(employee.name)),
            DataCell(_cellText(employee.idNumber)),
            DataCell(_cellText(_formatDate(employee.expiryDate))),
            DataCell(_statusChip(status, days)),
            DataCell(_cellText(_daysText(employee.expiryDate))),
            DataCell(_cellText(_renewalCount(employee))),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildVisitsReport(List<dynamic> visits) {
    if (visits.isEmpty) return _emptyReport('تقرير الزيارات');

    return _reportCard(
      title: 'تقرير الزيارات',
      count: visits.length,
      child: _table(
        columns: [
          DataColumn(label: _headerText('اسم الزائر')),
          DataColumn(label: _headerText('رقم التأشيرة')),
          DataColumn(label: _headerText('رقم الحدود')),
          DataColumn(label: _headerText('تاريخ انتهاء الزيارة')),
          DataColumn(label: _headerText('تاريخ انتهاء التأمين')),
          DataColumn(label: _headerText('الحالة')),
          DataColumn(label: _headerText('الأيام المتبقية')),
          DataColumn(label: _headerText('أيام التأمين المتبقية')),
          DataColumn(label: _headerText('عدد التجديدات')),
        ],
        rows: visits.map<DataRow>((visit) {
          final visitDays = _daysRemaining(visit.expiryDate);
          final status = _status(visit.expiryDate, visit.status);
          return DataRow(cells: [
            DataCell(_cellText(visit.visitorName)),
            DataCell(_cellText(_visitVisaNumber(visit))),
            DataCell(_cellText(visit.borderNumber)),
            DataCell(_cellText(_formatDate(visit.expiryDate))),
            DataCell(_cellText(_formatDate(visit.insuranceExpiryDate))),
            DataCell(_statusChip(status, visitDays)),
            DataCell(_cellText(_daysText(visit.expiryDate))),
            DataCell(_cellText(_daysText(visit.insuranceExpiryDate))),
            DataCell(_cellText(_renewalCount(visit))),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildRenewalsReport(List<dynamic> employees, List<dynamic> visits) {
    final rows = <Map<String, dynamic>>[];

    for (final employee in employees) {
      final count = _renewalCount(employee);
      if (count > 0) {
        rows.add({
          'section': 'الموظفين',
          'name': employee.name?.toString() ?? '-',
          'number': employee.idNumber?.toString() ?? '-',
          'date': employee.expiryDate,
          'insurance': null,
          'status': _status(employee.expiryDate, employee.status),
          'count': count,
        });
      }
    }

    for (final visit in visits) {
      final count = _renewalCount(visit);
      if (count > 0) {
        rows.add({
          'section': 'الزيارات',
          'name': visit.visitorName?.toString() ?? '-',
          'number': visit.borderNumber?.toString() ?? '-',
          'date': visit.expiryDate,
          'insurance': visit.insuranceExpiryDate,
          'status': _status(visit.expiryDate, visit.status),
          'count': count,
        });
      }
    }

    if (rows.isEmpty) return _emptyReport('تقرير التجديدات');

    return _reportCard(
      title: 'تقرير التجديدات',
      count: rows.length,
      child: _table(
        columns: [
          DataColumn(label: _headerText('القسم')),
          DataColumn(label: _headerText('الاسم')),
          DataColumn(label: _headerText('الرقم')),
          DataColumn(label: _headerText('تاريخ الانتهاء')),
          DataColumn(label: _headerText('التأمين')),
          DataColumn(label: _headerText('الحالة')),
          DataColumn(label: _headerText('عدد التجديدات')),
        ],
        rows: rows.map<DataRow>((row) {
          final days = _daysRemaining(row['date']);
          return DataRow(cells: [
            DataCell(_cellText(row['section'])),
            DataCell(_cellText(row['name'])),
            DataCell(_cellText(row['number'])),
            DataCell(_cellText(_formatDate(row['date']))),
            DataCell(_cellText(_formatDate(row['insurance']))),
            DataCell(_statusChip(row['status'] as String, days)),
            DataCell(_cellText(row['count'])),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _emptyReport(String title) {
    return _reportCard(
      title: title,
      count: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(LucideIcons.fileText, size: 44, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text('لا توجد بيانات للعرض في التقرير', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status, int? days) {
    Color bg;
    Color fg;
    if (days != null && days < 0) {
      bg = const Color(0xffFEE2E2);
      fg = const Color(0xffDC2626);
    } else if (days != null && days <= 30) {
      bg = const Color(0xffFEF3C7);
      fg = const Color(0xffD97706);
    } else {
      bg = const Color(0xffDCFCE7);
      fg = const Color(0xff16A34A);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18)),
      child: Text(status, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }

  List<List<String>> _currentExportRows() {
    final employees = context.read<EmployeeProvider>().employees;
    final visits = context.read<VisitProvider>().visits;

    if (selectedTab == 0) {
      return [
        ['اسم الموظف', 'رقم الهوية', 'تاريخ انتهاء الهوية', 'الحالة', 'الأيام المتبقية', 'عدد التجديدات'],
        ...employees.map((e) => [
              e.name?.toString() ?? '-',
              e.idNumber?.toString() ?? '-',
              _formatDate(e.expiryDate),
              _status(e.expiryDate, e.status),
              _daysText(e.expiryDate),
              _renewalCount(e).toString(),
            ]),
      ];
    }

    if (selectedTab == 1) {
      return [
        [
          'اسم الزائر',
          'رقم التأشيرة',
          'رقم الحدود',
          'تاريخ انتهاء الزيارة',
          'تاريخ انتهاء التأمين',
          'الحالة',
          'الأيام المتبقية',
          'أيام التأمين المتبقية',
          'عدد التجديدات',
        ],
        ...visits.map((v) => [
              v.visitorName?.toString() ?? '-',
              _visitVisaNumber(v),
              v.borderNumber?.toString() ?? '-',
              _formatDate(v.expiryDate),
              _formatDate(v.insuranceExpiryDate),
              _status(v.expiryDate, v.status),
              _daysText(v.expiryDate),
              _daysText(v.insuranceExpiryDate),
              _renewalCount(v).toString(),
            ]),
      ];
    }

    final rows = <List<String>>[
      ['القسم', 'الاسم', 'الرقم', 'تاريخ الانتهاء', 'التأمين', 'الحالة', 'عدد التجديدات'],
    ];

    for (final e in employees) {
      final count = _renewalCount(e);
      if (count > 0) {
        rows.add([
          'الموظفين',
          e.name?.toString() ?? '-',
          e.idNumber?.toString() ?? '-',
          _formatDate(e.expiryDate),
          '-',
          _status(e.expiryDate, e.status),
          count.toString(),
        ]);
      }
    }

    for (final v in visits) {
      final count = _renewalCount(v);
      if (count > 0) {
        rows.add([
          'الزيارات',
          v.visitorName?.toString() ?? '-',
          v.borderNumber?.toString() ?? '-',
          _formatDate(v.expiryDate),
          _formatDate(v.insuranceExpiryDate),
          _status(v.expiryDate, v.status),
          count.toString(),
        ]);
      }
    }

    return rows;
  }

  void _downloadWebFile(Uint8List bytes, String fileName, String mimeType) {
    final blob = html.Blob(<dynamic>[bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _exportExcel() async {
    try {
      final rows = _currentExportRows();
      final workbook = excel_lib.Excel.createExcel();
      final sheet = workbook['التقرير'];
      sheet.isRTL = true;

      for (final row in rows) {
        sheet.appendRow(row.map((value) => excel_lib.TextCellValue(value)).toList());
      }

      final bytes = workbook.save();
      if (bytes == null || bytes.isEmpty) {
        throw Exception('تعذر إنشاء ملف Excel');
      }

      _downloadWebFile(
        Uint8List.fromList(bytes),
        'تقرير_${tabs[selectedTab]}.xlsx',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تصدير تقرير Excel بنجاح')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تصدير Excel: $e')),
      );
    }
  }

  Future<void> _exportPdf() async {
    try {
      final rows = _currentExportRows();
      final arabicFont = await PdfGoogleFonts.notoSansArabicRegular();
      final arabicBold = await PdfGoogleFonts.notoSansArabicBold();

      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(
          base: arabicFont,
          bold: arabicBold,
        ),
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          textDirection: pw.TextDirection.rtl,
          header: (context) => pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              child: pw.Text(
                'نظام إدارة الهويات - تقرير ${tabs[selectedTab]}',
                style: pw.TextStyle(font: arabicBold, fontSize: 16),
              ),
            ),
          ),
          build: (context) => [
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Table.fromTextArray(
                headers: rows.isNotEmpty ? rows.first : <String>[],
                data: rows.length > 1 ? rows.skip(1).toList() : <List<String>>[],
                headerStyle: pw.TextStyle(font: arabicBold, fontSize: 8),
                cellStyle: pw.TextStyle(font: arabicFont, fontSize: 7.5),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFEFF6FF),
                ),
                cellAlignment: pw.Alignment.center,
                headerAlignment: pw.Alignment.center,
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              ),
            ),
          ],
        ),
      );

      final bytes = await pdf.save();
      _downloadWebFile(
        Uint8List.fromList(bytes),
        'تقرير_${tabs[selectedTab]}.pdf',
        'application/pdf',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تصدير تقرير PDF بنجاح')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تصدير PDF: $e')),
      );
    }
  }
}
