import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  static const _blue = Color(0xff2563EB);
  static const _green = Color(0xff16A34A);
  static const _red = Color(0xffDC2626);
  static const _pageBg = Color(0xffF7F9FC);

  final customerController = TextEditingController();
  final activationKeyController = TextEditingController();
  final expiryController = TextEditingController();

  bool licenseActive = true;
  int? selectedAlertDays;
  int? remainingDays;
  int usedDevices = 0;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  @override
  void dispose() {
    customerController.dispose();
    activationKeyController.dispose();
    expiryController.dispose();
    super.dispose();
  }

  Future<void> _loadSubscription() async {
    final prefs = await SharedPreferences.getInstance();

    customerController.text =
        prefs.getString('subscription_customer') ?? '';
    activationKeyController.text =
        prefs.getString('subscription_activation_key') ?? '';
    expiryController.text =
        prefs.getString('subscription_expiry') ?? '';

    licenseActive = prefs.getBool('subscription_active') ?? true;
    selectedAlertDays = prefs.getInt('subscription_alert_days');
    usedDevices = prefs.getInt('subscription_used_devices') ?? 0;

    _updateRemainingDays();

    if (mounted) setState(() {});
  }

  void _updateRemainingDays() {
    final parsed = _parseDate(expiryController.text.trim());

    if (parsed == null) {
      remainingDays = null;
      return;
    }

    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    final expiry = DateTime(parsed.year, parsed.month, parsed.day);
    remainingDays = expiry.difference(today).inDays;
  }

  DateTime? _parseDate(String value) {
    if (value.isEmpty) return null;

    final normalized = value.replaceAll('/', '-').trim();

    final direct = DateTime.tryParse(normalized);
    if (direct != null) return direct;

    final parts = normalized.split('-');
    if (parts.length != 3) return null;

    final a = int.tryParse(parts[0]);
    final b = int.tryParse(parts[1]);
    final c = int.tryParse(parts[2]);

    if (a == null || b == null || c == null) return null;

    if (a > 31) {
      return DateTime.tryParse(
        '${a.toString().padLeft(4, '0')}-'
        '${b.toString().padLeft(2, '0')}-'
        '${c.toString().padLeft(2, '0')}',
      );
    }

    return DateTime.tryParse(
      '${c.toString().padLeft(4, '0')}-'
      '${b.toString().padLeft(2, '0')}-'
      '${a.toString().padLeft(2, '0')}',
    );
  }

  bool get _isLicenseActive =>
      licenseActive && (remainingDays == null || remainingDays! >= 0);

  String _remainingText() {
    final days = remainingDays;

    if (days == null) return 'غير محددة';
    if (days < 0) return 'منتهية منذ ${days.abs()} يوم';
    if (days == 0) return 'تنتهي اليوم';
    return '$days يوم';
  }

  Color get _remainingColor {
    final days = remainingDays;

    if (days == null) return const Color(0xff64748B);
    if (days < 0 || days <= 7) return _red;
    if (days <= 30) return const Color(0xffD97706);
    return _green;
  }

  Future<void> _saveAlertSettings() async {
    final prefs = await SharedPreferences.getInstance();

    if (selectedAlertDays == null) {
      await prefs.remove('subscription_alert_days');
    } else {
      await prefs.setInt(
        'subscription_alert_days',
        selectedAlertDays!,
      );
    }

    if (!mounted) return;

    setState(() {
      _message = 'تم حفظ إعدادات التنبيه';
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      if (_message == 'تم حفظ إعدادات التنبيه') {
        setState(() => _message = null);
      }
    });
  }

  Future<void> _deactivateThisDevice({StateSetter? dialogSetState}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Text(
              'إلغاء تفعيل هذا الجهاز',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            content: const Text(
              'سيتم إلغاء تفعيل الترخيص على هذا الجهاز فقط.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('إلغاء التفعيل'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('subscription_active', false);

    if (!mounted) return;

    setState(() {
      licenseActive = false;
      _message = 'تم إلغاء تفعيل هذا الجهاز';
    });

    // تحديث نافذة إدارة الاشتراك فورًا أيضًا، وليس الشاشة الرئيسية فقط.
    dialogSetState?.call(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        color: _pageBg,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPageTitle(),
              const SizedBox(height: 16),
              _buildLicenseCard(),
              const SizedBox(height: 14),
              _buildManagementButton(),
              if (_message != null) ...[
                const SizedBox(height: 10),
                _buildMessage(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          LucideIcons.keyRound,
          size: 23,
          color: _blue,
        ),
        const SizedBox(width: 8),
        const Text(
          'التفعيل',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w800,
            color: Color(0xff111827),
          ),
        ),
      ],
    );
  }

  Widget _buildLicenseCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isLicenseActive
              ? const Color(0xffBBF7D0)
              : const Color(0xffFECACA),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.rtl,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _isLicenseActive
                    ? const Color(0xffDCFCE7)
                    : const Color(0xffFEE2E2),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(
                _isLicenseActive
                    ? LucideIcons.badgeCheck
                    : LucideIcons.shieldAlert,
                color: _isLicenseActive ? _green : _red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'حالة الترخيص',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff475569),
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  textDirection: TextDirection.rtl,
                  children: [
                    Icon(
                      _isLicenseActive
                          ? LucideIcons.circleCheck
                          : LucideIcons.circleX,
                      size: 16,
                      color: _isLicenseActive ? _green : _red,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _isLicenseActive
                          ? 'الترخيص مفعل'
                          : 'الترخيص غير مفعل',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _isLicenseActive ? _green : _red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _showSubscriptionManager,
        style: ElevatedButton.styleFrom(
          backgroundColor: _blue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              LucideIcons.settings2,
              size: 20,
            ),
            SizedBox(width: 9),
            Text(
              'إدارة الاشتراك',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(width: 6),
            Icon(
              LucideIcons.chevronLeft,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage() {
    final success = _message == 'تم حفظ إعدادات التنبيه';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: success
            ? const Color(0xffECFDF5)
            : const Color(0xffFEF2F2),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: success
              ? const Color(0xffA7F3D0)
              : const Color(0xffFECACA),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            success ? LucideIcons.circleCheck : LucideIcons.circleX,
            size: 18,
            color: success ? _green : _red,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              _message!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: success
                    ? const Color(0xff047857)
                    : const Color(0xffB91C1C),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSubscriptionManager() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 22,
            ),
            backgroundColor: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 470),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 15, 18, 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 30,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: StatefulBuilder(
                  builder: (context, setDialogState) {
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildDialogHeader(
                            dialogContext,
                          ),
                          const SizedBox(height: 12),

                          // حالة الترخيص تظهر مباشرة أسفل عنوان إدارة الاشتراك
                          // وقبل اسم العميل، بمحاذاة RTL ثابتة: الأيقونة يمين النص.
                          _buildLicenseStatusBox(),
                          const SizedBox(height: 14),

                          _buildDialogLabel('اسم العميل'),
                          const SizedBox(height: 6),
                          _buildReadOnlyField(
                            value: customerController.text,
                            hint: 'غير متوفر',
                            icon: LucideIcons.userRound,
                          ),
                          const SizedBox(height: 12),

                          _buildDialogLabel('مفتاح التفعيل'),
                          const SizedBox(height: 6),
                          _buildReadOnlyField(
                            value: activationKeyController.text,
                            hint: 'غير متوفر',
                            icon: LucideIcons.keyRound,
                          ),
                          const SizedBox(height: 12),

                          _buildDialogLabel('تاريخ الانتهاء'),
                          const SizedBox(height: 6),
                          _buildReadOnlyField(
                            value: expiryController.text,
                            hint: 'غير محدد',
                            icon: LucideIcons.calendarDays,
                          ),
                          const SizedBox(height: 12),

                          _buildInfoRow(
                            title: 'المدة المتبقية',
                            value: _remainingText(),
                            icon: LucideIcons.hourglass,
                            valueColor: _remainingColor,
                          ),
                          const SizedBox(height: 10),

                          _buildInfoRow(
                            title: 'الأجهزة المستخدمة',
                            value: usedDevices == 0
                                ? 'غير محدد'
                                : '$usedDevices جهاز',
                            icon: LucideIcons.monitorSmartphone,
                            valueColor: const Color(0xff475569),
                          ),
                          const SizedBox(height: 18),

                          _buildDialogLabel(
                            'تنبيهات باقتراب انتهاء الاشتراك',
                          ),
                          const SizedBox(height: 9),

                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.start,
                            children: [3, 7, 14, 30].map((days) {
                              final selected =
                                  selectedAlertDays == days;

                              return ChoiceChip(
                                label: Text('$days يوم'),
                                selected: selected,
                                onSelected: (_) {
                                  setDialogState(() {
                                    selectedAlertDays =
                                        selected ? null : days;
                                  });
                                },
                                selectedColor:
                                    const Color(0xffDBEAFE),
                                backgroundColor:
                                    const Color(0xffF8FAFC),
                                side: BorderSide(
                                  color: selected
                                      ? const Color(0xff93C5FD)
                                      : const Color(0xffE2E8F0),
                                ),
                                labelStyle: TextStyle(
                                  color: selected
                                      ? _blue
                                      : const Color(0xff475569),
                                  fontWeight: FontWeight.w700,
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 18),

                          _buildDeactivateButton(
                            dialogSetState: setDialogState,
                          ),
                          const SizedBox(height: 10),

                          ElevatedButton(
                            onPressed: selectedAlertDays == null
                                ? null
                                : () async {
                                    await _saveAlertSettings();
                                    if (dialogContext.mounted) {
                                      Navigator.pop(dialogContext);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _blue,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xffE2E8F0),
                              disabledForegroundColor: const Color(0xff94A3B8),
                              elevation: 0,
                              minimumSize:
                                  const Size.fromHeight(45),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(13),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  LucideIcons.save,
                                  size: 18,
                                ),
                                SizedBox(width: 7),
                                Text(
                                  'حفظ إعدادات التنبيه',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 9),

                          const Text(
                            'بيانات العميل ومفتاح التفعيل وتاريخ الانتهاء والأجهزة للعرض فقط.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: Color(0xff94A3B8),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );

    if (mounted) {
      _updateRemainingDays();
      setState(() {});
    }
  }

  Widget _buildDialogHeader(BuildContext dialogContext) {
    return Row(
      children: [
        IconButton(
          tooltip: 'إغلاق',
          onPressed: () => Navigator.pop(dialogContext),
          icon: const Icon(
            LucideIcons.x,
            size: 21,
            color: Color(0xff475569),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'إدارة الاشتراك',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Color(0xff111827),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'بيانات الاشتراك الحالية لهذا الجهاز',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xff64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: const Color(0xffEFF6FF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  LucideIcons.settings2,
                  color: _blue,
                  size: 21,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField({
    required String value,
    required String hint,
    required IconData icon,
  }) {
    final shown = value.trim().isEmpty ? hint : value.trim();

    return Container(
      constraints: const BoxConstraints(minHeight: 49),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xffE2E8F0),
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: Center(
              child: Icon(
                icon,
                color: _blue,
                size: 19,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              shown,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: value.trim().isEmpty
                    ? const Color(0xff94A3B8)
                    : const Color(0xff334155),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String title,
    required String value,
    required IconData icon,
    required Color valueColor,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: Center(
              child: Icon(
                icon,
                size: 19,
                color: _blue,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xff374151),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseStatusBox() {
    final active = _isLicenseActive;

    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          Icon(
            active ? LucideIcons.badgeCheck : LucideIcons.badgeX,
            color: active ? _green : _red,
            size: 19,
          ),
          const SizedBox(width: 7),
          Text(
            active ? 'الترخيص مفعل' : 'الترخيص غير مفعل',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: active ? _green : _red,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeactivateButton({StateSetter? dialogSetState}) {
    final active = _isLicenseActive;

    return SizedBox(
      height: 45,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: active
            ? () => _deactivateThisDevice(dialogSetState: dialogSetState)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _red,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xffF1F5F9),
          disabledForegroundColor: const Color(0xff94A3B8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.powerOff,
              size: 18,
              color: active ? Colors.white : const Color(0xff94A3B8),
            ),
            const SizedBox(width: 8),
            Text(
              'إلغاء تفعيل هذا الجهاز',
              style: TextStyle(
                color: active ? Colors.white : const Color(0xff94A3B8),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogLabel(String text) {
    return Text(
      text,
      textAlign: TextAlign.right,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xff374151),
      ),
    );
  }
}
