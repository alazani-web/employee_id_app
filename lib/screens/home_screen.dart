import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../providers/employee_provider.dart';
import '../providers/visit_provider.dart';
import '../providers/alert_provider.dart';
import 'settings_screen.dart';
import '../services/supabase_service.dart';

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
  SubscriptionInfo? _subscriptionInfo;
  TrialInfo? _trialInfo;
  bool _subscriptionLoading = true;
  Timer? _trialTimer;

  @override
  void initState() {
    super.initState();
    _loadDocumentCount();
    _loadSubscriptionInfo();
    _trialTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _refreshTrial(),
    );
  }

  @override
  void dispose() {
    _trialTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshTrial() async {
    try {
      final info = await SupabaseService.instance.trialInfo;
      if (!mounted) return;
      setState(() {
        _trialInfo = info;
      });
    } catch (_) {}
  }

  Future<void> _loadSubscriptionInfo() async {
    try {
      final info = await SupabaseService.instance.subscriptionInfo;
      final trial = await SupabaseService.instance.trialInfo;
      if (!mounted) return;
      setState(() {
        _subscriptionInfo = info;
        _trialInfo = trial;
        _subscriptionLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _subscriptionInfo = null;
        _subscriptionLoading = false;
      });
    }
  }

  int get _trialRemainingDays {
    final info = _trialInfo;
    if (info == null) return 0;
    final seconds = info.trialEnd.difference(DateTime.now()).inSeconds;
    if (seconds <= 0) return 0;
    return ((seconds + 86399) ~/ 86400).clamp(0, 7);
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  String get _subscriptionSubtitle {
    if (_subscriptionLoading) return 'جاري تحميل بيانات الاشتراك...';

    final info = _subscriptionInfo;
    if (info?.active == true) {
      return 'الاشتراك مفعل\nالأيام المتبقية: ${info!.remainingDays} يوم';
    }

    final trial = _trialInfo;
    final days = _trialRemainingDays;
    if (trial != null && trial.active && days > 0) {
      return 'التجربة المجانية مفعلة\nالمتبقي: $days ${days == 1 ? 'يوم' : 'أيام'}\nتنتهي: ${_formatDate(trial.trialEnd)}';
    }

    return 'التجربة المجانية: انتهت\nفعّل اشتراكًا للاستمرار';
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Container(
                height: 68,
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
                childAspectRatio: 3.35,
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

              SubscriptionCard(
                subscriptionInfo: _subscriptionInfo,
                trialInfo: _trialInfo,
                remainingDays: _trialRemainingDays,
                subtitle: _subscriptionSubtitle,
                onTap: () {
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
                  widget.onNavigate?.call('backup');
                },
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
        height: 50,
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
  final String icon;
  final String subtitle;
  final String button;
  final VoidCallback? onTap;

  const InfoCard({
    super.key,
    required this.title,
    required this.icon,
    required this.subtitle,
    required this.button,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SvgPicture.asset(icon, width: 24, height: 24),
              const SizedBox(width: 10),
              Text(title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(subtitle,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xff7A8495),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff2864D7),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(button,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SubscriptionCard extends StatelessWidget {
  final SubscriptionInfo? subscriptionInfo;
  final TrialInfo? trialInfo;
  final int remainingDays;
  final String subtitle;
  final VoidCallback? onTap;

  const SubscriptionCard({
    super.key,
    required this.subscriptionInfo,
    required this.trialInfo,
    required this.remainingDays,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = subscriptionInfo?.active == true;
    final trial = !active && trialInfo != null && trialInfo!.active && remainingDays > 0;

    final color = active
        ? const Color(0xff2864D7)
        : trial
            ? const Color(0xff16A34A)
            : const Color(0xffDC2626);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: .25)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                active ? Icons.verified_rounded : Icons.workspace_premium_rounded,
                size: 34,
                color: color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  active ? 'الاشتراك مفعل' : trial ? 'التجربة المجانية' : 'انتهت التجربة',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            subtitle,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              height: 1.8,
              color: Color(0xff475569),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                active ? 'إدارة الاشتراك' : 'تفعيل الاشتراك الآن',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

