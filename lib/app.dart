import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_screen.dart';
import 'screens/employees_screen.dart';
import 'screens/visits_screen.dart';
import 'screens/documents_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';

import 'widgets/app_header.dart';
import 'widgets/bottom_navigation.dart';
import 'widgets/side_menu.dart';
import 'widgets/app_lock_screen.dart';
import 'providers/alert_provider.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  String currentPage = 'home';

  late final List<Widget> _mainPages;

  @override
  void initState() {
    super.initState();

    _mainPages = [
      HomeScreen(onNavigate: navigate),
      const EmployeesScreen(),
      const VisitsScreen(),
      const DocumentsScreen(),
      const ReportsScreen(),
    ];

    WidgetsBinding.instance.addObserver(this);
    _loadLockState();
  }

  bool _lockEnabled = false;
  bool _isLocked = false;
  bool _loadingLock = true;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadLockState() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('app_lock_enabled') ?? false;
    final pin = prefs.getString('app_lock_pin') ?? '';

    if (!mounted) return;

    setState(() {
      _lockEnabled = enabled && pin.isNotEmpty;
      _isLocked = enabled && pin.isNotEmpty;
      _loadingLock = false;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _refreshLockForBackground();
    }
  }

  Future<void> _refreshLockForBackground() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('app_lock_enabled') ?? false;
    final pin = prefs.getString('app_lock_pin') ?? '';

    if (!mounted) return;

    setState(() {
      _lockEnabled = enabled && pin.isNotEmpty;

      if (_lockEnabled) {
        _isLocked = true;
      }
    });
  }

  Future<bool> _verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('app_lock_pin') ?? '';

    if (pin == saved) {
      if (mounted) {
        setState(() {
          _isLocked = false;
        });
      }

      return true;
    }

    return false;
  }

  void navigate(String page) {
    if (!mounted) return;

    // إغلاق القائمة الجانبية من الجهة اليسرى
    scaffoldKey.currentState?.closeEndDrawer();

    setState(() {
      currentPage = page;
    });
  }

  int getCurrentIndex() {
    switch (currentPage) {
      case 'employees':
        return 1;

      case 'visits':
        return 2;

      case 'documents':
        return 3;

      case 'reports':
        return 4;

      default:
        return 0;
    }
  }

  bool get _isMainPage =>
      currentPage == 'home' ||
      currentPage == 'employees' ||
      currentPage == 'visits' ||
      currentPage == 'documents' ||
      currentPage == 'reports';

  Widget _buildPage() {
    if (!_isMainPage) {
      return SettingsScreen(
        selectedPage: currentPage,
        onBack: () => navigate('home'),
      );
    }

    return IndexedStack(
      index: getCurrentIndex(),
      children: _mainPages,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingLock) {
      return const Material(
        color: Color(0xffF7F9FC),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Stack(
      children: [
        Scaffold(
          key: scaffoldKey,

          // القائمة الجانبية تظهر من الجهة اليسرى
          // لأن التطبيق يعمل باتجاه RTL
          endDrawer: SideMenu(
            onNavigate: navigate,
          ),

          body: Column(
            children: [
              AppHeader(
                alertCount:
                    context.watch<AlertProvider>().alertCount,

                // فتح القائمة من الجهة اليسرى
                onMenuTap: () {
                  scaffoldKey.currentState?.openEndDrawer();
                },
              ),

              Expanded(
                child: _buildPage(),
              ),

              if (_isMainPage)
                SizedBox(
                  height: 64,
                  child: BottomNavigation(
                    currentIndex: getCurrentIndex(),
                    onTap: (index) {
                      const pages = [
                        'home',
                        'employees',
                        'visits',
                        'documents',
                        'reports',
                      ];

                      navigate(pages[index]);
                    },
                  ),
                ),
            ],
          ),
        ),

        if (_isLocked)
          AppLockScreen(
            onUnlock: _verifyPin,
          ),
      ],
    );
  }
}