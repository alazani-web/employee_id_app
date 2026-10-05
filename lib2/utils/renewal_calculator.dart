class RenewalCalculator {
  /// قراءة تاريخ الانتهاء من جميع الصيغ المستخدمة في التطبيق.
  ///
  /// يدعم:
  /// yyyy-MM-dd
  /// dd-MM-yyyy
  /// dd/MM/yyyy
  static DateTime? parseDate(String value) {
    final raw = value.trim();

    if (raw.isEmpty) {
      return null;
    }

    final normalized = raw.replaceAll('/', '-');

    // أولاً: yyyy-MM-dd
    final direct = DateTime.tryParse(normalized);

    if (direct != null) {
      return DateTime(
        direct.year,
        direct.month,
        direct.day,
      );
    }

    // ثانياً: محاولة قراءة dd-MM-yyyy
    final parts = normalized.split('-');

    if (parts.length != 3) {
      return null;
    }

    final first = int.tryParse(parts[0]);
    final second = int.tryParse(parts[1]);
    final third = int.tryParse(parts[2]);

    if (first == null ||
        second == null ||
        third == null) {
      return null;
    }

    DateTime? parsed;

    // yyyy-MM-dd
    if (first > 31) {
      parsed = DateTime.tryParse(
        '${first.toString().padLeft(4, '0')}-'
        '${second.toString().padLeft(2, '0')}-'
        '${third.toString().padLeft(2, '0')}',
      );
    }

    // dd-MM-yyyy
    else {
      parsed = DateTime.tryParse(
        '${third.toString().padLeft(4, '0')}-'
        '${second.toString().padLeft(2, '0')}-'
        '${first.toString().padLeft(2, '0')}',
      );
    }

    if (parsed == null) {
      return null;
    }

    return DateTime(
      parsed.year,
      parsed.month,
      parsed.day,
    );
  }

  /// حساب تاريخ الانتهاء الجديد.
  ///
  /// مهم:
  /// الحساب يبدأ من تاريخ انتهاء الهوية الحالي،
  /// وليس من تاريخ اليوم.
  static DateTime calculateRenewalDate({
    required DateTime expiryDate,
    required int renewalMonths,
  }) {
    return expiryDate.add(
      Duration(
        days: getRenewalDays(renewalMonths),
      ),
    );
  }

  /// معادلة التجديد المعتمدة في التطبيق.
  static int getRenewalDays(int renewalMonths) {
    switch (renewalMonths) {
      case 3:
        return 90;

      case 6:
        return 178;

      case 9:
        return 267;

      case 12:
        return 355;

      default:
        throw ArgumentError(
          'مدة التجديد يجب أن تكون 3 أو 6 أو 9 أو 12 شهر',
        );
    }
  }
}