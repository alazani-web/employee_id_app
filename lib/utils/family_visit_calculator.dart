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
  /// [expiryDate] تاريخ انتهاء/بداية فترة الزيارة.
  ///
  /// [renewalMonths]:
  /// 1 = شهر واحد
  /// 3 = ثلاثة أشهر
  static DateTime calculateNextRenewal({
    required DateTime expiryDate,
    int renewalMonths = 1,
    DateTime? fromDate,
  }) {
    if (renewalMonths != 1 && renewalMonths != 3) {
      throw ArgumentError(
        'مدة تجديد الزيارة العائلية يجب أن تكون 1 أو 3 أشهر.',
      );
    }

    final DateTime today = fromDate ?? DateTime.now();

    DateTime renewalDate = _addMonths(
      expiryDate,
      renewalMonths,
    );

    // إذا كان موعد التجديد قد مضى،
    // ننتقل إلى موعد التجديد القادم حسب نفس دورة التجديد.
    while (!renewalDate.isAfter(today)) {
      renewalDate = _addMonths(
        renewalDate,
        renewalMonths,
      );
    }

    return renewalDate;
  }

  /// إضافة عدد من الأشهر إلى التاريخ.
  ///
  /// يتم التعامل مع الأشهر التي لا تحتوي على نفس رقم اليوم.
  ///
  /// مثال:
  /// 31 يناير + شهر
  /// = آخر يوم من فبراير.
  static DateTime _addMonths(
    DateTime date,
    int months,
  ) {
    final int totalMonths =
        date.year * 12 +
        (date.month - 1) +
        months;

    final int newYear = totalMonths ~/ 12;
    final int newMonth = (totalMonths % 12) + 1;

    // آخر يوم في الشهر الجديد.
    final int lastDayOfMonth =
        DateTime(newYear, newMonth + 1, 0).day;

    // الحفاظ على رقم اليوم قدر الإمكان.
    final int newDay =
        date.day > lastDayOfMonth
            ? lastDayOfMonth
            : date.day;

    return DateTime(
      newYear,
      newMonth,
      newDay,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  /// تحويل مدة التجديد من النص إلى عدد الأشهر.
  ///
  /// أمثلة:
  /// "شهر"       -> 1
  /// "شهر واحد"  -> 1
  /// "1 شهر"     -> 1
  /// "3 أشهر"    -> 3
  /// "3 شهر"     -> 3
  static int getRenewalMonths(String? renewalPeriod) {
    if (renewalPeriod == null ||
        renewalPeriod.trim().isEmpty) {
      return 1;
    }

    final String value =
        renewalPeriod.trim().toLowerCase();

    if (value.contains('3')) {
      return 3;
    }

    return 1;
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