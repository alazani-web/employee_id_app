import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/employees_screen.dart';
import 'screens/visits_screen.dart';
import 'screens/documents_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';

import 'widgets/app_header.dart';
import 'widgets/bottom_navigation.dart';
import 'widgets/side_menu.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  // المفتاح الخاص بالـ Scaffold
  final GlobalKey<ScaffoldState> scaffoldKey =
      GlobalKey<ScaffoldState>();

  String currentPage = "home";

  int alertCount = 0;

  // =====================================================
  // الصفحة الحالية
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
  // التنقل
  // =====================================================

  void navigate(String page) {
    setState(() {
      currentPage = page;
    });
  }

  // =====================================================
  // الشريط السفلي
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
    return Scaffold(
        key: scaffoldKey,

        // =================================================
        // تم التغيير إلى drawer لفتح القائمة من اليسار
        // =================================================

        drawer: SideMenu(
          onNavigate: navigate,
        ),

        // =================================================
        // محتوى التطبيق
        // =================================================

        body: Column(
          children: [

            // الهيدر
            AppHeader(
              alertCount: alertCount,

              // تم التغيير إلى openDrawer للفتح من اليسار
              onMenuTap: () {
                scaffoldKey.currentState?.openDrawer();
              },
            ),

            // الصفحة
            Expanded(
              child: getCurrentPage(),
            ),

            // الشريط السفلي
            BottomNavigation(
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
          ],
        ),
    );
  }
}