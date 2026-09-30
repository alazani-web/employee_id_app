import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/employees_screen.dart';
import 'screens/visits_screen.dart';
import 'screens/documents_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/tasks_screen.dart';

import 'widgets/app_header.dart';
import 'widgets/bottom_navigation.dart';
import 'widgets/side_menu.dart';



class App extends StatefulWidget {

  const App({super.key});


  @override
  State<App> createState() => _AppState();

}



class _AppState extends State<App> {


  String currentPage = "home";


  int alertCount = 0;




  Widget getCurrentPage(){


    switch(currentPage){


      case "employees":
        return const EmployeesScreen();



      case "visits":
        return const VisitsScreen();



      case "documents":
        return const DocumentsScreen();



      case "reports":
        return const ReportsScreen();



      case "alerts":
        return const AlertsScreen();



      case "settings":
        return const SettingsScreen();



      case "tasks":
        return const TasksScreen();



      default:
        return const HomeScreen();

    }

  }





  void navigate(String page){

    setState(() {

      currentPage = page;

    });

  }






  @override
  Widget build(BuildContext context){


    return MaterialApp(


      debugShowCheckedModeBanner:false,


      title:"Employee ID App",



      theme:ThemeData(


        useMaterial3:true,


        fontFamily:"Arial",


      ),




      home:Scaffold(



        drawer:SideMenu(

          onNavigate:navigate,

        ),





        body: Builder(

          builder: (context){


            return Column(


              children:[




                AppHeader(


                  alertCount:alertCount,


                  onMenuTap:(){


                    Scaffold.of(context).openDrawer();


                  },


                ),





                Expanded(


                  child:getCurrentPage(),


                ),





                BottomNavigation(


                  currentPage: currentPage,


                  onNavigate: navigate,


                )



              ],


            );


          },

        ),



      ),



    );


  }


}