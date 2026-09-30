import 'package:flutter/material.dart';

class VisitsScreen extends StatefulWidget {
  const VisitsScreen({super.key});

  @override
  State<VisitsScreen> createState() => _VisitsScreenState();
}


class _VisitsScreenState extends State<VisitsScreen> {

  int selectedFilter = 0;


  final List<String> filters = [
    "الكل",
    "نشط",
    "تنتهي قريباً",
    "منتهي",
  ];



  @override
  Widget build(BuildContext context) {


    return Directionality(

      textDirection: TextDirection.rtl,


      child: Scaffold(


        backgroundColor:
        const Color(0xffF7F9FC),



        body: Column(


          children: [


            const SizedBox(height:15),




            // البحث

            Container(


              margin:
              const EdgeInsets.symmetric(horizontal:16),


              height:58,


              decoration: BoxDecoration(


                color:Colors.white,


                borderRadius:
                BorderRadius.circular(20),



                border: Border.all(

                  color:
                  Colors.grey.shade200,

                ),


              ),




              child: TextField(


                textAlign:TextAlign.right,


                decoration:InputDecoration(


                  border:
                  InputBorder.none,



                  hintText:

                  "البحث بالاسم أو رقم الحدود أو التأشيرة...",



                  hintStyle:const TextStyle(

                    color:Colors.grey,

                    fontSize:16,

                  ),




                  suffixIcon:const Icon(

                    Icons.search,

                    color:Colors.grey,

                  ),




                  contentPadding:

                  const EdgeInsets.all(18),



                ),



              ),



            ),




            const SizedBox(height:15),





            // الفلاتر نفس الموظفين

            SizedBox(


              height:55,


              child:Row(


                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,



                children:List.generate(filters.length,(index){



                  bool active =
                      selectedFilter == index;



                  return GestureDetector(



                    onTap:(){


                      setState(() {


                        selectedFilter=index;


                      });


                    },




                    child:Container(


                      width:90,


                      height:42,


                      alignment:
                      Alignment.center,




                      decoration:BoxDecoration(


                        color:active

                            ? const Color(0xff2962C7)

                            : Colors.white,



                        borderRadius:

                        BorderRadius.circular(25),




                        border:Border.all(


                          color:
                          Colors.grey.shade200,


                        ),



                      ),




                      child:Text(


                        filters[index],




                        style:TextStyle(


                          color:active

                              ? Colors.white

                              : Colors.black87,



                          fontSize:14,



                          fontWeight:
                          FontWeight.w600,


                        ),



                      ),



                    ),



                  );



                }),



              ),



            ),





            const SizedBox(height:10),





            // رأس الجدول


            Container(


              height:50,


              color:
              const Color(0xffEEF1F7),



              child:const Row(



                children:[



                  Expanded(

                    child:Center(

                      child:Text(

                        "اسم الزائر",

                        style:TextStyle(

                          color:Colors.grey,

                          fontSize:14,

                        ),

                      ),

                    ),

                  ),




                  Expanded(

                    child:Center(

                      child:Text(

                        "رقم الحدود",

                        style:TextStyle(

                          color:Colors.grey,

                          fontSize:14,

                        ),

                      ),

                    ),

                  ),




                  Expanded(

                    child:Center(

                      child:Text(

                        "الحالة",

                        style:TextStyle(

                          color:Colors.grey,

                          fontSize:14,

                        ),

                      ),

                    ),

                  ),



                ],



              ),



            ),






            Expanded(


              child:Center(


                child:Text(


                  "لا توجد زيارات مسجلة",



                  style:TextStyle(


                    color:
                    Colors.grey.shade400,


                    fontSize:17,


                  ),



                ),



              ),



            ),




          ],



        ),






        // زر + نفس الموظفين

        floatingActionButton:FloatingActionButton(


          onPressed:(){},



          backgroundColor:
          const Color(0xff2962C7),




          shape:
          const CircleBorder(),



          elevation:4,



          child:const Icon(


            Icons.add,


            color:Colors.white,


            size:32,



          ),



        ),






        floatingActionButtonLocation:


        FloatingActionButtonLocation.endFloat,



      ),



    );


  }


}