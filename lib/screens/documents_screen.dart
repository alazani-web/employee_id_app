import 'package:flutter/material.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}


class _DocumentsScreenState extends State<DocumentsScreen> {

  String selectedFilter = "الكل";


  @override
  Widget build(BuildContext context) {

    return Directionality(

      textDirection: TextDirection.rtl,

      child: Scaffold(

        backgroundColor: const Color(0xffF7F8FC),



        floatingActionButtonLocation:
            FloatingActionButtonLocation.endFloat,



        floatingActionButton: Directionality(

          textDirection: TextDirection.ltr,

          child: Padding(

            padding: const EdgeInsets.only(
              left: 20,
              bottom: 55,
            ),

            child: FloatingActionButton(

              onPressed: () {},

              backgroundColor:
                  const Color(0xff2864D7),

              elevation: 5,

              shape: const CircleBorder(),

              child: const Icon(

                Icons.add,

                color: Colors.white,

                size: 32,

              ),

            ),

          ),

        ),



        body: SafeArea(

          child: Padding(

            padding: const EdgeInsets.all(16),

            child: Column(

              children: [



                // البحث

                Container(

                  height: 58,

                  decoration: BoxDecoration(

                    color: Colors.white,

                    borderRadius:
                        BorderRadius.circular(18),

                    border: Border.all(

                      color: Colors.grey.shade200,

                    ),

                  ),


                  child: const TextField(

                    textAlign: TextAlign.right,


                    decoration: InputDecoration(

                      hintText:
                          "البحث بالاسم أو رقم الوثيقة...",


                      hintStyle: TextStyle(

                        color: Colors.grey,

                        fontSize: 16,

                      ),


                      suffixIcon: Icon(

                        Icons.search,

                        color: Colors.grey,

                      ),


                      border: InputBorder.none,


                      contentPadding:
                          EdgeInsets.symmetric(

                            vertical: 18,

                            horizontal: 20,

                          ),

                    ),

                  ),

                ),



                const SizedBox(height: 20),



                // الفلاتر

                Row(

                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,

                  children: [

                    filterButton("الكل"),

                    filterButton("نشط"),

                    filterButton("تنتهي قريباً"),

                    filterButton("منتهي"),

                  ],

                ),



                const SizedBox(height: 20),




                Expanded(

                  child: Container(

                    width: double.infinity,


                    decoration: BoxDecoration(

                      color: Colors.white,

                      borderRadius:
                          BorderRadius.circular(25),

                    ),


                    child: Center(

                      child: Text(

                        "لا توجد وثائق مسجلة",


                        style: TextStyle(

                          color:
                              Colors.grey.shade400,

                          fontSize: 18,

                        ),

                      ),

                    ),

                  ),

                ),



              ],

            ),

          ),

        ),

      ),

    );

  }





  Widget filterButton(String title) {


    bool active =
        selectedFilter == title;



    return GestureDetector(

      onTap: () {

        setState(() {

          selectedFilter = title;

        });

      },


      child: Container(

        padding:
            const EdgeInsets.symmetric(

              horizontal: 25,

              vertical: 12,

            ),



        decoration: BoxDecoration(

          color: active

              ? const Color(0xff2864D7)

              : Colors.white,



          borderRadius:
              BorderRadius.circular(30),



          border: Border.all(

            color: Colors.grey.shade200,

          ),

        ),



        child: Text(

          title,


          style: TextStyle(

            color: active

                ? Colors.white

                : Colors.black87,


            fontSize: 15,


            fontWeight:
                FontWeight.w600,

          ),

        ),

      ),

    );

  }

}