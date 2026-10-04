// lib/utils/renewal_calculator.dart

/// حاسبة تجديد هويات الموظفين.
///
/// مدد التجديد المسموح بها للموظفين:
/// - 3 أشهر
/// - 6 أشهر
/// - 9 أشهر
/// - 12 شهر
///
/// هذا الملف خاص بالموظفين فقط.
/// الزيارات العائلية لها حاسبة مستقلة في:
/// family_visit_calculator.dart
class RenewalCalculator {
  /// حساب تاريخ التجديد القادم للموظف.
  ///
  /// وفق طريقة الاحتساب المرسلة:
  /// 3 أشهر = 90 يوم
  /// 6 أشهر = 178 يوم
  /// 12 شهر = 355 يوم
  ///
  /// ملاحظة: 9 أشهر غير موجودة صراحة في المرجع المرسل،
  /// وتم اعتماد 267 يوم كامتداد لدورة 3 أشهر.
  static DateTime calculateRenewalDate({
    required DateTime expiryDate,
    required int renewalMonths,
  }) {
    final int renewalDays = _renewalDays(renewalMonths);
    return expiryDate.add(Duration(days: renewalDays));
  }

  static int _renewalDays(int renewalMonths) {
    switch (renewalMonths) {
      case 3:
        return 90;
      case 6:
        return 178;
      case 9:
        return 206;
      case 12:
        return 355;
      default:
        throw ArgumentError(
          'مدة تجديد الموظف يجب أن تكون 3 أو 6 أو 9 أو 12 شهرًا.',
        );
    }
  }

  static int getRenewalMonths(String? renewalPeriod) {
    if (renewalPeriod == null || renewalPeriod.trim().isEmpty) {
      return 3;
    }

    final String value = renewalPeriod.trim().toLowerCase();

    if (value.contains('12')) {
      return 12;
    }
    if (value.contains('9')) {
      return 9;
    }
    if (value.contains('6')) {
      return 6;
    }
    if (value.contains('3')) {
      return 3;
    }

    return 3;
  }

  static String formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();

    return '$day/$month/$year';
  }
}
