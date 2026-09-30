import 'package:flutter/material.dart';

class BottomNavigation extends StatelessWidget {
  final String currentPage;
  final Function(String) onNavigate;

  const BottomNavigation({
    super.key,
    required this.currentPage,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final Color blue = const Color(0xff2864D7);
    final Color grey = const Color(0xff7A8495);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: 82,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // 1. الرئيسية
            navItem(
              "home",
              "الرئيسية",
              Icons.home_outlined,
              Icons.home,
              blue,
              grey,
            ),
            // 2. الموظفين
            navItem(
              "employees",
              "الموظفين",
              Icons.people_outline,
              Icons.people,
              blue,
              grey,
            ),
            // 3. الزيارات (أيقونة الطائرة المائلة تماماً كما في الصورة)
            navItem(
              "visits",
              "الزيارات",
              Icons.flight_outlined,
              Icons.flight,
              blue,
              grey,
            ),
            // 4. الوثائق (أيقونة المجلد المفتوح)
            navItem(
              "documents",
              "الوثائق",
              Icons.folder_open_outlined,
              Icons.folder,
              blue,
              grey,
            ),
            // 5. التقارير
            navItem(
              "reports",
              "التقارير",
              Icons.description_outlined,
              Icons.description,
              blue,
              grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget navItem(
    String id,
    String title,
    IconData icon,
    IconData activeIcon,
    Color blue,
    Color grey,
  ) {
    bool selected = currentPage == id;

    return GestureDetector(
      onTap: () {
        onNavigate(id);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            selected ? activeIcon : icon,
            size: 26,
            color: selected ? blue : grey,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? blue : grey,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: selected ? blue : Colors.transparent,
              shape: BoxShape.circle,
            ),
          )
        ],
      ),
    );
  }
}