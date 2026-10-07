import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../providers/employee_provider.dart';
import '../providers/visit_provider.dart';
import '../providers/alert_provider.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<String>? onNavigate;

  const HomeScreen({
    super.key,
    this.onNavigate,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const List<String> _weekdays = [
    '',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  static const List<String> _months = [
    '',
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

  String get _currentWeekday => _weekdays[DateTime.now().weekday];

  String get _currentDate {
    final now = DateTime.now();
    return '${now.day} ${_months[now.month]} ${now.year}';
  }

  static const String _documentsStorageKey =
      'employee_id_app_documents_v2';

  int _documentCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDocumentCount();
  }

  Future<void> _loadDocumentCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawDocuments = prefs.getString(_documentsStorageKey);

      int count = 0;

      if (rawDocuments != null && rawDocuments.isNotEmpty) {
        final decoded = jsonDecode(rawDocuments);

        if (decoded is List) {
          count = decoded.length;
        }
      }

      if (!mounted) return;

      setState(() {
        _documentCount = count;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _documentCount = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeeCount =
        context.watch<EmployeeProvider>().employeeCount;

    final visitCount =
        context.watch<VisitProvider>().visitCount;

    final alertCount =
        context.watch<AlertProvider>().alertCount;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF7F9FC),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              10,
              8,
              10,
              12 + MediaQuery.of(context).padding.bottom,
            ),
          child: Column(
            children: [
              Container(
                constraints: const BoxConstraints(minHeight: 62, maxHeight: 68),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'لوحة التحكم الرئيسية',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'ملخص شامل لحالة النظام',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xffEFF4FF),
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          const Text(
                            'اليوم',
                            style: TextStyle(
                              color: Color(0xff2864D7),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _currentWeekday,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _currentDate,
                            style: const TextStyle(
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

              const SizedBox(height: 8),

              GridView.count(
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 3.05,
                children: [
                  StatCard(
                    title: 'الموظفين',
                    count: '$employeeCount',
                    icon: 'assets/icons/users.svg',
                    color: const Color(0xff2864D7),
                    background: const Color(0xffEFF4FF),
                    onTap: () {
                      widget.onNavigate?.call('employees');
                    },
                  ),

                  StatCard(
                    title: 'الوثائق',
                    count: '$_documentCount',
                    icon: 'assets/icons/folder_open.svg',
                    color: const Color(0xff2864D7),
                    background: const Color(0xffEFF4FF),
                    onTap: () {
                      widget.onNavigate?.call('documents');
                    },
                  ),

                  StatCard(
                    title: 'الزيارات',
                    count: '$visitCount',
                    icon: 'assets/icons/calendar.svg',
                    color: const Color(0xff3D9850),
                    background: const Color(0xffEFFAF1),
                    onTap: () {
                      widget.onNavigate?.call('visits');
                    },
                  ),

                  StatCard(
                    title: 'التنبيهات',
                    count: '$alertCount',
                    icon: 'assets/icons/notifications.svg',
                    color: const Color(0xffD8792B),
                    background: const Color(0xfffff5ed),
                    onTap: () {
                      widget.onNavigate?.call('alerts');
                    },
                  ),
                ],
              ),

              const SizedBox(height: 12),

              InfoCard(
                title: 'حالة الترخيص',
                icon: 'assets/icons/badge_check.svg',
                subtitle:
                    'مفتاح التفعيل: مفعل\nالأيام المتبقية: 12512 يوم',
                button: 'إدارة الترخيص',
                onTap: () {
                  // افتح صفحة التفعيل من خلال نظام التنقل الرئيسي
                  // حتى يظهر زر الرجوع ولا يتم إنشاء شاشة Settings ثانية.
                  widget.onNavigate?.call('activation');
                },
              ),

              const SizedBox(height: 12),

              InfoCard(
                title: 'النسخ الاحتياطي',
                icon: 'assets/icons/database.svg',
                subtitle:
                    'آخر نسخة احتياطية\nلا توجد نسخة محفوظة',
                button: 'إنشاء نسخة احتياطية',
                onTap: () {
                  // افتح النسخ الاحتياطي من خلال نظام التنقل الرئيسي
                  // حتى يظهر زر الرجوع ولا يتم إنشاء شاشة Settings ثانية.
                  widget.onNavigate?.call('backup');
                },
              ),
            ],
          ),
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
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.background,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding:
            const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff7A8495),
                  ),
                ),
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),

            Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                icon,
                width: 18,
                height: 18,
                colorFilter: ColorFilter.mode(
                  color,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String button;
  final String icon;
  final VoidCallback? onTap;

  const InfoCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.button,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: Color(0xffEFF4FF),
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  icon,
                  width: 18,
                  height: 18,
                  colorFilter:
                      const ColorFilter.mode(
                    Color(0xff2864D7),
                    BlendMode.srcIn,
                  ),
                ),
              ),

              const SizedBox(width: 6),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
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

          const SizedBox(height: 8),

          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xff2864D7),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
              child: Text(
                button,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
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