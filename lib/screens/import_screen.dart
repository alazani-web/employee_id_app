import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/employee.dart';
import '../providers/employee_provider.dart';
import '../services/import_service.dart';
import '../widgets/import_progress_view.dart';
import '../widgets/top_message.dart';

enum ImportMode { employees, visits }

class VisitImportResult {
  final String fileName;
  final int totalRecords;
  final int importedCount;
  final int rejectedCount;

  const VisitImportResult({
    required this.fileName,
    required this.totalRecords,
    required this.importedCount,
    required this.rejectedCount,
  });
}

class ImportScreen extends StatefulWidget {
  final ImportMode mode;
  final Future<VisitImportResult> Function(BuildContext context, PlatformFile file, ImportProgressCallback onProgress)? onVisitImport;
  final Future<void> Function()? onDownloadTemplate;
  final String? templateDescription;

  const ImportScreen({
    super.key,
    this.mode = ImportMode.employees,
    this.onVisitImport,
    this.onDownloadTemplate,
    this.templateDescription,
  });

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
  VisitImportResult? _visitResult;
  ImportProgress _progress = const ImportProgress(progress: 0, stage: 'قراءة الملف');
  String? _error;

  Future<void> _pickFile() async {
    if (_isImporting) return;
    setState(() { _error = null; _result = null; _visitResult = null; });

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

    // الزيارات تستخدم نفس الواجهة والتقدم والنتيجة، لكن منطق البيانات يبقى مستقلًا.
    if (widget.mode == ImportMode.visits) {
      final callback = widget.onVisitImport;
      if (callback == null) {
        setState(() => _error = 'تعذر تشغيل استيراد الزيارات.');
        return;
      }

      setState(() {
        _isImporting = true;
        _result = null;
        _visitResult = null;
        _error = null;
        _progress = const ImportProgress(progress: 0, stage: 'قراءة الملف');
      });

      try {
        final result = await callback(
          context,
          file,
          (progress) {
            if (!mounted) return;
            setState(() => _progress = progress);
          },
        );

        // نبقي شاشة اكتمال الاستيراد ظاهرة لحظة قصيرة حتى تكون
        // النتيجة انتقالًا واضحًا وليست قفزة مفاجئة.
        await Future<void>.delayed(const Duration(milliseconds: 350));

        if (!mounted) return;
        setState(() {
          _visitResult = result;
          _isImporting = false;
          _progress = ImportProgress(
            progress: 1,
            stage: 'اكتمل الاستيراد',
            processed: result.totalRecords,
            total: result.totalRecords,
            imported: result.importedCount,
            skipped: result.rejectedCount,
          );
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isImporting = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
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

      await Future<void>.delayed(const Duration(milliseconds: 350));

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
                          duration: const Duration(milliseconds: 700),
                          reverseDuration: const Duration(milliseconds: 350),
                          child: _isImporting
                              ? _buildProgress()
                              : (_result != null || _visitResult != null)
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
              widget.mode == ImportMode.visits ? 'استيراد الزيارات' : 'استيراد الموظفين',
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
        const SizedBox(height: 4),
        SizedBox(
          height: 170,
          width: double.infinity,
          child: Image.asset(
            'assets/icons/import_employees_hero.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const _FallbackHero(),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          widget.mode == ImportMode.visits
              ? 'استيراد بيانات الزيارات'
              : 'استيراد بيانات الموظفين',
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w900,
            color: navy,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          widget.mode == ImportMode.visits
              ? 'يمكنك استيراد بيانات الزيارات من ملف Excel بسهولة وسرعة\nيرجى استخدام النموذج المرفق لضمان توافق البيانات'
              : 'يمكنك استيراد بيانات الموظفين من ملف Excel بسهولة وسرعة\nيرجى استخدام النموذج المرفق لضمان توافق البيانات',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11.5,
            height: 1.55,
            color: Color(0xff64748B),
          ),
        ),
        const SizedBox(height: 11),
        _buildDropZone(),
        if (_file != null) ...[
          const SizedBox(height: 9),
          _buildFileCard(),
        ],
        const SizedBox(height: 8),
        _buildTemplateCard(),
        if (_error != null) ...[
          const SizedBox(height: 9),
          _buildError(),
        ],
        const SizedBox(height: 11),
        SizedBox(
          width: double.infinity,
          height: 47,
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .58),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xff9FC3FF), width: 1.1),
        ),
        child: const Column(
          children: [
            Icon(LucideIcons.cloudUpload, size: 42, color: blue),
            SizedBox(height: 8),
            Text('اختر ملف Excel هنا', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: navy)),
            SizedBox(height: 3),
            Text('أو اسحب الملف إلى هنا', style: TextStyle(fontSize: 11, color: Color(0xff64748B))),
            SizedBox(height: 2),
            Text('(XLSX أو XLS)', style: TextStyle(fontSize: 10, color: Color(0xff94A3B8))),
          ],
        ),
      ),
    );
  }

  Widget _buildFileCard() {
    final file = _file!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xffDCE7F7))),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: const Color(0xffDCFCE7), borderRadius: BorderRadius.circular(10)),
            child: const Icon(LucideIcons.fileSpreadsheet, color: green, size: 21),
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
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(color: const Color(0xffEFF6FF), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xffBFDBFE))),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          const Icon(LucideIcons.info, color: blue, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.templateDescription ??
                  (widget.mode == ImportMode.visits
                      ? 'يجب أن يحتوي الملف على بيانات الزيارة وتواريخ الانتهاء المطلوبة.'
                      : 'يجب أن يحتوي الملف على اسم الموظف، رقم الهوية/الإقامة، وتاريخ انتهاء الهوية.'),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 10.5, height: 1.55, color: Color(0xff334155)),
            ),
          ),
          const SizedBox(width: 7),
          InkWell(
            onTap: () async {
              if (widget.onDownloadTemplate != null) {
                await widget.onDownloadTemplate!();
              } else {
                await _downloadTemplate();
              }
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: const Color(0xffDBEAFE), borderRadius: BorderRadius.circular(10)),
              child: const Icon(LucideIcons.download, color: blue, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadTemplate() async {
    if (_isImporting || !mounted) return;

    try {
      if (widget.onDownloadTemplate != null) {
        await widget.onDownloadTemplate!();
        return;
      }

      final workbook = excel_lib.Excel.createExcel();
      final sheetName = workbook.getDefaultSheet() ?? 'Sheet1';
      final sheet = workbook[sheetName];

      sheet.appendRow([
        excel_lib.TextCellValue('اسم الموظف'),
        excel_lib.TextCellValue('رقم الهوية/الإقامة'),
        excel_lib.TextCellValue('تاريخ انتهاء الهوية'),
      ]);

      // صف مثال واضح للمستخدم، ويمكن حذفه قبل الاستيراد.
      sheet.appendRow([
        excel_lib.TextCellValue('مثال: أحمد محمد'),
        excel_lib.TextCellValue('1234567890'),
        excel_lib.TextCellValue('2027-01-01'),
      ]);

      final bytes = workbook.encode();
      if (bytes == null || bytes.isEmpty) {
        throw Exception('تعذر إنشاء قالب Excel.');
      }

      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'حفظ قالب الموظفين',
        fileName: 'قالب_استيراد_الموظفين.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        bytes: Uint8List.fromList(bytes),
      );

      if (!mounted) return;

      if (savedPath == null || savedPath.isEmpty) {
        TopMessage.show(
          context,
          'تم إلغاء حفظ القالب',
          type: TopMessageType.info,
        );
      } else {
        TopMessage.show(
          context,
          'تم حفظ قالب الموظفين بنجاح',
        );
      }
    } catch (e) {
      if (!mounted) return;
      TopMessage.show(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        type: TopMessageType.error,
      );
    }
  }

  Widget _buildProgress() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Text(widget.mode == ImportMode.visits ? 'جاري استيراد الزيارات' : 'جاري استيراد الموظفين', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: navy)),
        const SizedBox(height: 3),
        const Text('يرجى عدم إغلاق التطبيق حتى اكتمال العملية', style: TextStyle(fontSize: 10.5, color: Color(0xff64748B))),
        const SizedBox(height: 5),
        ImportProgressView(progress: _progress),
      ],
    );
  }

  Widget _buildSuccess() {
    if (widget.mode == ImportMode.visits && _visitResult != null) {
      return _buildVisitSuccess(_visitResult!);
    }

    final result = _result!;
    return Column(
      children: [
        const SizedBox(height: 2),
        _buildSuccessVisual(),
        const Text(
          'تم الاستيراد بنجاح',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w900,
            color: navy,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        const Text(
          'تمت إضافة بيانات الموظفين إلى النظام',
          style: TextStyle(fontSize: 12, color: Color(0xff64748B)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _statCard(
                icon: LucideIcons.circleX,
                value: '${result.skippedCount}',
                label: 'تم تجاهلهم',
                color: red,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statCard(
                icon: LucideIcons.userPlus,
                value: '${result.importedCount}',
                label: 'تمت إضافتهم',
                color: blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statCard(
                icon: LucideIcons.fileText,
                value: '${result.totalRecords}',
                label: 'إجمالي السجلات',
                color: blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildNotes(result),
        const SizedBox(height: 10),
        _buildActionButtons('الموظفين'),
      ],
    );
  }

  Widget _buildVisitSuccess(VisitImportResult result) {
    return Column(
      children: [
        const SizedBox(height: 2),
        _buildSuccessVisual(),
        const Text(
          'تم استيراد الزيارات بنجاح',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w900,
            color: navy,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        const Text(
          'تمت إضافة بيانات الزيارات إلى النظام',
          style: TextStyle(fontSize: 12, color: Color(0xff64748B)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _statCard(
                icon: LucideIcons.circleX,
                value: '${result.rejectedCount}',
                label: 'تم رفضهم',
                color: red,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statCard(
                icon: LucideIcons.userPlus,
                value: '${result.importedCount}',
                label: 'تم قبولهم',
                color: blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statCard(
                icon: LucideIcons.fileText,
                value: '${result.totalRecords}',
                label: 'إجمالي الزيارات',
                color: blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildVisitNotes(result),
        const SizedBox(height: 10),
        _buildActionButtons('الزيارات'),
      ],
    );
  }

  /// صورة الخلفية النهائية التي تحتوي على الحلقات والنقاط.
  /// علامة الصح توضع فوقها حتى يبقى مركز الصورة واضحًا ونظيفًا.
  Widget _buildSuccessVisual() {
    return SizedBox(
      width: double.infinity,
      height: 190,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/icons/import_success_background.png',
            width: double.infinity,
            height: 190,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
          Container(
            width: 82,
            height: 82,
            decoration: const BoxDecoration(
              color: blue,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              LucideIcons.check,
              color: Colors.white,
              size: 52,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String label) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 45,
          child: FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(LucideIcons.list, size: 18),
            label: Text('عرض $label', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
            style: FilledButton.styleFrom(
              backgroundColor: blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 45,
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _file = null;
                _result = null;
                _visitResult = null;
                _error = null;
                _progress = const ImportProgress(progress: 0, stage: 'قراءة الملف');
              });
            },
            icon: const Icon(LucideIcons.history, size: 18),
            label: const Text('استيراد ملف آخر', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
            style: OutlinedButton.styleFrom(
              foregroundColor: navy,
              side: const BorderSide(color: Color(0xffCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisitNotes(VisitImportResult result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xffEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(LucideIcons.info, color: blue, size: 17),
              SizedBox(width: 6),
              Text('ملاحظات', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: blue)),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'تم قبول ${result.importedCount} زيارة وإضافتها إلى النظام.',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 9.5, height: 1.6, color: Color(0xff475569)),
          ),
          if (result.rejectedCount > 0)
            Text(
              'تم رفض ${result.rejectedCount} سجل بسبب التكرار أو عدم اكتمال البيانات.',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 9.5, height: 1.6, color: Color(0xff475569)),
            ),
        ],
      ),
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

class _FallbackHero extends StatelessWidget {
  const _FallbackHero();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        LucideIcons.fileSpreadsheet,
        color: Color(0xff2563EB),
        size: 72,
      ),
    );
  }
}
