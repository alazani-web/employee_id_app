import 'package:flutter/material.dart';

/// منتقي التاريخ الموحد في التطبيق بالكامل.
/// لا يستخدم showDatePicker لذلك لا يعتمد على MaterialLocalizations.
class AppDatePicker {
  static const Color primaryBlue = Color(0xff1565C0);

  static Future<String?> show(
    BuildContext context, {
    DateTime? initialDate,
  }) async {
    DateTime selectedDate = initialDate ?? DateTime.now();
    DateTime displayedMonth =
        DateTime(selectedDate.year, selectedDate.month, 1);
    bool isYearMonthPickerOpen = false;

    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setPickerState) {
            final daysInMonth = DateUtils.getDaysInMonth(
              displayedMonth.year,
              displayedMonth.month,
            );

            // يبدأ الأسبوع من الأحد بما يتوافق مع واجهة التطبيق العربية.
            final firstDayOffset =
                DateTime(displayedMonth.year, displayedMonth.month, 1).weekday %
                    7;

            const monthNames = [
              'يناير',
              'فبراير',
              'مارس',
              'أبريل',
              'مايو',
              'يونيو',
              'يوليو',
              'أغسطس',
              'سبتمبر',
              'أكتوبر',
              'نوفمبر',
              'ديسمبر',
            ];

            const weekDays = [
              'أحد',
              'اثنين',
              'ثلاثاء',
              'أربعاء',
              'خميس',
              'جمعة',
              'سبت',
            ];

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Dialog(
                insetPadding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // رأس منتقي التاريخ — نفس تصميم الموظفين
                      InkWell(
                        onTap: () {
                          setPickerState(() {
                            isYearMonthPickerOpen = !isYearMonthPickerOpen;
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          color: primaryBlue,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'تاريخ الاختيار (انقر لتغيير السنة والشهر)',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Icon(
                                    Icons.unfold_more,
                                    color: Colors.white.withValues(alpha: .8),
                                    size: 16,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${monthNames[displayedMonth.month - 1]}، ${displayedMonth.year}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (isYearMonthPickerOpen)
                        _buildYearMonthSelector(
                          displayedMonth: displayedMonth,
                          monthNames: monthNames,
                          onYearChanged: (year) {
                            setPickerState(() {
                              displayedMonth =
                                  DateTime(year, displayedMonth.month, 1);
                            });
                          },
                          onMonthChanged: (month) {
                            setPickerState(() {
                              displayedMonth =
                                  DateTime(displayedMonth.year, month, 1);
                              isYearMonthPickerOpen = false;
                            });
                          },
                        )
                      else ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                tooltip: 'الشهر السابق',
                                onPressed: () {
                                  setPickerState(() {
                                    displayedMonth = DateTime(
                                      displayedMonth.year,
                                      displayedMonth.month - 1,
                                      1,
                                    );
                                  });
                                },
                                icon: const Icon(
                                  Icons.chevron_right,
                                  color: primaryBlue,
                                ),
                              ),
                              Text(
                                '${monthNames[displayedMonth.month - 1]} ${displayedMonth.year}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                tooltip: 'الشهر التالي',
                                onPressed: () {
                                  setPickerState(() {
                                    displayedMonth = DateTime(
                                      displayedMonth.year,
                                      displayedMonth.month + 1,
                                      1,
                                    );
                                  });
                                },
                                icon: const Icon(
                                  Icons.chevron_left,
                                  color: primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Row(
                            children: weekDays
                                .map(
                                  (day) => Expanded(
                                    child: Center(
                                      child: Text(
                                        day,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),

                        const SizedBox(height: 6),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: daysInMonth + firstDayOffset,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              mainAxisSpacing: 4,
                              crossAxisSpacing: 4,
                            ),
                            itemBuilder: (context, index) {
                              if (index < firstDayOffset) {
                                return const SizedBox.shrink();
                              }

                              final dayNumber =
                                  index - firstDayOffset + 1;

                              final isSelected =
                                  selectedDate.year ==
                                          displayedMonth.year &&
                                      selectedDate.month ==
                                          displayedMonth.month &&
                                      selectedDate.day == dayNumber;

                              final today = DateTime.now();
                              final isToday =
                                  today.year == displayedMonth.year &&
                                      today.month == displayedMonth.month &&
                                      today.day == dayNumber;

                              return InkWell(
                                onTap: () {
                                  final picked = DateTime(
                                    displayedMonth.year,
                                    displayedMonth.month,
                                    dayNumber,
                                  );

                                  final formatted =
                                      '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';

                                  Navigator.pop(dialogContext, formatted);
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xffEBF3FE)
                                        : Colors.transparent,
                                    border: isSelected
                                        ? Border.all(
                                            color: primaryBlue,
                                            width: 1.5,
                                          )
                                        : isToday
                                            ? Border.all(
                                                color: primaryBlue
                                                    .withValues(alpha: .35),
                                              )
                                            : null,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$dayNumber',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected || isToday
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? primaryBlue
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),

                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xffF1F5F9),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () =>
                                Navigator.pop(dialogContext, null),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.black87,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'إلغاء',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildYearMonthSelector({
    required DateTime displayedMonth,
    required List<String> monthNames,
    required ValueChanged<int> onYearChanged,
    required ValueChanged<int> onMonthChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'اختر السنة:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: displayedMonth.year,
                isExpanded: true,
                items: List.generate(31, (index) => 2000 + index)
                    .map(
                      (year) => DropdownMenuItem<int>(
                        value: year,
                        child: Text(
                          '$year',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) onYearChanged(value);
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'اختر الشهر:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 12,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final isSelected = displayedMonth.month == index + 1;

              return InkWell(
                onTap: () => onMonthChanged(index + 1),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? primaryBlue : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? primaryBlue
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Text(
                    monthNames[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
