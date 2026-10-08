import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/supabase_service.dart';

class LicenseManagerScreen extends StatefulWidget {
  const LicenseManagerScreen({super.key});

  @override
  State<LicenseManagerScreen> createState() =>
      _LicenseManagerScreenState();
}

class _LicenseManagerScreenState
    extends State<LicenseManagerScreen> {

  final TextEditingController customerController =
      TextEditingController();

  bool loading = false;

  String selectedPlan = 'premium';
  int selectedDays = 365;

  String? generatedKey;


  @override
  void dispose() {
    customerController.dispose();
    super.dispose();
  }


  Future<void> _createKey() async {

    final customer =
        customerController.text.trim();

    if (customer.isEmpty) {
      _message('أدخل اسم العميل');
      return;
    }

    setState(() {
      loading = true;
      generatedKey = null;
    });


    try {

      final key =
          await SupabaseService.instance
              .createLicenseKey(
        customerName: customer,
        plan: selectedPlan,
        days: selectedDays,
      );


      if (!mounted) return;


      setState(() {
        generatedKey = key;
      });


    } catch (e) {

      _message(
        'حدث خطأ أثناء إنشاء المفتاح',
      );

    } finally {

      if (mounted) {
        setState(() {
          loading = false;
        });
      }

    }
  }


  void _copyKey() {

    if (generatedKey == null) return;

    Clipboard.setData(
      ClipboardData(
        text: generatedKey!,
      ),
    );

    _message(
      'تم نسخ المفتاح',
    );
  }


  void _message(String text) {

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(text),
      ),
    );

  }



  @override
  Widget build(BuildContext context) {

    return Directionality(
      textDirection: TextDirection.rtl,

      child: Scaffold(

        backgroundColor:
            const Color(0xffF7F9FC),


        appBar: AppBar(

          title: const Text(
            'إدارة الاشتراكات',
          ),

          centerTitle: true,

          backgroundColor:
              const Color(0xff2864D7),

          foregroundColor:
              Colors.white,

        ),


        body: FutureBuilder<bool>(

          future:
              SupabaseService.instance.isAdmin,


          builder: (context, snapshot) {


            if (snapshot.connectionState ==
                ConnectionState.waiting) {

              return const Center(
                child:
                    CircularProgressIndicator(),
              );

            }


            if (snapshot.data != true) {

              return const Center(
                child: Text(
                  'غير مصرح بالدخول',
                  style: TextStyle(
                    fontSize:18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              );

            }



            return SingleChildScrollView(

              padding:
                  const EdgeInsets.all(16),


              child: Column(

                children: [


                  _card(

                    child: Column(

                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,


                      children: [


                        const Text(
                          'إنشاء مفتاح جديد',
                          style: TextStyle(
                            fontSize:18,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),


                        const SizedBox(height:16),



                        TextField(

                          controller:
                              customerController,

                          decoration:
                              _input(
                            'اسم العميل',
                            Icons.person,
                          ),

                        ),



                        const SizedBox(height:14),



                        DropdownButtonFormField<String>(

                          value:selectedPlan,

                          decoration:
                              _input(
                            'الباقة',
                            Icons.workspace_premium,
                          ),


                          items: const [

                            DropdownMenuItem(
                              value:'basic',
                              child:
                                  Text('Basic'),
                            ),

                            DropdownMenuItem(
                              value:'premium',
                              child:
                                  Text('Premium'),
                            ),

                            DropdownMenuItem(
                              value:'pro',
                              child:
                                  Text('Pro'),
                            ),

                          ],


                          onChanged:(v){

                            if(v!=null){

                              setState(() {
                                selectedPlan=v;
                              });

                            }

                          },

                        ),



                        const SizedBox(height:14),



                        DropdownButtonFormField<int>(

                          value:selectedDays,

                          decoration:
                              _input(
                            'مدة الاشتراك',
                            Icons.calendar_month,
                          ),


                          items: const [

                            DropdownMenuItem(
                              value:30,
                              child:
                                  Text('30 يوم'),
                            ),

                            DropdownMenuItem(
                              value:90,
                              child:
                                  Text('90 يوم'),
                            ),

                            DropdownMenuItem(
                              value:365,
                              child:
                                  Text('365 يوم'),
                            ),

                            DropdownMenuItem(
                              value:1095,
                              child:
                                  Text('3 سنوات'),
                            ),

                          ],


                          onChanged:(v){

                            if(v!=null){

                              setState(() {
                                selectedDays=v;
                              });

                            }

                          },

                        ),



                        const SizedBox(height:20),



                        SizedBox(

                          height:48,

                          child:
                          ElevatedButton.icon(

                            onPressed:
                                loading
                                ? null
                                : _createKey,


                            icon:
                                const Icon(
                              Icons.key,
                            ),


                            label:
                                Text(
                              loading
                              ? 'جاري الإنشاء...'
                              : 'إنشاء مفتاح',
                            ),


                            style:
                            ElevatedButton.styleFrom(

                              backgroundColor:
                                  const Color(
                                    0xff2864D7,
                                  ),

                              foregroundColor:
                                  Colors.white,

                              shape:
                              RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(14),
                              ),

                            ),

                          ),

                        ),


                      ],

                    ),

                  ),




                  if(generatedKey != null)
                    const SizedBox(height:16),



                  if(generatedKey != null)

                    _card(

                      child: Column(

                        children:[


                          const Text(
                            'تم إنشاء المفتاح',
                            style:TextStyle(
                              fontSize:17,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),


                          const SizedBox(height:15),


                          SelectableText(

                            generatedKey!,

                            style:
                            const TextStyle(
                              fontSize:18,
                              fontWeight:
                                  FontWeight.w900,
                              color:
                              Color(0xff2864D7),
                            ),

                          ),


                          const SizedBox(height:15),


                          ElevatedButton.icon(

                            onPressed:
                                _copyKey,

                            icon:
                            const Icon(
                              Icons.copy,
                            ),

                            label:
                            const Text(
                              'نسخ المفتاح',
                            ),

                          )


                        ],

                      ),

                    ),


                ],

              ),

            );


          },

        ),

      ),

    );

  }



  Widget _card({
    required Widget child,
  }) {

    return Container(

      width:
          double.infinity,

      padding:
          const EdgeInsets.all(18),

      decoration:
      BoxDecoration(

        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(20),

        border:
        Border.all(
          color:
          const Color(0xffE5E7EB),
        ),

      ),

      child:child,

    );

  }



  InputDecoration _input(
      String hint,
      IconData icon,
      ){

    return InputDecoration(

      labelText:
          hint,

      prefixIcon:
          Icon(icon),

      filled:true,

      fillColor:
          const Color(0xffF8FAFC),

      border:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(12),
      ),

    );

  }

}