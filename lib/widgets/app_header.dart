import 'package:flutter/material.dart';


class AppHeader extends StatelessWidget {

  final int alertCount;
  final VoidCallback onMenuTap;


  const AppHeader({
    super.key,
    required this.alertCount,
    required this.onMenuTap,
  });


  @override
  Widget build(BuildContext context) {

    return Container(

      height: 85,

      color: Colors.white,


      child: Row(

        mainAxisAlignment: MainAxisAlignment.spaceBetween,

        children: [


          IconButton(

            onPressed: onMenuTap,

            icon: const Icon(
              Icons.menu,
              size: 35,
              color: Color(0xff111827),
            ),

          ),



          const Text(

            "نظام إدارة الهويات",

            style: TextStyle(

              fontSize: 24,

              fontWeight: FontWeight.bold,

              color: Color(0xff111827),

            ),

          ),



          Stack(

            children: [


              IconButton(

                onPressed: () {},

                icon: const Icon(

                  Icons.notifications_none,

                  size: 35,

                  color: Color(0xff111827),

                ),

              ),



              if(alertCount > 0)

              Positioned(

                right: 5,

                top: 5,

                child: CircleAvatar(

                  radius: 11,

                  backgroundColor: Colors.red,

                  child: Text(

                    alertCount.toString(),

                    style: const TextStyle(

                      color: Colors.white,

                      fontSize: 12,

                    ),

                  ),

                ),

              )

            ],

          )

        ],

      ),

    );

  }

}