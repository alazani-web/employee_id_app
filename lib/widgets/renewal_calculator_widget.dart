import 'package:flutter/material.dart';

class RenewalCalculatorWidget extends StatefulWidget {
  final DateTime currentExpiryDate; // تاريخ الانتهاء الحالي للموظف
  final Function(DateTime newDate)? onDateChanged; // لإرسال التاريخ الجديد عند تغييره

  const RenewalCalculatorWidget({
    Key? key,
    required this.currentExpiryDate,
    this.onDateChanged,
  }) : super(key: key);

  @override
  State<RenewalCalculatorWidget> createState() => _RenewalCalculatorWidgetState();
}

class _RenewalCalculatorWidgetState extends State<RenewalCalculatorWidget> {
  // مدة التجديد بالأشهر (3، 6، 9، 12، 24)
  final List<int> _renewalOptionsInMonths = [3, 6, 9, 12, 24]; 
  int? _selectedMonths;
  DateTime? _newExpiryDate;

  // دالة حساب تاريخ الانتهاء الجديد (حسب نظام الجوازات)
  DateTime calculateSaudiRenewalDate(DateTime startDate, int monthsToAdd) {
    int targetYear = startDate.year + ((startDate.month + monthsToAdd - 1) ~/ 12);
    int targetMonth = ((startDate.month + monthsToAdd - 1) % 12) + 1;

    // معرفة عدد أيام الشهر المستهدف لتجنب تجاوز نهاية الشهر (مثلاً 29/30/31)
    int lastDayOfTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;
    int targetDay = startDate.day > lastDayOfTargetMonth ? lastDayOfTargetMonth : startDate.day;

    DateTime calculatedDate = DateTime(targetYear, targetMonth, targetDay);

    // خصم يوم واحد ليطابق طريقة احتساب الجوازات (نهاية التجديد تكون اليوم السابق)
    return calculatedDate.subtract(const Duration(days: 1));
  }

  void _onDurationChanged(int? months) {
    if (months == null) return;
    setState(() {
      _selectedMonths = months;
      _newExpiryDate = calculateSaudiRenewalDate(widget.currentExpiryDate, months);
    });

    // إرسال النتيجة للشاشة الرئيسية عند تحديد خيار
    if (widget.onDateChanged != null && _newExpiryDate != null) {
      widget.onDateChanged!(_newExpiryDate!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // قائمة اختيار مدة التجديد
        DropdownButtonFormField<int>(
          decoration: const InputDecoration(
            labelText: 'مدة التجديد',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          ),
          value: _selectedMonths,
          hint: const Text('اختر مدة التجديد (3، 6، 9... أشهر)'),
          items: _renewalOptionsInMonths.map((int months) {
            String label = months >= 12 
                ? '${months ~/ 12} سنة (${months} شهر)' 
                : '$months أشهر';
            return DropdownMenuItem<int>(
              value: months,
              child: Text(label),
            );
          }).toList(),
          onChanged: _onDurationChanged,
        ),
        
        const SizedBox(height: 12),

        // عرض تاريخ الانتهاء الجديد للموظف
        if (_newExpiryDate != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'تاريخ الانتهاء الجديد للموظف:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_newExpiryDate!.year}/${_newExpiryDate!.month.toString().padLeft(2, '0')}/${_newExpiryDate!.day.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}