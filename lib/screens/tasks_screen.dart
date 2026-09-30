import 'package:flutter/material.dart';


class TasksScreen extends StatelessWidget {

  const TasksScreen({super.key});


  @override
  Widget build(BuildContext context){

    return Scaffold(

      body: Center(

        child: Text(
          "المهام",
          style: TextStyle(
            fontSize:24,
            fontWeight:FontWeight.bold,
          ),
        ),

      ),

    );

  }
}