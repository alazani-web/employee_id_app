import 'package:flutter/material.dart';


class AddButton extends StatelessWidget {

  final VoidCallback onTap;


  const AddButton({

    super.key,

    required this.onTap,

  });



  @override
  Widget build(BuildContext context) {


    return Positioned(

      left: 25,

      bottom: 85,


      child: GestureDetector(


        onTap: onTap,


        child: Container(


          width: 58,

          height: 58,


          decoration: BoxDecoration(

            color: const Color(0xff2864D7),

            shape: BoxShape.circle,

            boxShadow: [

              BoxShadow(

                color: Colors.black.withValues(alpha: 0.15),

                blurRadius: 8,

              )

            ],

          ),


          child: const Icon(

            Icons.add,

            color: Colors.white,

            size: 32,

          ),


        ),

      ),

    );


  }

}