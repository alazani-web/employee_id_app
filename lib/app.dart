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
import 'screens/admin_login_screen.dart';



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
  TrialInfo? _trialInfo;

  // مدة التجربة المجانية ثابتة في Supabase = 7 أيام.


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
      final service = SupabaseService.instance;

      // أولاً نتحقق من المدير قبل إنشاء مستخدم مجهول.
      // المدير يتجاوز شاشة التفعيل بالكامل.
      final isAdmin = await service.isAdmin;

      if (isAdmin) {
        if (!mounted) return;

        setState(() {
          _subscriptionRequired = false;
          _subscriptionLoading = false;
        });

        return;
      }

      // العملاء فقط يحتاجون جلسة وتجربة/اشتراك.
      await service.ensureSignedIn();

      final trial = await service.trialInfo;
      final active = await service.hasActiveSubscription;

      if (!mounted) return;

      setState(() {
        _trialInfo = trial;

        // المدير يتجاوز شاشة التفعيل دائمًا.
        // العملاء: اشتراك فعال أو تجربة مجانية 7 أيام.
        _subscriptionRequired =
            !isAdmin && !active && !(trial?.active ?? false);

        _subscriptionLoading = false;
      });
    } catch (e) {
      debugPrint('SUBSCRIPTION/TRIAL LOAD ERROR => $e');
      if (!mounted) return;

      // إذا تعذر الوصول للسيرفر لا نقفل التطبيق خطأً؛ ننتظر إعادة المحاولة.
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
        onSubscriptionDeactivated: _handleSubscriptionDeactivated,

      );

    }



    return IndexedStack(

      index: getCurrentIndex(),

      children: _mainPages,

    );

  }



  void _handleSubscriptionDeactivated() {
    if (!mounted) return;

    setState(() {
      _subscriptionRequired = true;
      _subscriptionLoading = false;
      _trialInfo = null;
      currentPage = 'home';
    });
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
          _loadSubscriptionState();
          // الاشتراك الفعال يتغلب على حالة التجربة المجانية.
          // نعيد تحميل البيانات عند الحاجة دون إظهار شاشة التفعيل مجددًا.
        },
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

// ============================================================
// شاشة تفعيل الاشتراك — Premium / Enterprise
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

enum _ActivationState { idle, checking, success, error }

class _SubscriptionActivationScreenState
    extends State<SubscriptionActivationScreen>
    with TickerProviderStateMixin {
  final TextEditingController _keyController = TextEditingController();
  final FocusNode _keyFocus = FocusNode();

  late final AnimationController _ambientController;
  late final AnimationController _spinController;
  late final AnimationController _successController;
  late final AnimationController _entryController;

  _ActivationState _state = _ActivationState.idle;
  String _message = '';

  static const Color navy = Color(0xff0D2452);
  static const Color blue = Color(0xff2563EB);
  static const Color blueLight = Color(0xffEAF2FF);
  static const Color background = Color(0xffF5F8FD);
  static const Color text = Color(0xff101828);
  static const Color muted = Color(0xff667085);
  static const Color success = Color(0xff16A34A);
  static const Color danger = Color(0xffD9485F);

  @override
  void initState() {
    super.initState();

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat(reverse: true);

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _keyController.dispose();
    _keyFocus.dispose();
    _ambientController.dispose();
    _spinController.dispose();
    _successController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    final key = _keyController.text.trim();

    if (key.isEmpty) {
      _showError('أدخل مفتاح الاشتراك أولاً');
      _keyFocus.requestFocus();
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _state = _ActivationState.checking;
      _message = 'يتم التحقق من صلاحية المفتاح بأمان...';
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
          const Duration(milliseconds: 1300),
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

      debugPrint('SUBSCRIPTION ACTIVATION ERROR => $e');
      _showError(
        'تعذر الاتصال بخدمة الاشتراك. تحقق من الإنترنت وحاول مرة أخرى.',
      );
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

    Future<void>.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted || _state != _ActivationState.error) return;

      setState(() {
        _state = _ActivationState.idle;
        _message = '';
      });
    });
  }

  Color get _accent {
    switch (_state) {
      case _ActivationState.success:
        return success;
      case _ActivationState.error:
        return danger;
      case _ActivationState.checking:
      case _ActivationState.idle:
        return blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: background,
        body: Stack(
          children: [
            _buildAmbientBackground(),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _entryController,
                        curve: Curves.easeOut,
                      ),
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, .035),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _entryController,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                        child: _buildPremiumCard(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmbientBackground() {
    return AnimatedBuilder(
      animation: _ambientController,
      builder: (context, child) {
        final t = _ambientController.value;

        return Stack(
          children: [
            Positioned(
              top: -150 + (t * 18),
              right: -120,
              child: _glow(
                360,
                const Color(0xffD9E7FF),
              ),
            ),
            Positioned(
              bottom: -190 + (t * 12),
              left: -140,
              child: _glow(
                390,
                const Color(0xffE7EEFF),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _glow(double size, Color color) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: .72),
              color.withValues(alpha: .12),
              Colors.transparent,
            ],
            stops: const [0, .55, 1],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumCard() {
    final checking = _state == _ActivationState.checking;
    final successState = _state == _ActivationState.success;
    final errorState = _state == _ActivationState.error;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: errorState
              ? const Color(0xffF3CDD3)
              : successState
                  ? const Color(0xffCBE9D6)
                  : const Color(0xffE3EAF4),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x180B1F45),
            blurRadius: 45,
            offset: Offset(0, 22),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTopBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 30, 28, 27),
            child: Column(
              children: [
                _buildPremiumBadge(),
                const SizedBox(height: 25),
                _buildHero(),
                const SizedBox(height: 21),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child: Text(
                    successState
                        ? 'تم تفعيل اشتراكك'
                        : errorState
                            ? 'لم يتم تفعيل المفتاح'
                            : checking
                                ? 'جاري التحقق من المفتاح'
                                : 'فعّل اشتراكك',
                    key: ValueKey(_state),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 29,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                      color: text,
                      letterSpacing: -.6,
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Text(
                    _state == _ActivationState.idle
                        ? 'افتح كامل مزايا النظام باستخدام مفتاح الاشتراك الخاص بك.'
                        : _message,
                    key: ValueKey(_message),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.65,
                      color: errorState
                          ? const Color(0xffC2414A)
                          : successState
                              ? const Color(0xff16834A)
                              : muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                _buildKeyInput(
                  disabled: checking || successState,
                ),
                const SizedBox(height: 13),
                _buildActivateButton(),
                const SizedBox(height: 8),

                // دخول الإدارة لتجاوز الاشتراك لحساب المدير فقط
                _buildAdminLoginButton(),

                const SizedBox(height: 13),
                _buildBenefits(),
                const SizedBox(height: 18),
                _buildSecurityNote(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            Color(0xff1749A5),
            Color(0xff2563EB),
            Color(0xff3D7CF1),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withValues(alpha: .22),
              ),
            ),
            child: const Icon(
              LucideIcons.crown,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ترخيص نظام إدارة الهويات',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'PREMIUM LICENSE  •  وصول كامل',
                  style: TextStyle(
                    color: Color(0xDFFFFFFF),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .11),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: .18),
              ),
            ),
            child: const Icon(
              LucideIcons.shieldCheck,
              color: Colors.white,
              size: 19,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xffF0F5FF),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xffD8E5FF),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.sparkles,
            color: blue,
            size: 14,
          ),
          SizedBox(width: 7),
          Text(
            'PREMIUM ACCESS',
            style: TextStyle(
              color: Color(0xff285BB8),
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    final checking = _state == _ActivationState.checking;
    final successState = _state == _ActivationState.success;
    final errorState = _state == _ActivationState.error;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _spinController,
        _successController,
      ]),
      builder: (context, child) {
        final successScale =
            successState ? 1 + (_successController.value * .08) : 1.0;

        return SizedBox(
          width: 154,
          height: 154,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _accent.withValues(alpha: .09),
                    width: 1,
                  ),
                ),
              ),
              Container(
                width: 126,
                height: 126,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accent.withValues(alpha: .035),
                  border: Border.all(
                    color: _accent.withValues(alpha: .16),
                    width: 1.2,
                  ),
                ),
              ),
              if (checking)
                SizedBox(
                  width: 130,
                  height: 130,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: _accent.withValues(alpha: .35),
                  ),
                ),
              if (checking)
                Transform.rotate(
                  angle: _spinController.value * 6.28318,
                  child: SizedBox(
                    width: 130,
                    height: 130,
                    child: CustomPaint(
                      painter: _ActivationArcPainter(
                        color: _accent,
                      ),
                    ),
                  ),
                ),
              Transform.scale(
                scale: successScale,
                child: Container(
                  width: 94,
                  height: 94,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _accent.withValues(alpha: .16),
                        _accent.withValues(alpha: .045),
                      ],
                    ),
                    border: Border.all(
                      color: _accent.withValues(alpha: .25),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _accent.withValues(alpha: .13),
                        blurRadius: 28,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
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
                      successState
                          ? LucideIcons.circleCheck
                          : errorState
                              ? LucideIcons.circleX
                              : LucideIcons.keyRound,
                      key: ValueKey(_state),
                      color: _accent,
                      size: 42,
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

  Widget _buildKeyInput({required bool disabled}) {
    final errorState = _state == _ActivationState.error;
    final successState = _state == _ActivationState.success;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: errorState
              ? const Color(0xffE6A5AD)
              : successState
                  ? const Color(0xffBCE4CB)
                  : const Color(0xffD8E2EF),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xffEAF1FF),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              LucideIcons.keyRound,
              color: blue,
              size: 19,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _keyController,
              focusNode: _keyFocus,
              enabled: !disabled,
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              textCapitalization: TextCapitalization.characters,
              onSubmitted: (_) => _activate(),
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: Color(0xff172B4D),
              ),
              decoration: const InputDecoration(
                hintText: 'XXXX-XXXX-XXXX-XXXX',
                hintStyle: TextStyle(
                  color: Color(0xffAAB6C8),
                  fontSize: 13.5,
                  letterSpacing: 1.3,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 14,
                ),
              ),
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: const Color(0xffE2E8F0),
              ),
            ),
            child: const Icon(
              LucideIcons.lockKeyhole,
              color: Color(0xff91A0B5),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivateButton() {
    final checking = _state == _ActivationState.checking;
    final successState = _state == _ActivationState.success;

    return SizedBox(
      width: double.infinity,
      height: 57,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            if (!checking && !successState)
              const BoxShadow(
                color: Color(0x332563EB),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
          ],
        ),
        child: ElevatedButton(
          onPressed: checking || successState ? null : _activate,
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            disabledBackgroundColor: _accent.withValues(alpha: .62),
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: checking
                ? const Row(
                    key: ValueKey('checking'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.3,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'جاري التحقق من المفتاح',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  )
                : successState
                    ? const Row(
                        key: ValueKey('success'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.circleCheck,
                            size: 21,
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
                          Text(
                            'تحقق وتفعيل الاشتراك',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: 9),
                          Icon(
                            LucideIcons.arrowLeft,
                            size: 20,
                          ),
                        ],
                      ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefits() {
    return Row(
      children: [
        Expanded(
          child: _benefit(
            LucideIcons.shieldCheck,
            'حماية',
            'تحقق آمن',
          ),
        ),
        _benefitDivider(),
        Expanded(
          child: _benefit(
            LucideIcons.cloud,
            'سحابي',
            'بيانات محفوظة',
          ),
        ),
        _benefitDivider(),
        Expanded(
          child: _benefit(
            LucideIcons.zap,
            'فوري',
            'تفعيل مباشر',
          ),
        ),
      ],
    );
  }

  Widget _benefit(IconData icon, String title, String subtitle) {
    return Column(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xffF0F5FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: blue,
            size: 18,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: text,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 8.5,
            color: muted,
          ),
        ),
      ],
    );
  }

  Widget _benefitDivider() {
    return Container(
      width: 1,
      height: 50,
      color: const Color(0xffE8EDF4),
    );
  }

  Widget _buildAdminLoginButton() {
    return TextButton.icon(
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminLoginScreen(),
          ),
        );

        if (!mounted) return;
        widget.onActivated();
      },
      icon: const Icon(
        Icons.admin_panel_settings_outlined,
        size: 18,
      ),
      label: const Text(
        'دخول الإدارة',
        style: TextStyle(
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildSecurityNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xffE4EAF2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: const Color(0xffE5EBF3),
              ),
            ),
            child: const Icon(
              LucideIcons.lockKeyhole,
              color: Color(0xff5D769C),
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'يتم التحقق من المفتاح عبر خادم الاشتراكات بشكل آمن، ولا يتم حفظ المفتاح الكامل داخل التطبيق.',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 9.5,
                height: 1.55,
                color: muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivationArcPainter extends CustomPainter {
  final Color color;

  const _ActivationArcPainter({
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 2;

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      -1.2,
      1.55,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _ActivationArcPainter oldDelegate,
  ) {
    return oldDelegate.color != color;
  }
}
