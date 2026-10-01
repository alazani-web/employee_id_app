import 'package:flutter/material.dart';
import '../screens/alerts_screen.dart';

class AppHeader extends StatelessWidget {
  final int alertCount;
  final VoidCallback? onMenuTap;

  const AppHeader({
    super.key,
    this.alertCount = 0,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white,

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          // =================================================
          // زر القائمة
          // =================================================

          IconButton(
            onPressed: onMenuTap,

            icon: const Icon(
              Icons.menu,
              size: 30,
              color: Color(0xff111827),
            ),
          ),

          // =================================================
          // اسم التطبيق
          // =================================================

          const Text(
            "نظام إدارة الهويات",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xff111827),
            ),
          ),

          // =================================================
          // التنبيهات
          // =================================================

          Stack(
            clipBehavior: Clip.none,
            children: [

              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AlertsScreen(),
                    ),
                  );
                },

                icon: const Icon(
                  Icons.notifications_none,
                  size: 30,
                  color: Color(0xff111827),
                ),
              ),

              if (alertCount > 0)
                Positioned(
                  right: 4,
                  top: 2,

                  child: Container(
                    width: 19,
                    height: 19,

                    alignment: Alignment.center,

                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),

                    child: Text(
                      alertCount.toString(),

                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}