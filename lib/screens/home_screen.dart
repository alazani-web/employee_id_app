import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/employee_provider.dart';
import '../providers/visit_provider.dart';
import '../providers/alert_provider.dart'; // استيراد مزود التنبيهات

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // جلب عدد الموظفين الحقيقي من المزود
    final employeeCount = context.watch<EmployeeProvider>().employeeCount;
    
    // جلب عدد الزيارات الحقيقي ديناميكياً من الـ VisitProvider
    final visitCount = context.watch<VisitProvider>().visitCount;

    // جلب عدد التنبيهات ديناميكياً من الـ AlertProvider
    final alertCount = context.watch<AlertProvider>().alertCount;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF7F9FC),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              // Header المطابق تماماً لتصميم الصناديق
              Container(
                height: 78,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // العنوان والملخص في اليمين بخط بارز
                    const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "لوحة التحكم الرئيسية",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "ملخص شامل لحالة النظام",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    // التاريخ واليوم في اليسار
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xffEFF4FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "اليوم",
                            style: TextStyle(
                              color: Color(0xff2864D7),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "الأربعاء",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "30 سبتمبر 2026",
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 5.0,
                children: [
                  StatCard(
                    title: "الموظفين",
                    count: "$employeeCount",
                    icon: "assets/icons/users.svg",
                    color: const Color(0xff2864D7),
                    background: const Color(0xffEFF4FF),
                  ),
                  const StatCard(
                    title: "الوثائق",
                    count: "0",
                    icon: "assets/icons/folder_open.svg",
                    color: Color(0xff2864D7),
                    background: Color(0xffEFF4FF),
                  ),
                  StatCard(
                    title: "الزيارات",
                    count: "$visitCount",
                    icon: "assets/icons/calendar.svg",
                    color: const Color(0xff3D9850),
                    background: const Color(0xffEFFAF1),
                  ),
                  StatCard(
                    title: "التنبيهات",
                    count: "$alertCount", // عرض عداد التنبيهات الديناميكي هنا
                    icon: "assets/icons/notifications.svg",
                    color: const Color(0xffD8792B),
                    background: const Color(0xfffff5ed),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              const InfoCard(
                title: "حالة الترخيص",
                icon: "assets/icons/badge_check.svg",
                subtitle: "مفتاح التفعيل: مفعل\nالأيام المتبقية: 12512 يوم",
                button: "إدارة الترخيص",
              ),

              const SizedBox(height: 12),

              const InfoCard(
                title: "النسخ الاحتياطي",
                icon: "assets/icons/database.svg",
                subtitle: "آخر نسخة احتياطية\nلا توجد نسخة محفوظة",
                button: "إنشاء نسخة احتياطية",
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String count;
  final String icon;
  final Color color;
  final Color background;

  const StatCard({
    super.key,
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff7A8495),
                ),
              ),
              Text(
                count,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(
              icon,
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(
                color,
                BlendMode.srcIn,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String button;
  final String icon;

  const InfoCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.button,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xffEFF4FF),
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  icon,
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    Color(0xff2864D7),
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff2864D7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                button,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}