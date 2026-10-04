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
  /// [expiryDate] تاريخ بداية/انتهاء الفترة التي سيتم احتساب التجديد منها.
  ///
  /// [renewalMonths] مدة التجديد:
  /// 3 أو 6 أو 9 أو 12 شهر.
  ///
  /// يتم تطبيق تصحيح يومين لمطابقة احتساب تاريخ أبشر المستخدم
  /// في النظام الحالي.
  static DateTime calculateRenewalDate({
    required DateTime expiryDate,
    required int renewalMonths,
  }) {
    if (![3, 6, 9, 12].contains(renewalMonths)) {
      throw ArgumentError(
        'مدة تجديد الموظف يجب أن تكون 3 أو 6 أو 9 أو 12 شهرًا.',
      );
    }

    final int totalMonths =
        expiryDate.year * 12 +
        (expiryDate.month - 1) +
        renewalMonths;

    final int targetYear = totalMonths ~/ 12;
    final int targetMonth = (totalMonths % 12) + 1;

    // آخر يوم في الشهر المستهدف.
    final int lastDayOfTargetMonth =
        DateTime(targetYear, targetMonth + 1, 0).day;

    // المحافظة على يوم البداية قدر الإمكان.
    // إذا كان اليوم غير موجود في الشهر المستهدف،
    // يتم استخدام آخر يوم في ذلك الشهر.
    final int targetDay =
        expiryDate.day > lastDayOfTargetMonth
            ? lastDayOfTargetMonth
            : expiryDate.day;

    final DateTime calculatedDate = DateTime(
      targetYear,
      targetMonth,
      targetDay,
    );

    // تصحيح الفرق الحالي مع تاريخ أبشر.
    return calculatedDate.subtract(
      const Duration(days: 2),
    );
  }

  /// استخراج مدة التجديد من النص.
  ///
  /// أمثلة:
  /// "3 أشهر"  -> 3
  /// "6 أشهر"  -> 6
  /// "9 أشهر"  -> 9
  /// "12 شهر"  -> 12
  ///
  /// إذا لم يتم التعرف على المدة، يتم إرجاع 3 أشهر
  /// كقيمة افتراضية للموظفين.
  static int getRenewalMonths(String? renewalPeriod) {
    if (renewalPeriod == null ||
        renewalPeriod.trim().isEmpty) {
      return 3;
    }

    final String value =
        renewalPeriod.trim().toLowerCase();

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

  /// تنسيق التاريخ بصيغة:
  /// يوم/شهر/سنة
  static String formatDate(DateTime date) {
    final String day =
        date.day.toString().padLeft(2, '0');

    final String month =
        date.month.toString().padLeft(2, '0');

    final String year =
        date.year.toString();

    return '$day/$month/$year';
  }
}