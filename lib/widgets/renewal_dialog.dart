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
                insetPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 350,
                    maxHeight: 560,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _dialogHeader(
                          title: 'تجديد بيانات الموظف',
                          subtitle: employeeName,
                          color: const Color(0xff16A34A),
                          onClose: () => Navigator.pop(dialogContext),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'مدة التجديد (بالأشهر)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 11.5,
                          ),
                        ),
                        const SizedBox(height: 7),
                        _monthButtons(
                          values: const [3, 6, 9, 12],
                          selected: selectedMonths,
                          onSelected: (value) =>
                              setDialogState(() => selectedMonths = value),
                          singular: false,
                        ),
                        const SizedBox(height: 11),
                        _infoRow(
                          'تاريخ الانتهاء الحالي:',
                          _formatDate(currentExpiry),
                          const Color(0xff6B7280),
                        ),
                        const SizedBox(height: 7),
                        _infoRow(
                          'تاريخ الانتهاء الجديد:',
                          formatted,
                          const Color(0xff15803D),
                          highlight: true,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'ملاحظات التجديد',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 11.5,
                          ),
                        ),
                        const SizedBox(height: 5),
                        TextField(
                          controller: notesController,
                          maxLines: 2,
                          textDirection: TextDirection.rtl,
                          decoration: InputDecoration(
                            hintText: 'أدخل ملاحظات اختيارية...',
                            hintStyle: const TextStyle(fontSize: 11),
                            filled: true,
                            fillColor: const Color(0xffF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 9,
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
                        const SizedBox(height: 13),
                        _dialogButtons(
                          confirmText: 'تأكيد التجديد',
                          onConfirm: () => Navigator.pop(
                            dialogContext,
                            RenewalDialogResult(
                              currentExpiry: currentExpiry,
                              newExpiry: newExpiry,
                              months: selectedMonths,
                              formattedDate: formatted,
                              notes: notesController.text.trim(),
                            ),
                          ),
                          onCancel: () => Navigator.pop(dialogContext),
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
    } finally {
      notesController.dispose();
    }
  }

  static Future<RenewalDialogResult?> showVisit(
    BuildContext context, {
    required String visitorName,
    required String expiryDate,
  }) async {
    final currentExpiry =
        RenewalCalculator.parseDate(expiryDate) ?? _parseFlexibleDate(expiryDate);

    if (currentExpiry == null) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تعذر فتح التجديد'),
            content: const Text(
              'تاريخ انتهاء الزيارة غير صالح. يرجى تعديل تاريخ الزيارة أولًا.',
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

    int selectedMonths = 1;
    DateTime selectedDate =
        _calculateVisitDate(currentExpiry, selectedMonths);

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
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 350,
                  maxHeight: 570,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _dialogHeader(
                        title: 'تجديد الزيارة',
                        subtitle: visitorName,
                        color: const Color(0xff2563EB),
                        onClose: () => Navigator.pop(dialogContext),
                      ),
                      const SizedBox(height: 11),
                      _infoRow(
                        'تاريخ انتهاء الزيارة الحالي:',
                        _formatDate(currentExpiry),
                        const Color(0xff6B7280),
                      ),
                      const SizedBox(height: 7),
                      _infoRow(
                        'تاريخ التجديد الجديد:',
                        formatted,
                        const Color(0xff2563EB),
                        highlight: true,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'مدة التجديد',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 11.5,
                          color: Color(0xff111827),
                        ),
                      ),
                      const SizedBox(height: 7),
                      _monthButtons(
                        values: const [1, 3],
                        selected: selectedMonths,
                        onSelected: (value) {
                          setDialogState(() {
                            selectedMonths = value;
                            selectedDate =
                                _calculateVisitDate(currentExpiry, value);
                          });
                        },
                        singular: true,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'تعديل تاريخ التجديد',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 11.5,
                          color: Color(0xff111827),
                        ),
                      ),
                      const SizedBox(height: 5),
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () async {
                          final picked = await AppDatePicker.show(
                            dialogContext,
                            initialDate: selectedDate,
                          );
                          if (picked == null || !dialogContext.mounted) return;

                          final parsed = _parseFlexibleDate(picked);
                          if (parsed == null) return;

                          setDialogState(() {
                            selectedDate = parsed;
                          });
                        },
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 11),
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
                                size: 19,
                                color: Color(0xff64748B),
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  formatted,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    color: Color(0xff334155),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_left,
                                size: 19,
                                color: Color(0xff94A3B8),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _dialogButtons(
                        confirmText: 'تأكيد التجديد',
                        onConfirm: () => Navigator.pop(
                          dialogContext,
                          RenewalDialogResult(
                            currentExpiry: currentExpiry,
                            newExpiry: selectedDate,
                            months: selectedMonths,
                            formattedDate: formatted,
                            notes: '',
                          ),
                        ),
                        onCancel: () => Navigator.pop(dialogContext),
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

  static Widget _dialogHeader({
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onClose,
  }) {
    return Row(
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
          onPressed: onClose,
          icon: const Icon(
            Icons.close,
            size: 18,
            color: Color(0xff6B7280),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                title,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Color(0xff111827),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Color(0xff6B7280),
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withOpacity(.10),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.autorenew,
            color: color,
            size: 19,
          ),
        ),
      ],
    );
  }

  static Widget _monthButtons({
    required List<int> values,
    required int selected,
    required ValueChanged<int> onSelected,
    required bool singular,
  }) {
    return Row(
      children: values.map((months) {
        final isSelected = selected == months;
        final label = singular
            ? '$months ${months == 1 ? 'شهر' : 'أشهر'}'
            : '$months أشهر';

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: SizedBox(
              height: 36,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected
                      ? const Color(0xFF1D4ED8)
                      : const Color(0xffF8FAFC),
                  foregroundColor:
                      isSelected ? Colors.white : Colors.black87,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => onSelected(months),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  static Widget _dialogButtons({
    required String confirmText,
    required VoidCallback onConfirm,
    required VoidCallback onCancel,
  }) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D4ED8),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: onConfirm,
            child: Text(
              confirmText,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xffF3F4F6),
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: onCancel,
            child: const Text(
              'إلغاء',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  static DateTime _calculateVisitDate(DateTime expiry, int months) {
    return FamilyVisitCalculator.calculateNextRenewal(
      expiryDate: expiry,
      renewalMonths: months,
    );
  }

  static DateTime? _parseFlexibleDate(String value) {
    var normalized = value.trim().replaceAll('/', '-');
    if (normalized.isEmpty) return null;

    // إزالة الوقت إذا كان التاريخ محفوظًا بصيغة ISO مع وقت.
    if (normalized.contains('T')) {
      normalized = normalized.split('T').first;
    }
    if (normalized.contains(' ')) {
      normalized = normalized.split(' ').first;
    }

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

    DateTime? result;

    if (a > 31) {
      result = DateTime.tryParse(
        '${a.toString().padLeft(4, '0')}-'
        '${b.toString().padLeft(2, '0')}-'
        '${c.toString().padLeft(2, '0')}',
      );
    } else {
      result = DateTime.tryParse(
        '${c.toString().padLeft(4, '0')}-'
        '${b.toString().padLeft(2, '0')}-'
        '${a.toString().padLeft(2, '0')}',
      );
    }

    if (result == null) return null;

    return DateTime(result.year, result.month, result.day);
  }

  static Widget _infoRow(
    String title,
    String value,
    Color valueColor, {
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xffF0FDF4) : const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(10),
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: highlight
                    ? const Color(0xff166534)
                    : const Color(0xff475569),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
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
