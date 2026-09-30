import 'package:flutter/material.dart';


class SideMenu extends StatelessWidget {

  final Function(String) onNavigate;


  const SideMenu({

    super.key,

    required this.onNavigate,

  });



  @override
  Widget build(BuildContext context) {

    return Directionality(

      textDirection: TextDirection.rtl,

      child: Drawer(

        width: MediaQuery.of(context).size.width * 0.82,

        backgroundColor: Colors.white,


        child: SafeArea(

          child: Column(

            children: [


              // رأس القائمة

              Padding(

                padding: const EdgeInsets.symmetric(
                  horizontal:20,
                  vertical:18,
                ),

                child: Row(

                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,


                  children: [


                    const Text(

                      "القائمة الجانبية",

                      style: TextStyle(

                        fontSize:26,

                        fontWeight:FontWeight.bold,

                      ),

                    ),



                    Container(

                      width:45,

                      height:45,


                      decoration: BoxDecoration(

                        color: const Color(0xffF3F5F9),

                        shape: BoxShape.circle,

                      ),


                      child: IconButton(

                        onPressed:(){

                          Navigator.pop(context);

                        },

                        icon: const Icon(

                          Icons.close,

                          color:Color(0xff7A8495),

                          size:26,

                        ),

                      ),

                    ),


                  ],

                ),

              ),



              const Divider(),



              Expanded(

                child: ListView(

                  padding: EdgeInsets.zero,


                  children: [


                    menuItem(

                      context,

                      Icons.settings_outlined,

                      "الإعدادات",

                      "الإعدادات العامة",

                      "settings",

                    ),



                    menuItem(

                      context,

                      Icons.storage_outlined,

                      "النسخ الاحتياطي",

                      "تصدير واستعادة البيانات",

                      "backup",

                    ),



                    menuItem(

                      context,

                      Icons.key_outlined,

                      "التفعيل",

                      "إدارة الاشتراك والأجهزة",

                      "activation",

                    ),



                    menuItem(

                      context,

                      Icons.shield_outlined,

                      "قفل التطبيق",

                      "رقم سري وبصمة الوجه",

                      "lock",

                    ),



                    menuItem(

                      context,

                      Icons.notifications_none,

                      "ضبط الإشعارات",

                      "مواعيد وتنبيهات النظام",

                      "alerts",

                    ),



                    menuItem(

                      context,

                      Icons.assignment_outlined,

                      "المهام",

                      "إدارة المهام والمتابعات",

                      "tasks",

                    ),



                    menuItem(

                      context,

                      Icons.info_outline,

                      "نبذة عن التطبيق",

                      "معلومات النظام والإصدار",

                      "about",

                    ),


                  ],

                ),

              ),


            ],

          ),

        ),

      ),

    );

  }




  Widget menuItem(

      BuildContext context,

      IconData icon,

      String title,

      String subtitle,

      String page,

      ){



    return InkWell(

      onTap:(){

        Navigator.pop(context);

        onNavigate(page);

      },


      child: Padding(

        padding: const EdgeInsets.symmetric(

          horizontal:24,

          vertical:16,

        ),


        child: Row(

          children: [



            Icon(

              icon,

              size:32,

              color:const Color(0xff2864D7),

            ),



            const SizedBox(width:22),



            Column(

              crossAxisAlignment:

              CrossAxisAlignment.start,


              children: [



                Text(

                  title,

                  style:const TextStyle(

                    fontSize:20,

                    fontWeight:FontWeight.bold,

                  ),

                ),



                const SizedBox(height:4),



                Text(

                  subtitle,

                  style:const TextStyle(

                    fontSize:14,

                    color:Colors.grey,

                  ),

                ),


              ],

            ),



          ],

        ),

      ),

    );


  }


}