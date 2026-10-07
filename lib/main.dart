import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/employee_provider.dart';
import 'providers/visit_provider.dart';
import 'providers/alert_provider.dart';
import 'services/notification_service.dart';
import 'package:flutter/cupertino.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة نظام الإشعارات قبل تشغيل التطبيق.
  await NotificationService.instance.initialize();

  // إعادة جدولة التنبيهات الموجودة في البيانات المحلية.
  try {
    await NotificationService.instance.syncStoredData();
  } catch (_) {
    // لا نمنع تشغيل التطبيق إذا تعذر نظام الإشعارات.
  }

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

        // تم حذف const من PageTransitionsTheme
        // لأن CupertinoPageTransitionsBuilder()
        // ليس تعبيرًا ثابتًا في إصدار Flutter الحالي.
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
