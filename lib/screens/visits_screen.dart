import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import 'package:excel/excel.dart' as excel_lib;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:universal_html/universal_html.dart' as html;

import '../models/visit.dart';
import '../providers/visit_provider.dart';
import '../widgets/app_date_picker.dart';
import '../widgets/confirm_delete_dialog.dart';

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
            const SizedBox(height: 6),
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
    padding: const EdgeInsets.symmetric(
      horizontal: 30,
      vertical: 12,
    ),
    color: const Color(0xFFF7F8FC),
    child: Row(
      textDirection: TextDirection.rtl,
      children: const [

   Expanded(
  flex: 4,
  child: Padding(
    padding: const EdgeInsets.only(right: 70),
    child: Align(
      alignment: Alignment.centerRight,
      child: Text(
        'اسم الزائر',
        textAlign: TextAlign.right,
        style: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  ),
),

  Expanded(
  flex: 3,
  child: Padding(
    padding: const EdgeInsets.only(right: 35),
    child: Align(
      alignment: Alignment.centerRight,
      child: Text(
        'رقم الحدود',
        style: TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 13,
        ),
      ),
    ),
  ),
),
        Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.center,
            child: Text(
              'الحالة',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
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
              Icons.flight_takeoff_outlined,
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
      onTap: () => _showActions(context, visit),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 13,
        ),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Color(0xFFE5E7EB),
            ),
          ),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [

            // اسم الزائر
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.only(right: 70),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
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
                      const SizedBox(height: 4),
                      Text(
                        _displayDate(visit.expiryDate),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // رقم الحدود
            Expanded(
              flex: 3,
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  visit.borderNumber.isEmpty
                      ? '-'
                      : visit.borderNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: dark,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),

            // الحالة
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          status,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      if (daysText.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          daysText,
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            color: dark,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
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
    final parsed = _parseDate(initial ?? '');
    final value = await AppDatePicker.show(
      context,
      initialDate: parsed ?? DateTime.now(),
    );
    return value;
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
        vertical: 10,
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
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
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
          const SizedBox(height: 8),
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
                maxWidth: 420,
                maxHeight: MediaQuery.sizeOf(context).height * .90,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.flight_takeoff_outlined,
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
                    const Divider(height: 14),
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
                        const SizedBox(height: 6),
                        _field(
                          'رقم الجواز',
                          passport,
                          icon: Icons.badge_outlined,
                          digitsOnly: true,
                        ),
                        const SizedBox(height: 6),
                        _field(
                          'رقم التأشيرة',
                          visa,
                          icon: Icons.confirmation_number_outlined,
                          digitsOnly: true,
                        ),
                        const SizedBox(height: 6),
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
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
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
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 330),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'إجراءات الزيارة',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: dark,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(Icons.close, size: 21),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      visit.visitorName,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _actionTile(
                            'تعديل', Icons.edit_outlined, primaryBlue,
                            const Color(0xFFEFF6FF), () {
                              Navigator.pop(dialogContext);
                              _showEditVisit(context, visit);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _actionTile(
                            'السجل', Icons.history, purple,
                            const Color(0xFFF5F3FF), () {
                              Navigator.pop(dialogContext);
                              _showLogs(context, visit);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _actionTile(
                            'حذف', Icons.delete_outline,
                            const Color(0xFFDC2626), const Color(0xFFFEF2F2), () {
                              Navigator.pop(dialogContext);
                              _confirmDelete(context, visit);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _actionTile(
                            'تجديد', Icons.autorenew,
                            const Color(0xFF16A34A), const Color(0xFFF0FDF4), () {
                              Navigator.pop(dialogContext);
                              _showRenewVisit(context, visit);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
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
                          'إلغاء',
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

  Widget _actionTile(
    String title,
    IconData icon,
    Color color,
    Color background,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(.08)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 5),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditVisit(BuildContext context, Visit visit) async {
    final name = TextEditingController(text: visit.visitorName);
    final passport = TextEditingController(text: visit.passportNumber);
    final visa = TextEditingController(text: visit.visaNumber);
    final border = TextEditingController(text: visit.borderNumber);
    final expiry = TextEditingController(text: visit.expiryDate);
    final insurance =
        TextEditingController(text: visit.insuranceExpiryDate);
    final notes = TextEditingController(text: visit.notes);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 20,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 420,
                maxHeight: MediaQuery.sizeOf(context).height * .90,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.edit_outlined, color: purple),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'تعديل بيانات الزيارة',
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
                    const Divider(height: 20),
                    _section(
                      title: 'معلومات الزائر',
                      icon: Icons.person_outline,
                      color: purpleDark,
                      children: [
                        _field('اسم الزائر', name),
                        const SizedBox(height: 6),
                        _field('رقم الجواز', passport, digitsOnly: true),
                        const SizedBox(height: 6),
                        _field('رقم التأشيرة', visa, digitsOnly: true),
                        const SizedBox(height: 6),
                        _field('رقم الحدود', border, digitsOnly: true),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _section(
                      title: 'تواريخ الانتهاء',
                      icon: Icons.calendar_month_outlined,
                      color: primaryBlue,
                      children: [
                        _field(
                          'تاريخ انتهاء الزيارة',
                          expiry,
                          readOnly: true,
                          icon: Icons.calendar_month_outlined,
                          onTap: () async {
                            final value = await _pickDate(
                              context,
                              initial: expiry.text,
                            );
                            if (value != null) expiry.text = value;
                          },
                        ),
                        const SizedBox(height: 6),
                        _field(
                          'تاريخ انتهاء التأمين',
                          insurance,
                          readOnly: true,
                          icon: Icons.calendar_month_outlined,
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
                    _field('ملاحظات اختيارية...', notes, maxLines: 3),
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
                            'حفظ التعديل',
                            purple,
                            () async {
                              if (name.text.trim().isEmpty ||
                                  expiry.text.trim().isEmpty ||
                                  insurance.text.trim().isEmpty) {
                                _showNotice(
                                  context,
                                  title: 'بيانات ناقصة',
                                  message:
                                      'يرجى استكمال الحقول المطلوبة.',
                                  type: _NoticeType.warning,
                                );
                                return;
                              }

                              final updated = visit.copyWith(
                                visitorName: name.text.trim(),
                                passportNumber: passport.text.trim(),
                                visaNumber: visa.text.trim(),
                                borderNumber: border.text.trim(),
                                expiryDate: expiry.text.trim(),
                                insuranceExpiryDate: insurance.text.trim(),
                                notes: notes.text.trim(),
                              );

                              await context
                                  .read<VisitProvider>()
                                  .updateVisit(updated);

                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }
                              if (!context.mounted) return;
                              _showNotice(
                                context,
                                title: 'تم حفظ التعديل',
                                message: 'تم تحديث بيانات الزيارة بنجاح.',
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

  Future<void> _showRenewVisit(BuildContext context, Visit visit) async {
    int months = 1;
    String newInsurance = visit.insuranceExpiryDate;
    final insuranceController = TextEditingController(text: newInsurance);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final newDate = _calculateRenewal(visit.expiryDate, months);

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Dialog(
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.autorenew,
                            color: primaryBlue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'تجديد الزيارة',
                          style: TextStyle(
                            color: dark,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          visit.visitorName,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 11.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Column(
                            children: [
                              _renewRow(
                                'انتهاء الزيارة الحالي',
                                _displayDate(visit.expiryDate),
                                const Color(0xFF6B7280),
                              ),
                              const SizedBox(height: 6),
                              _renewRow(
                                'انتهاء الزيارة الجديد',
                                _displayDate(newDate),
                                primaryBlue,
                              ),
                              const SizedBox(height: 6),
                              _renewRow(
                                'انتهاء التأمين الحالي',
                                _displayDate(visit.insuranceExpiryDate),
                                const Color(0xFF6B7280),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'اختر مدة التجديد',
                            style: TextStyle(
                              color: dark,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: [1, 3].map((m) {
                            final active = months == m;
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  left: m == 3 ? 0 : 6,
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(13),
                                  onTap: () => setDialogState(() {
                                    months = m;
                                  }),
                                  child: Container(
                                    height: 42,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: active
                                          ? primaryBlue
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(13),
                                      border: Border.all(
                                        color: active
                                            ? primaryBlue
                                            : const Color(0xFFE5E7EB),
                                      ),
                                    ),
                                    child: Text(
                                      '$m شهر',
                                      style: TextStyle(
                                        color: active ? Colors.white : dark,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 6),
                        _field(
                          'تاريخ انتهاء التأمين الجديد',
                          insuranceController,
                          readOnly: true,
                          icon: Icons.calendar_month_outlined,
                          onTap: () async {
                            final value = await _pickDate(
                              context,
                              initial: newInsurance,
                            );
                            if (value != null) {
                              newInsurance = value;
                              insuranceController.text = value;
                              setDialogState(() {});
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            onPressed: () async {
                              await context
                                  .read<VisitProvider>()
                                  .renewVisit(
                                    visit.id,
                                    newExpiryDate: newDate,
                                    renewalMonths: months,
                                    newInsuranceExpiryDate:
                                        newInsurance.isEmpty
                                            ? null
                                            : newInsurance,
                                  );
                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }
                              if (!context.mounted) return;
                              _showNotice(
                                context,
                                title: 'تم تجديد الزيارة',
                                message:
                                    'تم تحديث تاريخ انتهاء الزيارة والتأمين بنجاح.',
                                type: _NoticeType.success,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'تأكيد التجديد',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFF374151),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'إلغاء',
                              style: TextStyle(fontWeight: FontWeight.w600),
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
      },
    );

    insuranceController.dispose();
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

  String _calculateRenewal(String current, int months) {
    final start = _parseDate(current) ?? DateTime.now();
    int month = start.month + months;
    int year = start.year + ((month - 1) ~/ 12);
    month = ((month - 1) % 12) + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = start.day > lastDay ? lastDay : start.day;
    return _date(DateTime(year, month, day));
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
                    const SizedBox(height: 6),
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
              vertical: 20,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 520,
                maxHeight: MediaQuery.sizeOf(context).height * .82,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 14, 12),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'استيراد الزيارات العائلية',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: dark,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(
                            Icons.close,
                            color: Color(0xFF9AA2AD),
                            size: 21,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFE7E7EA),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                      child: Column(
                        children: [
                          const Text(
                            'قم بتحميل ملف Excel أو CSV يحتوي على بيانات\nالزيارات العائلية',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF7D8794),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              height: 1.55,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 44,
                            child: TextButton.icon(
                              onPressed: () =>
                                  _downloadVisitTemplate(context),
                              style: TextButton.styleFrom(
                                backgroundColor: const Color(0xFFF7F3FC),
                                foregroundColor: purple,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(13),
                                ),
                              ),
                              icon: const Icon(
                                Icons.download_rounded,
                                size: 19,
                              ),
                              label: const Text(
                                'تحميل قالب Excel للزيارات العائلية',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 24,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: const Color(0xFFE2E5EA),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.file_upload_outlined,
                                  color: Color(0xFFA4ACB8),
                                  size: 42,
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'اسحب وأفلت ملف الزيارات هنا',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: dark,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'أو',
                                  style: TextStyle(
                                    color: Color(0xFF7D8794),
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 44,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(dialogContext);
                                      _importVisits(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: purple,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.description_outlined,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'اختر ملف',
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
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(
                              14,
                              14,
                              14,
                              16,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F3FC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFEAE2F5),
                              ),
                            ),
                            child: Directionality(
                              textDirection: TextDirection.rtl,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      'متطلبات ملف الزيارات العائلية:',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        color: Color(0xFF6F2CA8),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      '• اسم الزائر، رقم التأشيرة، رقم الحدود، رقم الجواز\n'
                                      '• تاريخ انتهاء الزيارة وتاريخ انتهاء التأمين',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        color: Color(0xFF6F2CA8),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w400,
                                        height: 1.8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFE7E7EA),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                    child: SizedBox(
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
                  ),
                ],
              ),
            ),
          ),
        );
      },
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

  Future<void> _importVisits(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        if (!context.mounted) return;
        _showNotice(
          context,
          title: 'تعذر قراءة الملف',
          message: 'لم يتمكن التطبيق من قراءة محتوى الملف.',
          type: _NoticeType.error,
        );
        return;
      }

      final imported = <Visit>[];
      int invalidRows = 0;
      final fileName = file.name.toLowerCase();

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
          }
        }
      }

      if (imported.isEmpty) {
        if (!context.mounted) return;
        _showNotice(
          context,
          title: 'لم يتم الاستيراد',
          message: 'لم يتم العثور على صفوف صالحة في الملف.',
          type: _NoticeType.warning,
        );
        return;
      }

      final provider = context.read<VisitProvider>();
      final added = await provider.addVisitsBatch(imported);
      final skipped = imported.length - added;

      if (!context.mounted) return;

      final details = <String>[];
      if (added > 0) details.add('تمت إضافة $added زيارة');
      if (skipped > 0) details.add('تم تجاهل $skipped زيارة مكررة');
      if (invalidRows > 0) details.add('تم تجاهل $invalidRows صف غير صالح');

      _showNotice(
        context,
        title: added > 0 ? 'تم الاستيراد بنجاح' : 'لم تتم إضافة زيارات',
        message: details.isEmpty
            ? 'لم يتم العثور على بيانات جديدة.'
            : details.join(' • '),
        type: added > 0 ? _NoticeType.success : _NoticeType.warning,
      );
    } catch (e, stackTrace) {
      debugPrint('VISIT IMPORT ERROR: $e');
      debugPrint(stackTrace.toString());
      if (!context.mounted) return;
      _showNotice(
        context,
        title: 'خطأ في الاستيراد',
        message: 'حدث خطأ أثناء قراءة الملف:\n$e',
        type: _NoticeType.error,
      );
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