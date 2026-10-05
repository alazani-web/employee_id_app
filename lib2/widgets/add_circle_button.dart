import 'package:flutter/material.dart';


class AddCircleButton extends StatelessWidget {

  final VoidCallback onPressed;


  const AddCircleButton({

    super.key,

    required this.onPressed,

  });


  @override
  Widget build(BuildContext context) {


    return Positioned(

      left: 20,

      bottom: 85,


      child: FloatingActionButton(

        onPressed: onPressed,


        backgroundColor:
            const Color(0xff2864D7),


        shape: const CircleBorder(),


        child: const Icon(

          Icons.add,

          color: Colors.white,

          size: 32,

        ),

      ),

    );


  }

}