import 'package:flutter/material.dart';


class EmployeesScreen extends StatefulWidget {

  const EmployeesScreen({super.key});


  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();

}



class _EmployeesScreenState extends State<EmployeesScreen> {


  int selectedFilter = 0;


  final TextEditingController searchController =
  TextEditingController();



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
        const Color(0xfff7f9fc),



        body: Column(


          children: [



            const SizedBox(height:15),




            // شريط البحث


            Container(


              margin:
              const EdgeInsets.symmetric(horizontal:16),


              height:65,


              padding:
              const EdgeInsets.symmetric(horizontal:18),



              decoration:BoxDecoration(


                color:Colors.white,


                borderRadius:
                BorderRadius.circular(22),


              ),



              child:TextField(


                controller: searchController,


                textDirection:
                TextDirection.rtl,


                textAlign:
                TextAlign.right,



                decoration:InputDecoration(


                  border:
                  InputBorder.none,



                  hintText:
                  "البحث بالاسم أو رقم الهوية...",



                  hintStyle:
                  const TextStyle(


                    color:Colors.grey,


                    fontSize:16,


                  ),



                  suffixIcon:
                  const Icon(


                    Icons.search,


                    color:Colors.grey,


                    size:30,


                  ),



                ),


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
                const EdgeInsets.symmetric(
                    horizontal:16
                ),



                itemCount:
                filters.length,



                itemBuilder:
                    (context,index){



                  bool active =
                      selectedFilter == index;



                  return GestureDetector(


                    onTap:(){


                      setState(() {


                        selectedFilter=index;


                      });


                    },



                    child:Container(


                      width:115,


                      margin:
                      const EdgeInsets.only(
                          left:10
                      ),



                      decoration:
                      BoxDecoration(



                        color:active

                            ? const Color(0xff2962c7)

                            : Colors.white,



                        borderRadius:
                        BorderRadius.circular(30),



                        border:
                        Border.all(

                          color:
                          Colors.grey.shade200,

                        ),


                      ),




                      child:Center(


                        child:Text(


                          filters[index],



                          style:TextStyle(


                            color:active

                                ? Colors.white

                                : Colors.black87,



                            fontSize:15,



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




            const SizedBox(height:10),




            // عناوين الجدول



            Container(


              height:50,


              color:
              const Color(0xffeef1f7),




              child:const Row(



                children:[



                  Expanded(

                    child:Center(

                      child:Text(

                        "اسم الموظف",

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

                        "رقم الهوية",

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





            // لا يوجد بيانات



            Expanded(


              child:Center(


                child:Column(


                  mainAxisAlignment:
                  MainAxisAlignment.center,



                  children:[



                    Icon(


                      Icons.people_outline,


                      size:60,


                      color:
                      Colors.grey.shade400,


                    ),




                    const SizedBox(height:12),




                    Text(


                      "لا يوجد موظفين مسجلين",



                      style:TextStyle(


                        color:
                        Colors.grey.shade500,



                        fontSize:17,


                      ),


                    ),



                  ],


                ),


              ),


            ),



          ],


        ),





        floatingActionButton:


        FloatingActionButton(



          onPressed:(){},



          backgroundColor:
          const Color(0xff2962c7),




          shape:
          const CircleBorder(),




          elevation:4,




          child:
          const Icon(


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