import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/visit_provider.dart';
import '../models/visit.dart';

class VisitsScreen extends StatefulWidget {
  const VisitsScreen({super.key});

  @override
  State<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends State<VisitsScreen> {
  static const Color primaryBlue = Color(0xff2563EB);

  int selectedFilter = 0;
  final TextEditingController searchController = TextEditingController();

  final List<String> filters = [
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

  Map<String, dynamic> _status(String date) {
    if (date.trim().isEmpty) {
      return {'label': 'سارية', 'days': null};
    }

    try {
      final expiry = DateTime.parse(date);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final expiryDay = DateTime(expiry.year, expiry.month, expiry.day);
      final days = expiryDay.difference(today).inDays;

      if (days < 0) return {'label': 'منتهية', 'days': days};
      if (days <= 30) return {'label': 'تحتاج متابعة', 'days': days};
      return {'label': 'سارية', 'days': days};
    } catch (_) {
      return {'label': 'سارية', 'days': null};
    }
  }

  String _date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<String?> _pickDate(
    BuildContext context, {
    String? initial,
  }) async {
    DateTime first = DateTime.now();

    if (initial != null && initial.isNotEmpty) {
      first = DateTime.tryParse(initial) ?? DateTime.now();
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: first,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('ar'),
    );

    return picked == null ? null : _date(picked);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VisitProvider>();

    final query = searchController.text.trim().toLowerCase();

    final filtered = provider.visits.where((visit) {
      final matchesSearch =
          visit.visitorName.toLowerCase().contains(query) ||
          visit.visaNumber.toLowerCase().contains(query) ||
          visit.borderNumber.toLowerCase().contains(query);

      if (!matchesSearch) return false;

      final status = _status(visit.expiryDate)['label'];

      if (selectedFilter == 0) return true;
      if (selectedFilter == 1) return status == 'سارية';
      if (selectedFilter == 2) {
        return status == 'تحتاج متابعة';
      }
      if (selectedFilter == 3) return status == 'منتهية';

      return true;
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF7F8FC),
        body: Column(
          children: [
            const SizedBox(height: 15),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        controller: searchController,
                        onChanged: (_) => setState(() {}),
                        textAlign: TextAlign.right,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText:
                              'البحث بالاسم أو رقم الحدود أو التأشيرة...',
                          hintStyle:
                              TextStyle(color: Colors.grey, fontSize: 13),
                          prefixIcon:
                              Icon(Icons.search, color: Colors.grey),
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xffF0F5FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.filter_list,
                      color: primaryBlue,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(filters.length, (index) {
                  final active = selectedFilter == index;

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: index == filters.length - 1 ? 0 : 6,
                      ),
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => selectedFilter = index),
                        child: Container(
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color:
                                active ? primaryBlue : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: active
                                  ? primaryBlue
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: Text(
                            filters[index],
                            style: TextStyle(
                              color:
                                  active ? Colors.white : Colors.black87,
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
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'لا توجد زيارات مسجلة',
                        style:
                            TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final visit = filtered[index];
                        final status = _status(visit.expiryDate);
                        final label = status['label'] as String;
                        final days = status['days'] as int?;

                        Color statusColor = const Color(0xff16A34A);
                        Color statusBg = const Color(0xffF0FDF4);

                        if (label == 'منتهية') {
                          statusColor = const Color(0xffDC2626);
                          statusBg = const Color(0xffFEF2F2);
                        } else if (label == 'تحتاج متابعة') {
                          statusColor = const Color(0xffD97706);
                          statusBg = const Color(0xffFFFBEB);
                        }

                        return Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () =>
                                _showActions(context, visit),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color:
                                          const Color(0xffEFF6FF),
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.flight_land_outlined,
                                      color: primaryBlue,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          visit.visitorName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          [
                                            if (visit.borderNumber
                                                .trim()
                                                .isNotEmpty)
                                              'الحدود: ${visit.borderNumber}',
                                            if (visit.visaNumber
                                                .trim()
                                                .isNotEmpty)
                                              'التأشيرة: ${visit.visaNumber}',
                                          ].join('  •  '),
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 11,
                                          ),
                                        ),
                                        if (visit.expiryDate.isNotEmpty)
                                          Text(
                                            'الانتهاء: ${visit.expiryDate}',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 11,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 9,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusBg,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          label,
                                          style: TextStyle(
                                            color: statusColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (days != null)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 5),
                                          child: Text(
                                            days < 0
                                                ? 'منتهية منذ ${days.abs()} يوم'
                                                : 'متبقي $days يوم',
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddVisit(context),
          backgroundColor: primaryBlue,
          shape: const CircleBorder(),
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }

  InputDecoration _input(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          TextStyle(color: Colors.grey.shade400, fontSize: 12),
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
        borderSide: const BorderSide(color: primaryBlue),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    bool multiline = false,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          maxLines: multiline ? 3 : 1,
          decoration: _input(label),
        ),
      ],
    );
  }

  Future<void> _showAddVisit(BuildContext context) async {
    final name = TextEditingController();
    final visa = TextEditingController();
    final border = TextEditingController();
    final expiry = TextEditingController();
    final insurance = TextEditingController();
    final notes = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                title: Row(
                  children: const [
                    Icon(
                      Icons.flight_land_outlined,
                      color: primaryBlue,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'إضافة زيارة جديدة',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: SizedBox(
                    width: 380,
                    child: Column(
                      children: [
                        _field('اسم الزائر *', name),
                        const SizedBox(height: 12),
                        _field('رقم التأشيرة', visa),
                        const SizedBox(height: 12),
                        _field('رقم الحدود', border),
                        const SizedBox(height: 12),
                        _field(
                          'تاريخ انتهاء الزيارة *',
                          expiry,
                          readOnly: true,
                          onTap: () async {
                            final value = await _pickDate(
                              context,
                              initial: expiry.text,
                            );
                            if (value != null) {
                              expiry.text = value;
                              setDialogState(() {});
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        _field(
                          'تاريخ انتهاء التأمين',
                          insurance,
                          readOnly: true,
                          onTap: () async {
                            final value = await _pickDate(
                              context,
                              initial: insurance.text,
                            );
                            if (value != null) {
                              insurance.text = value;
                              setDialogState(() {});
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        _field(
                          'ملاحظات',
                          notes,
                          multiline: true,
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (name.text.trim().isEmpty ||
                          expiry.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'يرجى إدخال اسم الزائر وتاريخ انتهاء الزيارة',
                            ),
                          ),
                        );
                        return;
                      }

                      final visit = Visit(
                        id: DateTime.now()
                            .microsecondsSinceEpoch
                            .toString(),
                        visitorName: name.text.trim(),
                        visaNumber: visa.text.trim(),
                        borderNumber: border.text.trim(),
                        expiryDate: expiry.text.trim(),
                        insuranceExpiryDate:
                            insurance.text.trim(),
                        notes: notes.text.trim(),
                      );

                      await context
                          .read<VisitProvider>()
                          .addVisit(visit);

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                    },
                    icon: const Icon(
                      Icons.save_outlined,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'حفظ',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    name.dispose();
    visa.dispose();
    border.dispose();
    expiry.dispose();
    insurance.dispose();
    notes.dispose();
  }

  void _showActions(BuildContext context, Visit visit) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    visit.visitorName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'رقم التأشيرة: ${visit.visaNumber.isEmpty ? '-' : visit.visaNumber}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _actionButton(
                          'تعديل',
                          Icons.edit_outlined,
                          const Color(0xff2563EB),
                          const Color(0xffEFF6FF),
                          () {
                            Navigator.pop(sheetContext);
                            _showEditVisit(context, visit);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _actionButton(
                          'تجديد',
                          Icons.autorenew,
                          const Color(0xff16A34A),
                          const Color(0xffF0FDF4),
                          () {
                            Navigator.pop(sheetContext);
                            _showRenewVisit(context, visit);
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
                          'السجل',
                          Icons.history,
                          const Color(0xff7C3AED),
                          const Color(0xffF5F3FF),
                          () {
                            Navigator.pop(sheetContext);
                            _showLogs(context, visit);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _actionButton(
                          'حذف',
                          Icons.delete_outline,
                          const Color(0xffDC2626),
                          const Color(0xffFEF2F2),
                          () {
                            Navigator.pop(sheetContext);
                            _confirmDelete(context, visit);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('إغلاق'),
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

  Widget _actionButton(
    String label,
    IconData icon,
    Color color,
    Color bg,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditVisit(
    BuildContext context,
    Visit visit,
  ) async {
    final name =
        TextEditingController(text: visit.visitorName);
    final visa =
        TextEditingController(text: visit.visaNumber);
    final border =
        TextEditingController(text: visit.borderNumber);
    final expiry =
        TextEditingController(text: visit.expiryDate);
    final insurance =
        TextEditingController(text: visit.insuranceExpiryDate);
    final notes =
        TextEditingController(text: visit.notes);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: const Text(
              'تعديل بيانات الزيارة',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 380,
                child: Column(
                  children: [
                    _field('اسم الزائر *', name),
                    const SizedBox(height: 12),
                    _field('رقم التأشيرة', visa),
                    const SizedBox(height: 12),
                    _field('رقم الحدود', border),
                    const SizedBox(height: 12),
                    _field(
                      'تاريخ انتهاء الزيارة *',
                      expiry,
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
                    _field(
                      'تاريخ انتهاء التأمين',
                      insurance,
                      readOnly: true,
                      onTap: () async {
                        final value = await _pickDate(
                          context,
                          initial: insurance.text,
                        );
                        if (value != null) insurance.text = value;
                      },
                    ),
                    const SizedBox(height: 12),
                    _field(
                      'ملاحظات',
                      notes,
                      multiline: true,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (name.text.trim().isEmpty ||
                      expiry.text.trim().isEmpty) {
                    return;
                  }

                  final updated = visit.copyWith(
                    visitorName: name.text.trim(),
                    visaNumber: visa.text.trim(),
                    borderNumber: border.text.trim(),
                    expiryDate: expiry.text.trim(),
                    insuranceExpiryDate:
                        insurance.text.trim(),
                    notes: notes.text.trim(),
                  );

                  await context
                      .read<VisitProvider>()
                      .updateVisit(updated);

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('حفظ'),
              ),
            ],
          ),
        );
      },
    );

    name.dispose();
    visa.dispose();
    border.dispose();
    expiry.dispose();
    insurance.dispose();
    notes.dispose();
  }

  Future<void> _showRenewVisit(
    BuildContext context,
    Visit visit,
  ) async {
    int months = 12;
    String newDate = _calculateRenewal(
      visit.expiryDate,
      months,
    );

    String newInsurance = visit.insuranceExpiryDate;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            newDate = _calculateRenewal(
              visit.expiryDate,
              months,
            );

            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                title: const Text(
                  'تجديد الزيارة',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: SizedBox(
                  width: 360,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        visit.visitorName,
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'مدة التجديد',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [3, 6, 9, 12].map((m) {
                          final active = months == m;

                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 5),
                              child: GestureDetector(
                                onTap: () {
                                  setStateDialog(() {
                                    months = m;
                                  });
                                },
                                child: Container(
                                  height: 40,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: active
                                        ? primaryBlue
                                        : const Color(0xffF8FAFC),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$m',
                                    style: TextStyle(
                                      color: active
                                          ? Colors.white
                                          : Colors.black87,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xffF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'تاريخ الانتهاء الجديد: $newDate',
                          style: const TextStyle(
                            color: Color(0xff16A34A),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _field(
                        'تاريخ التأمين الجديد',
                        TextEditingController(
                          text: newInsurance,
                        ),
                        readOnly: true,
                        onTap: () async {
                          final value = await _pickDate(
                            context,
                            initial: newInsurance,
                          );
                          if (value != null) {
                            newInsurance = value;
                            setStateDialog(() {});
                          }
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await context.read<VisitProvider>().renewVisit(
                            visit.id,
                            newExpiryDate: newDate,
                            newInsuranceExpiryDate:
                                newInsurance.isEmpty
                                    ? null
                                    : newInsurance,
                          );

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff16A34A),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('تأكيد التجديد'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _calculateRenewal(String current, int months) {
    final start = DateTime.tryParse(current) ?? DateTime.now();

    int month = start.month + months;
    int year = start.year + ((month - 1) ~/ 12);
    month = ((month - 1) % 12) + 1;

    final lastDay = DateTime(year, month + 1, 0).day;
    final day = start.day > lastDay ? lastDay : start.day;

    return _date(
      DateTime(year, month, day).subtract(
        const Duration(days: 1),
      ),
    );
  }

  void _showLogs(BuildContext context, Visit visit) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text(
              'سجل الزيارة',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: 380,
              child: visit.logs.isEmpty
                  ? const Text(
                      'لا يوجد سجل حتى الآن',
                      style: TextStyle(color: Colors.grey),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: visit.logs.length,
                      separatorBuilder: (_, __) =>
                          const Divider(),
                      itemBuilder: (_, index) {
                        return Text(
                          visit.logs[index],
                          style: const TextStyle(fontSize: 12),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('إغلاق'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, Visit visit) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text(
              'حذف الزيارة',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'هل تريد حذف زيارة ${visit.visitorName}؟',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await context
                      .read<VisitProvider>()
                      .removeVisit(visit.id);

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffDC2626),
                  foregroundColor: Colors.white,
                ),
                child: const Text('حذف'),
              ),
            ],
          ),
        );
      },
    );
  }
}
