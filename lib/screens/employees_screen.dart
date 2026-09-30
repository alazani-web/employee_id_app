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

                color: Colors.white,

                borderRadius:
                BorderRadius.circular(20),

                border: Border.all(

                  color: Colors.grey.shade200,

                ),

              ),



              child: TextField(

                controller: searchController,

                textAlign: TextAlign.right,


                decoration: InputDecoration(

                  border: InputBorder.none,


                  hintText:
                  "البحث بالاسم أو رقم الهوية...",


                  hintStyle: const TextStyle(

                    color: Colors.grey,

                    fontSize:16,

                  ),



                  suffixIcon: const Icon(

                    Icons.search,

                    color: Colors.grey,

                  ),


                ),

              ),

            ),



            const SizedBox(height:15),




            // الفلاتر

            SizedBox(

              height:55,


              child: Row(

                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,


                children: List.generate(filters.length,(index){


                  bool active =
                      selectedFilter == index;



                  return GestureDetector(


                    onTap:(){

                      setState(() {

                        selectedFilter=index;

                      });

                    },



                    child: Container(

                      width:90,

                      height:42,


                      alignment:
                      Alignment.center,



                      decoration: BoxDecoration(


                        color: active

                            ? const Color(0xff2962C7)

                            : Colors.white,



                        borderRadius:
                        BorderRadius.circular(25),



                        border: Border.all(

                          color:
                          Colors.grey.shade200,

                        ),

                      ),



                      child: Text(

                        filters[index],


                        style: TextStyle(

                          color: active

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




            // عناوين الجدول

            Container(

              height:50,


              color:
              const Color(0xffEEF1F7),



              child: const Row(

                children: [


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





        // زر +

        floatingActionButton: FloatingActionButton(


          onPressed:(){

            showEmployeeActions(context);

          },


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






  void showEmployeeActions(BuildContext context){


    showModalBottomSheet(

      context: context,

      backgroundColor: Colors.transparent,

      isScrollControlled: true,


      builder:(context){


        return Directionality(

          textDirection: TextDirection.rtl,


          child: Container(

            margin:
            const EdgeInsets.all(16),


            padding:
            const EdgeInsets.all(24),


            decoration: const BoxDecoration(

              color:Colors.white,

              borderRadius: BorderRadius.all(

                Radius.circular(35),

              ),

            ),



            child: Column(

              mainAxisSize:
              MainAxisSize.min,


              children:[



                Row(

                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,


                  children:[


                    CircleAvatar(

                      backgroundColor:
                      const Color(0xffF3F5FA),

                      child:IconButton(

                        onPressed:(){

                          Navigator.pop(context);

                        },


                        icon:
                        const Icon(Icons.close),

                      ),

                    ),




                    const Text(

                      "اختر العملية",

                      style:TextStyle(

                        fontSize:26,

                        fontWeight:
                        FontWeight.bold,

                      ),

                    ),


                  ],

                ),




                const SizedBox(height:35),




                actionCard(

                  Icons.person_add_alt_1,

                  "إضافة موظف",

                  "إضافة موظف جديد إلى النظام",

                ),




                const SizedBox(height:20),




                actionCard(

                  Icons.upload_file,

                  "استيراد موظفين",

                  "استيراد موظفين من ملف بيانات",

                ),




                const SizedBox(height:30),




                SizedBox(

                  width:double.infinity,

                  height:60,


                  child:ElevatedButton(

                    onPressed:(){

                      Navigator.pop(context);

                    },


                    style:ElevatedButton.styleFrom(

                      backgroundColor:
                      const Color(0xff101828),

                      shape:
                      RoundedRectangleBorder(

                        borderRadius:
                        BorderRadius.circular(18),

                      ),

                    ),



                    child:const Text(

                      "إغلاق",

                      style:TextStyle(

                        color:Colors.white,

                        fontSize:18,

                      ),

                    ),


                  ),

                ),


              ],

            ),

          ),

        );

      },

    );

  }






  Widget actionCard(

      IconData icon,

      String title,

      String subtitle,

      ){

    return Container(

      padding:
      const EdgeInsets.all(18),


      decoration:BoxDecoration(

        borderRadius:
        BorderRadius.circular(22),


        border:Border.all(

          color:
          Colors.grey.shade200,

        ),

      ),



      child:Row(

        children:[



          Container(

            width:65,

            height:65,


            decoration:BoxDecoration(

              color:
              const Color(0xffF1F5FF),

              borderRadius:
              BorderRadius.circular(18),

            ),



            child:Icon(

              icon,

              color:
              const Color(0xff2962C7),

              size:32,

            ),

          ),




          const SizedBox(width:20),



          Column(

            crossAxisAlignment:
            CrossAxisAlignment.start,


            children:[


              Text(

                title,

                style:const TextStyle(

                  fontSize:20,

                  fontWeight:
                  FontWeight.bold,

                ),

              ),



              const SizedBox(height:6),



              Text(

                subtitle,

                style:const TextStyle(

                  color:Colors.grey,

                  fontSize:15,

                ),

              ),


            ],

          ),


        ],

      ),

    );

  }


}