import 'package:flutter/material.dart';

class CommonFilterBar extends StatelessWidget {

  final String selected;
  final Function(String) onChanged;

  const CommonFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });


  @override
  Widget build(BuildContext context) {

    final filters = [
      "الكل",
      "نشط",
      "تنتهي قريباً",
      "منتهي",
    ];


    return SizedBox(

      height: 55,

      child: Row(

        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,

        children: filters.map((filter){

          bool active = selected == filter;


          return GestureDetector(

            onTap: (){
              onChanged(filter);
            },


            child: Container(

              width: 90,

              height: 42,


              alignment: Alignment.center,


              decoration: BoxDecoration(

                color: active
                    ? const Color(0xff2864D7)
                    : Colors.white,


                borderRadius:
                    BorderRadius.circular(25),


                border: Border.all(
                  color: Colors.grey.shade200,
                ),

              ),


              child: Text(

                filter,

                style: TextStyle(

                  fontSize: 14,

                  fontWeight:
                      FontWeight.w600,


                  color: active
                      ? Colors.white
                      : Colors.black87,

                ),

              ),

            ),

          );


        }).toList(),

      ),

    );

  }

}