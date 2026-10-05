// lib/utils/family_visit_calculator.dart

/// حاسبة تجديد الزيارات العائلية.
///
/// مدد التجديد المسموح بها:
/// 1 شهر
/// 3 أشهر
///
/// هذا الملف خاص بالزيارات العائلية فقط.
class FamilyVisitCalculator {
  /// حساب تاريخ التجديد القادم.
  ///
  /// expiryDate:
  /// تاريخ انتهاء الزيارة الحالي.
  ///
  /// renewalMonths:
  /// 1 = شهر
  /// 3 = ثلاثة أشهر
  static DateTime calculateRenewalDate({
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

    // إذا كان التاريخ الناتج قد مضى،
    // ننتقل للدورة التالية.
    while (!renewalDate.isAfter(today)) {
      renewalDate = _addMonths(
        renewalDate,
        renewalMonths,
      );
    }

    return renewalDate;
  }

  /// الاسم القديم للدالة، أبقيناه للتوافق
  /// مع أي ملف آخر يستخدمه.
  static DateTime calculateNextRenewal({
    required DateTime expiryDate,
    int renewalMonths = 1,
    DateTime? fromDate,
  }) {
    return calculateRenewalDate(
      expiryDate: expiryDate,
      renewalMonths: renewalMonths,
      fromDate: fromDate,
    );
  }

  /// إضافة أشهر للتاريخ مع مراعاة نهاية الشهر.
  ///
  /// مثال:
  /// 31 يناير + شهر = 28 فبراير
  /// أو 29 فبراير في السنة الكبيسة.
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

    final int lastDayOfMonth =
        DateTime(newYear, newMonth + 1, 0).day;

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

  /// تحويل النص إلى مدة التجديد.
  ///
  /// "شهر"       -> 1
  /// "شهر واحد"  -> 1
  /// "1 شهر"     -> 1
  /// "3 أشهر"    -> 3
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

  /// تنسيق التاريخ:
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