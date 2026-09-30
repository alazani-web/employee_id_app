import 'package:flutter/material.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int selectedTab = 0; // 0: الموظفين, 1: الزيارات, 2: التجديدات

  // اللون الأزرق الرئيسي الموحد المطابق لجميع الشاشات
  final Color primaryBlue = const Color(0xff2563EB);

  final List<String> tabs = [
    "الموظفين",
    "الزيارات",
    "التجديدات",
  ];

  final List<IconData> tabIcons = [
    Icons.people_outline,
    Icons.flight_land_outlined,
    Icons.autorenew_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF7F8FC),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // كرت عنوان الشاشة وأزرار التصدير
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xffF0F5FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.description_outlined, color: primaryBlue, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "التقارير",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "تصدير ومراجعة تقارير الموظفين والزيارات والتجديدات",
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xffECFDF5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xffA7F3D0)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.file_download_outlined, color: Color(0xff059669), size: 18),
                                SizedBox(width: 6),
                                Text(
                                  "Excel",
                                  style: TextStyle(color: Color(0xff059669), fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xffFEF2F2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xffFECACA)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.picture_as_pdf_outlined, color: Color(0xffDC2626), size: 18),
                                SizedBox(width: 6),
                                Text(
                                  "PDF",
                                  style: TextStyle(color: Color(0xffDC2626), fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // أزرار التبديل (الفلاتر العلوية) باللون الأزرق الموحد
              Row(
                children: List.generate(tabs.length, (index) {
                  bool active = selectedTab == index;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: index == tabs.length - 1 ? 0 : 8.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedTab = index;
                          });
                        },
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: active ? primaryBlue : Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: active ? primaryBlue : Colors.grey.shade200,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                tabIcons[index],
                                size: 18,
                                color: active ? Colors.white : Colors.grey.shade700,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                tabs[index],
                                style: TextStyle(
                                  color: active ? Colors.white : Colors.grey.shade700,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 16),

              // كروت الإحصائيات الأربعة (بدون بيانات / أصفار)
              Row(
                children: [
                  Expanded(child: statCard("الموظفين", "0", Icons.people_outline, Colors.blue)),
                  const SizedBox(width: 10),
                  Expanded(child: statCard("الزيارات", "0", Icons.flight_land_outlined, Colors.green)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: statCard("الوثائق", "0", Icons.folder_open_outlined, Colors.orange)),
                  const SizedBox(width: 10),
                  Expanded(child: statCard("نتائج التقرير", "0", Icons.assignment_outlined, Colors.purple)),
                ],
              ),

              const SizedBox(height: 20),

              // جدول/عرض التقرير الجاهز
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "تقرير ${tabs[selectedTab]}",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        Text(
                          "عدد النتائج: 0",
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // واجهة عدم وجود بيانات متناسقة
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 30),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.insert_chart_outlined_outlined, size: 54, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              "لا توجد بيانات للعرض في التقرير",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ودجت كرت الإحصائيات المصغر
  Widget statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ],
      ),
    );
  }
}