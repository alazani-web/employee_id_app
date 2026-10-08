import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'services/supabase_service.dart';



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

  bool _subscriptionLoading = true;
  bool _subscriptionRequired = false;

  // مدة التجربة المجانية. غيّر الرقم فقط إذا أردت مدة مختلفة.
  static const int _trialDays = 0;
  static const String _trialStartKey = 'app_trial_start_date';


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
    _loadSubscriptionState();

  }



  @override

  void dispose() {

    WidgetsBinding.instance.removeObserver(this);

    super.dispose();

  }



  Future<void> _loadSubscriptionState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const trialKey = _trialStartKey;

      DateTime? trialStart;
      final saved = prefs.getString(trialKey);
      if (saved != null && saved.isNotEmpty) {
        trialStart = DateTime.tryParse(saved);
      }

      trialStart ??= DateTime.now();
      if (saved == null || saved.isEmpty || DateTime.tryParse(saved) == null) {
        await prefs.setString(trialKey, trialStart.toIso8601String());
      }

      final active = await SupabaseService.instance.hasActiveSubscription;
      final trialEnds = trialStart.add(const Duration(days: _trialDays));
      final expired = DateTime.now().isAfter(trialEnds);

      if (!mounted) return;
      setState(() {
        _subscriptionRequired = !active && expired;
        _subscriptionLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _subscriptionLoading = false;
        _subscriptionRequired = false;
      });
    }
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

    if (_loadingLock || _subscriptionLoading) {
      return const Material(
        color: Color(0xffF7F9FC),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_subscriptionRequired) {
      return SubscriptionActivationScreen(
        onActivated: () {
          if (!mounted) return;
          setState(() {
            _subscriptionRequired = false;
            _subscriptionLoading = false;
          });
        },
      );
    }

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


// ============================================================
// شاشة تفعيل الاشتراك
// ============================================================

class SubscriptionActivationScreen extends StatefulWidget {
  final VoidCallback onActivated;

  const SubscriptionActivationScreen({
    super.key,
    required this.onActivated,
  });

  @override
  State<SubscriptionActivationScreen> createState() =>
      _SubscriptionActivationScreenState();
}

enum _ActivationState {
  idle,
  checking,
  success,
  error,
}

class _SubscriptionActivationScreenState
    extends State<SubscriptionActivationScreen>
    with TickerProviderStateMixin {
  final TextEditingController _keyController = TextEditingController();
  final FocusNode _keyFocus = FocusNode();

  late final AnimationController _pulseController;
  late final AnimationController _spinController;
  late final AnimationController _successController;

  _ActivationState _state = _ActivationState.idle;
  String _message = '';

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
  }

  @override
  void dispose() {
    _keyController.dispose();
    _keyFocus.dispose();
    _pulseController.dispose();
    _spinController.dispose();
    _successController.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    final key = _keyController.text.trim();

    if (key.isEmpty) {
      _showError('أدخل مفتاح الاشتراك أولاً');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _state = _ActivationState.checking;
      _message = 'جاري التحقق من صلاحية المفتاح...';
    });

    _spinController
      ..reset()
      ..repeat();

    try {
      final service = SupabaseService.instance;

      await service.ensureSignedIn();

      final result = await service.activateSubscription(key);

      if (!mounted) return;

      _spinController
        ..stop()
        ..reset();

      if (result.success) {
        setState(() {
          _state = _ActivationState.success;
          _message = result.message;
        });

        _successController
          ..reset()
          ..forward();

        await Future<void>.delayed(
          const Duration(milliseconds: 1250),
        );

        if (!mounted) return;
        widget.onActivated();
        return;
      }

      _showError(result.message);
    } catch (e) {
      if (!mounted) return;

      _spinController
        ..stop()
        ..reset();

      _showError('تعذر الاتصال بخدمة الاشتراك. حاول مرة أخرى.');
      debugPrint('SUBSCRIPTION ACTIVATION ERROR => $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    _spinController
      ..stop()
      ..reset();

    setState(() {
      _state = _ActivationState.error;
      _message = message;
    });

    Future<void>.delayed(
      const Duration(milliseconds: 1000),
      () {
        if (!mounted) return;
        if (_state == _ActivationState.error) {
          setState(() {
            _state = _ActivationState.idle;
            _message = '';
          });
        }
      },
    );
  }

  Color get _accent {
    switch (_state) {
      case _ActivationState.success:
        return const Color(0xff16A34A);
      case _ActivationState.error:
        return const Color(0xffE05260);
      default:
        return const Color(0xff2563EB);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF3F6FB),
        body: Stack(
          children: [
            Positioned(
              top: -100,
              left: -90,
              child: _ambientOrb(
                size: 260,
                color: const Color(0xffDCE8FF),
              ),
            ),
            Positioned(
              bottom: -130,
              right: -100,
              child: _ambientOrb(
                size: 300,
                color: const Color(0xffE5ECFA),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 26,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 455,
                    ),
                    child: _buildPremiumCard(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ambientOrb({
    required double size,
    required Color color,
  }) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withOpacity(.72),
              color.withOpacity(.08),
              Colors.transparent,
            ],
            stops: const [0, .62, 1],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumCard() {
    final bool isSuccess = _state == _ActivationState.success;
    final bool isError = _state == _ActivationState.error;
    final bool isChecking = _state == _ActivationState.checking;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isSuccess
              ? const Color(0xffCDEEDB)
              : isError
                  ? const Color(0xffF3D5D8)
                  : const Color(0xffE6EBF3),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140B1F45),
            blurRadius: 45,
            offset: Offset(0, 20),
          ),
          BoxShadow(
            color: Color(0x080B1F45),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Column(
          children: [
            _buildPremiumHeader(),

            Padding(
              padding: const EdgeInsets.fromLTRB(28, 26, 28, 26),
              child: Column(
                children: [
                  _buildPremiumStatusIcon(),

                  const SizedBox(height: 24),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      isSuccess
                          ? 'تم تفعيل الاشتراك'
                          : isError
                              ? 'تعذر تفعيل الاشتراك'
                              : isChecking
                                  ? 'جاري التحقق'
                                  : 'فعّل اشتراكك',
                      key: ValueKey<String>(
                        '${_state}_title',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 27,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xff101828),
                        letterSpacing: -.4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      _state == _ActivationState.idle
                          ? 'أدخل مفتاح الاشتراك للوصول إلى جميع مزايا النظام.'
                          : _message,
                      key: ValueKey<String>(_message),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.65,
                        color: isError
                            ? const Color(0xffC2414A)
                            : isSuccess
                                ? const Color(0xff16834A)
                                : const Color(0xff667085),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 26),

                  _buildKeyInput(isChecking || isSuccess),

                  const SizedBox(height: 14),

                  _buildActivationButton(),

                  const SizedBox(height: 20),

                  _buildSecurityNote(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return Container(
      height: 92,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            Color(0xff1747A3),
            Color(0xff2864D7),
            Color(0xff3B7AF0),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.14),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withOpacity(.20),
              ),
            ),
            child: const Icon(
              LucideIcons.crown,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'ترخيص نظام إدارة الهويات',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'تفعيل آمن • وصول كامل • اشتراك مرتبط بجهازك',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Color(0xCFFFFFFF),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumStatusIcon() {
    final bool isChecking = _state == _ActivationState.checking;
    final bool isSuccess = _state == _ActivationState.success;
    final bool isError = _state == _ActivationState.error;

    final Color color = _accent;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseController,
        _spinController,
        _successController,
      ]),
      builder: (context, child) {
        final pulse = .94 + (_pulseController.value * .06);
        final double ringScale = isChecking
            ? 1.0 + (_spinController.value * .035)
            : isSuccess
                ? 1.0 + (_successController.value * .08)
                : 1.0;

        return SizedBox(
          width: 138,
          height: 138,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (!isSuccess && !isError)
                Transform.scale(
                  scale: pulse,
                  child: Container(
                    width: 124,
                    height: 124,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withOpacity(.10),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

              if (isChecking)
                SizedBox(
                  width: 128,
                  height: 128,
                  child: CircularProgressIndicator(
                    value: null,
                    strokeWidth: 2.2,
                    color: color.withOpacity(.35),
                  ),
                ),

              if (isChecking)
                Transform.rotate(
                  angle: _spinController.value * 6.28318,
                  child: SizedBox(
                    width: 128,
                    height: 128,
                    child: CustomPaint(
                      painter: _PremiumArcPainter(
                        color: color,
                        strokeWidth: 4,
                      ),
                    ),
                  ),
                ),

              Transform.scale(
                scale: ringScale,
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        color.withOpacity(.16),
                        color.withOpacity(.055),
                      ],
                    ),
                    border: Border.all(
                      color: color.withOpacity(.24),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(.13),
                        blurRadius: 25,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutBack,
                        ),
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: Icon(
                      isSuccess
                          ? LucideIcons.circleCheck
                          : isError
                              ? LucideIcons.circleX
                              : LucideIcons.keyRound,
                      key: ValueKey(_state),
                      color: color,
                      size: 39,
                      
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKeyInput(bool disabled) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _state == _ActivationState.error
              ? const Color(0xffE8A3AA)
              : _state == _ActivationState.success
                  ? const Color(0xffBCE4CB)
                  : const Color(0xffDDE5F0),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _keyController,
        focusNode: _keyFocus,
        enabled: !disabled,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        textCapitalization: TextCapitalization.characters,
        keyboardType: TextInputType.text,
        onSubmitted: (_) => _activate(),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.8,
          color: Color(0xff172B4D),
        ),
        decoration: InputDecoration(
          hintText: 'XXXX-XXXX-XXXX-XXXX',
          hintStyle: const TextStyle(
            color: Color(0xffA8B4C7),
            fontSize: 14,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xffEAF1FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                LucideIcons.keyRound,
                color: Color(0xff2864D7),
                size: 18,
              ),
            ),
          ),
          suffixIcon: const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(
              LucideIcons.lockKeyhole,
              color: Color(0xff98A6BA),
              size: 19,
            ),
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 19,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildActivationButton() {
    final bool checking = _state == _ActivationState.checking;
    final bool success = _state == _ActivationState.success;

    return SizedBox(
      width: double.infinity,
      height: 55,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          boxShadow: [
            if (!checking && !success)
              BoxShadow(
                color: const Color(0xff2563EB).withOpacity(.22),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
          ],
        ),
        child: ElevatedButton(
          onPressed: checking || success ? null : _activate,
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            disabledBackgroundColor: _accent.withOpacity(.60),
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(17),
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: animation,
                  child: child,
                ),
              );
            },
            child: checking
                ? const Row(
                    key: ValueKey('checking'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 21,
                        height: 21,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 11),
                      Text(
                        'جاري التحقق...',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  )
                : success
                    ? const Row(
                        key: ValueKey('success'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.circleCheck,
                            size: 22,
                          ),
                          SizedBox(width: 9),
                          Text(
                            'تم التفعيل بنجاح',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      )
                    : const Row(
                        key: ValueKey('idle'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.arrowLeft,
                            size: 20,
                          ),
                          SizedBox(width: 9),
                          Text(
                            'تفعيل الاشتراك',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityNote() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFD),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xffE8EDF4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xffEAF1FF),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              LucideIcons.shieldCheck,
              color: Color(0xff2864D7),
              size: 17,
            ),
          ),
          const SizedBox(width: 9),
          const Expanded(
            child: Text(
              'يتم التحقق من المفتاح عبر خادم الاشتراكات بشكل آمن، ولا يتم حفظ المفتاح الكامل داخل الواجهة.',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 10.5,
                height: 1.55,
                color: Color(0xff667085),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumArcPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const _PremiumArcPainter({
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - strokeWidth / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.25,
      1.65,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _PremiumArcPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class _PremiumStatusPainter extends CustomPainter {
  final _ActivationState state;
  final Color color;
  final double progress;

  const _PremiumStatusPainter({
    required this.state,
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (state == _ActivationState.success) {
      final path = Path()
        ..moveTo(size.width * .27, size.height * .52)
        ..lineTo(size.width * .45, size.height * .69)
        ..lineTo(size.width * .75, size.height * .34);

      final metric = path.computeMetrics().first;
      final partial = metric.extractPath(
        0,
        metric.length * Curves.easeOutCubic.transform(
          progress.clamp(0.0, 1.0),
        ),
      );

      canvas.drawPath(partial, paint);
      return;
    }

    if (state == _ActivationState.error) {
      final p1 = Path()
        ..moveTo(size.width * .32, size.height * .32)
        ..lineTo(size.width * .68, size.height * .68);

      final p2 = Path()
        ..moveTo(size.width * .68, size.height * .32)
        ..lineTo(size.width * .32, size.height * .68);

      canvas.drawPath(p1, paint);
      canvas.drawPath(p2, paint);
      return;
    }

    // مفتاح احترافي مرسوم بدل أيقونة جاهزة.
    final keyPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(
      Offset(size.width * .35, size.height * .48),
      size.width * .13,
      keyPaint,
    );

    canvas.drawLine(
      Offset(size.width * .46, size.height * .48),
      Offset(size.width * .73, size.height * .48),
      keyPaint,
    );

    canvas.drawLine(
      Offset(size.width * .62, size.height * .48),
      Offset(size.width * .62, size.height * .61),
      keyPaint,
    );

    canvas.drawLine(
      Offset(size.width * .72, size.height * .48),
      Offset(size.width * .72, size.height * .57),
      keyPaint,
    );

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      center,
      size.width * .035,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PremiumStatusPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.color != color ||
        oldDelegate.progress != progress;
  }
}

