import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'activation_screen.dart';
import 'backup_screen.dart';
import '../widgets/top_message.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  final String selectedPage;
  final VoidCallback? onBack;

  // يتم استدعاؤه فور تغيير حالة قفل التطبيق
  // حتى تتحدث App مباشرةً بدون إعادة تشغيل.
  final ValueChanged<bool>? onLockStateChanged;

  const SettingsScreen({
    super.key,
    this.selectedPage = "settings",
    this.onBack,
    this.onLockStateChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String currentPage;

  // =========================
  // الإعدادات
  // =========================

  bool notificationsEnabled = true;
  bool identityNotifications = true;
  bool documentNotifications = true;
  bool visitNotifications = true;
  bool taskNotifications = true;

  bool isLockEnabled = false;
  bool faceIdEnabled = false;

  int notificationDays = 30;

  TimeOfDay? notificationTime;

  String? _notificationSaveMessage;

  // مفتاح لتحديد مكان نافذة اختيار الوقت رأسيًا بالنسبة لخانة الوقت.
  final GlobalKey _notificationTimeKey = GlobalKey();

  final TextEditingController companyController =
      TextEditingController(text: "شركتي");

  final TextEditingController pinController =
      TextEditingController();

  final TextEditingController confirmPinController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    currentPage = widget.selectedPage;
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      isLockEnabled = prefs.getBool('app_lock_enabled') ?? false;
      faceIdEnabled = prefs.getBool('app_lock_biometric') ?? false;
      notificationsEnabled =
          prefs.getBool('notifications_enabled') ?? true;
      identityNotifications =
          prefs.getBool('identity_notifications') ?? true;
      documentNotifications =
          prefs.getBool('document_notifications') ?? true;
      visitNotifications =
          prefs.getBool('visit_notifications') ?? true;
      taskNotifications =
          prefs.getBool('task_notifications') ?? true;
    });
  }

  @override
  void didUpdateWidget(covariant SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedPage != widget.selectedPage) {
      setState(() {
        currentPage = widget.selectedPage;
      });
    }
  }

  @override
  void dispose() {
    companyController.dispose();
    pinController.dispose();
    confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        color: const Color(0xffF7F9FC),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            32,
          ),
          child: Column(
            children: [
              _buildPageHeader(),
              const SizedBox(height: 14),
              _buildSelectedContent(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // عنوان الصفحة
  // ============================================================

  Widget _buildPageHeader() {
    String title = "إعدادات النظام";
    IconData icon = LucideIcons.settings;

    switch (currentPage) {
      case "backup":
        title = "النسخ الاحتياطي";
        icon = LucideIcons.database;
        break;

      case "activation":
        title = "التفعيل";
        icon = LucideIcons.keyRound;
        break;

      case "lock":
        title = "قفل التطبيق";
        icon = LucideIcons.shieldCheck;
        break;

      case "alerts":
      case "notification_settings":
        title = "ضبط الإشعارات";
        icon = LucideIcons.bell;
        break;

      case "tasks":
        title = "المهام";
        icon = LucideIcons.clipboardList;
        break;

      case "about":
        title = "نبذة عن التطبيق";
        icon = LucideIcons.info;
        break;
    }

    return Padding(
  padding: const EdgeInsets.symmetric(vertical: 6),
  child: Row(
    children: [
      if (widget.onBack != null)
        IconButton(
          onPressed: widget.onBack,
          tooltip: "رجوع",
          icon: const Icon(
            LucideIcons.arrowRight,
            size: 24,
            color: Color(0xff1F2937),
          ),
        )
      else
        const SizedBox(width: 48),

      Expanded(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: Color(0xff1F2937),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              icon,
              size: 23,
              color: const Color(0xff2864D7),
            ),
          ],
        ),
      ),

      const SizedBox(width: 48),
    ],
  ),
);
  }

  // ============================================================
  // تحديد الصفحة
  // ============================================================

  Widget _buildSelectedContent() {
    switch (currentPage) {
      case "settings":
        return _buildGeneralSettingsView();

      case "backup":
        return BackupScreen(onBack: widget.onBack);

      case "activation":
        return const ActivationScreen();

      case "lock":
        return _buildLockView();

      case "alerts":
      case "notification_settings":
        return _buildAlertsView();

      case "tasks":
        return _buildTasksView();

      case "about":
        return _buildAboutView();

      default:
        return _buildGeneralSettingsView();
    }
  }

  // ============================================================
  // 1 - الإعدادات العامة
  // ============================================================

  Widget _buildGeneralSettingsView() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "الإعدادات العامة",
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xff111827),
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            "إدارة الإعدادات الأساسية للنظام",
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xff7A8495),
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            "اسم الشركة",
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xff374151),
            ),
          ),

          const SizedBox(height: 7),

          TextField(
            controller: companyController,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintText: "اسم الشركة",
              filled: true,
              fillColor: const Color(0xffF8FAFC),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xffE5E7EB),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xffE5E7EB),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xff2864D7),
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          _buildBlueButton(
            title: "حفظ الإعدادات",
            icon: LucideIcons.save,
            onPressed: () {
              _showMessage("تم حفظ الإعدادات");
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 2 - النسخ الاحتياطي
  // ============================================================

  // ============================================================
  // 3 - التفعيل
  // ============================================================

  Widget _buildActivationView() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle(
            "التفعيل والاشتراك",
            LucideIcons.keyRound,
          ),

          const SizedBox(height: 8),

          const Text(
            "إدارة حالة التفعيل والاشتراك والأجهزة المرتبطة.",
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xff7A8495),
            ),
          ),

          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xffEFFAF1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.badgeCheck,
                  color: Color(0xff3D9850),
                  size: 25,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "حالة الترخيص",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "مفتاح التفعيل: مفعل",
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xff3D9850),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            "الأيام المتبقية: 12512 يوم",
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xff7A8495),
            ),
          ),

          const SizedBox(height: 18),

          _buildBlueButton(
            title: "إدارة الاشتراك",
            icon: LucideIcons.userCog,
            onPressed: () {
              _showMessage("إدارة الاشتراك");
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 4 - قفل التطبيق
  // ============================================================

  Widget _buildLockView() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle(
            "قفل التطبيق",
            LucideIcons.shield,
          ),

          const SizedBox(height: 7),

          const Text(
            "حماية التطبيق برقم سري أو باستخدام المصادقة.",
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xff7A8495),
            ),
          ),

          const SizedBox(height: 14),

          _buildSwitchRow(
            title: "تفعيل قفل التطبيق",
            value: isLockEnabled,
            onChanged: (value) async {
              setState(() {
                isLockEnabled = value;
              });

              if (!value) {
                final prefs = await SharedPreferences.getInstance();

                // الإيقاف الفوري للقفل.
                await prefs.setBool('app_lock_enabled', false);
                await prefs.setBool('app_lock_biometric', false);
                await prefs.remove('app_lock_pin');

                if (!mounted) return;

                widget.onLockStateChanged?.call(false);
                _showMessage("تم إيقاف قفل التطبيق");
              }
            },
          ),

          if (isLockEnabled) ...[
            const SizedBox(height: 12),

            _buildSwitchRow(
              title: "استخدام بصمة الوجه (قريبًا)",
              value: false,
              enabled: false,
              onChanged: (_) {},
            ),

            const SizedBox(height: 18),

            const Text(
              "الرقم السري",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 7),

            TextField(
              controller: pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: "أدخل الرقم السري",
                filled: true,
                fillColor: const Color(0xffF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xffE5E7EB),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              "تأكيد الرقم السري",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 7),

            TextField(
              controller: confirmPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: "أعد إدخال الرقم السري",
                filled: true,
                fillColor: const Color(0xffF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xffE5E7EB),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            _buildBlueButton(
              title: "حفظ إعدادات القفل",
              icon: LucideIcons.save,
              onPressed: _saveLockSettings,
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // 5 - ضبط الإشعارات
  // ============================================================

  Widget _buildAlertsView() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle(
            "ضبط الإشعارات",
            LucideIcons.bell,
          ),

          const SizedBox(height: 7),

          const Text(
            "مواعيد وفحص تنبيهات الهويات والنظام.",
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xff7A8495),
            ),
          ),

          const SizedBox(height: 16),

          _buildSwitchRow(
            title: "تفعيل الإشعارات",
            value: notificationsEnabled,
            onChanged: (value) {
              setState(() {
                notificationsEnabled = value;
              });
            },
          ),

          if (notificationsEnabled) ...[
            const Divider(height: 22),

            _buildSwitchRow(
              title: "تنبيهات انتهاء الهويات",
              value: identityNotifications,
              onChanged: (value) {
                setState(() {
                  identityNotifications = value;
                });
              },
            ),

            _buildSwitchRow(
              title: "تنبيهات انتهاء الوثائق",
              value: documentNotifications,
              onChanged: (value) {
                setState(() {
                  documentNotifications = value;
                });
              },
            ),

            _buildSwitchRow(
              title: "تنبيهات الزيارات",
              value: visitNotifications,
              onChanged: (value) {
                setState(() {
                  visitNotifications = value;
                });
              },
            ),

            _buildSwitchRow(
              title: "تنبيهات المهام",
              value: taskNotifications,
              onChanged: (value) {
                setState(() {
                  taskNotifications = value;
                });
              },
            ),

            const SizedBox(height: 12),

            _buildSettingBox(
              title: "التنبيه قبل انتهاء الهوية",
              trailing: DropdownButton<int>(
                value: notificationDays,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(
                    value: 7,
                    child: Text("7 أيام"),
                  ),
                  DropdownMenuItem(
                    value: 15,
                    child: Text("15 يوم"),
                  ),
                  DropdownMenuItem(
                    value: 30,
                    child: Text("30 يوم"),
                  ),
                  DropdownMenuItem(
                    value: 60,
                    child: Text("60 يوم"),
                  ),
                  DropdownMenuItem(
                    value: 90,
                    child: Text("90 يوم"),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    notificationDays = value;
                  });
                },
              ),
            ),

            const SizedBox(height: 10),

            _buildSettingBox(
              title: "وقت الفحص اليومي",
              trailing: KeyedSubtree(
                key: _notificationTimeKey,
                child: TextButton(
                  onPressed: _selectNotificationTime,
                  child: Text(
                    notificationTime == null
                        ? 'اختر الوقت'
                        : notificationTime!.format(context),
                    style: TextStyle(
                      fontSize: 13,
                      color: notificationTime == null
                          ? const Color(0xff64748B)
                          : const Color(0xff2864D7),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            _buildBlueButton(
              title: "حفظ إعدادات الإشعارات",
              icon: LucideIcons.save,
              onPressed: _saveNotificationSettings,
            ),

            const SizedBox(height: 9),

            SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () async {
                  try {
                    final count = await NotificationService.instance
                        .showCurrentIdentityExpiryAlerts(
                      withinDays: notificationDays,
                    );

                    if (!mounted) return;

                    if (count > 0) {
                      TopMessage.show(
                        context,
                        "تم عرض $count من الهويات القريبة من الانتهاء",
                      );
                    } else {
                      TopMessage.show(
                        context,
                        "لا توجد هويات تنتهي خلال $notificationDays يومًا",
                      );
                    }
                  } catch (e) {
                    if (!mounted) return;
                    TopMessage.show(
                      context,
                      "تعذر فحص تنبيهات الهويات",
                      type: TopMessageType.error,
                    );
                  }
                },
                icon: const Icon(
                  Icons.notifications_active_outlined,
                  size: 18,
                ),
                label: const Text(
                  "اختبار الإشعار الآن",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xff2864D7),
                  side: const BorderSide(
                    color: Color(0xffC9D8F5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            if (_notificationSaveMessage != null) ...[
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Container(
                  key: ValueKey(_notificationSaveMessage),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffECFDF5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xffA7F3D0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        LucideIcons.checkCircle,
                        size: 18,
                        color: Color(0xff059669),
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          _notificationSaveMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xff047857),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ============================================================
  // 6 - المهام
  // ============================================================

  Widget _buildTasksView() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle(
            "إدارة المهام",
            LucideIcons.clipboardList,
          ),

          const SizedBox(height: 7),

          const Text(
            "قائمة متابعة المهام والملاحظات.",
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xff7A8495),
            ),
          ),

          const SizedBox(height: 18),

          _buildEmptyState(
            icon: LucideIcons.listChecks,
            title: "لا توجد مهام حالياً",
            subtitle: "ستظهر المهام والمتابعات هنا.",
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 7 - نبذة عن التطبيق
  // ============================================================

  Widget _buildAboutView() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle(
            "نبذة عن التطبيق",
            LucideIcons.info,
          ),

          const SizedBox(height: 16),

          _buildAboutRow(
            "اسم التطبيق",
            "نظام إدارة الهويات",
          ),

          _buildAboutRow(
            "الإصدار",
            "1.0.0",
          ),

          _buildAboutRow(
            "حالة النظام",
            "يعمل بشكل طبيعي",
          ),

          _buildAboutRow(
            "الترخيص",
            "مفعل",
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Widgets
  // ============================================================

  Widget _buildCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xffE5E7EB),
        ),
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(
    String title,
    IconData icon,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xff111827),
          ),
        ),
        const SizedBox(width: 7),
        Icon(
          icon,
          size: 23,
          color: Color(0xff2864D7),
        ),
      ],
    );
  }

  Widget _buildSwitchRow({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return Row(
      children: [
        Switch(
          value: value,
          activeColor: const Color(0xff2864D7),
          onChanged: enabled ? onChanged : null,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xff374151),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingBox({
    required String title,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xffE5E7EB),
        ),
      ),
      child: Row(
        children: [
          trailing,
          const Spacer(),
          Text(
            title,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xff374151),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlueButton({
    required String title,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 43,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff2864D7),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(
          icon,
          size: 19,
          color: Colors.white,
        ),
        label: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 43,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(
          icon,
          size: 19,
          color: Colors.white,
        ),
        label: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 25,
        horizontal: 15,
      ),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 38,
            color: const Color(0xff2864D7),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xff7A8495),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutRow(
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 9,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xff6B7280),
              ),
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xff374151),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // الوظائف
  // ============================================================

  Future<void> _selectNotificationTime() async {
    final hourController = TextEditingController();
    final minuteController = TextEditingController();
    final hourFocusNode = FocusNode();
    final minuteFocusNode = FocusNode();

    if (notificationTime != null) {
      final existingHour = notificationTime!.hourOfPeriod == 0
          ? 12
          : notificationTime!.hourOfPeriod;

      hourController.text = existingHour.toString().padLeft(2, '0');
      minuteController.text =
          notificationTime!.minute.toString().padLeft(2, '0');
    }

    bool selectedPm = notificationTime?.period == DayPeriod.pm;

    final screenSize = MediaQuery.of(context).size;
    final popupWidth = (screenSize.width - 32).clamp(260.0, 360.0);
    const popupHeight = 224.0;
    final double top = ((screenSize.height - popupHeight) / 2)
        .clamp(12.0, screenSize.height - popupHeight - 12.0);
    final double left = ((screenSize.width - popupWidth) / 2)
        .clamp(12.0, screenSize.width - popupWidth - 12.0);

    try {
      // مهم: لا نعدّل State الصفحة من داخل الـ Dialog.
      // الـ Dialog يرجع TimeOfDay أولاً، وبعد إغلاقه فقط نحدّث الصفحة.
      final selectedTime = await showGeneralDialog<TimeOfDay>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'اختيار الوقت',
        barrierColor: Colors.black38,
        transitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Stack(
              children: [
                Positioned(
                  top: top,
                  left: left,
                  width: popupWidth.toDouble(),
                  child: Material(
                    color: Colors.transparent,
                    child: StatefulBuilder(
                      builder: (ctx, setModalState) {
                        String? errorMessage;

                        return StatefulBuilder(
                          builder: (ctx, setErrorState) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (ctx.mounted && !hourFocusNode.hasFocus &&
                                  !minuteFocusNode.hasFocus) {
                                hourFocusNode.requestFocus();
                              }
                            });

                            void focusMinutes() {
                              if (ctx.mounted) {
                                minuteFocusNode.requestFocus();
                              }
                            }

                            return Container(
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                10,
                                12,
                                12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0xffE2E8F0),
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x22000000),
                                    blurRadius: 18,
                                    offset: Offset(0, 7),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        LucideIcons.clock,
                                        color: Color(0xff2563EB),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      const Expanded(
                                        child: Text(
                                          'اختيار الوقت',
                                          style: TextStyle(
                                            color: Color(0xff111827),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap: () => Navigator.pop(dialogContext),
                                        child: const Padding(
                                          padding: EdgeInsets.all(3),
                                          child: Icon(
                                            LucideIcons.x,
                                            color: Color(0xff475569),
                                            size: 19,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _timeInputField(
                                          controller: hourController,
                                          focusNode: hourFocusNode,
                                          label: 'الساعة',
                                          hint: '00',
                                          maxLength: 2,
                                          compact: true,
                                          textInputAction: TextInputAction.next,
                                          onChanged: (value) {
                                            if (value.length >= 2) {
                                              focusMinutes();
                                            }
                                          },
                                          onSubmitted: (_) => focusMinutes(),
                                          onEditingComplete: focusMinutes,
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.only(
                                          left: 5,
                                          right: 5,
                                          top: 9,
                                        ),
                                        child: Text(
                                          ':',
                                          style: TextStyle(
                                            fontSize: 21,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xff111827),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: _timeInputField(
                                          controller: minuteController,
                                          focusNode: minuteFocusNode,
                                          label: 'الدقيقة',
                                          hint: '00',
                                          maxLength: 2,
                                          compact: true,
                                          textInputAction: TextInputAction.done,
                                        ),
                                      ),
                                      const SizedBox(width: 7),
                                      _periodSelector(
                                        selectedPm,
                                        (value) {
                                          setModalState(() {
                                            selectedPm = value;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  if (errorMessage != null) ...[
                                    const SizedBox(height: 5),
                                    Text(
                                      errorMessage!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xffDC2626),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 11),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () =>
                                              Navigator.pop(dialogContext),
                                          style: OutlinedButton.styleFrom(
                                            minimumSize:
                                                const Size.fromHeight(38),
                                            padding: EdgeInsets.zero,
                                            side: const BorderSide(
                                              color: Color(0xffE2E8F0),
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: const Text(
                                            'إلغاء',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xff374151),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            final hour = int.tryParse(
                                              hourController.text.trim(),
                                            );
                                            final minute = int.tryParse(
                                              minuteController.text.trim(),
                                            );

                                            if (hour == null ||
                                                hour < 1 ||
                                                hour > 12) {
                                              setErrorState(() {
                                                errorMessage =
                                                    'أدخل الساعة من 1 إلى 12';
                                              });
                                              hourFocusNode.requestFocus();
                                              return;
                                            }

                                            if (minute == null ||
                                                minute < 0 ||
                                                minute > 59) {
                                              setErrorState(() {
                                                errorMessage =
                                                    'أدخل الدقيقة من 00 إلى 59';
                                              });
                                              minuteFocusNode.requestFocus();
                                              return;
                                            }

                                            final normalizedHour = selectedPm
                                                ? (hour == 12 ? 12 : hour + 12)
                                                : (hour == 12 ? 0 : hour);

                                            final result = TimeOfDay(
                                              hour: normalizedHour,
                                              minute: minute,
                                            );

                                            // أغلق الـ Dialog أولاً وأرجع الوقت.
                                            // ممنوع استدعاء setState الخاص بالصفحة هنا.
                                            Navigator.pop(dialogContext, result);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xff2563EB),
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            minimumSize:
                                                const Size.fromHeight(38),
                                            padding: EdgeInsets.zero,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: const Text(
                                            'حسنًا',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(
                begin: 0.96,
                end: 1.0,
              ).animate(curved),
              alignment: Alignment.center,
              child: child,
            ),
          );
        },
      );

      // هنا فقط، بعد إغلاق نافذة الوقت، نحدّث State الصفحة.
      if (selectedTime != null && mounted) {
        setState(() {
          notificationTime = selectedTime;
        });
      }
    } finally {
      hourController.dispose();
      minuteController.dispose();
      hourFocusNode.dispose();
      minuteFocusNode.dispose();
    }
  }

  Widget _timeInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required int maxLength,
    bool compact = false,
    FocusNode? focusNode,
    TextInputAction? textInputAction,
    ValueChanged<String>? onChanged,
    VoidCallback? onEditingComplete,
    ValueChanged<String>? onSubmitted,
  }) {
    return Column(
      children: [
        SizedBox(
          height: compact ? 42 : 56,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            onEditingComplete: onEditingComplete,
            onSubmitted: onSubmitted,
            textInputAction: textInputAction,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: maxLength,
            decoration: InputDecoration(
              counterText: '',
              hintText: hint,
              hintStyle: TextStyle(
                color: const Color(0xffCBD5E1),
                fontSize: compact ? 18 : 22,
                fontWeight: FontWeight.w600,
              ),
              filled: true,
              fillColor: const Color(0xffF8FAFC),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 8,
                vertical: compact ? 3 : 7,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xffE2E8F0),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xffE2E8F0),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xff2563EB),
                  width: 1.5,
                ),
              ),
            ),
            style: TextStyle(
              fontSize: compact ? 18 : 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xff111827),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: const Color(0xff64748B),
            fontSize: compact ? 9 : 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _periodSelector(
    bool isPm,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      width: 48,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xffE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
              onTap: () => onChanged(false),
              child: Container(
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: !isPm
                      ? const Color(0xff2563EB)
                      : Colors.transparent,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10),
                  ),
                ),
                child: Text(
                  'ص',
                  style: TextStyle(
                    color: !isPm
                        ? Colors.white
                        : const Color(0xff111827),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          Container(
            height: 1,
            color: const Color(0xffE2E8F0),
          ),
          Expanded(
            child: InkWell(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(10),
              ),
              onTap: () => onChanged(true),
              child: Container(
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isPm
                      ? const Color(0xff2563EB)
                      : Colors.transparent,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(10),
                  ),
                ),
                child: Text(
                  'م',
                  style: TextStyle(
                    color: isPm
                        ? Colors.white
                        : const Color(0xff111827),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', notificationsEnabled);
    await prefs.setBool('identity_notifications', identityNotifications);
    await prefs.setBool('document_notifications', documentNotifications);
    await prefs.setBool('visit_notifications', visitNotifications);
    await prefs.setBool('task_notifications', taskNotifications);

    if (!notificationsEnabled) {
      await NotificationService.instance.cancelAll();
    } else {
      await NotificationService.instance.syncStoredData();
    }

    setState(() {
      _notificationSaveMessage = "تم حفظ إعدادات الإشعارات";
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      if (_notificationSaveMessage == "تم حفظ إعدادات الإشعارات") {
        setState(() {
          _notificationSaveMessage = null;
        });
      }
    });
  }

  Future<void> _saveLockSettings() async {
    final prefs = await SharedPreferences.getInstance();

    if (!isLockEnabled) {
      await prefs.setBool('app_lock_enabled', false);
      await prefs.remove('app_lock_pin');
      await prefs.setBool('app_lock_biometric', false);

      if (!mounted) return;

      widget.onLockStateChanged?.call(false);
      _showMessage("تم إيقاف قفل التطبيق");
      return;
    }

    final pin = pinController.text.trim();
    final confirm = confirmPinController.text.trim();

    if (pin.length < 4) {
      _showMessage(
        "الرقم السري يجب أن يتكون من 4 أرقام على الأقل",
        type: TopMessageType.error,
      );
      return;
    }

    if (pin != confirm) {
      _showMessage(
        "الرقم السري غير متطابق",
        type: TopMessageType.error,
      );
      return;
    }

    await prefs.setBool('app_lock_enabled', true);
    await prefs.setString('app_lock_pin', pin);
    await prefs.setBool('app_lock_biometric', faceIdEnabled);

    if (!mounted) return;

    // تحديث App مباشرةً بدون إعادة تشغيل التطبيق.
    widget.onLockStateChanged?.call(true);

    _showMessage("تم حفظ إعدادات القفل بنجاح");
  }

  void _showMessage(
    String message, {
    TopMessageType type = TopMessageType.success,
  }) {
    TopMessage.show(context, message, type: type);
  }
}