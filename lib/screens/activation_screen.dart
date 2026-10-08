import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/supabase_service.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen>
    with SingleTickerProviderStateMixin {
  SubscriptionInfo? _info;
  TrialInfo? _trialInfo;

  bool _loading = true;
  bool _deactivating = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  static const Color primary = Color(0xff2864D7);
  static const Color primaryDark = Color(0xff1749A5);
  static const Color background = Color(0xffF5F8FD);
  static const Color textDark = Color(0xff172033);
  static const Color textMuted = Color(0xff718096);
  static const Color green = Color(0xff16A34A);
  static const Color red = Color(0xffDC3E4D);

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _load();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final info = await SupabaseService.instance.subscriptionInfo;
    final trial = await SupabaseService.instance.trialInfo;

    if (!mounted) return;

    setState(() {
      _info = info;
      _trialInfo = trial;
      _loading = false;
    });

    _animationController.forward();
  }

  String _date(DateTime value) {
    final d = value.day.toString().padLeft(2, '0');
    final m = value.month.toString().padLeft(2, '0');

    return '$d/$m/${value.year}';
  }

  String _remaining(SubscriptionInfo info) {
    if (!info.active) {
      return 'منتهي';
    }

    if (info.remainingDays <= 0) {
      return 'ينتهي اليوم';
    }

    return '${info.remainingDays} يوم';
  }

  double _progress(SubscriptionInfo info) {
    final totalDays = info.expiresAt
        .difference(info.activatedAt)
        .inDays
        .clamp(1, 3650);

    final remainingDays = info.remainingDays.clamp(0, totalDays);

    return (remainingDays / totalDays).clamp(0.0, 1.0);
  }

  Future<void> _deactivate() async {
    if (_deactivating) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xfffff1f2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xffffd5d9),
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.power,
                      color: red,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'إلغاء تفعيل الجهاز؟',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'سيتم إلغاء ربط الاشتراك بهذا الجهاز، ويمكن تفعيل المفتاح مرة أخرى على جهاز آخر.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: textMuted,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            side: const BorderSide(
                              color: Color(0xffDCE3EF),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'إلغاء',
                            style: TextStyle(
                              color: Color(0xff475569),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            backgroundColor: red,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'إلغاء التفعيل',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _deactivating = true;
    });

    try {
      /*
       * هذه الدالة تقوم بتحرير المفتاح من Supabase
       * ثم يمكن حذف بيانات الاشتراك المحلية.
       */
      await SupabaseService.instance.deactivateSubscription();
      await SupabaseService.instance.clearSubscription();

      if (!mounted) return;

      setState(() {
        _info = null;
        _deactivating = false;
      });

      _showMessage(
        'تم إلغاء تفعيل الجهاز وتحرير مفتاح الاشتراك',
        success: true,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _deactivating = false;
      });

      _showMessage(
        'تعذر إلغاء تفعيل الاشتراك، حاول مرة أخرى',
        success: false,
      );
    }
  }

  void _showMessage(
    String message, {
    required bool success,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: success ? green : red,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        content: Row(
          children: [
            Icon(
              success
                  ? LucideIcons.circleCheck
                  : LucideIcons.circleAlert,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: background,
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: primary,
                ),
              )
            : FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildContent(),
                ),
              ),
      ),
    );
  }

  Widget _buildContent() {
    final info = _info;

    if (info == null) {
      if (_trialInfo != null && _trialInfo!.active) {
        return _buildTrialState();
      }

      return _buildEmptyState();
    }

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _buildPremiumHeader(info),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  _buildStatusCard(info),
                  const SizedBox(height: 14),
                  _buildProgressCard(info),
                  const SizedBox(height: 14),
                  _buildDetailsSection(info),
                  const SizedBox(height: 14),
                  _buildSecurityCard(),
                  const SizedBox(height: 20),
                  _buildDeactivateButton(),
                  const SizedBox(height: 12),
                  const Text(
                    'اشتراكك مرتبط بهذا الجهاز ويتم التحقق من صلاحيته بشكل آمن.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xff94A3B8),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader(SubscriptionInfo info) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            primary,
            primaryDark,
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -25,
            top: -35,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: -40,
            bottom: -55,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.badgeCheck,
                      color: Colors.white,
                      size: 27,
                    ),
                  ),
                  const SizedBox(width: 13),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'إدارة الاشتراك',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'إدارة الترخيص والاشتراك الحالي',
                          style: TextStyle(
                            color: Color(0xffDCE8FF),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _headerStat(
                      icon: LucideIcons.crown,
                      title: 'الباقة',
                      value: info.plan,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _headerStat(
                      icon: LucideIcons.clock3,
                      title: 'المتبقي',
                      value: info.active
                          ? '${info.remainingDays} يوم'
                          : 'منتهي',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerStat({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xffC9D9FF),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(SubscriptionInfo info) {
    final active = info.active;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: active
              ? const Color(0xffD9F2E2)
              : const Color(0xffffd8dd),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 22,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xffECFDF3)
                  : const Color(0xfffff1f2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              active
                  ? LucideIcons.circleCheck
                  : LucideIcons.circleX,
              color: active ? green : red,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  active ? 'الاشتراك مفعل' : 'الاشتراك منتهي',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: active ? green : red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  active
                      ? 'اشتراكك يعمل بشكل طبيعي ويمكنك استخدام النظام بالكامل.'
                      : 'انتهت صلاحية الاشتراك الحالي.',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: textMuted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xffECFDF3)
                  : const Color(0xfffff1f2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: active ? green : red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  active ? 'فعال' : 'منتهي',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: active ? green : red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(SubscriptionInfo info) {
    final progress = _progress(info);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xffE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.chartNoAxesColumnIncreasing,
                color: primary,
                size: 20,
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'مدة الاشتراك',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                  ),
                ),
              ),
              Text(
                _remaining(info),
                style: const TextStyle(
                  color: primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: const Color(0xffE8EEF8),
              valueColor: const AlwaysStoppedAnimation<Color>(
                primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'تاريخ التفعيل ${_date(info.activatedAt)}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: textMuted,
                  ),
                ),
              ),
              Text(
                'ينتهي ${_date(info.expiresAt)}',
                style: const TextStyle(
                  fontSize: 10.5,
                  color: textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(SubscriptionInfo info) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'تفاصيل الاشتراك',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: textDark,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _detailCard(
                icon: LucideIcons.crown,
                title: 'الباقة',
                value: info.plan,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _detailCard(
                icon: LucideIcons.calendarDays,
                title: 'تاريخ التفعيل',
                value: _date(info.activatedAt),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _detailCard(
                icon: LucideIcons.calendarCheck,
                title: 'تاريخ الانتهاء',
                value: _date(info.expiresAt),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _detailCard(
                icon: LucideIcons.clock3,
                title: 'المتبقي',
                value: _remaining(info),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _wideDetailCard(
          icon: LucideIcons.keyRound,
          title: 'مفتاح التفعيل',
          value: info.maskedKey,
        ),
        const SizedBox(height: 10),
        _wideDetailCard(
          icon: LucideIcons.smartphone,
          title: 'الجهاز المرتبط',
          value: 'هذا الجهاز',
        ),
      ],
    );
  }

  Widget _detailCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 105,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xffE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xffEEF4FF),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: primary,
              size: 18,
            ),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10.5,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _wideDetailCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xffE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xffEEF4FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: primary,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: textMuted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            LucideIcons.shieldCheck,
            color: Color(0xff94B8F8),
            size: 19,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xffF0F6FF),
            Color(0xffF8FBFF),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xffD9E7FF),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              LucideIcons.shieldCheck,
              color: primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'اشتراكك محمي',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: textDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'يتم حفظ بيانات الترخيص بشكل آمن ولا يتم عرض المفتاح الكامل داخل التطبيق.',
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.5,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeactivateButton() {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: _deactivating ? null : _deactivate,
        style: OutlinedButton.styleFrom(
          foregroundColor: red,
          disabledForegroundColor: const Color(0xff94A3B8),
          side: BorderSide(
            color: _deactivating
                ? const Color(0xffE2E8F0)
                : const Color(0xffffb8c0),
          ),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _deactivating
            ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  strokeWidth: 2.3,
                  color: red,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.power,
                    size: 19,
                  ),
                  SizedBox(width: 9),
                  Text(
                    'إلغاء تفعيل هذا الجهاز',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
      ),
    );
  }


  Widget _buildTrialState() {
    final trial = _trialInfo!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xffD9E7FF),
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
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xffECFDF3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.gift,
                size: 45,
                color: green,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'التجربة المجانية مفعلة',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w900,
                color: textDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'متبقي ${trial.remainingDays} أيام للاستفادة من جميع مزايا النظام',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: textMuted,
                height: 1.8,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xffF5F8FD),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.calendarDays,
                    color: primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'تنتهي في ${_date(trial.trialEnd)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'الدخول إلى النظام',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0xffE1E8F2),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 25,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xffEAF2FF),
                        Color(0xffDCEAFF),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.keyRound,
                    color: primary,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'لا يوجد اشتراك مفعل',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 9),
                const Text(
                  'لا توجد بيانات اشتراك محفوظة على هذا الجهاز حاليًا.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: textMuted,
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xffF5F8FD),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        LucideIcons.info,
                        color: primary,
                        size: 18,
                      ),
                      SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'قم بتفعيل مفتاح اشتراك صالح للوصول إلى جميع مزايا النظام.',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.5,
                            color: textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}