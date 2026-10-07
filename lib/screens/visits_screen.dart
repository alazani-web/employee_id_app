import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import 'package:excel/excel.dart' as excel_lib;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../widgets/action_sheet.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:universal_html/universal_html.dart' as html;

import '../models/visit.dart';
import '../providers/visit_provider.dart';
import '../widgets/app_date_picker.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/action_result_dialog.dart';
import '../widgets/renewal_dialog.dart';
import '../utils/family_visit_calculator.dart';
import '../services/import_service.dart';
import 'import_screen.dart';

class VisitsScreen extends StatefulWidget {
  const VisitsScreen({super.key});

  @override
  State<VisitsScreen> createState() => _VisitsScreenState();
}

enum _NoticeType { success, warning, error, info }

class _VisitsScreenState extends State<VisitsScreen> {
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color purple = Color(0xFF7C3AED);
  static const Color purpleDark = Color(0xFF6D28D9);
  static const Color dark = Color(0xFF111827);
  static const Color pageBg = Color(0xFFF7F8FC);

  final TextEditingController searchController = TextEditingController();
  int selectedFilter = 0;

  final List<String> filters = const [
    'الكل',
    'نشط',
    'تنتهي قريباً',
    'منتهي',
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  DateTime? _parseDate(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;

    final iso = DateTime.tryParse(text);
    if (iso != null) return iso;

    final parts = text.replaceAll('/', '-').split('-');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime.tryParse(
          '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
        );
      }
    }
    return null;
  }

  String _date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _displayDate(String value) {
    final d = _parseDate(value);
    if (d == null) return value.isEmpty ? '-' : value;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  int? _daysRemaining(String value) {
    final d = _parseDate(value);
    if (d == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    return target.difference(today).inDays;
  }

  String _statusLabel(String value) {
    final days = _daysRemaining(value);
    if (days == null) return 'سارية';
    if (days < 0) return 'منتهية';
    if (days <= 30) return 'تحتاج متابعة';
    return 'سارية';
  }

  Color _statusColor(String status) {
    if (status == 'منتهية') return const Color(0xFFB94A43);
    if (status == 'تحتاج متابعة') return const Color(0xFFB7791F);
    return const Color(0xFF237A43);
  }

  Color _statusBackground(String status) {
    if (status == 'منتهية') return const Color(0xFFFBE5E2);
    if (status == 'تحتاج متابعة') return const Color(0xFFFFF1D6);
    return const Color(0xFFDFF7E8);
  }

  List<Visit> _filteredVisits(List<Visit> visits) {
    final query = searchController.text.trim().toLowerCase();

    final result = visits.where((visit) {
      final matchesSearch =
          query.isEmpty ||
          visit.visitorName.toLowerCase().contains(query) ||
          visit.passportNumber.toLowerCase().contains(query) ||
          visit.visaNumber.toLowerCase().contains(query) ||
          visit.borderNumber.toLowerCase().contains(query) ||
          visit.notes.toLowerCase().contains(query);

      if (!matchesSearch) return false;

      final status = _statusLabel(visit.expiryDate);
      switch (selectedFilter) {
        case 1:
          return status == 'سارية';
        case 2:
          return status == 'تحتاج متابعة';
        case 3:
          return status == 'منتهية';
        default:
          return true;
      }
    }).toList();

    // ترتيب الزيارات حسب المدة المتبقية: الأقل أولاً.
    // الزيارة المنتهية (الأيام السالبة) تظهر قبل الزيارات الأطول مدة.
    result.sort((a, b) {
      final aDays = _daysRemaining(a.expiryDate);
      final bDays = _daysRemaining(b.expiryDate);

      if (aDays == null && bDays == null) {
        return a.visitorName.compareTo(b.visitorName);
      }
      if (aDays == null) return 1;
      if (bDays == null) return -1;

      final byDays = aDays.compareTo(bDays);
      if (byDays != 0) return byDays;

      return a.visitorName.compareTo(b.visitorName);
    });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VisitProvider>();
    final visits = _filteredVisits(provider.visits);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: pageBg,
        body: Column(
          children: [
            const SizedBox(height: 15),
            _buildSearch(),
            const SizedBox(height: 12),
            _buildFilters(),
            const SizedBox(height: 10),
            _buildListHeader(),
            const SizedBox(height: 1),
            Expanded(
              child: visits.isEmpty
                  ? _emptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 90),
                      itemCount: visits.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 1),
                      itemBuilder: (context, index) =>
                          _buildVisitRow(context, visits[index]),
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showOperations(context),
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 31),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }


  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: TextField(
          controller: searchController,
          onChanged: (_) => setState(() {}),
          textAlign: TextAlign.right,
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'البحث بالاسم أو رقم الحدود أو التأشيرة...',
            hintStyle: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 13,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Color(0xFF9CA3AF),
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(filters.length, (index) {
          final active = selectedFilter == index;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: index == filters.length - 1 ? 0 : 7,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => setState(() => selectedFilter = index),
                child: Container(
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active ? primaryBlue : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: active
                          ? primaryBlue
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Text(
                    filters[index],
                    style: TextStyle(
                      color: active ? Colors.white : dark,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }


  Widget _buildListHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      color: const Color(0xFFF7F8FC),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  'الحالة',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.center,
                child: const Text(
                  'رقم الحدود',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: const Text(
                  'اسم الزائر',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.flight_outlined,
              color: purple,
              size: 35,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'لا توجد زيارات مسجلة',
            style: TextStyle(
              color: dark,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'اضغط + لإضافة زيارة جديدة أو استيراد ملف',
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildVisitRow(BuildContext context, Visit visit) {
    final status = _statusLabel(visit.expiryDate);
    final days = _daysRemaining(visit.expiryDate);
    final statusColor = _statusColor(status);
    final statusBg = _statusBackground(status);

    final daysText = days == null
        ? ''
        : days < 0
            ? 'متأخرة ${days.abs()} يوم'
            : days == 0
                ? 'تنتهي اليوم'
                : 'متبقي $days يوم';

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: null,
        onLongPress: () => _showActions(context, visit),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(15)),
                          child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w500)),
                        ),
                      ),
                      if (daysText.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(daysText, textAlign: TextAlign.left,
                          style: const TextStyle(color: dark, fontSize: 9.5, fontWeight: FontWeight.w400)),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Text(visit.borderNumber.isEmpty ? '-' : visit.borderNumber,
                        maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                        style: const TextStyle(color: dark, fontSize: 12.5, fontWeight: FontWeight.w400)),
                      const SizedBox(height: 4),
                      const Text('رقم الحدود',
                        style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 9, fontWeight: FontWeight.w400)),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              visit.visitorName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: dark,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              _displayDate(visit.expiryDate),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Future<void> _showOperations(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: Colors.white,
            elevation: 10,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 350),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(
                            Icons.close,
                            color: Color(0xFF9CA3AF),
                            size: 20,
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'اختر العملية',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: dark,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _operationListCard(
                      title: 'إضافة زيارة',
                      subtitle: 'إضافة زيارة عائلية جديدة',
                      color: purple,
                      background: const Color(0xFFF8F3FF),
                      assetIcon: 'assets/icons/plane.svg',
                      onTap: () {
                        Navigator.pop(dialogContext);
                        _showAddVisit(context);
                      },
                    ),
                    const SizedBox(height: 8),

                    _operationListCard(
                      title: 'استيراد زيارات',
                      subtitle: 'استيراد زيارات من ملف Excel أو CSV',
                      color: primaryBlue,
                      background: const Color(0xFFF3F7FF),
                      icon: Icons.file_upload_outlined,
                      onTap: () {
                        Navigator.pop(dialogContext);
                        _showImportDialog(context);
                      },
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                        child: const Text(
                          'إغلاق',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _operationListCard({
    required String title,
    required String subtitle,
    required Color color,
    required Color background,
    required VoidCallback onTap,
    IconData? icon,
    String? assetIcon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: double.infinity,
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFE7EDF5)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(11),
              ),
              alignment: Alignment.center,
              child: assetIcon != null
                  ? SvgPicture.asset(
                      assetIcon,
                      width: 21,
                      height: 21,
                      colorFilter: ColorFilter.mode(
                        color,
                        BlendMode.srcIn,
                      ),
                    )
                  : Icon(
                      icon,
                      color: color,
                      size: 21,
                    ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: dark,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _pickDate(
    BuildContext context, {
    String? initial,
  }) async {
    try {
      final parsed = _parseDateSafe(initial ?? '');
      final value = await AppDatePicker.show(
        context,
        initialDate: parsed ?? DateTime.now(),
      );
      return value?.trim();
    } catch (e, stackTrace) {
      debugPrint('VISIT DATE PICKER ERROR: $e');
      debugPrint(stackTrace.toString());
      return null;
    }
  }

  DateTime? _parseDateSafe(String value) {
    var text = value.trim();
    if (text.isEmpty) return null;

    const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
    const westernDigits = '0123456789';
    for (int i = 0; i < arabicDigits.length; i++) {
      text = text.replaceAll(arabicDigits[i], westernDigits[i]);
    }

    text = text.replaceAll('/', '-');
    if (text.contains('T')) text = text.split('T').first;
    if (text.contains(' ')) text = text.split(' ').first;

    final iso = DateTime.tryParse(text);
    if (iso != null) {
      return DateTime(iso.year, iso.month, iso.day);
    }

    final parts = text.split('-');
    if (parts.length == 3) {
      int? first = int.tryParse(parts[0]);
      int? second = int.tryParse(parts[1]);
      int? third = int.tryParse(parts[2]);

      if (first != null && second != null && third != null) {
        // dd-MM-yyyy
        if (third >= 1000) {
          final result = DateTime.tryParse(
            '${third.toString().padLeft(4, '0')}-'
            '${second.toString().padLeft(2, '0')}-'
            '${first.toString().padLeft(2, '0')}',
          );
          if (result != null) {
            return DateTime(result.year, result.month, result.day);
          }
        }

        // yyyy-MM-dd
        if (first >= 1000) {
          final result = DateTime.tryParse(
            '${first.toString().padLeft(4, '0')}-'
            '${second.toString().padLeft(2, '0')}-'
            '${third.toString().padLeft(2, '0')}',
          );
          if (result != null) {
            return DateTime(result.year, result.month, result.day);
          }
        }
      }
    }

    return null;
  }

  InputDecoration _inputStyle(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFFA1A1AA),
        fontSize: 13,
      ),
      suffixIcon: icon == null
          ? null
          : Icon(icon, color: const Color(0xFF9CA3AF), size: 21),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: purple, width: 1.5),
      ),
    );
  }

  Widget _field(
    String hint,
    TextEditingController controller, {
    IconData? icon,
    bool readOnly = false,
    VoidCallback? onTap,
    int maxLines = 1,
    bool digitsOnly = false,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      textAlign: TextAlign.right,
      keyboardType: digitsOnly ? TextInputType.number : TextInputType.text,
      inputFormatters: digitsOnly
          ? <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly]
          : null,
      decoration: _inputStyle(hint, icon: icon),
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Future<void> _showAddVisit(BuildContext context) async {
    final name = TextEditingController();
    final passport = TextEditingController();
    final visa = TextEditingController();
    final border = TextEditingController();
    final expiry = TextEditingController();
    final insurance = TextEditingController();
    final notes = TextEditingController();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 650,
                maxHeight: MediaQuery.sizeOf(context).height * .90,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.flight_outlined,
                          color: purple,
                          size: 29,
                        ),
                        const SizedBox(width: 9),
                        const Expanded(
                          child: Text(
                            'إضافة زيارة عائلية جديدة',
                            style: TextStyle(
                              color: dark,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(
                            Icons.close,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 22),
                    _section(
                      title: 'معلومات الزائر',
                      icon: Icons.person_outline,
                      color: purpleDark,
                      children: [
                        _field(
                          'اسم الزائر',
                          name,
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 10),
                        _field(
                          'رقم الجواز',
                          passport,
                          icon: Icons.badge_outlined,
                          digitsOnly: true,
                        ),
                        const SizedBox(height: 10),
                        _field(
                          'رقم التأشيرة',
                          visa,
                          icon: Icons.confirmation_number_outlined,
                          digitsOnly: true,
                        ),
                        const SizedBox(height: 10),
                        _field(
                          'رقم الحدود',
                          border,
                          icon: Icons.pin_outlined,
                          digitsOnly: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _section(
                      title: 'تواريخ الانتهاء',
                      icon: Icons.calendar_month_outlined,
                      color: primaryBlue,
                      children: [
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'تاريخ انتهاء الزيارة *',
                            style: TextStyle(
                              color: dark,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        _field(
                          'DD-MM-YYYY',
                          expiry,
                          icon: Icons.calendar_month_outlined,
                          readOnly: true,
                          onTap: () async {
                            final value = await _pickDate(
                              context,
                              initial: expiry.text,
                            );
                            if (value != null) expiry.text = value;
                          },
                        ),
                        const SizedBox(height: 12),
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'تاريخ انتهاء التأمين *',
                            style: TextStyle(
                              color: dark,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        _field(
                          'DD-MM-YYYY',
                          insurance,
                          icon: Icons.calendar_month_outlined,
                          readOnly: true,
                          onTap: () async {
                            final value = await _pickDate(
                              context,
                              initial: insurance.text,
                            );
                            if (value != null) insurance.text = value;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _section(
                      title: 'ملاحظات',
                      icon: Icons.notes_outlined,
                      color: purple,
                      children: [
                        _field(
                          'ملاحظات اختيارية...',
                          notes,
                          maxLines: 3,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _button(
                            'إلغاء',
                            const Color(0xFF374151),
                            () => Navigator.pop(dialogContext),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _button(
                            'إضافة الزيارة',
                            purple,
                            () async {
                              final visitorName = name.text.trim();
                              final passportNumber = passport.text.trim();
                              final visaNumber = visa.text.trim();
                              final borderNumber = border.text.trim();

                              if (visitorName.isEmpty ||
                                  expiry.text.trim().isEmpty ||
                                  insurance.text.trim().isEmpty) {
                                _showNotice(
                                  context,
                                  title: 'بيانات ناقصة',
                                  message:
                                      'يرجى إدخال اسم الزائر وتاريخ انتهاء الزيارة والتأمين.',
                                  type: _NoticeType.warning,
                                );
                                return;
                              }

                              final provider = context.read<VisitProvider>();

                              String normalizeIdentifier(String value) {
                                var result = value.trim();
                                const arabic = '٠١٢٣٤٥٦٧٨٩';
                                const western = '0123456789';
                                for (int i = 0; i < arabic.length; i++) {
                                  result = result.replaceAll(arabic[i], western[i]);
                                }
                                return result.replaceAll(RegExp(r'[\s\-_/+,]+'), '');
                              }

                              String normalizeName(String value) {
                                return value
                                    .trim()
                                    .toLowerCase()
                                    .replaceAll(RegExp(r'\s+'), '')
                                    .replaceAll('أ', 'ا')
                                    .replaceAll('إ', 'ا')
                                    .replaceAll('آ', 'ا')
                                    .replaceAll('ة', 'ه');
                              }

                              final passportKey = normalizeIdentifier(passportNumber);
                              final visaKey = normalizeIdentifier(visaNumber);
                              final borderKey = normalizeIdentifier(borderNumber);
                              final nameKey = normalizeName(visitorName);

                              final duplicate = provider.visits.any((v) {
                                final samePassport = passportKey.isNotEmpty &&
                                    passportKey == normalizeIdentifier(v.passportNumber);
                                final sameVisa = visaKey.isNotEmpty &&
                                    visaKey == normalizeIdentifier(v.visaNumber);
                                final sameBorder = borderKey.isNotEmpty &&
                                    borderKey == normalizeIdentifier(v.borderNumber);

                                final existingName = normalizeName(v.visitorName);
                                final noIdentifiersEntered =
                                    passportKey.isEmpty &&
                                    visaKey.isEmpty &&
                                    borderKey.isEmpty;
                                final noExistingIdentifiers =
                                    normalizeIdentifier(v.passportNumber).isEmpty &&
                                    normalizeIdentifier(v.visaNumber).isEmpty &&
                                    normalizeIdentifier(v.borderNumber).isEmpty;

                                return samePassport ||
                                    sameVisa ||
                                    sameBorder ||
                                    (noIdentifiersEntered &&
                                        noExistingIdentifiers &&
                                        nameKey.isNotEmpty &&
                                        nameKey == existingName);
                              });

                              if (duplicate) {
                                if (!context.mounted) return;
                                await showDialog<void>(
                                  context: context,
                                  builder: (noticeContext) => Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      title: const Text(
                                        'الزيارة مكررة',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      content: const Text(
                                        'هذا الشخص مسجل مسبقًا في قائمة الزيارات.',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(noticeContext),
                                          child: const Text('حسنًا'),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                                return;
                              }

                              await provider.addVisit(
                                Visit(
                                  id: DateTime.now()
                                      .microsecondsSinceEpoch
                                      .toString(),
                                  visitorName: visitorName,
                                  passportNumber: passport.text.trim(),
                                  visaNumber: visaNumber,
                                  borderNumber: borderNumber,
                                  expiryDate: expiry.text.trim(),
                                  insuranceExpiryDate:
                                      insurance.text.trim(),
                                  notes: notes.text.trim(),
                                  status: 'سارية',
                                ),
                              );

                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }
                              if (!context.mounted) return;
                              _showNotice(
                                context,
                                title: 'تمت إضافة الزيارة',
                                message: 'تم تسجيل الزيارة بنجاح.',
                                type: _NoticeType.success,
                              );
                            },
                            icon: Icons.save_outlined,
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
      },
    );

    name.dispose();
    passport.dispose();
    visa.dispose();
    border.dispose();
    expiry.dispose();
    insurance.dispose();
    notes.dispose();
  }

  Widget _button(
    String text,
    Color color,
    VoidCallback onPressed, {
    IconData? icon,
  }) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 19),
        label: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  void _showActions(BuildContext context, Visit visit) {
    ActionSheet.show(
      context,
      title: 'إجراءات الزيارة',
      subtitle: visit.visitorName,
      headerIcon: Icons.edit_note_rounded,
      actions: [
        ActionSheetItem(
          label: 'تعديل',
          icon: Icons.edit_outlined,
          iconColor: primaryBlue,
          backgroundColor: const Color(0xFFEFF6FF),
          onTap: () => _showEditVisit(context, visit),
        ),
        ActionSheetItem(
          label: 'السجل',
          icon: Icons.history_rounded,
          iconColor: purple,
          backgroundColor: const Color(0xFFF5F3FF),
          onTap: () => _showLogs(context, visit),
        ),
        ActionSheetItem(
          label: 'حذف',
          icon: Icons.delete_outline_rounded,
          iconColor: const Color(0xFFDC2626),
          backgroundColor: const Color(0xFFFEF2F2),
          onTap: () => _confirmDelete(context, visit),
        ),
        ActionSheetItem(
          label: 'تجديد',
          icon: Icons.autorenew_rounded,
          iconColor: const Color(0xFF16A34A),
          backgroundColor: const Color(0xFFF0FDF4),
          onTap: () => _showRenewVisit(context, visit),
        ),
      ],
    );
  }


  Future<void> _showEditVisit(BuildContext context, Visit visit) async {
    final name = TextEditingController(text: visit.visitorName);
    final passport = TextEditingController(text: visit.passportNumber);
    final visa = TextEditingController(text: visit.visaNumber);
    final border = TextEditingController(text: visit.borderNumber);
    final expiry = TextEditingController(text: visit.expiryDate);
    final insurance = TextEditingController(text: visit.insuranceExpiryDate);
    final notes = TextEditingController(text: visit.notes);

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 35,
                vertical: 35,
              ),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 410,
                  maxHeight: MediaQuery.sizeOf(dialogContext).height * .72,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F3FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.edit_outlined,
                              color: purple,
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 9),
                          const Expanded(
                            child: Text(
                              'تعديل بيانات الزيارة',
                              style: TextStyle(
                                color: dark,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            onPressed: () => Navigator.pop(dialogContext),
                            icon: const Icon(
                              Icons.close,
                              color: Color(0xFF6B7280),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      const SizedBox(height: 10),

                      // معلومات الزائر — بحجم مضغوط حتى لا تكون نافذة التعديل كبيرة.
                      _sectionCompact(
                        title: 'معلومات الزائر',
                        icon: Icons.person_outline,
                        color: purpleDark,
                        children: [
                          _fieldCompact('اسم الزائر', name),
                          const SizedBox(height: 7),
                          _fieldCompact('رقم الجواز', passport, digitsOnly: true),
                          const SizedBox(height: 7),
                          _fieldCompact('رقم التأشيرة', visa, digitsOnly: true),
                          const SizedBox(height: 7),
                          _fieldCompact('رقم الحدود', border, digitsOnly: true),
                        ],
                      ),
                      const SizedBox(height: 9),

                      // التواريخ — نستخدم dialogContext نفسه عند فتح منتقي التاريخ.
                      _sectionCompact(
                        title: 'تواريخ الانتهاء',
                        icon: Icons.calendar_month_outlined,
                        color: primaryBlue,
                        children: [
                          _fieldCompact(
                            'تاريخ انتهاء الزيارة',
                            expiry,
                            readOnly: true,
                            icon: Icons.calendar_month_outlined,
                            onTap: () async {
                              final value = await _pickDate(
                                dialogContext,
                                initial: expiry.text,
                              );
                              if (!dialogContext.mounted) return;
                              if (value != null && value.isNotEmpty) {
                                expiry.text = value;
                              }
                            },
                          ),
                          const SizedBox(height: 7),
                          _fieldCompact(
                            'تاريخ انتهاء التأمين',
                            insurance,
                            readOnly: true,
                            icon: Icons.calendar_month_outlined,
                            onTap: () async {
                              final value = await _pickDate(
                                dialogContext,
                                initial: insurance.text,
                              );
                              if (!dialogContext.mounted) return;
                              if (value != null && value.isNotEmpty) {
                                insurance.text = value;
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),

                      _fieldCompact(
                        'ملاحظات اختيارية...',
                        notes,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _buttonCompact(
                              'إلغاء',
                              const Color(0xFF374151),
                              () => Navigator.pop(dialogContext),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buttonCompact(
                              'حفظ التعديل',
                              purple,
                              () async {
                                final visitorName = name.text.trim();
                                final newExpiry = expiry.text.trim();
                                final newInsurance = insurance.text.trim();

                                if (visitorName.isEmpty ||
                                    newExpiry.isEmpty ||
                                    newInsurance.isEmpty) {
                                  _showNotice(
                                    context,
                                    title: 'بيانات ناقصة',
                                    message: 'يرجى استكمال الحقول المطلوبة.',
                                    type: _NoticeType.warning,
                                  );
                                  return;
                                }

                                final expiryDate = _parseDateSafe(newExpiry);
                                final insuranceDate = _parseDateSafe(newInsurance);

                                if (expiryDate == null || insuranceDate == null) {
                                  _showNotice(
                                    context,
                                    title: 'تاريخ غير صالح',
                                    message: 'يرجى اختيار تاريخ الانتهاء من التقويم ثم المحاولة مرة أخرى.',
                                    type: _NoticeType.warning,
                                  );
                                  return;
                                }

                                // نحفظ التاريخ بصيغة موحدة حتى لا تسبب صيغة
                                // التاريخ القادمة من التقويم مشكلة عند الحفظ
                                // أو عند جدولة الإشعارات.
                                final normalizedExpiry = _date(expiryDate);
                                final normalizedInsurance = _date(insuranceDate);

                                try {
                                  final updated = visit.copyWith(
                                    visitorName: visitorName,
                                    passportNumber: passport.text.trim(),
                                    visaNumber: visa.text.trim(),
                                    borderNumber: border.text.trim(),
                                    expiryDate: normalizedExpiry,
                                    insuranceExpiryDate: normalizedInsurance,
                                    notes: notes.text.trim(),
                                  );

                                  await context
                                      .read<VisitProvider>()
                                      .updateVisit(updated);

                                  if (!dialogContext.mounted) return;
                                  Navigator.pop(dialogContext);

                                  if (!context.mounted) return;
                                  await ActionResultDialog.show(
                                    context,
                                    type: ActionResultType.success,
                                    title: 'تم تعديل الزيارة بنجاح',
                                    name: updated.visitorName,
                                    message: 'تم حفظ التعديلات وتحديث تاريخ الانتهاء بنجاح.',
                                  );
                                } catch (e, stackTrace) {
                                  debugPrint('VISIT EDIT ERROR: $e');
                                  debugPrint(stackTrace.toString());

                                  if (!context.mounted) return;
                                  _showNotice(
                                    context,
                                    title: 'تعذر حفظ التعديل',
                                    message: 'حدث خطأ أثناء حفظ بيانات الزيارة. يرجى المحاولة مرة أخرى.',
                                    type: _NoticeType.error,
                                  );
                                }
                              },
                              icon: Icons.save_outlined,
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
        },
      );
    } finally {
      name.dispose();
      passport.dispose();
      visa.dispose();
      border.dispose();
      expiry.dispose();
      insurance.dispose();
      notes.dispose();
    }
  }

  Widget _sectionCompact({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ...children,
        ],
      ),
    );
  }

  Widget _fieldCompact(
    String hint,
    TextEditingController controller, {
    IconData? icon,
    bool readOnly = false,
    VoidCallback? onTap,
    int maxLines = 1,
    bool digitsOnly = false,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      minLines: maxLines == 1 ? 1 : null,
      textAlign: TextAlign.right,
      keyboardType: digitsOnly ? TextInputType.number : TextInputType.text,
      inputFormatters: digitsOnly
          ? <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly]
          : null,
      style: const TextStyle(
        color: dark,
        fontSize: 12,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFFA1A1AA),
          fontSize: 11,
        ),
        suffixIcon: icon == null
            ? null
            : Icon(icon, color: const Color(0xFF9CA3AF), size: 18),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: purple, width: 1.2),
        ),
      ),
    );
  }

  Widget _buttonCompact(
    String text,
    Color color,
    VoidCallback onPressed, {
    IconData? icon,
  }) {
    return SizedBox(
      height: 42,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 16),
        label: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 11.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      ),
    );
  }

  Future<void> _showRenewVisit(BuildContext context, Visit visit) async {
    final result = await RenewalDialog.showVisit(
      context,
      visitorName: visit.visitorName,
      expiryDate: visit.expiryDate,
    );

    if (result == null || !mounted) return;

    await context.read<VisitProvider>().renewVisit(
      visit.id,
      newExpiryDate: result.formattedDate,
      renewalMonths: result.months,
      newInsuranceExpiryDate: null,
    );

    if (!mounted) return;

    await ActionResultDialog.show(
      context,
      type: ActionResultType.success,
      title: 'تم تجديد الزيارة بنجاح',
      name: visit.visitorName,
      message: 'تم حفظ تاريخ التجديد الجديد بنجاح.',
    );
  }


  Widget _renewRow(String title, String value, Color valueColor) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 11,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  void _showLogs(BuildContext context, Visit visit) {
    final logs = List<String>.from(visit.logs).reversed.toList();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 620),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.history, color: purple, size: 25),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'سجل الزيارة',
                            style: TextStyle(
                              color: dark,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        visit.visitorName,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: logs.isEmpty
                          ? const Center(
                              child: Text(
                                'لا يوجد سجل لهذه الزيارة حتى الآن.',
                                style: TextStyle(color: Color(0xFF6B7280)),
                              ),
                            )
                          : ListView.separated(
                              itemCount: logs.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (_, index) {
                                final log = logs[index];
                                final isRenewal = log.contains('تجديد');
                                final isAdded = log.contains('إضافة');
                                final accent = isRenewal
                                    ? const Color(0xFF16A34A)
                                    : isAdded
                                        ? purple
                                        : primaryBlue;
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(13),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9FAFB),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: const Color(0xFFE5E7EB),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: accent.withOpacity(.10),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          isRenewal
                                              ? Icons.autorenew
                                              : isAdded
                                                  ? Icons.add_circle_outline
                                                  : Icons.edit_outlined,
                                          color: accent,
                                          size: 19,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          log,
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                            color: dark,
                                            fontSize: 11.5,
                                            height: 1.55,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFF374151),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        child: const Text(
                          'إغلاق',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, Visit visit) async {
    final confirmed = await showConfirmDeleteDialog(
      context,
      title: 'تأكيد الحذف',
      message:
          'هل أنت متأكد من حذف زيارة ${visit.visitorName}؟\nلا يمكن التراجع عن هذا الإجراء.',
    );

    if (!confirmed || !context.mounted) return;

    await context.read<VisitProvider>().removeVisit(visit.id);

    if (!context.mounted) return;
    _showNotice(
      context,
      title: 'تم حذف الزيارة',
      message: 'تم حذف الزيارة من القائمة بنجاح.',
      type: _NoticeType.success,
    );
  }


  Future<void> _showImportDialog(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ImportScreen(
          mode: ImportMode.visits,
          templateDescription:
              'يجب أن يحتوي الملف على اسم الزائر، رقم الجواز، رقم التأشيرة، رقم الحدود، وتواريخ انتهاء الزيارة والتأمين.',
          onDownloadTemplate: () => _downloadVisitTemplate(context),
          onVisitImport: (screenContext, file, onProgress) =>
              _importVisits(screenContext, file, onProgress),
        ),
      ),
    );
  }

  Future<bool> _saveExcelBytes(List<int> bytes, String fileName) async {
    if (kIsWeb) {
      final blob = html.Blob(
        [Uint8List.fromList(bytes)],
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..style.display = 'none';
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);
      return true;
    }

    final saved = await FilePicker.platform.saveFile(
      dialogTitle: 'حفظ قالب Excel',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      bytes: Uint8List.fromList(bytes),
    );
    return saved != null;
  }

  Future<void> _downloadVisitTemplate(BuildContext context) async {
    try {
      final workbook = excel_lib.Excel.createExcel();
      final sheet = workbook['الزيارات'];
      workbook.setDefaultSheet('الزيارات');

      final headers = [
        'اسم الزائر',
        'رقم الجواز',
        'رقم التأشيرة',
        'رقم الحدود',
        'تاريخ انتهاء الزيارة',
        'تاريخ انتهاء التأمين',
        'ملاحظات',
      ];

      sheet.appendRow(
        headers.map((h) => excel_lib.TextCellValue(h)).toList(),
      );
      sheet.appendRow([
        excel_lib.TextCellValue('مثال: سارة محمد العزازي'),
        excel_lib.TextCellValue('1234567890'),
        excel_lib.TextCellValue('456456456'),
        excel_lib.TextCellValue('3954181727'),
        excel_lib.TextCellValue('2026-10-31'),
        excel_lib.TextCellValue('2026-11-30'),
        excel_lib.TextCellValue(''),
      ]);

      final bytes = workbook.save();
      if (bytes == null || bytes.isEmpty) {
        throw Exception('تعذر إنشاء ملف Excel');
      }

      final saved = await _saveExcelBytes(bytes, 'قالب_استيراد_الزيارات.xlsx');

      if (!context.mounted || !saved) return;
      _showNotice(
        context,
        title: 'تم تحميل القالب',
        message: 'تم إنشاء قالب Excel الجاهز لاستيراد الزيارات.',
        type: _NoticeType.success,
      );
    } catch (e, stackTrace) {
      debugPrint('VISIT TEMPLATE ERROR: $e');
      debugPrint(stackTrace.toString());
      if (!context.mounted) return;
      _showNotice(
        context,
        title: 'تعذر تحميل القالب',
        message: 'حدث خطأ أثناء إنشاء ملف Excel.\n$e',
        type: _NoticeType.error,
      );
    }
  }

  String _normalizeHeader(String value) {
    return value
        .replaceAll('\ufeff', '')
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s_\-/:\\]+'), '')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه');
  }

  int _headerIndex(List<String> headers, List<String> aliases) {
    for (int i = 0; i < headers.length; i++) {
      final current = _normalizeHeader(headers[i]);
      if (aliases.any((alias) => current == _normalizeHeader(alias))) {
        return i;
      }
    }
    return -1;
  }

  String _normalizeIdentifier(String value) {
    var result = value.trim();

    const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
    const westernDigits = '0123456789';
    for (int i = 0; i < arabicDigits.length; i++) {
      result = result.replaceAll(arabicDigits[i], westernDigits[i]);
    }

    result = result.replaceAll(RegExp(r'(?<=\d)\.0+$'), '');
    result = result.replaceAll(RegExp(r'[\s\-_/+,]+'), '');

    return result;
  }

  Visit _buildImportedVisit({
    required String name,
    required String passport,
    required String visa,
    required String border,
    required String expiry,
    required String insurance,
    required String notes,
    required int rowNumber,
  }) {
    return Visit(
      id: '${DateTime.now().microsecondsSinceEpoch}_$rowNumber',
      visitorName: name.trim(),
      passportNumber: _normalizeIdentifier(passport),
      visaNumber: _normalizeIdentifier(visa),
      borderNumber: _normalizeIdentifier(border),
      expiryDate: expiry.trim(),
      insuranceExpiryDate: insurance.trim(),
      notes: notes.trim(),
      status: 'سارية',
    );
  }

  Future<VisitImportResult> _importVisits(BuildContext context, PlatformFile file, ImportProgressCallback onProgress) async {
    try {
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        throw Exception('لم يتمكن التطبيق من قراءة محتوى الملف.');
      }

      onProgress(const ImportProgress(progress: .05, stage: 'قراءة الملف'));
      await Future<void>.delayed(const Duration(milliseconds: 450));

      final imported = <Visit>[];
      int invalidRows = 0;
      int totalRows = 0;
      int processedRows = 0;
      final fileName = file.name.toLowerCase();

      void reportParsingProgress() {
        processedRows++;
        final ratio = totalRows <= 0 ? 0.0 : (processedRows / totalRows).clamp(0.0, 1.0).toDouble();
        if (processedRows == 1 || processedRows % 20 == 0 || processedRows == totalRows) {
          onProgress(ImportProgress(
            progress: 0.10 + (ratio * 0.48),
            stage: 'تحليل البيانات',
            processed: processedRows,
            total: totalRows,
            imported: imported.length,
            skipped: invalidRows,
          ));
        }
      }

      void addRowFromColumns(
        List<String> columns,
        int rowNumber,
        Map<String, int>? map,
      ) {
        int at(String key, int fallback) =>
            map != null && map[key] != null ? map[key]! : fallback;

        final name = columns.length > at('name', 0)
            ? columns[at('name', 0)].trim()
            : '';
        if (name.isEmpty) {
          invalidRows++;
          return;
        }

        imported.add(
          _buildImportedVisit(
            name: name,
            passport: columns.length > at('passport', 1)
                ? columns[at('passport', 1)]
                : '',
            visa: columns.length > at('visa', 2)
                ? columns[at('visa', 2)]
                : '',
            border: columns.length > at('border', 3)
                ? columns[at('border', 3)]
                : '',
            expiry: columns.length > at('expiry', 4)
                ? columns[at('expiry', 4)]
                : '',
            insurance: columns.length > at('insurance', 5)
                ? columns[at('insurance', 5)]
                : '',
            notes: columns.length > at('notes', 6)
                ? columns[at('notes', 6)]
                : '',
            rowNumber: rowNumber,
          ),
        );
      }

      if (fileName.endsWith('.xlsx')) {
        final workbook = excel_lib.Excel.decodeBytes(bytes);

        for (final sheetName in workbook.tables.keys) {
          final sheet = workbook.tables[sheetName];
          if (sheet == null || sheet.maxRows == 0) continue;

          String cellValue(dynamic row, int index) {
            if (index >= row.length) return '';
            final cell = row[index];
            if (cell == null || cell.value == null) return '';
            final value = cell.value;
            if (value is excel_lib.TextCellValue) {
              return value.value.text?.trim() ?? '';
            }
            if (value is excel_lib.IntCellValue) return value.value.toString();
            if (value is excel_lib.DoubleCellValue) {
              final n = value.value;
              return n == n.roundToDouble()
                  ? n.toInt().toString()
                  : n.toString();
            }
            if (value is excel_lib.DateCellValue) {
              return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
            }
            return value.toString().trim();
          }

          final firstRow = sheet.rows.first;
          final headerValues = List.generate(
            firstRow.length,
            (i) => cellValue(firstRow, i),
          );

          final map = <String, int>{
            'name': _headerIndex(headerValues, [
              'اسم الزائر', 'اسم الزائر الكامل', 'الاسم', 'visitor name', 'name'
            ]),
            'passport': _headerIndex(headerValues, [
              'رقم الجواز', 'الجواز', 'passport number', 'passport no', 'passport'
            ]),
            'visa': _headerIndex(headerValues, [
              'رقم التأشيرة', 'التأشيرة', 'visa number', 'visa'
            ]),
            'border': _headerIndex(headerValues, [
              'رقم الحدود', 'الحدود', 'border number', 'border'
            ]),
            'expiry': _headerIndex(headerValues, [
              'تاريخ انتهاء الزيارة', 'انتهاء الزيارة', 'تاريخ الزيارة',
              'visit expiry date', 'visit expiry'
            ]),
            'insurance': _headerIndex(headerValues, [
              'تاريخ انتهاء التأمين', 'انتهاء التأمين', 'insurance expiry date',
              'insurance expiry'
            ]),
            'notes': _headerIndex(headerValues, [
              'ملاحظات', 'ملاحظات اختيارية', 'notes', 'note'
            ]),
          };

          final hasHeader = map.values.any((i) => i >= 0);
          final startRow = hasHeader ? 1 : 0;
          totalRows += (sheet.maxRows - startRow).clamp(0, sheet.maxRows).toInt();

          for (int rowIndex = startRow; rowIndex < sheet.maxRows; rowIndex++) {
            final row = sheet.rows[rowIndex];
            if (row.isEmpty) continue;
            final columns = List.generate(
              row.length,
              (i) => cellValue(row, i),
            );
            addRowFromColumns(
              columns,
              rowIndex + 1,
              hasHeader
                  ? {
                      for (final e in map.entries)
                        if (e.value >= 0) e.key: e.value,
                    }
                  : null,
            );
            reportParsingProgress();
          }
        }
      } else if (fileName.endsWith('.csv')) {
        final csvText = utf8.decode(bytes, allowMalformed: true);
        final lines = csvText
            .split(RegExp(r'\r?\n'))
            .where((line) => line.trim().isNotEmpty)
            .toList();

        if (lines.isNotEmpty) {
          final delimiter = lines.first.contains(';') &&
                  !lines.first.contains(',')
              ? ';'
              : ',';
          final first = _parseCsvLine(lines.first, delimiter: delimiter);
          final map = <String, int>{
            'name': _headerIndex(first, [
              'اسم الزائر', 'اسم الزائر الكامل', 'الاسم', 'visitor name', 'name'
            ]),
            'passport': _headerIndex(first, [
              'رقم الجواز', 'الجواز', 'passport number', 'passport no', 'passport'
            ]),
            'visa': _headerIndex(first, [
              'رقم التأشيرة', 'التأشيرة', 'visa number', 'visa'
            ]),
            'border': _headerIndex(first, [
              'رقم الحدود', 'الحدود', 'border number', 'border'
            ]),
            'expiry': _headerIndex(first, [
              'تاريخ انتهاء الزيارة', 'انتهاء الزيارة', 'visit expiry date',
              'visit expiry'
            ]),
            'insurance': _headerIndex(first, [
              'تاريخ انتهاء التأمين', 'انتهاء التأمين', 'insurance expiry date',
              'insurance expiry'
            ]),
            'notes': _headerIndex(first, [
              'ملاحظات', 'notes', 'note'
            ]),
          };

          final hasHeader = map.values.any((i) => i >= 0);
          final startRow = hasHeader ? 1 : 0;
          totalRows += (lines.length - startRow).clamp(0, lines.length).toInt();
          for (int rowIndex = startRow; rowIndex < lines.length; rowIndex++) {
            final columns = _parseCsvLine(lines[rowIndex], delimiter: delimiter);
            if (columns.isEmpty) continue;
            addRowFromColumns(
              columns,
              rowIndex + 1,
              hasHeader
                  ? {
                      for (final e in map.entries)
                        if (e.value >= 0) e.key: e.value,
                    }
                  : null,
            );
            reportParsingProgress();
          }
        }
      }

      onProgress(ImportProgress(
        progress: .64,
        stage: 'التحقق من التكرار',
        processed: totalRows,
        total: totalRows,
        imported: imported.length,
        skipped: invalidRows,
      ));
      await Future<void>.delayed(const Duration(milliseconds: 650));

      if (imported.isEmpty) {
        throw Exception('لم يتم العثور على صفوف صالحة في الملف.');
      }

      final provider = context.read<VisitProvider>();
      onProgress(ImportProgress(
        progress: .78,
        stage: 'إضافة الزيارات',
        processed: totalRows,
        total: totalRows,
        imported: 0,
        skipped: invalidRows,
      ));
      await Future<void>.delayed(const Duration(milliseconds: 550));

      final added = await provider.addVisitsBatch(imported);
      final duplicateCount = imported.length - added;
      final rejected = duplicateCount + invalidRows;

      onProgress(ImportProgress(
        progress: 1,
        stage: 'اكتمل الاستيراد',
        processed: totalRows,
        total: totalRows,
        imported: added,
        skipped: rejected,
      ));
      await Future<void>.delayed(const Duration(milliseconds: 900));

      return VisitImportResult(
        fileName: file.name,
        totalRecords: totalRows,
        importedCount: added,
        rejectedCount: rejected,
      );
    } catch (e, stackTrace) {
      debugPrint('VISIT IMPORT ERROR: $e');
      debugPrint(stackTrace.toString());
      rethrow;
    }
  }

  List<String> _parseCsvLine(String line, {String delimiter = ","}) {
    final result = <String>[];
    final buffer = StringBuffer();
    bool quoted = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        if (quoted && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          quoted = !quoted;
        }
      } else if (char == delimiter && !quoted) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }

    result.add(buffer.toString());
    return result;
  }

  void _showNotice(
    BuildContext context, {
    required String title,
    required String message,
    required _NoticeType type,
  }) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final accent = type == _NoticeType.success
        ? const Color(0xFF16A34A)
        : type == _NoticeType.warning
            ? const Color(0xFFD97706)
            : type == _NoticeType.error
                ? const Color(0xFFDC2626)
                : purple;

    final background = type == _NoticeType.success
        ? const Color(0xFFF0FDF4)
        : type == _NoticeType.warning
            ? const Color(0xFFFFFBEB)
            : type == _NoticeType.error
                ? const Color(0xFFFEF2F2)
                : const Color(0xFFFAF5FF);

    final icon = type == _NoticeType.success
        ? Icons.check_circle_outline
        : type == _NoticeType.warning
            ? Icons.info_outline
            : type == _NoticeType.error
                ? Icons.error_outline
                : Icons.info_outline;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) => Positioned(
        top: 18,
        left: 18,
        right: 18,
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Material(
              color: Colors.transparent,
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 520),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: accent.withOpacity(.12)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.12),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: accent, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(title, textAlign: TextAlign.right,
                              style: const TextStyle(color: dark, fontSize: 12.5, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(message, textAlign: TextAlign.right, maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10, height: 1.35)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 7),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => entry.remove(),
                        icon: const Icon(Icons.close, color: Color(0xFF9CA3AF), size: 18),
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

    overlay.insert(entry);
    Future<void>.delayed(const Duration(seconds: 4), () {
      if (entry.mounted) entry.remove();
    });
  }

}
