import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/employee_provider.dart';
import 'providers/visit_provider.dart';
import 'providers/alert_provider.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة نظام الإشعارات قبل تشغيل التطبيق
  await NotificationService.instance.initialize();

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

      theme: ThemeData(
        fontFamily: 'Cairo',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1D4ED8),
          primary: const Color(0xFF1D4ED8),
        ),
      ),

      home: const App(),
    );
  }
}