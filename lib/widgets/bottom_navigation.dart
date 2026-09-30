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

    return BottomNavigationBar(

      currentIndex: _index(),


      onTap: (index){

        switch(index){


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

      },


      type: BottomNavigationBarType.fixed,


      selectedItemColor: const Color(0xff2962c7),

      unselectedItemColor: Colors.grey,


      items: const [


        BottomNavigationBarItem(

          icon: Icon(Icons.home_outlined),

          label:"الرئيسية",

        ),



        BottomNavigationBarItem(

          icon: Icon(Icons.people_outline),

          label:"الموظفين",

        ),



        BottomNavigationBarItem(

          icon: Icon(Icons.flight_outlined),

          label:"الزيارات",

        ),



        BottomNavigationBarItem(

          icon: Icon(Icons.folder_outlined),

          label:"الوثائق",

        ),



        BottomNavigationBarItem(

          icon: Icon(Icons.description_outlined),

          label:"التقارير",

        ),



      ],

    );

  }



  int _index(){


    switch(currentPage){


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

}