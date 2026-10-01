import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final String selectedPage;

  const SettingsScreen({
    super.key,
    this.selectedPage = "settings",
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

  bool isLockEnabled = true;
  bool faceIdEnabled = false;

  int notificationDays = 30;

  TimeOfDay notificationTime = const TimeOfDay(
    hour: 9,
    minute: 0,
  );

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
            12,
            16,
            100,
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
    IconData icon = Icons.settings_outlined;

    switch (currentPage) {
      case "backup":
        title = "النسخ الاحتياطي";
        icon = Icons.storage_outlined;
        break;

      case "activation":
        title = "التفعيل";
        icon = Icons.key_outlined;
        break;

      case "lock":
        title = "قفل التطبيق";
        icon = Icons.shield_outlined;
        break;

      case "alerts":
        title = "ضبط الإشعارات";
        icon = Icons.notifications_none;
        break;

      case "tasks":
        title = "المهام";
        icon = Icons.assignment_outlined;
        break;

      case "about":
        title = "نبذة عن التطبيق";
        icon = Icons.info_outline;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
        return _buildBackupView();

      case "activation":
        return _buildActivationView();

      case "lock":
        return _buildLockView();

      case "alerts":
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
            icon: Icons.save_outlined,
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

  Widget _buildBackupView() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle(
            "النسخ الاحتياطي والاستعادة",
            Icons.storage_outlined,
          ),

          const SizedBox(height: 8),

          const Text(
            "إدارة النسخ الاحتياطية واستعادة بيانات النظام.",
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xff7A8495),
            ),
          ),

          const SizedBox(height: 18),

          _buildActionButton(
            title: "إنشاء نسخة احتياطية",
            icon: Icons.download_outlined,
            color: const Color(0xff2864D7),
            onPressed: () {
              _showMessage("تم طلب إنشاء نسخة احتياطية");
            },
          ),

          const SizedBox(height: 10),

          _buildActionButton(
            title: "استعادة نسخة احتياطية",
            icon: Icons.upload_outlined,
            color: const Color(0xff374151),
            onPressed: () {
              _showMessage("تم اختيار استعادة النسخة الاحتياطية");
            },
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xffF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "آخر نسخة احتياطية",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  "لا توجد نسخة محفوظة",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xff7A8495),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
            Icons.key_outlined,
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
                  Icons.verified_outlined,
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
            icon: Icons.manage_accounts_outlined,
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
            Icons.shield_outlined,
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
            onChanged: (value) {
              setState(() {
                isLockEnabled = value;
              });
            },
          ),

          if (isLockEnabled) ...[
            const SizedBox(height: 12),

            _buildSwitchRow(
              title: "استخدام بصمة الوجه",
              value: faceIdEnabled,
              onChanged: (value) {
                setState(() {
                  faceIdEnabled = value;
                });
              },
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
              icon: Icons.save_outlined,
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
            Icons.notifications_none,
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
              trailing: TextButton(
                onPressed: _selectNotificationTime,
                child: Text(
                  notificationTime.format(context),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xff2864D7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            _buildBlueButton(
              title: "حفظ إعدادات الإشعارات",
              icon: Icons.save_outlined,
              onPressed: _saveNotificationSettings,
            ),
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
            Icons.assignment_outlined,
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
            icon: Icons.task_alt_outlined,
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
            Icons.info_outline,
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
  }) {
    return Row(
      children: [
        Switch(
          value: value,
          activeColor: const Color(0xff2864D7),
          onChanged: onChanged,
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
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: notificationTime,
    );

    if (picked == null) return;

    setState(() {
      notificationTime = picked;
    });
  }

  void _saveNotificationSettings() {
    _showMessage(
      "تم حفظ إعدادات الإشعارات",
    );
  }

  void _saveLockSettings() {
    if (isLockEnabled) {
      if (pinController.text.isEmpty) {
        _showMessage("أدخل الرقم السري أولاً");
        return;
      }

      if (pinController.text != confirmPinController.text) {
        _showMessage("الرقم السري غير متطابق");
        return;
      }
    }

    _showMessage("تم حفظ إعدادات القفل");
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.right,
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}