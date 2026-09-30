import 'package:flutter/material.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  int selectedTab = 0;
  final Color primaryBlue = const Color(0xff2563EB); // اللون الأزرق الرئيسي الموحد

  final List<String> tabs = [
    "جميع التنبيهات",
    "الموظفين (10)",
    "الزيارات العائلية (3)",
    "الوثائق",
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF7F8FC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xff111827)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "نظام إدارة الهويات",
            style: TextStyle(
              color: Color(0xff111827),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.menu, color: Color(0xff111827)),
              onPressed: () {},
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // عنوان الصفحة
              Row(
                children: [
                  Icon(Icons.notifications_active_outlined, color: Colors.amber.shade700, size: 28),
                  const SizedBox(width: 8),
                  const Text(
                    "التنبيهات والإشعارات",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // كروت الإحصائيات الأربعة
              Row(
                children: [
                  Expanded(child: summaryStatCard("إجمالي التنبيهات", "10", Icons.notifications_outlined, Colors.blue)),
                  const SizedBox(width: 10),
                  Expanded(child: summaryStatCard("منتهية الصلاحية", "0", Icons.cancel_outlined, Colors.red)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: summaryStatCard("عاجلة (7 أيام)", "2", Icons.warning_amber_rounded, Colors.orange)),
                  const SizedBox(width: 10),
                  Expanded(child: summaryStatCard("تحتاج متابعة", "8", Icons.access_time_rounded, Colors.amber.shade700)),
                ],
              ),

              const SizedBox(height: 20),

              // شريط الفلاتر (التبويبات)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(tabs.length, (index) {
                    bool active = selectedTab == index;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            selectedTab = index;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: active ? primaryBlue : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                          ),
                          child: Text(
                            tabs[index],
                            style: TextStyle(
                              color: active ? primaryBlue : Colors.grey.shade600,
                              fontWeight: active ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 15),

              // قائمة بطاقات التنبيهات
              alertCard(
                type: "موظف:",
                name: "عبدالغفور صالح احمد",
                badgeText: "3 يوم متبقي",
                badgeColor: const Color(0xffFFF3DC),
                badgeTextColor: Colors.amber.shade900,
                description: "هوية الموظف عبدالغفور صالح احمد تنتهي قريباً جداً",
                idNumber: "2128232549",
                expiryDate: "03/10/2026",
              ),
              const SizedBox(height: 12),
              alertCard(
                type: "موظف:",
                name: "محمد ابو الكلام كارسا",
                badgeText: "4 يوم متبقي",
                badgeColor: const Color(0xffFFF3DC),
                badgeTextColor: Colors.amber.shade900,
                description: "هوية الموظف محمد ابو الكلام كارسا تنتهي قريباً",
                idNumber: "2384729102",
                expiryDate: "04/10/2026",
              ),
            ],
          ),
        ),
      ),
    );
  }

  // كرت الإحصائيات المصغر
  Widget summaryStatCard(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ],
      ),
    );
  }

  // كرت التنبيه
  Widget alertCard({
    required String type,
    required String name,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
    required String description,
    required String idNumber,
    required String expiryDate,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffFFFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.people_alt_outlined, size: 18, color: Colors.brown),
                        const SizedBox(width: 6),
                        Text(
                          type,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.brown),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: const Text("تجديد", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badgeText,
              style: TextStyle(color: badgeTextColor, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 6),
          Text(
            "رقم الهوية: $idNumber | تاريخ الانتهاء: $expiryDate",
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}