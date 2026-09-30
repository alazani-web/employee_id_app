import 'package:flutter/material.dart';


class SideMenu extends StatelessWidget {

  final Function(String) onNavigate;


  const SideMenu({
    super.key,
    required this.onNavigate,
  });


  @override
  Widget build(BuildContext context){

    return Drawer(

      child: ListView(

        children:[

          const DrawerHeader(
            child: Text(
              "القائمة الجانبية",
              style: TextStyle(
                fontSize:22,
                fontWeight:FontWeight.bold,
              ),
            ),
          ),


          ListTile(
            leading: const Icon(Icons.home),
            title: const Text("الرئيسية"),
            onTap: (){
              onNavigate("home");
              Navigator.pop(context);
            },
          ),


          ListTile(
            leading: const Icon(Icons.people),
            title: const Text("الموظفين"),
            onTap: (){
              onNavigate("employees");
              Navigator.pop(context);
            },
          ),


          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("الإعدادات"),
            onTap: (){
              onNavigate("settings");
              Navigator.pop(context);
            },
          ),

        ],

      ),

    );
  }
}