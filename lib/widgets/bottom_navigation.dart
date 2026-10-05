import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: 64,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xffEEF1F5)),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: Color(0xff2864D7),
          unselectedItemColor: Color(0xff7A8495),
          selectedFontSize: 10,
          unselectedFontSize: 10,
          iconSize: 21,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          items: [
            _item('assets/icons/home.svg', 'الرئيسية'),
            _item('assets/icons/users.svg', 'الموظفين'),
            _item('assets/icons/plane.svg', 'الزيارات'),
            _item('assets/icons/folder_open.svg', 'الوثائق'),
            const BottomNavigationBarItem(
              icon: Icon(Icons.description_outlined, size: 21),
              activeIcon: Icon(Icons.description, size: 21),
              label: 'التقارير',
            ),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _item(String path, String label) {
    return BottomNavigationBarItem(
      icon: _iconSvg(path, false),
      activeIcon: _iconSvg(path, true),
      label: label,
    );
  }

  Widget _iconSvg(String path, bool active) {
    return SvgPicture.asset(
      path,
      width: 21,
      height: 21,
      colorFilter: ColorFilter.mode(
        active ? const Color(0xff2864D7) : const Color(0xff7A8495),
        BlendMode.srcIn,
      ),
    );
  }
}
