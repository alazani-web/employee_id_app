import 'package:flutter/material.dart';

class VisitsScreen extends StatefulWidget {
  const VisitsScreen({super.key});

  @override
  State<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends State<VisitsScreen> {
  int selectedFilter = 0;
  final TextEditingController searchController = TextEditingController();

  // اللون الأزرق الرئيسي الموحد المطابق لصفحة الموظفين
  final Color primaryBlue = const Color(0xff2563EB);

  final List<String> filters = [
    "الكل",
    "نشط",
    "تنتهي قريباً",
    "منتهي",
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF7F8FC),
        body: Column(
          children: [
            const SizedBox(height: 15),

            // شريط البحث مع زر الفلترة الجانبي
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        controller: searchController,
                        textAlign: TextAlign.right,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "البحث بالاسم أو رقم الحدود أو التأشيرة...",
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                          prefixIcon: Icon(Icons.search, color: Colors.grey),
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xffF0F5FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.filter_list, color: primaryBlue),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // الفلاتر العلوية
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(filters.length, (index) {
                  bool active = selectedFilter == index;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: index == filters.length - 1 ? 0 : 8.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedFilter = index;
                          });
                        },
                        child: Container(
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: active ? primaryBlue : Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: active ? primaryBlue : Colors.grey.shade200,
                            ),
                          ),
                          child: Text(
                            filters[index],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: active ? Colors.white : Colors.black87,
                              fontSize: 13,
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

            const SizedBox(height: 15),

            // قائمة الزيارات الخالية
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    "لا توجد زيارات مسجلة",
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
          ],
        ),

        // زر (+)
        floatingActionButton: FloatingActionButton(
          onPressed: () => showAddVisitDialog(context),
          backgroundColor: primaryBlue,
          shape: const CircleBorder(),
          elevation: 4,
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 32,
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  // نافذة إضافة زيارة جديدة
  void showAddVisitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 20, color: Colors.black54),
                      ),
                      Row(
                        children: [
                          const Text("إضافة زيارة جديدة", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 6),
                          Icon(Icons.flight_land_outlined, color: primaryBlue, size: 20),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  const Text("اسم الزائر", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 6),
                  customTextField("اسم الزائر"),

                  const SizedBox(height: 12),
                  const Text("رقم الحدود / التأشيرة", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 6),
                  customTextField("رقم الحدود أو التأشيرة"),

                  const SizedBox(height: 12),
                  const Text("تاريخ الانتهاء *", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 6),
                  customDateField(),

                  const SizedBox(height: 12),
                  const Text("ملاحظات", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const TextField(
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "ملاحظات",
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade200,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("إلغاء", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.save_outlined, color: Colors.white, size: 18),
                            label: const Text("حفظ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget customTextField(String hint) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  Widget customDateField() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: "DD-MM-YYYY",
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          prefixIcon: const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}