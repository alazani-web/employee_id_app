import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    Icons.people_outline,
    Icons.flight_land_outlined,
    Icons.autorenew_outlined,
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
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return null;

    final direct = DateTime.tryParse(text);
    if (direct != null) return direct;

    final normalized = text.replaceAll('/', '-');
    final p = normalized.split('-');
    if (p.length != 3) return null;

    final a = int.tryParse(p[0]);
    final b = int.tryParse(p[1]);
    final c = int.tryParse(p[2]);
    if (a == null || b == null || c == null) return null;

    if (a > 31) return DateTime.tryParse('${a.toString().padLeft(4, '0')}-${b.toString().padLeft(2, '0')}-${c.toString().padLeft(2, '0')}');
    return DateTime.tryParse('${c.toString().padLeft(4, '0')}-${b.toString().padLeft(2, '0')}-${a.toString().padLeft(2, '0')}');
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
    return (storedStatus?.toString().trim().isNotEmpty ?? false)
        ? storedStatus.toString()
        : '-';
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 16),
                  _buildTabs(),
                  const SizedBox(height: 16),
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
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
                    SizedBox(height: 5),
                    Text(
                      'تصدير ومراجعة تقارير الموظفين والزيارات والتجديدات',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 12, height: 1.35, color: Color(0xff6B7280)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 58,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xffEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.description_outlined, color: primaryBlue, size: 27),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _exportButton(
                  label: 'Excel',
                  icon: Icons.file_download_outlined,
                  foreground: const Color(0xff16A34A),
                  background: const Color(0xffF0FDF4),
                  border: const Color(0xffBBF7D0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _exportButton(
                  label: 'PDF',
                  icon: Icons.picture_as_pdf_outlined,
                  foreground: const Color(0xffDC2626),
                  background: const Color(0xffFEF2F2),
                  border: const Color(0xffFECACA),
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
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(13),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تصدير $label سيتم ربطه لاحقاً بملف التقرير')),
        );
      },
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: TextStyle(color: foreground, fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(width: 8),
            Icon(icon, color: foreground, size: 19),
          ],
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
            padding: EdgeInsets.only(left: index == tabs.length - 1 ? 0 : 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () => setState(() => selectedTab = index),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: active ? primaryBlue : Colors.white,
                  borderRadius: BorderRadius.circular(30),
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
                        fontSize: 13,
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
            Expanded(child: _statCard('الموظفين', '$employeeCount', Icons.people_outline, const Color(0xff2563EB), const Color(0xffEFF6FF))),
            const SizedBox(width: 8),
            Expanded(child: _statCard('الزيارات', '$visitCount', Icons.flight_land_outlined, const Color(0xff16A34A), const Color(0xffF0FDF4))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _statCard('الوثائق', '$documentCount', Icons.folder_open_outlined, const Color(0xffEA580C), const Color(0xffFFF7ED))),
            const SizedBox(width: 8),
            Expanded(child: _statCard('نتائج التقرير', '$reportCount', Icons.assignment_outlined, const Color(0xff7C3AED), const Color(0xffF5F3FF))),
          ],
        ),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color, Color background) {
    return Container(
      height: 82,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 44,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 23),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: Color(0xff6B7280), fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 27, height: 1, color: color, fontWeight: FontWeight.w800)),
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
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xffE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xff111827))),
                const SizedBox(height: 5),
                Text('عدد النتائج: $count', style: const TextStyle(fontSize: 12, color: Color(0xff6B7280))),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildEmployeesReport(List<dynamic> employees) {
    if (employees.isEmpty) return _emptyReport('تقرير الموظفين');

    return _reportCard(
      title: 'تقرير الموظفين',
      count: employees.length,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 46,
          dataRowMinHeight: 48,
          dataRowMaxHeight: 58,
          horizontalMargin: 10,
          columnSpacing: 24,
          headingRowColor: WidgetStateProperty.all(const Color(0xffEFF6FF)),
          columns: const [
            DataColumn(label: Text('اسم الموظف', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
            DataColumn(label: Text('رقم الهوية', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
            DataColumn(label: Text('تاريخ انتهاء الهوية', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
            DataColumn(label: Text('الحالة', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
            DataColumn(label: Text('الأيام المتبقية', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
            DataColumn(label: Text('عدد مرات التجديد', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
          ],
          rows: employees.map<DataRow>((employee) {
            final days = _daysRemaining(employee.expiryDate);
            final status = _status(employee.expiryDate, employee.status);
            return DataRow(cells: [
              DataCell(Text(employee.name.toString(), style: const TextStyle(fontSize: 13))),
              DataCell(Text(employee.idNumber.toString(), style: const TextStyle(fontSize: 13))),
              DataCell(Text(_formatDate(employee.expiryDate), style: const TextStyle(fontSize: 13))),
              DataCell(_statusChip(status, days)),
              DataCell(Text(_daysText(employee.expiryDate), style: const TextStyle(fontSize: 13))),
              DataCell(Text('${_renewalCount(employee)}', style: const TextStyle(fontSize: 13))),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildVisitsReport(List<dynamic> visits) {
    if (visits.isEmpty) return _emptyReport('تقرير الزيارات');

    return _reportCard(
      title: 'تقرير الزيارات',
      count: visits.length,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 46,
          dataRowMinHeight: 48,
          dataRowMaxHeight: 58,
          horizontalMargin: 10,
          columnSpacing: 24,
          headingRowColor: WidgetStateProperty.all(const Color(0xffEFF6FF)),
          columns: const [
            DataColumn(label: Text('اسم الزائر', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
            DataColumn(label: Text('رقم الحدود', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
            DataColumn(label: Text('تاريخ انتهاء الزيارة', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
            DataColumn(label: Text('تاريخ انتهاء التأمين', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
            DataColumn(label: Text('الحالة', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
            DataColumn(label: Text('الأيام المتبقية', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
          ],
          rows: visits.map<DataRow>((visit) {
            final expiry = visit.expiryDate;
            final days = _daysRemaining(expiry);
            final status = _status(expiry, visit.status);
            return DataRow(cells: [
              DataCell(Text(visit.visitorName.toString(), style: const TextStyle(fontSize: 13))),
              DataCell(Text(visit.borderNumber.toString(), style: const TextStyle(fontSize: 13))),
              DataCell(Text(_formatDate(expiry), style: const TextStyle(fontSize: 13))),
              DataCell(Text(_formatDate(visit.insuranceExpiryDate), style: const TextStyle(fontSize: 13))),
              DataCell(_statusChip(status, days)),
              DataCell(Text(_daysText(expiry), style: const TextStyle(fontSize: 13))),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRenewalsReport(List<dynamic> employees, List<dynamic> visits) {
    final rows = <Map<String, String>>[];

    for (final employee in employees) {
      final count = _renewalCount(employee);
      if (count > 0) {
        rows.add({
          'type': 'هوية موظف',
          'name': employee.name.toString(),
          'date': _formatDate(employee.expiryDate),
          'count': '$count',
          'status': _status(employee.expiryDate, employee.status),
        });
      }
    }

    for (final visit in visits) {
      final count = _renewalCount(visit);
      if (count > 0) {
        rows.add({
          'type': 'زيارة',
          'name': visit.visitorName.toString(),
          'date': _formatDate(visit.expiryDate),
          'count': '$count',
          'status': _status(visit.expiryDate, visit.status),
        });
      }
    }

    if (rows.isEmpty) return _emptyReport('تقرير التجديدات');

    return _reportCard(
      title: 'تقرير التجديدات',
      count: rows.length,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 46,
          dataRowMinHeight: 48,
          dataRowMaxHeight: 58,
          horizontalMargin: 10,
          columnSpacing: 26,
          headingRowColor: WidgetStateProperty.all(const Color(0xffEFF6FF)),
          columns: const [
            DataColumn(label: Text('النوع', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
            DataColumn(label: Text('الاسم', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
            DataColumn(label: Text('تاريخ التجديد / الانتهاء', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
            DataColumn(label: Text('الحالة', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
            DataColumn(label: Text('عدد مرات التجديد', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
          ],
          rows: rows.map((row) => DataRow(cells: [
            DataCell(Text(row['type']!, style: const TextStyle(fontSize: 13))),
            DataCell(Text(row['name']!, style: const TextStyle(fontSize: 13))),
            DataCell(Text(row['date']!, style: const TextStyle(fontSize: 13))),
            DataCell(_statusChip(row['status']!, _daysRemaining(row['date']))),
            DataCell(Text(row['count']!, style: const TextStyle(fontSize: 13))),
          ])).toList(),
        ),
      ),
    );
  }

  Widget _emptyReport(String title) {
    return _reportCard(
      title: title,
      count: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 46),
        child: Column(
          children: [
            Icon(Icons.insert_chart_outlined_outlined, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('لا توجد بيانات للعرض في التقرير', style: TextStyle(fontSize: 15, color: Colors.grey.shade500)),
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}
