import 'package:flutter/material.dart';

class BottomNavigation extends StatelessWidget {

  final String currentPage;
  final Function(String) onNavigate;


  const BottomNavigation({

    super.key,

    required this.currentPage,

    required this.onNavigate,

  });



  int getCurrentIndex() {

    switch (currentPage) {

      case "home":
        return 0;

      case "employees":
        return 1;

      case "visits":
        return 2;

      case "documents":
        return 3;

      case "reports":
        return 4;

      default:
        return 0;

    }

  }



  void changePage(int index) {

    switch (index) {

      case 0:
        onNavigate("home");
        break;

      case 1:
        onNavigate("employees");
        break;

      case 2:
        onNavigate("visits");
        break;

      case 3:
        onNavigate("documents");
        break;

      case 4:
        onNavigate("reports");
        break;

    }

  }



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

              offset: const Offset(0, -3),

            ),

          ],

        ),



        child: BottomNavigationBar(


          currentIndex: getCurrentIndex(),


          onTap: changePage,


          type: BottomNavigationBarType.fixed,


          backgroundColor: Colors.transparent,


          elevation: 0,


          selectedItemColor:
              const Color(0xff2864D7),


          unselectedItemColor:
              const Color(0xff7A8495),



          selectedLabelStyle: const TextStyle(

            fontSize: 13,

            fontWeight: FontWeight.bold,

          ),



          unselectedLabelStyle: const TextStyle(

            fontSize: 13,

          ),



          items: const [



            BottomNavigationBarItem(

              icon: Icon(Icons.home_outlined),

              activeIcon: Icon(Icons.home),

              label: "الرئيسية",

            ),



            BottomNavigationBarItem(

              icon: Icon(Icons.people_outline),

              activeIcon: Icon(Icons.people),

              label: "الموظفين",

            ),



            BottomNavigationBarItem(

              icon: Icon(Icons.flight_outlined),

              activeIcon: Icon(Icons.flight),

              label: "الزيارات",

            ),



            BottomNavigationBarItem(

              icon: Icon(Icons.folder_outlined),

              activeIcon: Icon(Icons.folder),

              label: "الوثائق",

            ),



            BottomNavigationBarItem(

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