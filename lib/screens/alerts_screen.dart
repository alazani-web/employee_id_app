import 'package:flutter/material.dart';


class AlertsScreen extends StatelessWidget {

  const AlertsScreen({super.key});


  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: Center(

        child: Text(
          "التنبيهات",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

      ),

    );

  }
}