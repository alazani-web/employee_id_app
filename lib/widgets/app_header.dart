import 'package:flutter/material.dart';
import '../screens/alerts_screen.dart';

class AppHeader extends StatelessWidget {
  final int alertCount;
  final VoidCallback? onMenuTap;

  const AppHeader({
    super.key,
    this.alertCount = 3,
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
          Builder(
            builder: (innerContext) {
              return IconButton(
                onPressed: () {
                  if (onMenuTap != null) {
                    onMenuTap!();
                  } else {
                    Scaffold.of(innerContext).openDrawer();
                  }
                },
                icon: const Icon(
                  Icons.menu,
                  size: 30,
                  color: Color(0xff111827),
                ),
              );
            },
          ),
          const Text(
            "نظام إدارة الهويات",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xff111827),
            ),
          ),
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AlertsScreen(),
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
                  right: 6,
                  top: 6,
                  child: CircleAvatar(
                    radius: 9,
                    backgroundColor: Colors.red,
                    child: Text(
                      alertCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
            ],
          )
        ],
      ),
    );
  }
}