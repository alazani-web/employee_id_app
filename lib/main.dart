import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/cupertino.dart';

import 'app.dart';
import 'providers/employee_provider.dart';
import 'providers/visit_provider.dart';
import 'providers/alert_provider.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ============================================================
  // Supabase
  // ============================================================

  await Supabase.initialize(
    url: 'https://ndlrmzpczioccwqxllhk.supabase.co',
    publishableKey: 'sb_publishable_YwRw43XWUpiDzgLJ7Ogq3w_vPNOm-JQ',
  );

  // ============================================================
  // Supabase connection/auth diagnostic
  // ============================================================
  try {
    final supabase = Supabase.instance.client;

    debugPrint('==============================================');
    debugPrint('SUPABASE TEST START');
    debugPrint('SUPABASE URL: ${supabase.rest.url}');

    final existingUser = supabase.auth.currentUser;

    if (existingUser != null) {
      debugPrint('SUPABASE USER ALREADY EXISTS: ${existingUser.id}');
    } else {
      debugPrint('SUPABASE USER: none -> creating anonymous user...');

      final response = await supabase.auth.signInAnonymously();

      if (response.user == null) {
        debugPrint('SUPABASE AUTH ERROR: signInAnonymously returned null user');
      } else {
        debugPrint('SUPABASE ANONYMOUS USER CREATED: ${response.user!.id}');
      }
    }

    final currentUser = supabase.auth.currentUser;
    debugPrint('SUPABASE CURRENT USER: ${currentUser?.id ?? 'NULL'}');
    debugPrint(
      'SUPABASE SESSION: ${supabase.auth.currentSession != null ? 'ACTIVE' : 'NULL'}',
    );

    // اختبار القراءة فقط من جدول employees.
    // لا نضيف ولا نعدل أي بيانات في هذا الاختبار.
    if (currentUser != null) {
      final rows = await supabase
          .from('employees')
          .select('id')
          .limit(1);

      debugPrint(
        'SUPABASE EMPLOYEES READ: SUCCESS (${rows.length} row(s) returned)',
      );
    }

    debugPrint('SUPABASE TEST END');
    debugPrint('==============================================');
  } catch (e, stackTrace) {
    debugPrint('==============================================');
    debugPrint('SUPABASE TEST ERROR: $e');
    debugPrint(stackTrace.toString());
    debugPrint('==============================================');
  }

  // ============================================================
  // Notifications
  // ============================================================

  // تهيئة نظام الإشعارات قبل تشغيل التطبيق.
  await NotificationService.instance.initialize();

  // إعادة جدولة التنبيهات الموجودة في البيانات المحلية.
  try {
    await NotificationService.instance.syncStoredData();
  } catch (_) {
    // لا نمنع تشغيل التطبيق إذا تعذر نظام الإشعارات.
  }

  // ============================================================
  // Application
  // ============================================================

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<EmployeeProvider>(
          create: (_) => EmployeeProvider(),
        ),

        ChangeNotifierProvider<VisitProvider>(
          create: (_) => VisitProvider(),
        ),

        ChangeNotifierProvider<AlertProvider>(
          create: (context) => AlertProvider(
            context.read<EmployeeProvider>(),
            context.read<VisitProvider>(),
          ),
        ),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نظام إدارة الهويات',
      debugShowCheckedModeBanner: false,

      // ============================================================
      // اللغة والاتجاه
      // ============================================================

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      supportedLocales: const [
        Locale('ar', 'SA'),
        Locale('en', 'US'),
      ],

      locale: const Locale('ar', 'SA'),

      // ============================================================
      // الثيم العام
      // ============================================================

      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Cairo',

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1D4ED8),
          primary: const Color(0xFF1D4ED8),
        ),

        // منع الـ Material من إضافة تأثيرات أو ألوان
        // غير مطلوبة على الأزرار والبطاقات.
        splashFactory: InkRipple.splashFactory,

        visualDensity: VisualDensity.standard,

        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android:
                CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS:
                CupertinoPageTransitionsBuilder(),
          },
        ),
      ),

      // ============================================================
      // الصفحة الرئيسية
      // ============================================================

      home: const App(),
    );
  }
}