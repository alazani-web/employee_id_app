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

              color: Colors.black.withValues(alpha: 0.05),

              blurRadius: 10,

              offset: const Offset(0, -3),

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



          selectedLabelStyle: const TextStyle(

            fontSize: 13,

            fontWeight: FontWeight.bold,

          ),



          unselectedLabelStyle: const TextStyle(

            fontSize: 13,

          ),



          items: [



            const BottomNavigationBarItem(

              icon: Icon(Icons.home_outlined),

              activeIcon: Icon(Icons.home),

              label: "الرئيسية",

            ),



            const BottomNavigationBarItem(

              icon: Icon(Icons.people_outline),

              activeIcon: Icon(Icons.people),

              label: "الموظفين",

            ),



            const BottomNavigationBarItem(

              icon: Icon(Icons.flight_outlined),

              activeIcon: Icon(Icons.flight),

              label: "الزيارات",

            ),



            BottomNavigationBarItem(

              icon: SvgPicture.asset(

                "assets/icons/document.svg",

                width: 24,

                height: 24,

                colorFilter: const ColorFilter.mode(

                  Color(0xff7A8495),

                  BlendMode.srcIn,

                ),

              ),


              activeIcon: SvgPicture.asset(

                "assets/icons/document.svg",

                width: 24,

                height: 24,

                colorFilter: const ColorFilter.mode(

                  Color(0xff2864D7),

                  BlendMode.srcIn,

                ),

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

}