import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SideMenu extends StatelessWidget {
  final Function(String) onNavigate;
  final bool isAdmin;
  final VoidCallback? onAdminLogout;

  const SideMenu({
    super.key,
    required this.onNavigate,
    this.isAdmin = false,
    this.onAdminLogout,
  });

  @override
  Widget build(BuildContext context) {
    // تحديد عرض القائمة ليكون على قدر محتوى النصوص تماماً (بين 240 إلى 270 بكسل)
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = (screenWidth * 0.60).clamp(240.0, 270.0);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Drawer(
        width: drawerWidth, // العرض المضبوط
        backgroundColor: Colors.white,
        elevation: 8,
        child: SafeArea(
          child: Column(
            children: [
              // ============================================================
              // رأس القائمة (Header)
              // ============================================================
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0xffF3F4F6),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // زر الإغلاق - يسار
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        LucideIcons.x,
                        size: 20,
                        color: Color(0xff6B7280),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),

                    // العنوان
                    const Text(
                      "القائمة الجانبية",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff111827),
                      ),
                    ),
                    
                    const SizedBox(width: 20), // لموازنة العنوان في المنتصف
                  ],
                ),
              ),

              // ============================================================
              // عناصر القائمة
              // ============================================================
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  children: [
                    menuItem(
                      context: context,
                      icon: LucideIcons.settings,
                      title: "الإعدادات",
                      subtitle: "الإعدادات العامة",
                      page: "settings",
                    ),
                    menuItem(
                      context: context,
                      icon: LucideIcons.database,
                      title: "النسخ الاحتياطي",
                      subtitle: "تصدير واستعادة البيانات",
                      page: "backup",
                    ),
                    menuItem(
                      context: context,
                      icon: LucideIcons.keyRound,
                      title: "التفعيل",
                      subtitle: "إدارة الاشتراك والأجهزة",
                      page: "activation",
                    ),
                    menuItem(
                      context: context,
                      icon: LucideIcons.shield,
                      title: "قفل التطبيق",
                      subtitle: "رقم سري وبصمة الوجه",
                      page: "lock",
                    ),
                    menuItem(
                      context: context,
                      icon: LucideIcons.bell,
                      title: "ضبط الإشعارات",
                      subtitle: "مواعيد وتنبيهات النظام",
                      page: "notification_settings",
                    ),
                    menuItem(
                      context: context,
                      icon: LucideIcons.clipboardList,
                      title: "المهام",
                      subtitle: "إدارة المهام والمتابعات",
                      page: "tasks",
                    ),
                    menuItem(
                      context: context,
                      icon: LucideIcons.info,
                      title: "نبذة عن التطبيق",
                      subtitle: "معلومات النظام والإصدار",
                      page: "about",
                    ),
                    if (isAdmin)
                      menuItem(
                        context: context,
                        icon: LucideIcons.keyRound,
                        title: "إدارة الاشتراكات",
                        subtitle: "المفاتيح والعملاء والتفعيل",
                        page: "license_manager",
                      ),
                  ],
                ),
              ),
              if (isAdmin)
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xffE5E7EB)),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onAdminLogout,
                      icon: const Icon(LucideIcons.logOut, size: 18, color: Colors.white),
                      label: const Text(
                        'تسجيل الخروج من الإدارة',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffD92D20),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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

  // =========================================================================
  // عنصر القائمة
  // =========================================================================
  Widget menuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String page,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onNavigate(page);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // الأيقونة - على اليمين
              Icon(
                icon,
                size: 22,
                color: const Color(0xff2563EB),
              ),
              const SizedBox(width: 10),

              // النصوص - تأخذ المساحة المتبقية بدون زيادات
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff1F2937),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xff9CA3AF),
                      ),
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
}