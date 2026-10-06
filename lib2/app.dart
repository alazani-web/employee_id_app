import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'screens/employees_screen.dart';
import 'screens/visits_screen.dart';
import 'screens/documents_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';

import 'widgets/app_header.dart';
import 'widgets/bottom_navigation.dart';
import 'widgets/side_menu.dart';

import 'providers/alert_provider.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  // =====================================================
  // مفاتيح التطبيق
  // =====================================================

  final GlobalKey<ScaffoldState> scaffoldKey =
      GlobalKey<ScaffoldState>();

  final GlobalKey<NavigatorState> pageNavigatorKey =
      GlobalKey<NavigatorState>();

  // =====================================================
  // الصفحة الحالية
  // =====================================================

  String currentPage = "home";

  // =====================================================
  // الحصول على الصفحة الحالية
  // =====================================================

  Widget getCurrentPage() {
    switch (currentPage) {
      case "home":
        return const HomeScreen();

      case "employees":
        return const EmployeesScreen();

      case "visits":
        return const VisitsScreen();

      case "documents":
        return const DocumentsScreen();

      case "reports":
        return const ReportsScreen();

      // صفحات الإعدادات
      case "settings":
      case "backup":
      case "activation":
      case "lock":
      case "alerts":
      case "tasks":
      case "about":
        return SettingsScreen(
          selectedPage: currentPage,
        );

      default:
        return const HomeScreen();
    }
  }

  // =====================================================
  // التنقل بين الصفحات
  // =====================================================

  void navigate(String page) {
    setState(() {
      currentPage = page;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final navigator = pageNavigatorKey.currentState;

      if (navigator == null) return;

      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => getCurrentPage(),
        ),
        (route) => false,
      );
    });
  }

  // =====================================================
  // تحديد العنصر النشط في الشريط السفلي
  // =====================================================

  int getCurrentIndex() {
    switch (currentPage) {
      case "employees":
        return 1;

      case "visits":
        return 2;

      case "documents":
        return 3;

      case "reports":
        return 4;

      case "home":
      default:
        return 0;
    }
  }

  // =====================================================
  // بناء التطبيق
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: "نظام إدارة الهويات",

      // ===================================================
      // دعم اللغة العربية
      // ===================================================

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

      // ===================================================
      // الثيم
      // ===================================================

      theme: ThemeData(
        useMaterial3: true,
        fontFamily: "Cairo",
        visualDensity: VisualDensity.standard,
      ),

      // ===================================================
      // التطبيق الرئيسي
      // ===================================================

      home: Scaffold(
        key: scaffoldKey,

        // =================================================
        // القائمة الجانبية
        // =================================================

        drawer: SideMenu(
          onNavigate: navigate,
        ),

        // =================================================
        // SafeArea
        //
        // يمنع المحتوى من الدخول في:
        // - شريط الحالة
        // - النوتش
        // - حواف الشاشة
        // - منطقة أزرار النظام
        // =================================================

        body: SafeArea(
          top: true,
          bottom: true,
          left: true,
          right: true,

          child: Column(
            children: [
              // =================================================
              // الهيدر
              // =================================================

              SizedBox(
                width: double.infinity,
                child: AppHeader(
                  alertCount:
                      context.watch<AlertProvider>().alertCount,

                  onMenuTap: () {
                    scaffoldKey.currentState?.openDrawer();
                  },
                ),
              ),

              // =================================================
              // محتوى الصفحات
              //
              // Expanded يمنع المحتوى من تجاوز المساحة المتاحة.
              // =================================================

              Expanded(
                child: ClipRect(
                  child: Navigator(
                    key: pageNavigatorKey,
                    onGenerateRoute: (_) {
                      return MaterialPageRoute(
                        builder: (_) => const HomeScreen(),
                      );
                    },
                  ),
                ),
              ),

              // =================================================
              // الشريط السفلي
              // =================================================

              SizedBox(
                width: double.infinity,
                child: BottomNavigation(
                  currentIndex: getCurrentIndex(),

                  onTap: (index) {
                    switch (index) {
                      case 0:
                        navigate("home");
                        break;

                      case 1:
                        navigate("employees");
                        break;

                      case 2:
                        navigate("visits");
                        break;

                      case 3:
                        navigate("documents");
                        break;

                      case 4:
                        navigate("reports");
                        break;
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}