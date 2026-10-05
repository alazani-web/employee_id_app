import 'package:flutter/material.dart';

import '../utils/renewal_calculator.dart';
import '../utils/family_visit_calculator.dart';
import '../widgets/app_date_picker.dart';

class RenewalDialogResult {
  final DateTime currentExpiry;
  final DateTime newExpiry;
  final int months;
  final String formattedDate;
  final String notes;

  const RenewalDialogResult({
    required this.currentExpiry,
    required this.newExpiry,
    required this.months,
    required this.formattedDate,
    required this.notes,
  });
}

class RenewalDialog {
  const RenewalDialog._();

  static Future<RenewalDialogResult?> show(
    BuildContext context, {
    required String employeeName,
    required String expiryDate,
  }) async {
    final currentExpiry = RenewalCalculator.parseDate(expiryDate);

    if (currentExpiry == null) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تعذر حساب التجديد'),
            content: const Text(
              'تاريخ انتهاء هوية الموظف غير صالح، لذلك لم يتم استخدام تاريخ اليوم كبديل.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('إغلاق'),
              ),
            ],
          ),
        ),
      );
      return null;
    }

    int selectedMonths = 12;
    final notesController = TextEditingController();

    try {
      return await showDialog<RenewalDialogResult>(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black54,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final newExpiry = RenewalCalculator.calculateRenewalDate(
              expiryDate: currentExpiry,
              renewalMonths: selectedMonths,
            );
            final formatted = _formatDate(newExpiry);

            return Directionality(
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
                  constraints: const BoxConstraints(maxWidth: 360),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                              onPressed: () => Navigator.pop(dialogContext),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xffF0FDF4),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.autorenew,
                              color: Color(0xff16A34A),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Center(
                        child: Text(
                          'تجديد بيانات الموظف',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          employeeName,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'مدة التجديد (بالأشهر)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [3, 6, 9, 12].map((months) {
                          final selected = selectedMonths == months;
                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: selected
                                      ? const Color(0xFF1D4ED8)
                                      : const Color(0xffF8FAFC),
                                  foregroundColor: selected
                                      ? Colors.white
                                      : Colors.black87,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () => setDialogState(
                                  () => selectedMonths = months,
                                ),
                                child: Text(
                                  '$months أشهر',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      _infoRow(
                        'تاريخ الانتهاء الحالي:',
                        _formatDate(currentExpiry),
                        const Color(0xff6B7280),
                      ),
                      const SizedBox(height: 8),
                      _infoRow(
                        'تاريخ الانتهاء الجديد:',
                        formatted,
                        const Color(0xff15803D),
                        highlight: true,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'ملاحظات التجديد',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: notesController,
                        maxLines: 2,
                        textDirection: TextDirection.rtl,
                        decoration: InputDecoration(
                          hintText: 'أدخل ملاحظات اختيارية...',
                          filled: true,
                          fillColor: const Color(0xffF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 11,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xffE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xffE2E8F0),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1D4ED8),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(
                                  dialogContext,
                                  RenewalDialogResult(
                                    currentExpiry: currentExpiry,
                                    newExpiry: newExpiry,
                                    months: selectedMonths,
                                    formattedDate: formatted,
                                    notes: notesController.text.trim(),
                                  ),
                                );
                              },
                              child: const Text(
                                'تأكيد التجديد',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: const Color(0xffF3F4F6),
                                foregroundColor: Colors.black87,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text(
                                'إلغاء',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
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
            );
          },
        ),
      );
    } finally {
      notesController.dispose();
    }
  }


  static Future<RenewalDialogResult?> showVisit(
    BuildContext context, {
    required String visitorName,
    required String expiryDate,
  }) async {
    final currentExpiry = _parseFlexibleDate(expiryDate);

    if (currentExpiry == null) return null;

    int selectedMonths = 1;
    DateTime selectedDate = _calculateVisitDate(currentExpiry, selectedMonths);

    return showDialog<RenewalDialogResult>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final formatted = _formatDate(selectedDate);

          return Directionality(
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
                constraints: const BoxConstraints(maxWidth: 360),
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                              onPressed: () => Navigator.pop(dialogContext),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xffEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.autorenew,
                              color: Color(0xff2563EB),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Center(
                        child: Text(
                          'تجديد الزيارة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff111827),
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          visitorName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _infoRow(
                        'تاريخ انتهاء الزيارة الحالي:',
                        _formatDate(currentExpiry),
                        const Color(0xff6B7280),
                      ),
                      const SizedBox(height: 8),
                      _infoRow(
                        'تاريخ التجديد الجديد:',
                        formatted,
                        const Color(0xff2563EB),
                        highlight: true,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'مدة التجديد',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Color(0xff111827),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [1, 3].map((months) {
                          final selected = selectedMonths == months;
                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: selected
                                      ? const Color(0xFF1D4ED8)
                                      : const Color(0xffF8FAFC),
                                  foregroundColor: selected
                                      ? Colors.white
                                      : Colors.black87,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  setDialogState(() {
                                    selectedMonths = months;
                                    selectedDate = _calculateVisitDate(
                                      currentExpiry,
                                      months,
                                    );
                                  });
                                },
                                child: Text(
                                  '$months شهر',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'تعديل تاريخ التجديد',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Color(0xff111827),
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () async {
                          final picked = await AppDatePicker.show(
                            context,
                            initialDate: selectedDate,
                          );
                          if (picked == null) return;

                          final parsed = _parseFlexibleDate(picked);
                          if (parsed == null) return;

                          setDialogState(() {
                            selectedDate = parsed;
                          });
                        },
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xffF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xffE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_month_outlined,
                                size: 20,
                                color: Color(0xff64748B),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  formatted,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    color: Color(0xff334155),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_left,
                                size: 20,
                                color: Color(0xff94A3B8),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1D4ED8),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(
                                  dialogContext,
                                  RenewalDialogResult(
                                    currentExpiry: currentExpiry,
                                    newExpiry: selectedDate,
                                    months: selectedMonths,
                                    formattedDate: formatted,
                                    notes: '',
                                  ),
                                );
                              },
                              child: const Text(
                                'تأكيد التجديد',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: const Color(0xffF3F4F6),
                                foregroundColor: Colors.black87,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text(
                                'إلغاء',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
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
        },
      ),
    );
  }

  static DateTime _calculateVisitDate(DateTime expiry, int months) {
    return FamilyVisitCalculator.calculateNextRenewal(
      expiryDate: expiry,
      renewalMonths: months,
    );
  }

  static DateTime? _parseFlexibleDate(String value) {
    final normalized = value.replaceAll('/', '-').trim();
    if (normalized.isEmpty) return null;

    final direct = DateTime.tryParse(normalized);
    if (direct != null) {
      return DateTime(direct.year, direct.month, direct.day);
    }

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
      '${a.toString().padLeft(4, '0')}',
    );
  }

  static Widget _infoRow(
    String title,
    String value,
    Color valueColor, {
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xffF0FDF4) : const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight
              ? const Color(0xffBBF7D0)
              : const Color(0xffE2E8F0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: highlight
                    ? const Color(0xff166534)
                    : const Color(0xff475569),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
