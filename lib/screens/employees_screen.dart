import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/employee_provider.dart';
import '../models/employee.dart';
import '../utils/renewal_calculator.dart';
import '../widgets/action_result_dialog.dart';
import '../widgets/renewal_dialog.dart';
import 'import_screen.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  int selectedFilter = 0;
  final TextEditingController searchController = TextEditingController();

  final List<String> filters = [
    "الكل",
    "نشط",
    "تنتهي قريباً",
    "منتهي",
  ];

  DateTime? _parseEmployeeDate(String value) {
    return RenewalCalculator.parseDate(value);
  }

  Map<String, dynamic> _getCalculatedStatus(String expiryDateStr) {
    final expiryDate = _parseEmployeeDate(expiryDateStr);
    if (expiryDate == null) {
      return {'status': 'سارية', 'daysLeft': null};
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final difference = expiryDate.difference(today).inDays;

    if (difference < 0) {
      return {'status': 'منتهية', 'daysLeft': difference};
    }
    if (difference <= 30) {
      return {'status': 'تحتاج متابعة', 'daysLeft': difference};
    }
    return {'status': 'سارية', 'daysLeft': difference};
  }

  // حساب تاريخ تجديد هوية الموظف من الحاسبة الموحدة.
  // هذا التعديل خاص بتجديد هويات الموظفين فقط.
  // الزيارات العائلية لها حاسبتها المستقلة.
  DateTime calculateSaudiRenewalDate(DateTime startDate, int monthsToAdd) {
    return RenewalCalculator.calculateRenewalDate(
      expiryDate: startDate,
      renewalMonths: monthsToAdd,
    );
  }

  Future<String?> _showCustomDatePicker(BuildContext context, {DateTime? initialDate}) async {
    DateTime selectedDate = initialDate ?? DateTime.now();
    DateTime displayedMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    bool isYearMonthPickerOpen = false;

    return await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (context, setPickerState) {
            final daysInMonth = DateUtils.getDaysInMonth(displayedMonth.year, displayedMonth.month);
            final firstDayOffset = DateTime(displayedMonth.year, displayedMonth.month, 1).weekday % 7;

            final monthNames = [
              "يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو",
              "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر"
            ];

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Dialog(
                insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          setPickerState(() {
                            isYearMonthPickerOpen = !isYearMonthPickerOpen;
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          color: const Color(0xff1565C0),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "تاريخ الاختيار (انقر لتغيير السنة والشهر)",
                                    style: TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                  Icon(Icons.unfold_more, color: Colors.white.withValues(alpha: 0.8), size: 16),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${monthNames[displayedMonth.month - 1]}، ${displayedMonth.year}",
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
                      if (isYearMonthPickerOpen) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xffF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("اختر السنة:", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
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
                                    items: List.generate(20, (index) => 2020 + index).map((year) {
                                      return DropdownMenuItem<int>(
                                        value: year,
                                        child: Text("$year", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setPickerState(() {
                                          displayedMonth = DateTime(val, displayedMonth.month, 1);
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text("اختر الشهر:", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
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
                                    onTap: () {
                                      setPickerState(() {
                                        displayedMonth = DateTime(displayedMonth.year, index + 1, 1);
                                        isYearMonthPickerOpen = false;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isSelected ? const Color(0xff1565C0) : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: isSelected ? const Color(0xff1565C0) : Colors.grey.shade200),
                                      ),
                                      child: Text(
                                        monthNames[index],
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                decoration: const BoxDecoration(color: Color(0xffF8FAFC), shape: BoxShape.circle),
                                child: IconButton(
                                  icon: const Icon(Icons.chevron_right, color: Colors.black87, size: 20),
                                  onPressed: () {
                                    setPickerState(() {
                                      displayedMonth = DateTime(displayedMonth.year, displayedMonth.month - 1, 1);
                                    });
                                  },
                                ),
                              ),
                              Text(
                                "${monthNames[displayedMonth.month - 1]} ${displayedMonth.year}",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Container(
                                decoration: const BoxDecoration(color: Color(0xffF8FAFC), shape: BoxShape.circle),
                                child: IconButton(
                                  icon: const Icon(Icons.chevron_left, color: Colors.black87, size: 20),
                                  onPressed: () {
                                    setPickerState(() {
                                      displayedMonth = DateTime(displayedMonth.year, displayedMonth.month + 1, 1);
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: const [
                              _DayLabel("ح"),
                              _DayLabel("ن"),
                              _DayLabel("ث"),
                              _DayLabel("ر"),
                              _DayLabel("خ"),
                              _DayLabel("ج"),
                              _DayLabel("س"),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: daysInMonth + firstDayOffset,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              mainAxisSpacing: 4,
                              crossAxisSpacing: 4,
                            ),
                            itemBuilder: (context, index) {
                              if (index < firstDayOffset) {
                                return const SizedBox.shrink();
                              }
                              final dayNumber = index - firstDayOffset + 1;
                              final isSelected = selectedDate.year == displayedMonth.year &&
                                  selectedDate.month == displayedMonth.month &&
                                  selectedDate.day == dayNumber;

                              return InkWell(
                                onTap: () {
                                  final picked = DateTime(displayedMonth.year, displayedMonth.month, dayNumber);
                                  final formatted = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                                  Navigator.pop(ctx, formatted);
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xffEBF3FE) : Colors.transparent,
                                    border: isSelected ? Border.all(color: const Color(0xff1565C0), width: 1.5) : null,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    "$dayNumber",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? const Color(0xff1565C0) : Colors.black87,
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
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xffF1F5F9),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () => Navigator.pop(ctx, null),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.close, size: 16, color: Colors.black87),
                                SizedBox(width: 6),
                                Text("إلغاء", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
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

  @override
  Widget build(BuildContext context) {
    final employeeProvider = Provider.of<EmployeeProvider>(context);
    final allEmployees = employeeProvider.employees;

    final filteredEmployees = allEmployees.where((emp) {
      final matchesSearch = emp.name.contains(searchController.text) ||
          emp.idNumber.contains(searchController.text);
      if (!matchesSearch) return false;

      final statusData = _getCalculatedStatus(emp.expiryDate);
      final currentStatus = statusData['status'];

      if (selectedFilter == 0) return true;
      if (selectedFilter == 1) return currentStatus == "سارية" || currentStatus == "نشط";
      if (selectedFilter == 2) return currentStatus == "تحتاج متابعة" || currentStatus == "تنتهي قريباً";
      if (selectedFilter == 3) return currentStatus == "منتهية" || currentStatus == "منتهي";

      return true;
    }).toList();

    // ترتيب الموظفين حسب المدة المتبقية للهوية:
    // الأقل مدة أولاً، ثم الأطول مدة.
    // الهوية المنتهية (أيام سالبة) تظهر أولاً.
    filteredEmployees.sort((a, b) {
      final aStatus = _getCalculatedStatus(a.expiryDate);
      final bStatus = _getCalculatedStatus(b.expiryDate);

      final aDays = aStatus['daysLeft'] as int?;
      final bDays = bStatus['daysLeft'] as int?;

      if (aDays == null && bDays == null) {
        return a.name.compareTo(b.name);
      }
      if (aDays == null) return 1;
      if (bDays == null) return -1;

      final byDays = aDays.compareTo(bDays);
      if (byDays != 0) return byDays;

      return a.name.compareTo(b.name);
    });

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            const SizedBox(height: 15),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: searchController,
                textAlign: TextAlign.right,
                onChanged: (val) => setState(() {}),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "البحث بالاسم أو رقم الهوية...",
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(filters.length, (index) {
                  bool active = selectedFilter == index;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: index == filters.length - 1 ? 0 : 6.0),
                      child: GestureDetector(
                        onTap: () => setState(() => selectedFilter = index),
                        child: Container(
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: active ? const Color(0xff1D4ED8) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: active ? const Color(0xff1D4ED8) : Colors.grey.shade200,
                            ),
                          ),
                          child: Text(
                            filters[index],
                            style: TextStyle(
                              color: active ? Colors.white : Colors.black87,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: const Color(0xFFF7F8FC),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          'الحالة',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Align(
                        alignment: Alignment.center,
                        child: const Text(
                          'رقم الهوية',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: const Text(
                          'اسم الموظف',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: filteredEmployees.isEmpty
                  ? const Center(child: Text("لا يوجد موظفين مسجلين", style: TextStyle(color: Colors.grey)))
                  : ListView.separated(
                      itemCount: filteredEmployees.length,
                      separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
                      itemBuilder: (context, index) {
                        final emp = filteredEmployees[index];
                        final statusData = _getCalculatedStatus(emp.expiryDate);

                        return InkWell(
                          onTap: () => _showEmployeeActionsModal(context, emp),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 20,
                            ),
                            child: Directionality(
                              textDirection: TextDirection.ltr,
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: _buildStatusBadge(
                                            statusData['status'],
                                          ),
                                        ),
                                        if (statusData['daysLeft'] != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            statusData['daysLeft'] < 0
                                                ? "متأخرة ${statusData['daysLeft'].abs()} يوم"
                                                : "متبقي ${statusData['daysLeft']} يوم",
                                            textAlign: TextAlign.left,
                                            style: const TextStyle(
                                              fontSize: 9.5,
                                              color: Color(0xFF111827),
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      children: [
                                        Text(
                                          emp.idNumber.isEmpty ? '-' : emp.idNumber,
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF111827),
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'رقم الهوية',
                                          style: TextStyle(
                                            color: Color(0xFF9CA3AF),
                                            fontSize: 9,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Directionality(
                                        textDirection: TextDirection.rtl,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: Text(
                                                emp.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.right,
                                                style: const TextStyle(
                                                  color: Color(0xFF111827),
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: Text(
                                                emp.expiryDate,
                                                textAlign: TextAlign.right,
                                                style: const TextStyle(
                                                  color: Color(0xFF6B7280),
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w400,
                                                ),
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
                    ),
            ),
          ],
        ),

        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddActionChoiceDialog(context),
          backgroundColor: const Color(0xff0D2869),
          shape: const CircleBorder(),
          elevation: 3,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  void _showAddActionChoiceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xffF1F5F9),
                      radius: 18,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 18, color: Colors.black54),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                    const Text(
                      'اختر العملية',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    showAddEmployeeDialog(context);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xffF1F5F9), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xffEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.person_add_alt_1_outlined, color: Color(0xff2563EB), size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('إضافة موظف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                              SizedBox(height: 2),
                              Text('إضافة موظف جديد إلى النظام', style: TextStyle(color: Colors.grey, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    Future.microtask(() {
                      if (!context.mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ImportScreen(),
                        ),
                      );
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xffF1F5F9), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xffEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.file_upload_outlined, color: Color(0xff2563EB), size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('استيراد موظفين', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                              SizedBox(height: 2),
                              Text('استيراد موظفين من ملف بيانات', style: TextStyle(color: Colors.grey, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff0F172A),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('إغلاق', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = const Color(0xffE8F5E9);
    Color text = const Color(0xff2E7D32);

    if (status == "تحتاج متابعة" || status == "تنتهي قريباً") {
      bg = const Color(0xffFFF7ED);
      text = const Color(0xffD97706);
    } else if (status == "منتهية" || status == "منتهي") {
      bg = const Color(0xffFFEBEE);
      text = const Color(0xffC62828);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(status, style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  void _showEmployeeActionsModal(BuildContext context, Employee emp) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xffF3F4F6),
                      radius: 16,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xffEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.edit_note, color: Color(0xff2563EB), size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text("إجراءات الموظف", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(emp.name, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        label: "السجل",
                        icon: Icons.visibility_outlined,
                        color: const Color(0xff2563EB),
                        bgColor: const Color(0xffF0F5FF),
                        onTap: () {
                          Navigator.pop(ctx);
                          _showLogsDialog(context, emp);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _actionButton(
                        label: "تعديل",
                        icon: Icons.edit_outlined,
                        color: const Color(0xff2563EB),
                        bgColor: const Color(0xffF0F5FF),
                        onTap: () {
                          Navigator.pop(ctx);
                          _showEditEmployeeDialog(context, emp);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        label: "تجديد",
                        icon: Icons.autorenew,
                        color: const Color(0xff16A34A),
                        bgColor: const Color(0xffF0FDF4),
                        onTap: () {
                          Navigator.pop(ctx);
                          _showRenewDialog(context, emp);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _actionButton(
                        label: "حذف",
                        icon: Icons.delete_outline,
                        color: const Color(0xffDC2626),
                        bgColor: const Color(0xffFEF2F2),
                        onTap: () {
                          Navigator.pop(ctx);
                          _confirmDelete(context, emp);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffF3F4F6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("إغلاق", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 44,
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _showEditEmployeeDialog(BuildContext context, Employee emp) {
    final nameController = TextEditingController(text: emp.name);
    final idController = TextEditingController(text: emp.idNumber);
    final dateController = TextEditingController(text: emp.expiryDate);

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xffF3F4F6),
                      radius: 16,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                    const Text('تعديل بيانات الموظف', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('اسم الموظف', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(controller: nameController, decoration: _inputStyle('أدخل اسم الموظف...')),
                const SizedBox(height: 12),
                const Text('رقم الهوية / الإقامة', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(controller: idController, decoration: _inputStyle('أدخل رقم الهوية...')),
                const SizedBox(height: 12),
                const Text('تاريخ انتهاء الإقامة', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: dateController,
                  readOnly: true,
                  onTap: () async {
                    final pickedDate = await _showCustomDatePicker(context);
                    if (pickedDate != null) {
                      dateController.text = pickedDate;
                    }
                  },
                  decoration: _inputStyle('YYYY-MM-DD').copyWith(
                    prefixIcon: const Icon(Icons.calendar_today_outlined, color: Color(0xFF1D4ED8), size: 18),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D4ED8),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          final updated = emp.copyWith(
                            name: nameController.text,
                            idNumber: idController.text,
                            expiryDate: dateController.text,
                          );
                          Provider.of<EmployeeProvider>(context, listen: false).updateEmployee(updated);
                          Navigator.pop(ctx);

                          await Future<void>.delayed(const Duration(milliseconds: 180));
                          if (!mounted) return;
                          await ActionResultDialog.show(
                            context,
                            type: ActionResultType.success,
                            title: 'تم تعديل بيانات الموظف',
                            name: updated.name,
                            message: 'تم حفظ التعديلات بنجاح',
                          );
                        },
                        child: const Text('حفظ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xffF3F4F6),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('إلغاء', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void showAddEmployeeDialog(BuildContext context) {
    final nameController = TextEditingController();
    final idController = TextEditingController();
    final dateController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xffF3F4F6),
                      radius: 16,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                    const Text('إضافة موظف جديد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('اسم الموظف', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(controller: nameController, decoration: _inputStyle('أدخل اسم الموظف...')),
                const SizedBox(height: 12),
                const Text('رقم الهوية / الإقامة', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(controller: idController, decoration: _inputStyle('أدخل رقم الهوية...')),
                const SizedBox(height: 12),
                const Text('تاريخ انتهاء الإقامة', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: dateController,
                  readOnly: true,
                  onTap: () async {
                    final pickedDate = await _showCustomDatePicker(context);
                    if (pickedDate != null) {
                      dateController.text = pickedDate;
                    }
                  },
                  decoration: _inputStyle('YYYY-MM-DD').copyWith(
                    prefixIcon: const Icon(Icons.calendar_today_outlined, color: Color(0xFF1D4ED8), size: 18),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D4ED8),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          final name = nameController.text.trim();
                          final idNumber = idController.text.trim();

                          if (name.isEmpty) return;

                          String normalizeId(String value) {
                            var result = value.trim();
                            const arabic = '٠١٢٣٤٥٦٧٨٩';
                            const western = '0123456789';
                            for (int i = 0; i < arabic.length; i++) {
                              result = result.replaceAll(arabic[i], western[i]);
                            }
                            return result.replaceAll(RegExp(r'[\s\-_/+,]+'), '');
                          }

                          String normalizeName(String value) {
                            return value
                                .trim()
                                .toLowerCase()
                                .replaceAll(RegExp(r'\s+'), '')
                                .replaceAll('أ', 'ا')
                                .replaceAll('إ', 'ا')
                                .replaceAll('آ', 'ا')
                                .replaceAll('ة', 'ه');
                          }

                          final provider = Provider.of<EmployeeProvider>(
                            context,
                            listen: false,
                          );

                          final idKey = normalizeId(idNumber);
                          final nameKey = normalizeName(name);

                          final duplicate = provider.employees.any((employee) {
                            final existingId = normalizeId(employee.idNumber);
                            final existingName = normalizeName(employee.name);

                            return (idKey.isNotEmpty &&
                                    idKey == existingId) ||
                                (idKey.isEmpty &&
                                    nameKey.isNotEmpty &&
                                    nameKey == existingName &&
                                    existingId.isEmpty);
                          });

                          if (duplicate) {
                            await showDialog<void>(
                              context: context,
                              builder: (noticeContext) => Directionality(
                                textDirection: TextDirection.rtl,
                                child: AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  title: const Text(
                                    'الموظف مكرر',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  content: const Text(
                                    'هذا الشخص مسجل مسبقًا في قائمة الموظفين.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(noticeContext),
                                      child: const Text('حسنًا'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                            return;
                          }

                          final newEmp = Employee(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            name: name,
                            idNumber: idNumber,
                            expiryDate: dateController.text.isEmpty
                                ? "2026-10-01"
                                : dateController.text,
                            status: "سارية",
                          );

                          provider.addEmployee(newEmp);
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }
                        },
                        child: const Text('حفظ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xffF3F4F6),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('إلغاء', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // نافذة التجديد الموحدة المستخدمة في جميع الصفحات.
  // نافذة RenewalDialog هي نافذة التجديد والتأكيد نفسها، لذلك لا نفتح
  // نافذة تأكيد ثانية ولا نستخدم Future.delayed.
  Future<void> _showRenewDialog(BuildContext context, Employee emp) async {
    final result = await RenewalDialog.show(
      context,
      employeeName: emp.name,
      expiryDate: emp.expiryDate,
    );

    if (result == null || !mounted) return;

    // حفظ التجديد مباشرة بعد ضغط "تأكيد التجديد".
    await Provider.of<EmployeeProvider>(
      context,
      listen: false,
    ).renewEmployeeId(emp.id, result.formattedDate);

    if (!mounted) return;

    // تحديث قائمة الموظفين بعد الحفظ.
    setState(() {});

    // نفس إشعار النجاح الموحد المستخدم في بقية الصفحات.
    await ActionResultDialog.show(
      context,
      type: ActionResultType.success,
      title: 'تم تجديد الهوية بنجاح',
      name: emp.name,
      message: 'تم حفظ تاريخ التجديد الجديد: ${result.formattedDate}',
    );
  }

  void _showLogsDialog(BuildContext context, Employee emp) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xffF3F4F6),
                      radius: 16,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                    const Text('سجل الإجراءات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.maxFinite,
                  child: emp.logs.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text("لا يوجد سجلات حالية", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: emp.logs.length,
                          itemBuilder: (context, i) => ListTile(
                            leading: const Icon(Icons.history, size: 16, color: Color(0xff2563EB)),
                            title: Text(emp.logs[i], style: const TextStyle(fontSize: 12)),
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffF3F4F6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("إغلاق", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Employee emp) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xffF3F4F6),
                      radius: 16,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xffFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.warning_amber_rounded, color: Color(0xffDC2626), size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text('تأكيد الحذف', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(
                  'هل أنت تأكد من حذف الموظف ${emp.name}؟ لا يمكن التراجع عن هذا الإجراء.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffDC2626),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          Provider.of<EmployeeProvider>(context, listen: false).removeEmployee(emp.id);
                          Navigator.pop(ctx);

                          await Future<void>.delayed(const Duration(milliseconds: 180));
                          if (!mounted) return;
                          await ActionResultDialog.show(
                            context,
                            type: ActionResultType.delete,
                            title: 'تم حذف الموظف بنجاح',
                            name: emp.name,
                            message: 'تمت إزالة الموظف من قائمة الموظفين',
                          );
                        },
                        child: const Text('حذف نهائي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xffF3F4F6),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('إلغاء', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
      filled: true,
      fillColor: const Color(0xffFAFAFA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1D4ED8)),
      ),
    );
  }
}

class _DayLabel extends StatelessWidget {
  final String label;
  const _DayLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _RenewalSuccessDialog extends StatefulWidget {
  final String employeeName;
  final String formattedDate;

  const _RenewalSuccessDialog({
    required this.employeeName,
    required this.formattedDate,
  });

  @override
  State<_RenewalSuccessDialog> createState() => _RenewalSuccessDialogState();
}

class _RenewalSuccessDialogState extends State<_RenewalSuccessDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _circleAnimation;
  late final Animation<double> _checkAnimation;
  late final Animation<double> _contentAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    );

    _circleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.58, curve: Curves.easeOutBack),
    );

    _checkAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.32, 0.82, curve: Curves.easeOutCubic),
    );

    _contentAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2300), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 360,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 35,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _circleAnimation,
                  child: SizedBox(
                    width: 92,
                    height: 92,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 92,
                          height: 92,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xffDCFCE7),
                          ),
                        ),
                        Container(
                          width: 70,
                          height: 70,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xff16A34A),
                          ),
                          child: AnimatedBuilder(
                            animation: _checkAnimation,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: _AnimatedCheckPainter(
                                  progress: _checkAnimation.value,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                FadeTransition(
                  opacity: _contentAnimation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.12),
                      end: Offset.zero,
                    ).animate(_contentAnimation),
                    child: Column(
                      children: [
                        const Text(
                          'تم تجديد الهوية بنجاح',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xff172033),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.employeeName,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff475569),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'تم تحديث تاريخ الانتهاء إلى ${widget.formattedDate}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xff7A8495),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xffF0FDF4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xffBBF7D0),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                size: 17,
                                color: Color(0xff16A34A),
                              ),
                              SizedBox(width: 7),
                              Text(
                                'تم حفظ التحديث بنجاح',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xff15803D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionSuccessDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final String employeeName;
  final bool isDelete;

  const _ActionSuccessDialog({
    required this.title,
    required this.subtitle,
    required this.employeeName,
    required this.isDelete,
  });

  @override
  State<_ActionSuccessDialog> createState() => _ActionSuccessDialogState();
}

class _ActionSuccessDialogState extends State<_ActionSuccessDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _circleAnimation;
  late final Animation<double> _checkAnimation;
  late final Animation<double> _contentAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _circleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
    );
    _checkAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.28, 0.78, curve: Curves.easeOutCubic),
    );
    _contentAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    );
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.isDelete
        ? const Color(0xffDC2626)
        : const Color(0xff16A34A);
    final light = widget.isDelete
        ? const Color(0xffFEE2E2)
        : const Color(0xffDCFCE7);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 360,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 35,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _circleAnimation,
                  child: Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: light,
                    ),
                    child: Center(
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent,
                        ),
                        child: AnimatedBuilder(
                          animation: _checkAnimation,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: _AnimatedCheckPainter(
                                progress: _checkAnimation.value,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                FadeTransition(
                  opacity: _contentAnimation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.12),
                      end: Offset.zero,
                    ).animate(_contentAnimation),
                    child: Column(
                      children: [
                        Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xff172033),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.employeeName,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff475569),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          widget.subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xff7A8495),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: light,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                widget.isDelete
                                    ? Icons.delete_sweep_rounded
                                    : Icons.verified_rounded,
                                size: 17,
                                color: accent,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                'تم حفظ العملية بنجاح',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedCheckPainter extends CustomPainter {
  final double progress;

  const _AnimatedCheckPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 5.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.23, size.height * 0.52)
      ..lineTo(size.width * 0.43, size.height * 0.70)
      ..lineTo(size.width * 0.77, size.height * 0.32);

    final metrics = path.computeMetrics();
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final visiblePath = metric.extractPath(
      0,
      metric.length * progress,
    );

    canvas.drawPath(visiblePath, paint);
  }

  @override
  bool shouldRepaint(covariant _AnimatedCheckPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
