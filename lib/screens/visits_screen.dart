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


        backgroundColor: const Color(0xfff7f9fc),



        body: Column(


          children: [



            const SizedBox(height:15),





            const SizedBox(height:15),




            // البحث


            Padding(

              padding:
              const EdgeInsets.symmetric(horizontal:16),


              child: Row(

                children: [



                  Expanded(

                    child: Container(

                      height:65,


                      decoration:BoxDecoration(

                        color:Colors.white,


                        borderRadius:
                        BorderRadius.circular(22),

                      ),



                      child: TextField(


                        textAlign:TextAlign.right,


                        decoration:InputDecoration(


                          border:InputBorder.none,


                          hintText:
                          "البحث بالاسم أو رقم الحدود أو التأشيرة...",


                          hintStyle:const TextStyle(

                            color:Colors.grey,

                            fontSize:15,

                          ),



                          suffixIcon:

                          const Icon(

                            Icons.search,

                            color:Colors.grey,

                          ),



                          contentPadding:

                          const EdgeInsets.all(18),


                        ),


                      ),


                    ),


                  ),




                  const SizedBox(width:12),




                  Container(


                    height:65,


                    width:65,



                    decoration:BoxDecoration(

                      color:Colors.white,


                      borderRadius:

                      BorderRadius.circular(20),


                    ),



                    child:const Icon(

                      Icons.filter_alt_outlined,


                      color:Color(0xff7b35d6),


                      size:30,

                    ),



                  )



                ],


              ),


            ),




            const SizedBox(height:15),




            // الفلاتر


            SizedBox(


              height:55,


              child:ListView.builder(



                scrollDirection:

                Axis.horizontal,



                padding:

                const EdgeInsets.symmetric(horizontal:16),



                itemCount:filters.length,



                itemBuilder:(context,index){



                  bool active =
                      selectedFilter == index;




                  return GestureDetector(



                    onTap:(){


                      setState(() {


                        selectedFilter=index;


                      });


                    },



                    child:Container(



                      width:120,



                      margin:

                      const EdgeInsets.only(left:10),




                      decoration:BoxDecoration(



                        color:active

                            ? const Color(0xff2962c7)

                            : Colors.white,




                        borderRadius:

                        BorderRadius.circular(30),




                        border:Border.all(

                          color:Colors.grey.shade200,

                        ),



                      ),




                      child:Center(



                        child:Text(



                          filters[index],




                          style:TextStyle(



                            color:active

                                ? Colors.white

                                : Colors.black87,




                            fontWeight:

                            FontWeight.bold,



                          ),




                        ),



                      ),



                    ),



                  );



                },



              ),



            ),




            const SizedBox(height:15),





            // رأس الجدول


            Container(


              height:50,


              color:

              const Color(0xffeef1f7),




              child:const Row(



                children:[




                  Expanded(

                    child:Center(

                      child:Text(

                        "اسم الزائر",

                        style:TextStyle(

                          color:Colors.grey,

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



                    color:Colors.grey.shade400,

                    fontSize:17,

                  ),



                ),



              ),



            )



          ],



        ),





        floatingActionButton:



        FloatingActionButton(



          onPressed:(){},



          backgroundColor:

          const Color(0xff2962c7),




          shape:

          const CircleBorder(),





          child:const Icon(



            Icons.add,

            color:Colors.white,

            size:32,



          ),



        ),





        // يسار الشاشة في RTL


        floatingActionButtonLocation:

        FloatingActionButtonLocation.endFloat,




      ),


    );


  }


}