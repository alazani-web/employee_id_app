import 'dart:math' as math;
import 'dart:typed_data';

import 'package:excel/excel.dart' as excel_pkg;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/employee.dart';
import '../providers/employee_provider.dart';
import '../services/import_service.dart';
import '../widgets/import_progress_view.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  static const blue = Color(0xff2563EB);
  static const green = Color(0xff16A34A);
  static const red = Color(0xffEF4444);
  static const navy = Color(0xff0F1E46);
  static const pageBg = Color(0xffF5F9FF);

  PlatformFile? _file;
  bool _isImporting = false;
  EmployeeImportResult? _result;
  ImportProgress _progress = const ImportProgress(progress: 0, stage: 'قراءة الملف');
  String? _error;

  Future<void> _pickFile() async {
    if (_isImporting) return;
    setState(() { _error = null; _result = null; });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null || file.bytes!.isEmpty) {
      setState(() { _error = 'تعذر قراءة بيانات الملف.'; _file = null; });
      return;
    }
    setState(() => _file = file);
  }

  Future<void> _startImport() async {
    final file = _file;
    final bytes = file?.bytes;
    if (file == null || bytes == null || bytes.isEmpty) {
      setState(() => _error = 'اختر ملف Excel أو CSV أولاً.');
      return;
    }

    final provider = context.read<EmployeeProvider>();
    setState(() {
      _isImporting = true;
      _result = null;
      _error = null;
      _progress = const ImportProgress(progress: 0, stage: 'قراءة الملف');
    });

    try {
      final result = await ImportService.importEmployees(
        fileName: file.name,
        bytes: bytes,
        existingEmployees: List<Employee>.from(provider.employees),
        saveEmployees: provider.addEmployeesBatch,
        onProgress: (value) {
          if (!mounted) return;
          setState(() => _progress = value);
        },
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _isImporting = false;
        _progress = ImportProgress(
          progress: 1,
          stage: 'اكتمل الاستيراد',
          processed: result.totalRecords,
          total: result.totalRecords,
          imported: result.importedCount,
          skipped: result.skippedCount,
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isImporting = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: pageBg,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 370),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 2),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: _isImporting ? const NeverScrollableScrollPhysics() : null,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 450),
                          child: _isImporting
                              ? _buildProgress()
                              : _result != null
                                  ? _buildSuccess()
                                  : _buildSelect(),
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
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 48,
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            onPressed: _isImporting ? null : () => Navigator.of(context).pop(),
            icon: const Icon(LucideIcons.chevronRight, size: 21, color: navy),
          ),
          Expanded(
            child: Text(
              'استيراد الموظفين',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: navy),
            ),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xffDDE8F7)),
            ),
            child: const Icon(LucideIcons.circleHelp, color: navy, size: 17),
          ),
        ],
      ),
    );
  }

  Widget _buildSelect() {
    return Column(
      children: [
        const SizedBox(height: 2),
        SizedBox(
          height: 150,
          width: double.infinity,
          child: Image.asset(
            'assets/icons/import_employees_hero.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const _FallbackHero(),
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'استيراد بيانات الموظفين',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: navy),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        const Text(
          'يمكنك استيراد بيانات الموظفين من ملف Excel بسهولة وسرعة\nيرجى استخدام النموذج المرفق لضمان توافق البيانات',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10.5, height: 1.5, color: Color(0xff64748B)),
        ),
        const SizedBox(height: 8),
        _buildDropZone(),
        if (_file != null) ...[
          const SizedBox(height: 9),
          _buildFileCard(),
        ],
        const SizedBox(height: 7),
        _buildTemplateCard(),
        if (_error != null) ...[
          const SizedBox(height: 9),
          _buildError(),
        ],
        const SizedBox(height: 9),
        SizedBox(
          width: double.infinity,
          height: 45,
          child: FilledButton.icon(
            onPressed: _file == null ? null : _startImport,
            icon: const Icon(LucideIcons.upload, size: 19),
            label: const Text('بدء الاستيراد', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
            style: FilledButton.styleFrom(
              backgroundColor: blue,
              disabledBackgroundColor: const Color(0xffCBD5E1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropZone() {
    return InkWell(
      onTap: _pickFile,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.58),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xff9FC3FF), width: 1.1),
        ),
        child: const Column(
          children: [
            Icon(LucideIcons.cloudUpload, size: 34, color: blue),
            SizedBox(height: 5),
            Text('اختر ملف Excel هنا', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: navy)),
            SizedBox(height: 2),
            Text('أو اسحب الملف إلى هنا', style: TextStyle(fontSize: 10, color: Color(0xff64748B))),
            SizedBox(height: 1),
            Text('(XLSX أو XLS)', style: TextStyle(fontSize: 9.5, color: Color(0xff94A3B8))),
          ],
        ),
      ),
    );
  }

  Widget _buildFileCard() {
    final file = _file!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xffDCE7F7))),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: const Color(0xffDCFCE7), borderRadius: BorderRadius.circular(10)),
            child: const _ExcelIcon(),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(file.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: navy)),
                const SizedBox(height: 2),
                Text(_formatBytes(file.size), style: const TextStyle(fontSize: 10, color: Color(0xff64748B))),
              ],
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            onPressed: _pickFile,
            icon: const Icon(LucideIcons.x, color: Color(0xff64748B), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xffEFF6FF),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xffBFDBFE)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          InkWell(
            onTap: _downloadTemplate,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xffDBEAFE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.download, color: blue, size: 18),
            ),
          ),
          const SizedBox(width: 9),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'تحميل نموذج ملف Excel',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: navy,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'استخدم هذا النموذج لتنسيق البيانات بشكل صحيح',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 9.2,
                    color: Color(0xff64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(LucideIcons.info, color: blue, size: 17),
        ],
      ),
    );
  }

  Future<void> _downloadTemplate() async {
    try {
      final workbook = excel_pkg.Excel.createExcel();
      final sheet = workbook['Employees'];
      sheet.appendRow([
        excel_pkg.TextCellValue('اسم الموظف'),
        excel_pkg.TextCellValue('رقم الهوية/الإقامة'),
        excel_pkg.TextCellValue('تاريخ انتهاء الهوية'),
      ]);
      sheet.appendRow([
        excel_pkg.TextCellValue('مثال: محمد أحمد'),
        excel_pkg.TextCellValue('1234567890'),
        excel_pkg.TextCellValue('31/12/2026'),
      ]);

      final bytes = workbook.encode();
      if (bytes == null || bytes.isEmpty) {
        throw Exception('تعذر إنشاء نموذج Excel.');
      }

      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'حفظ نموذج Excel',
        fileName: 'Employees_Template.xlsx',
        bytes: Uint8List.fromList(bytes),
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (!mounted || savedPath == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ نموذج Excel بنجاح.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تنزيل النموذج: $e')),
      );
    }
  }

  Widget _buildProgress() {
    return Column(
      children: [
        const SizedBox(height: 8),
        const Text('جاري استيراد الموظفين', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: navy)),
        const SizedBox(height: 3),
        const Text('يرجى عدم إغلاق التطبيق حتى اكتمال العملية', style: TextStyle(fontSize: 10.5, color: Color(0xff64748B))),
        const SizedBox(height: 5),
        ImportProgressView(progress: _progress),
      ],
    );
  }

  Widget _buildSuccess() {
    final result = _result!;
    return Column(
      children: [
        const SizedBox(height: 5),
        SizedBox(
          height: 190,
          child: CustomPaint(
            painter: _SuccessRingsPainter(),
            child: const Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: blue,
                child: Icon(LucideIcons.check, color: Colors.white, size: 54),
              ),
            ),
          ),
        ),
        const Text('تم الاستيراد بنجاح', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: navy), textAlign: TextAlign.center),
        const SizedBox(height: 4),
        const Text('تمت إضافة بيانات الموظفين إلى النظام', style: TextStyle(fontSize: 12, color: Color(0xff64748B))),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _statCard(icon: LucideIcons.circleX, value: '${result.skippedCount}', label: 'تم تجاهلهم', color: red)),
            const SizedBox(width: 8),
            Expanded(child: _statCard(icon: LucideIcons.userPlus, value: '${result.importedCount}', label: 'تمت إضافتهم', color: blue)),
            const SizedBox(width: 8),
            Expanded(child: _statCard(icon: LucideIcons.fileText, value: '${result.totalRecords}', label: 'إجمالي السجلات', color: blue)),
          ],
        ),
        const SizedBox(height: 10),
        _buildNotes(result),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 45,
          child: FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(LucideIcons.list, size: 18),
            label: const Text('عرض الموظفين', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
            style: FilledButton.styleFrom(backgroundColor: blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 45,
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _file = null; _result = null; _error = null;
                _progress = const ImportProgress(progress: 0, stage: 'قراءة الملف');
              });
            },
            icon: const Icon(LucideIcons.history, size: 18),
            label: const Text('استيراد ملف آخر', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
            style: OutlinedButton.styleFrom(foregroundColor: navy, side: const BorderSide(color: Color(0xffCBD5E1)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
          ),
        ),
      ],
    );
  }

  Widget _statCard({required IconData icon, required String value, required String label, required Color color}) {
    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xffE1E9F5))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 1),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9.5, color: Color(0xff64748B), fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildNotes(EmployeeImportResult result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xffEFF6FF), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xffBFDBFE))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Row(textDirection: TextDirection.rtl, children: [Icon(LucideIcons.info, color: blue, size: 17), SizedBox(width: 6), Text('ملاحظات', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: blue))]),
          const SizedBox(height: 5),
          Text('تمت إضافة ${result.importedCount} موظف جديد إلى النظام.', textAlign: TextAlign.right, style: const TextStyle(fontSize: 9.5, height: 1.6, color: Color(0xff475569))),
          if (result.skippedCount > 0)
            Text('تم تجاهل ${result.skippedCount} سجل مكرر بناءً على رقم الهوية أو الاسم.', textAlign: TextAlign.right, style: const TextStyle(fontSize: 9.5, height: 1.6, color: Color(0xff475569))),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(color: const Color(0xffFEF2F2), borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xffFECACA))),
      child: Row(textDirection: TextDirection.rtl, children: [
        const Icon(LucideIcons.circleAlert, color: red, size: 18),
        const SizedBox(width: 7),
        Expanded(child: Text(_error!, textAlign: TextAlign.right, style: const TextStyle(fontSize: 10, height: 1.5, color: Color(0xff991B1B), fontWeight: FontWeight.w700))),
      ]),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _ExcelIcon extends StatelessWidget {
  const _ExcelIcon();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 22,
          height: 25,
          decoration: BoxDecoration(
            color: const Color(0xff16A34A),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Positioned(
          left: 4,
          child: Container(
            width: 11,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.95),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
        const Text(
          'X',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _FallbackHero extends StatelessWidget {
  const _FallbackHero();
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HeroPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _HeroPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = math.min(size.width, size.height) * .28;
    final ring = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.1..color = const Color(0xffBFDBFE);
    for (var i = 0; i < 3; i++) canvas.drawCircle(c, r + i * 28, ring);
    final sheet = Path()
      ..moveTo(c.dx - 42, c.dy - 55)..lineTo(c.dx + 25, c.dy - 55)..lineTo(c.dx + 45, c.dy - 35)..lineTo(c.dx + 45, c.dy + 62)..lineTo(c.dx - 42, c.dy + 62)..close();
    canvas.drawPath(sheet, Paint()..color = const Color(0xffDCE9FF));
    canvas.drawPath(sheet, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = const Color(0xff8DB7FF));
    canvas.drawRect(Rect.fromCenter(center: Offset(c.dx - 8, c.dy + 5), width: 44, height: 40), Paint()..color = const Color(0xff16A34A));
    final text = TextPainter(text: const TextSpan(text: 'X', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)), textDirection: TextDirection.ltr)..layout();
    text.paint(canvas, Offset(c.dx - 22, c.dy - 13));
    final cloud = Paint()..color = const Color(0xff2563EB)..style = PaintingStyle.stroke..strokeWidth = 4;
    canvas.drawArc(Rect.fromCircle(center: Offset(c.dx - 54, c.dy + 47), radius: 16), math.pi * .15, math.pi * 1.55, false, cloud);
    canvas.drawLine(Offset(c.dx - 60, c.dy + 55), Offset(c.dx - 54, c.dy + 47), cloud);
    canvas.drawLine(Offset(c.dx - 54, c.dy + 47), Offset(c.dx - 47, c.dy + 55), cloud);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SuccessRingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final base = math.min(size.width, size.height);
    final ring = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.0..color = const Color(0xffC7DBFA).withOpacity(.72);
    for (int i = 0; i < 4; i++) canvas.drawCircle(center, base * (.20 + i * .075), ring);
    final dotPaint = Paint()..color = const Color(0xff60A5FA);
    final points = [
      Offset(center.dx - base * .29, center.dy - base * .19), Offset(center.dx + base * .29, center.dy - base * .23),
      Offset(center.dx + base * .35, center.dy + base * .04), Offset(center.dx - base * .34, center.dy + base * .10), Offset(center.dx + base * .18, center.dy + base * .27),
    ];
    for (final point in points) canvas.drawCircle(point, 3.8, dotPaint);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
