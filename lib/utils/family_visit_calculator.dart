// lib/utils/family_visit_calculator.dart

/// حاسبة تجديد الزيارات العائلية.
///
/// مدد التجديد المسموح بها للزيارات العائلية:
/// - شهر واحد
/// - 3 أشهر
///
/// هذا الملف خاص بالزيارات العائلية فقط.
/// الموظفون لديهم حاسبة مستقلة في:
/// renewal_calculator.dart
class FamilyVisitCalculator {
  /// حساب تاريخ التجديد القادم للزيارة العائلية.
  ///
  /// يتم الاحتساب بالأيام:
  /// شهر واحد = 30 يوم
  /// 3 أشهر = 90 يوم
  static DateTime calculateNextRenewal({
    required DateTime expiryDate,
    int renewalMonths = 1,
    DateTime? fromDate,
  }) {
    final int renewalDays = _renewalDays(renewalMonths);
    final DateTime today = fromDate ?? DateTime.now();

    DateTime renewalDate =
        expiryDate.add(Duration(days: renewalDays));

    while (!renewalDate.isAfter(today)) {
      renewalDate =
          renewalDate.add(Duration(days: renewalDays));
    }

    return renewalDate;
  }

  static int _renewalDays(int renewalMonths) {
    switch (renewalMonths) {
      case 1:
        return 30;
      case 3:
        return 90;
      default:
        throw ArgumentError(
          'مدة تجديد الزيارة العائلية يجب أن تكون 1 أو 3 أشهر.',
        );
    }
  }

  static int getRenewalMonths(String? renewalPeriod) {
    if (renewalPeriod == null || renewalPeriod.trim().isEmpty) {
      return 1;
    }

    final String value = renewalPeriod.trim().toLowerCase();

    if (value.contains('3')) {
      return 3;
    }

    return 1;
  }

  static String formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();

    return '$day/$month/$year';
  }
}
