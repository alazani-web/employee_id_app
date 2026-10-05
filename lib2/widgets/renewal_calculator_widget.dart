class RenewalCalculator {
  static DateTime? parseDate(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return null;

    final normalized = raw.replaceAll('/', '-');
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

    DateTime? parsed;
    if (a > 31) {
      parsed = DateTime.tryParse(
        '${a.toString().padLeft(4, '0')}-'
        '${b.toString().padLeft(2, '0')}-'
        '${c.toString().padLeft(2, '0')}',
      );
    } else {
      parsed = DateTime.tryParse(
        '${c.toString().padLeft(4, '0')}-'
        '${b.toString().padLeft(2, '0')}-'
        '${a.toString().padLeft(2, '0')}',
      );
    }

    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  static DateTime calculateRenewalDate({
    required DateTime expiryDate,
    required int renewalMonths,
  }) {
    return expiryDate.add(
      Duration(days: getRenewalDays(renewalMonths)),
    );
  }

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
