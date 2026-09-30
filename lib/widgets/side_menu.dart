import 'package:flutter/material.dart';
import '../screens/settings_screen.dart'; // قم بتعديل مسار الملف حسب مشروعك

class SideMenu extends StatelessWidget {
  final Function(String)? onNavigate;

  const SideMenu({
    super.key,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Drawer(
        width: MediaQuery.of(context).size.width * 0.7,
        backgroundColor: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              // رأس القائمة الجانبية
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "القائمة الجانبية",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // عناصر القائمة الجانبية
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  children: [
                    _buildMenuItem(
                      context: context,
                      icon: Icons.settings_outlined,
                      title: "الإعدادات العامة",
                      subtitle: "إعدادات اسم الشركة والنظام",
                      pageKey: "settings",
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.storage_outlined,
                      title: "النسخ الاحتياطي",
                      subtitle: "تصدير واستعادة البيانات عبر Firebase",
                      pageKey: "backup",
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.key_outlined,
                      title: "التفعيل والاشتراك",
                      subtitle: "إدارة الاشتراك والأجهزة",
                      pageKey: "activation",
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.shield_outlined,
                      title: "قفل التطبيق",
                      subtitle: "رقم سري وبصمة الوجه",
                      pageKey: "lock",
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.notifications_none,
                      title: "ضبط الإشعارات",
                      subtitle: "مواعيد وفحص تنبيهات الهويات",
                      pageKey: "alerts",
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.assignment_outlined,
                      title: "المهام",
                      subtitle: "إدارة المهام والمتابعات",
                      pageKey: "tasks",
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.info_outline,
                      title: "نبذة عن التطبيق",
                      subtitle: "معلومات النظام والإصدار",
                      pageKey: "about",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String pageKey,
  }) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(icon, color: const Color(0xff2563EB), size: 22),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11, color: Colors.grey),
        maxLines: 1,
      ),
      onTap: () {
        Navigator.pop(context); // إغلاق الـ Drawer أولاً

        if (onNavigate != null) {
          // إذا كانت الشاشة الحالية تستمع للتغيير الداخلي
          onNavigate!(pageKey);
        } else {
          // فتح صفحة الإعدادات وعرض الصفحة المحددة مباشرة
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SettingsScreen(selectedPage: pageKey),
            ),
          );
        }
      },
    );
  }
}