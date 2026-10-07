import 'dart:math' as math;



import 'package:flutter/material.dart';

import 'package:hijri_core/hijri_core.dart' as hijri;



/// منتقي التاريخ الموحد في التطبيق بالكامل.

///

/// المزايا:

/// - تصميم أعمدة متحركة (اليوم / الشهر / السنة) قريب من التصميم المرجعي.

/// - عربي بالكامل مع أرقام عربية.

/// - التبديل بين الميلادي والهجري من داخل المنتقي.

/// - القيمة التي ترجع للتطبيق تبقى بالتنسيق الميلادي ISO: yyyy-MM-dd

///   حتى لا تتأثر قاعدة البيانات أو التنبيهات الحالية.

class AppDatePicker {

  static const Color primaryBlue = Color(0xff1565C0);



  static Future<String?> show(

    BuildContext context, {

    DateTime? initialDate,

  }) async {

    final safeInitial = initialDate ?? DateTime.now();



    return showDialog<String>(

      context: context,

      barrierDismissible: true,

      builder: (_) => _UnifiedDatePickerDialog(

        initialDate: DateTime(

          safeInitial.year,

          safeInitial.month,

          safeInitial.day,

        ),

      ),

    );

  }

}



class _UnifiedDatePickerDialog extends StatefulWidget {

  const _UnifiedDatePickerDialog({required this.initialDate});



  final DateTime initialDate;



  @override

  State<_UnifiedDatePickerDialog> createState() =>

      _UnifiedDatePickerDialogState();

}



class _UnifiedDatePickerDialogState extends State<_UnifiedDatePickerDialog> {

  static const List<String> _gregorianMonths = [

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



  static const List<String> _hijriMonths = [

    'محرم',

    'صفر',

    'ربيع الأول',

    'ربيع الآخر',

    'جمادى الأولى',

    'جمادى الآخرة',

    'رجب',

    'شعبان',

    'رمضان',

    'شوال',

    'ذو القعدة',

    'ذو الحجة',

  ];



  static const List<String> _weekDays = [

    'أحد',

    'اثنين',

    'ثلاثاء',

    'أربعاء',

    'خميس',

    'جمعة',

    'سبت',

  ];



  late DateTime _selectedGregorian;

  late int _day;

  late int _month;

  late int _year;

  bool _isHijri = false;



  FixedExtentScrollController? _dayController;

  FixedExtentScrollController? _monthController;

  FixedExtentScrollController? _yearController;



  @override

  void initState() {

    super.initState();

    _selectedGregorian = widget.initialDate;

    _setGregorianWheels(widget.initialDate);

    _createControllers();

  }



  void _createControllers() {

    _dayController?.dispose();

    _monthController?.dispose();

    _yearController?.dispose();



    _dayController = FixedExtentScrollController(initialItem: _day - 1);

    _monthController = FixedExtentScrollController(initialItem: _month - 1);



    final yearIndex = _year - _yearMin;

    _yearController = FixedExtentScrollController(

      initialItem: yearIndex.clamp(0, _yearMax - _yearMin),

    );

  }



  int get _yearMin {

    final current = _isHijri

        ? _HijriDate.fromGregorian(DateTime.now()).year

        : DateTime.now().year;

    return current - 50;

  }



  int get _yearMax {

    final current = _isHijri

        ? _HijriDate.fromGregorian(DateTime.now()).year

        : DateTime.now().year;

    return current + 50;

  }



  void _setGregorianWheels(DateTime date) {

    _selectedGregorian = DateTime(date.year, date.month, date.day);

    if (_isHijri) {

      final h = _HijriDate.fromGregorian(_selectedGregorian);

      _day = h.day;

      _month = h.month;

      _year = h.year;

    } else {

      _day = _selectedGregorian.day;

      _month = _selectedGregorian.month;

      _year = _selectedGregorian.year;

    }

  }



  void _toggleCalendar() {
    final currentGregorian = _selectedGregorianFromWheels();

    setState(() {
      _isHijri = !_isHijri;
      _setGregorianWheels(currentGregorian);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncWheelControllers();
    });
  }

  void _syncWheelControllers() {
    if (_dayController != null && _dayController!.hasClients) {
      _dayController!.jumpToItem(
        (_day - 1).clamp(0, _daysInCurrentMonth - 1).toInt(),
      );
    }

    if (_monthController != null && _monthController!.hasClients) {
      _monthController!.jumpToItem((_month - 1).clamp(0, 11).toInt());
    }

    if (_yearController != null && _yearController!.hasClients) {
      _yearController!.jumpToItem(
        (_year - _yearMin).clamp(0, _yearMax - _yearMin).toInt(),
      );
    }
  }

  DateTime _selectedGregorianFromWheels() {

    if (_isHijri) {

      return _HijriDate(_year, _month, _day).toGregorian();

    }



    final maxDay = DateUtils.getDaysInMonth(_year, _month);

    final safeDay = math.min(_day, maxDay);

    return DateTime(_year, _month, safeDay);

  }



  int get _daysInCurrentMonth {

    if (!_isHijri) {

      return DateUtils.getDaysInMonth(_year, _month);

    }

    return _HijriDate.daysInMonth(_year, _month);

  }



  void _changeDay(int value) {
    setState(() {
      _day = value.clamp(1, _daysInCurrentMonth).toInt();
      _selectedGregorian = _selectedGregorianFromWheels();
    });
  }



  void _changeMonth(int value) {
    setState(() {
      _month = value.clamp(1, 12).toInt();
      if (_day > _daysInCurrentMonth) _day = _daysInCurrentMonth;
      _selectedGregorian = _selectedGregorianFromWheels();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncWheelControllers();
    });
  }



  void _changeYear(int value) {
    setState(() {
      _year = value;
      if (_day > _daysInCurrentMonth) _day = _daysInCurrentMonth;
      _selectedGregorian = _selectedGregorianFromWheels();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncWheelControllers();
    });
  }



  String get _selectedTitle {

    return '${_toArabicDigits(_day)} ${(_isHijri ? _hijriMonths : _gregorianMonths)[_month - 1]} ${_toArabicDigits(_year)}';

  }



  String get _calendarLabel => _isHijri ? 'هجري' : 'ميلادي';



  String _toArabicDigits(Object value) {

    const western = '0123456789';

    const arabic = '٠١٢٣٤٥٦٧٨٩';

    return value

        .toString()

        .split('')

        .map((char) {

          final index = western.indexOf(char);

          return index == -1 ? char : arabic[index];

        })

        .join();

  }



  String _formatGregorian(DateTime date) {

    return '${date.year.toString().padLeft(4, '0')}-'

        '${date.month.toString().padLeft(2, '0')}-'

        '${date.day.toString().padLeft(2, '0')}';

  }



  @override

  void dispose() {

    _dayController?.dispose();

    _monthController?.dispose();

    _yearController?.dispose();

    super.dispose();

  }



  @override

  Widget build(BuildContext context) {

    final selectedGregorian = _selectedGregorianFromWheels();

    final gregorianWeekday = _weekDays[selectedGregorian.weekday % 7];



    return Directionality(

      textDirection: TextDirection.rtl,

      child: Dialog(

        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),

        backgroundColor: Colors.white,

        elevation: 12,

        shape: RoundedRectangleBorder(

          borderRadius: BorderRadius.circular(28),

        ),

        clipBehavior: Clip.antiAlias,

        child: ConstrainedBox(

          constraints: const BoxConstraints(maxWidth: 380, maxHeight: 590),

          child: Column(

            mainAxisSize: MainAxisSize.min,

            children: [

              _buildHeader(selectedGregorian, gregorianWeekday),

              _buildCalendarToggle(),

              _buildWheels(),

              _buildSelectedGregorianHint(selectedGregorian),

              _buildActions(selectedGregorian),

            ],

          ),

        ),

      ),

    );

  }



  Widget _buildHeader(DateTime selectedGregorian, String weekday) {

    return Container(

      width: double.infinity,

      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),

      decoration: const BoxDecoration(

        color: Color(0xffF7FAFF),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Row(

            children: [

              Container(

                width: 40,

                height: 40,

                decoration: BoxDecoration(

                  color: AppDatePicker.primaryBlue.withValues(alpha: .10),

                  borderRadius: BorderRadius.circular(12),

                ),

                child: const Icon(

                  Icons.calendar_month_rounded,

                  color: AppDatePicker.primaryBlue,

                  size: 21,

                ),

              ),

              const SizedBox(width: 11),

              Expanded(

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    const Text(

                      'اختيار التاريخ',

                      style: TextStyle(

                        fontSize: 12,

                        color: Colors.black54,

                        fontWeight: FontWeight.w600,

                      ),

                    ),

                    const SizedBox(height: 2),

                    Text(

                      _selectedTitle,

                      style: const TextStyle(

                        fontSize: 20,

                        fontWeight: FontWeight.w800,

                        color: Colors.black87,

                      ),

                    ),

                  ],

                ),

              ),

              IconButton(

                tooltip: 'إغلاق',

                onPressed: () => Navigator.pop(context),

                icon: const Icon(Icons.close_rounded, color: Colors.black54),

              ),

            ],

          ),

          const SizedBox(height: 12),

          Row(

            children: [

              Icon(

                Icons.event_available_rounded,

                size: 15,

                color: AppDatePicker.primaryBlue,

              ),

              const SizedBox(width: 5),

              Text(

                '$_weekdayLabel · $_calendarLabel',

                style: const TextStyle(

                  fontSize: 11,

                  color: Colors.black54,

                  fontWeight: FontWeight.w600,

                ),

              ),

            ],

          ),

        ],

      ),

    );

  }



  String get _weekdayLabel {

    if (_isHijri) {

      return _weekDays[_selectedGregorianFromWheels().weekday % 7];

    }

    return _weekDays[_selectedGregorian.weekday % 7];

  }



  Widget _buildCalendarToggle() {

    return Padding(

      padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),

      child: Container(

        height: 44,

        padding: const EdgeInsets.all(4),

        decoration: BoxDecoration(

          color: const Color(0xffF1F5F9),

          borderRadius: BorderRadius.circular(14),

        ),

        child: Row(

          children: [

            Expanded(child: _buildCalendarOption('ميلادي', !_isHijri)),

            Expanded(child: _buildCalendarOption('هجري', _isHijri)),

          ],

        ),

      ),

    );

  }



  Widget _buildCalendarOption(String label, bool selected) {

    return GestureDetector(

      onTap: selected

          ? null

          : () {

              _toggleCalendar();

            },

      child: AnimatedContainer(

        duration: const Duration(milliseconds: 180),

        curve: Curves.easeOut,

        alignment: Alignment.center,

        decoration: BoxDecoration(

          color: selected ? AppDatePicker.primaryBlue : Colors.transparent,

          borderRadius: BorderRadius.circular(11),

          boxShadow: selected

              ? [

                  BoxShadow(

                    color: AppDatePicker.primaryBlue.withValues(alpha: .16),

                    blurRadius: 7,

                    offset: const Offset(0, 2),

                  ),

                ]

              : null,

        ),

        child: Text(

          label,

          style: TextStyle(

            fontSize: 12,

            fontWeight: FontWeight.bold,

            color: selected ? Colors.white : Colors.black54,

          ),

        ),

      ),

    );

  }



  Widget _buildWheels() {

    final days = _daysInCurrentMonth;

    final years = List<int>.generate(

      _yearMax - _yearMin + 1,

      (index) => _yearMin + index,

    );



    return Padding(

      padding: const EdgeInsets.fromLTRB(12, 7, 12, 0),

      child: SizedBox(

        height: 185,

        child: Stack(

          alignment: Alignment.center,

          children: [

            Positioned.fill(

              child: IgnorePointer(

                child: Center(

                  child: Container(

                    height: 48,

                    margin: const EdgeInsets.symmetric(horizontal: 3),

                    decoration: BoxDecoration(

                      color: AppDatePicker.primaryBlue.withValues(alpha: .07),

                      borderRadius: BorderRadius.circular(15),

                      border: Border.all(

                        color: AppDatePicker.primaryBlue.withValues(alpha: .14),

                      ),

                    ),

                  ),

                ),

              ),

            ),

            Row(

              children: [

                Expanded(

                  flex: 2,

                  child: _buildWheel(

                    controller: _dayController,

                    itemCount: days,

                    onChanged: _changeDay,

                    itemBuilder: (value) => _wheelText(_toArabicDigits(value)),

                  ),

                ),

                Expanded(

                  flex: 3,

                  child: _buildWheel(

                    controller: _monthController,

                    itemCount: 12,

                    onChanged: _changeMonth,

                    itemBuilder: (value) => _wheelText(

                      (_isHijri ? _hijriMonths : _gregorianMonths)[value - 1],

                      compact: false,

                    ),

                  ),

                ),

                Expanded(

                  flex: 2,

                  child: _buildWheel(

                    controller: _yearController,

                    itemCount: years.length,

                    onChanged: _changeYear,

                    itemBuilder: (value) => _wheelText(_toArabicDigits(value)),

                  ),

                ),

              ],

            ),

          ],

        ),

      ),

    );

  }



  Widget _buildWheel({

    required FixedExtentScrollController? controller,

    required int itemCount,

    required ValueChanged<int> onChanged,

    required Widget Function(int value) itemBuilder,

  }) {

    if (controller == null) return const SizedBox.shrink();



    return GestureDetector(

      // السحب يبقى يعمل كالمعتاد، والضغط على العمود يفتح قائمة كاملة.

      onTap: () => _showSelectionList(

        itemCount: itemCount,

        selectedValue: _currentWheelValue(itemCount),

        onSelected: onChanged,

      ),

      child: ListWheelScrollView.useDelegate(

        controller: controller,

        itemExtent: 48,

        diameterRatio: 1.65,

        perspective: 0.002,

        physics: const FixedExtentScrollPhysics(),

        overAndUnderCenterOpacity: 0.42,

        onSelectedItemChanged: (index) {

          final value = itemCount > 31 ? _yearMin + index : index + 1;

          onChanged(value);

        },

        childDelegate: ListWheelChildBuilderDelegate(

          childCount: itemCount,

          builder: (context, index) {

            final value = itemCount > 31 ? _yearMin + index : index + 1;

            return Center(child: itemBuilder(value));

          },

        ),

      ),

    );

  }



  int _currentWheelValue(int itemCount) {

    if (itemCount > 31) return _year;

    if (itemCount == 12) return _month;

    return _day;

  }



  Future<void> _showSelectionList({

    required int itemCount,

    required int selectedValue,

    required ValueChanged<int> onSelected,

  }) async {

    final isYear = itemCount > 31;

    final isMonth = itemCount == 12;



    final values = List<int>.generate(

      itemCount,

      (index) => isYear ? _yearMin + index : index + 1,

    );



    final title = isYear

        ? 'اختيار السنة'

        : isMonth

            ? 'اختيار الشهر'

            : 'اختيار اليوم';



    final selectedIndex = isYear

        ? (selectedValue - _yearMin)

        : (selectedValue - 1);



    // عند فتح القائمة نضع القيمة الحالية/المحددة في منتصف العرض تقريبًا،

    // بدل أن تبدأ القائمة من 1 أو من أقدم سنة.

    final listController = ScrollController(

      initialScrollOffset: math.max(0.0, selectedIndex * 50.0 - 150.0),

    );



    final result = await showDialog<int>(

      context: context,

      builder: (dialogContext) {

        return Directionality(

          textDirection: TextDirection.rtl,

          child: Dialog(

            backgroundColor: Colors.white,

            shape: RoundedRectangleBorder(

              borderRadius: BorderRadius.circular(22),

            ),

            child: ConstrainedBox(

              constraints: const BoxConstraints(

                maxWidth: 340,

                maxHeight: 500,

              ),

              child: Column(

                mainAxisSize: MainAxisSize.min,

                children: [

                  Padding(

                    padding: const EdgeInsets.fromLTRB(18, 16, 10, 10),

                    child: Row(

                      children: [

                        Expanded(

                          child: Text(

                            title,

                            style: const TextStyle(

                              fontSize: 17,

                              fontWeight: FontWeight.w800,

                            ),

                          ),

                        ),

                        IconButton(

                          onPressed: () => Navigator.pop(dialogContext),

                          icon: const Icon(Icons.close_rounded),

                        ),

                      ],

                    ),

                  ),

                  const Divider(height: 1),

                  Expanded(

                    child: ListView.builder(

                      controller: listController,

                      itemExtent: 50,

                      itemCount: values.length,

                      padding: const EdgeInsets.symmetric(

                        horizontal: 12,

                        vertical: 8,

                      ),

                      itemBuilder: (_, index) {

                        final value = values[index];

                        final selected = value == selectedValue;

                        final label = isYear

                            ? _toArabicDigits(value)

                            : isMonth

                                ? (_isHijri

                                    ? _hijriMonths[value - 1]

                                    : _gregorianMonths[value - 1])

                                : _toArabicDigits(value);



                        return Padding(

                          padding: const EdgeInsets.symmetric(vertical: 3),

                          child: InkWell(

                            borderRadius: BorderRadius.circular(12),

                            onTap: () => Navigator.pop(dialogContext, value),

                            child: Container(

                              height: 44,

                              alignment: Alignment.center,

                              decoration: BoxDecoration(

                                color: selected

                                    ? AppDatePicker.primaryBlue.withValues(

                                        alpha: .10,

                                      )

                                    : Colors.transparent,

                                borderRadius: BorderRadius.circular(12),

                                border: selected

                                    ? Border.all(

                                        color: AppDatePicker.primaryBlue

                                            .withValues(alpha: .28),

                                      )

                                    : null,

                              ),

                              child: Text(

                                label,

                                style: TextStyle(

                                  fontSize: isMonth ? 14 : 16,

                                  fontWeight: selected

                                      ? FontWeight.w800

                                      : FontWeight.w600,

                                  color: selected

                                      ? AppDatePicker.primaryBlue

                                      : Colors.black87,

                                ),

                              ),

                            ),

                          ),

                        );

                      },

                    ),

                  ),

                  Padding(

                    padding: const EdgeInsets.all(12),

                    child: SizedBox(

                      width: double.infinity,

                      height: 44,

                      child: OutlinedButton(

                        onPressed: () => Navigator.pop(dialogContext),

                        child: const Text(

                          'إلغاء',

                          style: TextStyle(fontWeight: FontWeight.bold),

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



    listController.dispose();

    if (!mounted || result == null) return;

    onSelected(result);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (isYear && _yearController != null && _yearController!.hasClients) {
        _yearController!.jumpToItem(
          (result - _yearMin).clamp(0, _yearMax - _yearMin).toInt(),
        );
      } else if (isMonth && _monthController != null && _monthController!.hasClients) {
        _monthController!.jumpToItem((result - 1).clamp(0, 11).toInt());
      } else if (_dayController != null && _dayController!.hasClients) {
        _dayController!.jumpToItem(
          (result - 1).clamp(0, _daysInCurrentMonth - 1).toInt(),
        );
      }
    });

  }



  Widget _wheelText(String text, {bool compact = true}) {

    return Text(

      text,

      maxLines: 1,

      overflow: TextOverflow.ellipsis,

      textAlign: TextAlign.center,

      style: TextStyle(

        fontSize: compact ? 19 : 15,

        fontWeight: FontWeight.w800,

        color: Colors.black87,

      ),

    );

  }



  Widget _buildSelectedGregorianHint(DateTime selectedGregorian) {

    return Padding(

      padding: const EdgeInsets.fromLTRB(20, 4, 20, 2),

      child: Text(

        'سيتم حفظ التاريخ ميلاديًا: ${_toArabicDigits(selectedGregorian.day)} ${_gregorianMonths[selectedGregorian.month - 1]} ${_toArabicDigits(selectedGregorian.year)}',

        textAlign: TextAlign.center,

        style: const TextStyle(

          fontSize: 10,

          color: Colors.black45,

          fontWeight: FontWeight.w600,

        ),

      ),

    );

  }



  Widget _buildActions(DateTime selectedGregorian) {

    return Padding(

      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),

      child: Row(

        children: [

          Expanded(

            child: SizedBox(

              height: 48,

              child: OutlinedButton(

                onPressed: () => Navigator.pop(context),

                style: OutlinedButton.styleFrom(

                  foregroundColor: Colors.black54,

                  side: BorderSide(color: Colors.grey.shade200),

                  shape: RoundedRectangleBorder(

                    borderRadius: BorderRadius.circular(15),

                  ),

                ),

                child: const Text(

                  'إلغاء',

                  style: TextStyle(fontWeight: FontWeight.bold),

                ),

              ),

            ),

          ),

          const SizedBox(width: 10),

          Expanded(

            child: SizedBox(

              height: 48,

              child: ElevatedButton(

                onPressed: () {

                  Navigator.pop(context, _formatGregorian(selectedGregorian));

                },

                style: ElevatedButton.styleFrom(

                  backgroundColor: AppDatePicker.primaryBlue,

                  foregroundColor: Colors.white,

                  elevation: 0,

                  shape: RoundedRectangleBorder(

                    borderRadius: BorderRadius.circular(15),

                  ),

                ),

                child: const Text(

                  'تأكيد',

                  style: TextStyle(

                    fontWeight: FontWeight.bold,

                    fontSize: 14,

                  ),

                ),

              ),

            ),

          ),

        ],

      ),

    );

  }

}



/// تحويل تقويمي إسلامي حسابي إلى/من الميلادي.

///

/// لا يغير قيمة التاريخ المخزنة في التطبيق؛ الهجري هنا واجهة اختيار فقط،

/// ثم يرجع التاريخ الميلادي إلى بقية النظام.

class _HijriDate {

  const _HijriDate(this.year, this.month, this.day);



  final int year;

  final int month;

  final int day;



  /// التحويل الرسمي المستخدم هنا هو تقويم أم القرى السعودي.

  /// نستخدم مكتبة hijri_core لأنها مبنية على جدول أم القرى،

  /// بدل التحويل الحسابي التقريبي الذي كان يسبب اختلافات كبيرة.

  static _HijriDate fromGregorian(DateTime date) {

    final result = hijri.toHijri(

      DateTime.utc(date.year, date.month, date.day),

    );



    if (result == null) {

      throw StateError(

        'تعذر تحويل التاريخ الميلادي إلى الهجري ضمن نطاق تقويم أم القرى.',

      );

    }



    return _HijriDate(result.hy, result.hm, result.hd);

  }



  DateTime toGregorian() {

    final result = toGregorianDate(year, month, day);



    if (result == null) {

      throw StateError(

        'تعذر تحويل التاريخ الهجري إلى الميلادي ضمن نطاق تقويم أم القرى.',

      );

    }



    return DateTime(result.year, result.month, result.day);

  }



  static DateTime? toGregorianDate(int year, int month, int day) {

    return hijri.toGregorian(year, month, day);

  }



  static int daysInMonth(int year, int month) {

    return hijri.daysInHijriMonth(year, month);

  }

}
