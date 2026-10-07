import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:shared_preferences/shared_preferences.dart';



import 'screens/home_screen.dart';

import 'screens/employees_screen.dart';

import 'screens/visits_screen.dart';

import 'screens/documents_screen.dart';

import 'screens/reports_screen.dart';

import 'screens/alerts_screen.dart';

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



class _AppState extends State<App> with WidgetsBindingObserver {

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();



  String currentPage = 'home';



  late final List<Widget> _mainPages;



  bool _lockEnabled = false;

  bool _isLocked = false;

  bool _loadingLock = true;



  @override

  void initState() {

    super.initState();



    _mainPages = [

      HomeScreen(onNavigate: navigate),

      const EmployeesScreen(),

      const VisitsScreen(),

      const DocumentsScreen(),

      const ReportsScreen(),

      AlertsScreen(
        onBack: () => navigate('home'),
      ),

    ];



    WidgetsBinding.instance.addObserver(this);

    _loadLockState();

  }



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



  void _handleLockStateChanged(bool enabled) {

    if (!mounted) return;



    setState(() {

      _lockEnabled = enabled;



      if (!enabled) {

        _isLocked = false;

      }

    });

  }



  void navigate(String page) {

    if (!mounted) return;



    // إغلاق القائمة الجانبية

    scaffoldKey.currentState?.closeEndDrawer();



    setState(() {

      currentPage = page;

    });

  }



  /// مؤشر الصفحة داخل IndexedStack.

  ///

  /// التنبيهات = 5

  /// لأن ترتيب الصفحات:

  /// 0 home

  /// 1 employees

  /// 2 visits

  /// 3 documents

  /// 4 reports

  /// 5 alerts

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



      case 'alerts':

        return 5;



      case 'home':

      default:

        return 0;

    }

  }



  /// مؤشر BottomNavigation فقط.

  ///

  /// BottomNavigation يحتوي على 5 عناصر:

  /// 0 home

  /// 1 employees

  /// 2 visits

  /// 3 documents

  /// 4 reports

  ///

  /// لذلك عندما تكون الصفحة alerts لا نرسل 5 إلى BottomNavigation.

  int getBottomNavigationIndex() {

    switch (currentPage) {

      case 'employees':

        return 1;



      case 'visits':

        return 2;



      case 'documents':

        return 3;



      case 'reports':

        return 4;



      case 'alerts':

        return 0;



      case 'home':

      default:

        return 0;

    }

  }



  bool get _isMainPage =>

      currentPage == 'home' ||

      currentPage == 'employees' ||

      currentPage == 'visits' ||

      currentPage == 'documents' ||

      currentPage == 'reports' ||

      currentPage == 'alerts';



  Widget _buildPage() {

    if (!_isMainPage) {

      return SettingsScreen(

        selectedPage: currentPage,

        onBack: () => navigate('home'),

        onLockStateChanged: _handleLockStateChanged,

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



          // القائمة الجانبية

          endDrawer: SideMenu(

            onNavigate: navigate,

          ),



          body: SafeArea(
            top: true,
            bottom: true,
            left: false,
            right: false,
            child: Column(

              children: [

              AppHeader(

                alertCount: context.watch<AlertProvider>().alertCount,



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

                    // مهم جدًا:

                    // نستخدم مؤشر BottomNavigation وليس مؤشر IndexedStack.

                    currentIndex: getBottomNavigationIndex(),



                    onTap: (index) {

                      const pages = [

                        'home',

                        'employees',

                        'visits',

                        'documents',

                        'reports',

                      ];



                      // حماية من أي index غير صحيح.

                      if (index < 0 || index >= pages.length) {

                        return;

                      }



                      navigate(pages[index]);

                    },

                  ),

                ),

              ],

            ),

          ),

        ),



        if (_isLocked)

          AppLockScreen(

            onUnlock: _verifyPin,

            onBackToHome: () {

              setState(() {

                currentPage = 'home';

                _isLocked = false;

              });

            },

          ),

      ],

    );

  }

}



/// شاشة قفل التطبيق

/// زر الرجوع يعيد المستخدم مباشرة إلى الصفحة الرئيسية.

class AppLockScreen extends StatefulWidget {

  final Future<bool> Function(String pin) onUnlock;

  final VoidCallback? onBackToHome;



  const AppLockScreen({

    super.key,

    required this.onUnlock,

    this.onBackToHome,

  });



  @override

  State<AppLockScreen> createState() => _AppLockScreenState();

}



class _AppLockScreenState extends State<AppLockScreen> {

  final TextEditingController _pinController = TextEditingController();



  bool _checking = false;

  String? _error;



  @override

  void dispose() {

    _pinController.dispose();

    super.dispose();

  }



  Future<void> _unlock() async {

    final pin = _pinController.text.trim();



    if (pin.isEmpty) {

      setState(() {

        _error = 'أدخل الرقم السري';

      });

      return;

    }



    setState(() {

      _checking = true;

      _error = null;

    });



    final success = await widget.onUnlock(pin);



    if (!mounted) return;



    setState(() {

      _checking = false;

    });



    if (!success) {

      setState(() {

        _error = 'الرقم السري غير صحيح';

      });



      _pinController.clear();

    }

  }



  @override

  Widget build(BuildContext context) {

    return Directionality(

      textDirection: TextDirection.rtl,

      child: Material(

        color: const Color(0xffF7F9FC),

        child: SafeArea(

          child: Stack(

            children: [

              Center(

                child: SingleChildScrollView(

                  padding: const EdgeInsets.all(24),

                  child: ConstrainedBox(

                    constraints: const BoxConstraints(

                      maxWidth: 380,

                    ),

                    child: Container(

                      padding: const EdgeInsets.all(24),

                      decoration: BoxDecoration(

                        color: Colors.white,

                        borderRadius: BorderRadius.circular(22),

                        border: Border.all(

                          color: const Color(0xffE5E7EB),

                        ),

                        boxShadow: const [

                          BoxShadow(

                            color: Color(0x12000000),

                            blurRadius: 20,

                            offset: Offset(0, 8),

                          ),

                        ],

                      ),

                      child: Column(

                        mainAxisSize: MainAxisSize.min,

                        children: [

                          Container(

                            width: 68,

                            height: 68,

                            decoration: BoxDecoration(

                              color: const Color(0xffEFF6FF),

                              borderRadius: BorderRadius.circular(20),

                            ),

                            child: const Icon(

                              Icons.lock_outline_rounded,

                              size: 34,

                              color: Color(0xff2864D7),

                            ),

                          ),



                          const SizedBox(height: 18),



                          const Text(

                            'التطبيق مقفل',

                            style: TextStyle(

                              fontSize: 22,

                              fontWeight: FontWeight.bold,

                              color: Color(0xff111827),

                            ),

                          ),



                          const SizedBox(height: 7),



                          const Text(

                            'أدخل الرقم السري للمتابعة',

                            textAlign: TextAlign.center,

                            style: TextStyle(

                              fontSize: 13,

                              color: Color(0xff7A8495),

                            ),

                          ),



                          const SizedBox(height: 22),



                          TextField(

                            controller: _pinController,

                            obscureText: true,

                            keyboardType: TextInputType.number,

                            textAlign: TextAlign.center,

                            maxLength: 20,

                            onSubmitted: (_) => _unlock(),

                            decoration: InputDecoration(

                              counterText: '',

                              hintText: 'الرقم السري',

                              filled: true,

                              fillColor: const Color(0xffF8FAFC),



                              prefixIcon: const Icon(

                                Icons.lock_outline_rounded,

                                color: Color(0xff64748B),

                              ),



                              border: OutlineInputBorder(

                                borderRadius: BorderRadius.circular(13),

                                borderSide: const BorderSide(

                                  color: Color(0xffE5E7EB),

                                ),

                              ),



                              enabledBorder: OutlineInputBorder(

                                borderRadius: BorderRadius.circular(13),

                                borderSide: const BorderSide(

                                  color: Color(0xffE5E7EB),

                                ),

                              ),



                              focusedBorder: OutlineInputBorder(

                                borderRadius: BorderRadius.circular(13),

                                borderSide: const BorderSide(

                                  color: Color(0xff2864D7),

                                  width: 1.5,

                                ),

                              ),

                            ),

                          ),



                          if (_error != null) ...[

                            const SizedBox(height: 8),



                            Text(

                              _error!,

                              style: const TextStyle(

                                color: Color(0xffDC2626),

                                fontSize: 12,

                                fontWeight: FontWeight.w600,

                              ),

                            ),

                          ],



                          const SizedBox(height: 16),



                          SizedBox(

                            width: double.infinity,

                            height: 46,

                            child: ElevatedButton.icon(

                              onPressed: _checking ? null : _unlock,



                              style: ElevatedButton.styleFrom(

                                backgroundColor: const Color(0xff2864D7),

                                foregroundColor: Colors.white,

                                elevation: 0,



                                shape: RoundedRectangleBorder(

                                  borderRadius: BorderRadius.circular(13),

                                ),

                              ),



                              icon: _checking

                                  ? const SizedBox(

                                      width: 18,

                                      height: 18,

                                      child: CircularProgressIndicator(

                                        strokeWidth: 2,

                                        color: Colors.white,

                                      ),

                                    )

                                  : const Icon(

                                      Icons.lock_open_rounded,

                                      size: 19,

                                    ),



                              label: Text(

                                _checking

                                    ? 'جاري التحقق...'

                                    : 'فتح التطبيق',



                                style: const TextStyle(

                                  fontSize: 13,

                                  fontWeight: FontWeight.bold,

                                ),

                              ),

                            ),

                          ),

                        ],

                      ),

                    ),

                  ),

                ),

              ),



              // زر الرجوع إلى الصفحة الرئيسية

              Positioned(

                top: 12,

                right: 12,

                child: Material(

                  color: Colors.white,

                  borderRadius: BorderRadius.circular(12),

                  elevation: 0,



                  child: InkWell(

                    borderRadius: BorderRadius.circular(12),

                    onTap: widget.onBackToHome,



                    child: Container(

                      padding: const EdgeInsets.symmetric(

                        horizontal: 13,

                        vertical: 10,

                      ),



                      decoration: BoxDecoration(

                        borderRadius: BorderRadius.circular(12),

                        border: Border.all(

                          color: const Color(0xffE5E7EB),

                        ),

                      ),



                      child: const Row(

                        mainAxisSize: MainAxisSize.min,

                        children: [

                          Icon(

                            Icons.arrow_forward_rounded,

                            size: 18,

                            color: Color(0xff374151),

                          ),



                          SizedBox(width: 6),



                          Text(

                            'الرئيسية',

                            style: TextStyle(

                              fontSize: 12,

                              fontWeight: FontWeight.w700,

                              color: Color(0xff374151),

                            ),

                          ),

                        ],

                      ),

                    ),

                  ),

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }

}