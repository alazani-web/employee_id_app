import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xfff7f9fc),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              // لوحة التحكم
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // عنوان لوحة التحكم (اليمين)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "لوحة التحكم الرئيسية",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "ملخص شامل لحالة النظام",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    // كارت التاريخ (اليسار)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xfff0f4fd),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xff2962c7)),
                              SizedBox(width: 4),
                              Text(
                                "اليوم",
                                style: TextStyle(
                                  color: Color(0xff2962c7),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2),
                          Text(
                            "الأربعاء",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 1),
                          Text(
                            "٣٠ سبتمبر ٢٠٢٦",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // شبكة الإحصائيات (تم تصغير الحجم لتنسيق أفضل)
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.8, // نسبة العرض إلى الارتفاع لتقليل ارتفاع المربع
                children: const [
                  StatCard(
                    title: "الموظفين",
                    count: "27",
                    icon: Icons.people_outline,
                    color: Color(0xff1d5cc8),
                    background: Color(0xfff3f6fc),
                  ),
                  StatCard(
                    title: "الوثائق",
                    count: "0",
                    icon: Icons.inventory_2_outlined,
                    color: Color(0xff1d5cc8),
                    background: Color(0xfff3f6fc),
                  ),
                  StatCard(
                    title: "الزيارات",
                    count: "9",
                    icon: Icons.calendar_today_outlined,
                    color: Color(0xff2e7d32),
                    background: Color(0xfff1f8f3),
                  ),
                  StatCard(
                    title: "التنبيهات",
                    count: "18",
                    icon: Icons.notifications_none_outlined,
                    color: Color(0xffd96b27),
                    background: Color(0xfffff6ee),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // حالة الترخيص (تعديل المحاذاة لليمين)
              const InfoCard(
                icon: Icons.check_circle_outline,
                iconColor: Color(0xff2e7d32),
                title: "حالة الترخيص",
                subtitleSpan: TextSpan(
                  children: [
                    TextSpan(text: "مفتاح التفعيل: "),
                    TextSpan(
                      text: "مفعل\n",
                      style: TextStyle(color: Color(0xff2e7d32), fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: "الأيام المتبقية: 12512 يوم"),
                  ],
                ),
                buttonText: "إدارة الترخيص",
              ),

              const SizedBox(height: 10),

              // النسخ الاحتياطي (تعديل المحاذاة لليمين)
              const InfoCard(
                icon: Icons.dns_outlined,
                iconColor: Color(0xff1d5cc8),
                title: "النسخ الاحتياطي",
                subtitleSpan: TextSpan(
                  children: [
                    TextSpan(
                      text: "آخر نسخة احتياطية\n",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    TextSpan(text: "لا توجد نسخة محفوظة"),
                  ],
                ),
                buttonText: "إنشاء نسخة احتياطية",
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
  final IconData icon;
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // أيقونة جهة اليمين
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          // النصوص متراصة ومحاذاتها لليمين
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                ),
              ),
              Text(
                count,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final TextSpan subtitleSpan;
  final String buttonText;

  const InfoCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitleSpan,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // عنوان بطاقة المعلومات والأيقونة جهة اليمين
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          RichText(
            textAlign: TextAlign.right,
            text: TextSpan(
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                height: 1.4,
              ),
              children: [subtitleSpan],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff1d5cc8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                buttonText,
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