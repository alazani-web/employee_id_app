import 'package:flutter/material.dart';


class ReportsScreen extends StatelessWidget {

  const ReportsScreen({super.key});


  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          "التقارير",
        ),
        centerTitle: true,
      ),


      body: const Center(

        child: Text(
          "صفحة التقارير",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

      ),

    );

  }
}