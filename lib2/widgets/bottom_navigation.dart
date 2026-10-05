import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';


class BottomNavigation extends StatelessWidget {

  final int currentIndex;
  final Function(int) onTap;


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

              offset: const Offset(0,-3),

            ),

          ],

        ),


        child: BottomNavigationBar(

          currentIndex: currentIndex,

          onTap: onTap,

          type: BottomNavigationBarType.fixed,

          backgroundColor: Colors.transparent,

          elevation: 0,


          selectedItemColor: const Color(0xff2864D7),

          unselectedItemColor: const Color(0xff7A8495),



          items: [


            BottomNavigationBarItem(

              icon: iconSvg(
                "assets/icons/home.svg",
                false,
              ),

              activeIcon: iconSvg(
                "assets/icons/home.svg",
                true,
              ),

              label: "الرئيسية",

            ),



            BottomNavigationBarItem(

              icon: iconSvg(
                "assets/icons/users.svg",
                false,
              ),

              activeIcon: iconSvg(
                "assets/icons/users.svg",
                true,
              ),

              label: "الموظفين",

            ),




            BottomNavigationBarItem(

              icon: iconSvg(
                "assets/icons/plane.svg",
                false,
              ),

              activeIcon: iconSvg(
                "assets/icons/plane.svg",
                true,
              ),

              label: "الزيارات",

            ),





            BottomNavigationBarItem(

              icon: iconSvg(
                "assets/icons/folder_open.svg",
                false,
              ),

              activeIcon: iconSvg(
                "assets/icons/folder_open.svg",
                true,
              ),

              label: "الوثائق",

            ),




            const BottomNavigationBarItem(

              icon: Icon(Icons.description_outlined),

              activeIcon: Icon(Icons.description),

              label: "التقارير",

            ),


          ],

        ),

      ),

    );

  }



  Widget iconSvg(String path, bool active) {

    return SvgPicture.asset(

      path,

      width: 24,

      height: 24,


      colorFilter: ColorFilter.mode(

        active

            ? const Color(0xff2864D7)

            : const Color(0xff7A8495),

        BlendMode.srcIn,

      ),

    );

  }

}