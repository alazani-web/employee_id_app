import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final String selectedPage;

  const SettingsScreen({
    super.key,
    this.selectedPage = "settings", // قيمة افتراضية لتفادي خطأ missing_required_argument
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String currentPage;
  bool isLockEnabled = true;

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
  Widget build(BuildContext context) {
    // تم حذف Scaffold و AppBar لمنع تكرار الهيدر العلوي
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // عنوان الصفحة الرئيسي
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "إعدادات النظام",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff1F2937),
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.settings_outlined, color: Color(0xff4B5563), size: 24),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // عرض الواجهة بحسب الصفحة المختارة
          _buildSelectedContent(),
        ],
      ),
    );
  }

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

  // 1. واجهة الإعدادات العامة
  Widget _buildGeneralSettingsView() {
    return _buildCardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("الإعدادات العامة", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text("اسم الشركة", style: TextStyle(fontSize: 14, color: Color(0xff374151))),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: "شركتي",
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          _buildPrimaryButton("حفظ", Icons.save_outlined, const Color(0xff2563EB)),
        ],
      ),
    );
  }

  // 2. واجهة النسخ الاحتياطي (مطابقة تماماً للصورة)
  Widget _buildBackupView() {
    return _buildCardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            "النسخ الاحتياطي والاستعادة عبر Firebase",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "استخدم Firebase حصرياً للاحتفاظ بنسخة احتياطية سحابية مرتبطة بمفتاح اشتراكك واستعادتها متى شئت.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xff6B7280), height: 1.4),
          ),
          const SizedBox(height: 20),
          _buildActionButton("تصوير نسخة محلية", Icons.download, const Color(0xff2563EB)),
          const SizedBox(height: 12),
          _buildActionButton("استيراد نسخة محلية", Icons.upload, const Color(0xff111827)),
          const SizedBox(height: 12),
          _buildActionButton("رفع نسخة سحابية (Firebase)", Icons.cloud_upload_outlined, const Color(0xff16A34A)),
          const SizedBox(height: 12),
          _buildActionButton("استعادة سحابية (Firebase)", Icons.cloud_download_outlined, const Color(0xff9333EA)),
        ],
      ),
    );
  }

  // 3. واجهة التفعيل والاشتراك
  Widget _buildActivationView() {
    return _buildCardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("التفعيل والاشتراك (Firebase)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Icon(Icons.key, color: Color(0xff2563EB)),
            ],
          ),
          const SizedBox(height: 6),
          const Text("التطبيق مفعل بنجاح.", style: TextStyle(fontSize: 13, color: Color(0xff6B7280))),
          const SizedBox(height: 20),
          _buildPrimaryButton("إدارة الاشتراك", Icons.check_circle_outline, const Color(0xff16A34A)),
        ],
      ),
    );
  }

  // 4. واجهة قفل التطبيق
  Widget _buildLockView() {
    return _buildCardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("قفل التطبيق", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Icon(Icons.shield_outlined, color: Color(0xff2563EB)),
            ],
          ),
          const SizedBox(height: 4),
          const Text("حماية التطبيق برقم سري أو بصمة.", style: TextStyle(fontSize: 13, color: Color(0xff6B7280))),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("تفعيل قفل التطبيق", style: TextStyle(fontWeight: FontWeight.w600)),
              Checkbox(
                value: isLockEnabled,
                onChanged: (val) => setState(() => isLockEnabled = val ?? false),
              ),
            ],
          ),
          if (isLockEnabled) ...[
            const SizedBox(height: 16),
            const Text("الرقم السري", style: TextStyle(fontSize: 14)),
            const SizedBox(height: 6),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                hintText: "••••",
                suffixIcon: const Icon(Icons.remove_red_eye_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            const Text("تأكيد الرقم", style: TextStyle(fontSize: 14)),
            const SizedBox(height: 6),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                hintText: "تأكيد الرقم",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            _buildPrimaryButton("حفظ الإعدادات", Icons.save_outlined, const Color(0xff2563EB)),
          ]
        ],
      ),
    );
  }

  // 5. ضبط الإشعارات
  Widget _buildAlertsView() {
    return _buildCardWrapper(
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("ضبط الإشعارات", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Text("مواعيد وفحص تنبيهات الهويات والنظام.", style: TextStyle(color: Color(0xff6B7280))),
        ],
      ),
    );
  }

  // 6. المهام
  Widget _buildTasksView() {
    return _buildCardWrapper(
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("إدارة المهام", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Text("قائمة متابعة المهام والملاحظات.", style: TextStyle(color: Color(0xff6B7280))),
        ],
      ),
    );
  }

  // 7. نبذة عن التطبيق
  Widget _buildAboutView() {
    return _buildCardWrapper(
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("نبذة عن التطبيق", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Text("نظام إدارة الهويات - الإصدار 1.0.0", style: TextStyle(color: Color(0xff6B7280))),
        ],
      ),
    );
  }

  // ودجت مساعد لإطار الكارت
  Widget _buildCardWrapper({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffE5E7EB)),
      ),
      child: child,
    );
  }

  Widget _buildPrimaryButton(String title, IconData icon, Color color) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(icon, color: Colors.white),
        label: Text(title, style: const TextStyle(fontSize: 16, color: Colors.white)),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(icon, color: Colors.white, size: 20),
        label: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}