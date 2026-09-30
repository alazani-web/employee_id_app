import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';


class HomeScreen extends StatelessWidget {

  const HomeScreen({super.key});


  @override
  Widget build(BuildContext context) {

    return Directionality(

      textDirection: TextDirection.rtl,

      child: Scaffold(

        backgroundColor: const Color(0xffF7F9FC),

        body: SingleChildScrollView(

          padding: const EdgeInsets.all(16),

          child: Column(

            children: [


              Container(

                padding: const EdgeInsets.all(14),

                decoration: BoxDecoration(

                  color: Colors.white,

                  borderRadius:
                  BorderRadius.circular(20),

                ),


                child: Row(

                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,


                  children: [


                    Column(

                      crossAxisAlignment:
                      CrossAxisAlignment.end,


                      children: const [

                        Text(

                          "لوحة التحكم الرئيسية",

                          style: TextStyle(

                            fontSize:18,

                            fontWeight:
                            FontWeight.bold,

                          ),

                        ),


                        SizedBox(height:4),


                        Text(

                          "ملخص شامل لحالة النظام",

                          style:TextStyle(

                            color:Colors.grey,

                            fontSize:12,

                          ),

                        ),


                      ],

                    ),



                    Container(

                      padding:
                      const EdgeInsets.all(8),


                      decoration:BoxDecoration(

                        color:
                        const Color(0xffEFF4FF),

                        borderRadius:
                        BorderRadius.circular(15),

                      ),


                      child:const Column(

                        children:[

                          Text(

                            "اليوم",

                            style:TextStyle(

                              color:
                              Color(0xff2864D7),

                              fontSize:12,

                              fontWeight:
                              FontWeight.bold,

                            ),

                          ),

                          Text(

                            "الأربعاء",

                            style:TextStyle(

                              fontSize:12,

                              fontWeight:
                              FontWeight.bold,

                            ),

                          ),

                        ],

                      ),

                    )


                  ],

                ),

              ),



              const SizedBox(height:12),



              GridView.count(

                shrinkWrap:true,

                physics:
                const NeverScrollableScrollPhysics(),


                crossAxisCount:2,

                crossAxisSpacing:10,

                mainAxisSpacing:10,


                childAspectRatio:2.35,


                children:[


                  StatCard(

                    title:"الموظفين",

                    count:"27",

                    icon:
                    "assets/icons/users.svg",

                    color:
                    const Color(0xff2864D7),

                    background:
                    const Color(0xffEFF4FF),

                  ),



                  StatCard(

                    title:"الوثائق",

                    count:"0",

                    icon:
                    "assets/icons/folder_open.svg",

                    color:
                    const Color(0xff2864D7),

                    background:
                    const Color(0xffEFF4FF),

                  ),



                  StatCard(

                    title:"التنبيهات",

                    count:"18",

                    icon:
                    "assets/icons/document.svg",

                    color:
                    const Color(0xffD8792B),

                    background:
                    const Color(0xfffff5ed),

                  ),



                  StatCard(

                    title:"الزيارات",

                    count:"9",

                    icon:
                    "assets/icons/calendar.svg",

                    color:
                    const Color(0xff3D9850),

                    background:
                    const Color(0xffEFFAF1),

                  ),


                ],

              ),



              const SizedBox(height:14),



              InfoCard(

                title:"حالة الترخيص",

                subtitle:
                "مفتاح التفعيل: مفعل\nالأيام المتبقية: 12512 يوم",

                button:"إدارة الترخيص",

              ),



              const SizedBox(height:14),



              InfoCard(

                title:"النسخ الاحتياطي",

                subtitle:
                "آخر نسخة احتياطية\nلا توجد نسخة محفوظة",

                button:"إنشاء نسخة احتياطية",

              )


            ],

          ),

        ),

      ),

    );

  }

}




class StatCard extends StatelessWidget {


  final String title;

  final String count;

  final String icon;

  final Color color;

  final Color background;


  const StatCard({

    super.key,

    required this.title,

    required this.count,

    required this.icon,

    required this.color,

    required this.background,

  });



  @override
  Widget build(BuildContext context){


    return Container(

      height:80,


      padding:
      const EdgeInsets.symmetric(

        horizontal:10,

        vertical:6,

      ),


      decoration:BoxDecoration(

        color:background,

        borderRadius:
        BorderRadius.circular(18),

      ),


      child:Row(

        mainAxisAlignment:
        MainAxisAlignment.end,


        children:[


          Column(

            mainAxisAlignment:
            MainAxisAlignment.center,


            crossAxisAlignment:
            CrossAxisAlignment.end,


            children:[


              Text(

                title,

                style:const TextStyle(

                  color:
                  Color(0xff7A8495),

                  fontSize:12,

                ),

              ),



              Text(

                count,

                style:TextStyle(

                  color:color,

                  fontSize:20,

                  fontWeight:
                  FontWeight.bold,

                ),

              ),


            ],

          ),



          const SizedBox(width:8),



          Container(

            width:32,

            height:32,


            decoration:
            const BoxDecoration(

              color:Colors.white,

              shape:
              BoxShape.circle,

            ),


            child:SvgPicture.asset(

              icon,

              width:18,

              height:18,


              colorFilter:
              ColorFilter.mode(

                color,

                BlendMode.srcIn,

              ),

            ),

          )


        ],

      ),

    );

  }

}



class InfoCard extends StatelessWidget {


  final String title;

  final String subtitle;

  final String button;


  const InfoCard({

    super.key,

    required this.title,

    required this.subtitle,

    required this.button,

  });



  @override
  Widget build(BuildContext context){


    return Container(

      padding:
      const EdgeInsets.all(14),


      decoration:BoxDecoration(

        color:Colors.white,

        borderRadius:
        BorderRadius.circular(20),

      ),


      child:Column(

        crossAxisAlignment:
        CrossAxisAlignment.stretch,


        children:[


          Text(

            title,

            textAlign:
            TextAlign.right,


            style:const TextStyle(

              fontSize:17,

              fontWeight:
              FontWeight.bold,

            ),

          ),



          const SizedBox(height:6),



          Text(

            subtitle,

            textAlign:
            TextAlign.right,


            style:const TextStyle(

              color:Colors.grey,

              fontSize:13,

            ),

          ),



          const SizedBox(height:12),



          SizedBox(

            height:45,


            child:ElevatedButton(

              onPressed:(){},


              style:ElevatedButton.styleFrom(

                backgroundColor:
                const Color(0xff2864D7),

                shape:
                RoundedRectangleBorder(

                  borderRadius:
                  BorderRadius.circular(14),

                ),

              ),


              child:Text(

                button,

                style:
                const TextStyle(

                  color:Colors.white,

                ),

              ),

            ),

          )


        ],

      ),

    );

  }

}