import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'license_manager_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() =>
      _AdminLoginScreenState();
}

class _AdminLoginScreenState
    extends State<AdminLoginScreen> {

  final emailController =
      TextEditingController();

  final passwordController =
      TextEditingController();

  bool loading = false;
  bool hidePassword = true;


  Future<void> _login() async {

    final email =
        emailController.text.trim();

    final password =
        passwordController.text.trim();


    if (email.isEmpty || password.isEmpty) {

      _message(
        'أدخل البريد وكلمة المرور',
      );

      return;
    }


    setState(() {
      loading = true;
    });


    try {

      final supabase =
          Supabase.instance.client;


      // تسجيل الدخول
      final response =
          await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );


      final user =
          response.user;


      if (user == null) {

        throw Exception(
          'فشل تسجيل الدخول',
        );

      }


      // التحقق من صلاحية المدير
      final result =
          await supabase
              .from('app_users')
              .select('role')
              .eq('email', user.email!)
              .maybeSingle();


      debugPrint('ADMIN AUTH EMAIL: ${user.email}');
      debugPrint('ADMIN DB RESULT: $result');

      final role =
          result?['role']?.toString();


      if (role != 'admin') {

        await supabase.auth.signOut();

        throw Exception(
          'ليس لديك صلاحية مدير',
        );

      }


      if (!mounted) return;


      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const LicenseManagerScreen(),
        ),
      );


    } catch (e) {

      _message(
        e.toString()
            .replaceFirst(
              'Exception: ',
              '',
            ),
      );


    } finally {

      if (mounted) {

        setState(() {
          loading = false;
        });

      }

    }

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

      textDirection:
          TextDirection.rtl,


      child: Scaffold(

        backgroundColor:
            const Color(0xffF7F9FC),


        appBar: AppBar(

          title:
              const Text(
                'دخول الإدارة',
              ),

          centerTitle:
              true,

          backgroundColor:
              const Color(0xff2864D7),

          foregroundColor:
              Colors.white,

        ),


        body:

        Center(

          child:

          SingleChildScrollView(

            padding:
                const EdgeInsets.all(20),


            child:

            Container(

              padding:
                  const EdgeInsets.all(22),


              decoration:

              BoxDecoration(

                color:
                    Colors.white,

                borderRadius:
                    BorderRadius.circular(22),

                boxShadow:

                const [

                  BoxShadow(

                    color:
                        Color(0x14000000),

                    blurRadius:
                        20,

                    offset:
                        Offset(0,6),

                  ),

                ],

              ),


              child:

              Column(

                mainAxisSize:
                    MainAxisSize.min,


                children: [


                  Container(

                    width:
                        80,

                    height:
                        80,


                    decoration:

                    BoxDecoration(

                      color:
                          const Color(
                            0xffE8F0FF,
                          ),

                      borderRadius:
                          BorderRadius.circular(25),

                    ),


                    child:

                    const Icon(

                      Icons.admin_panel_settings,

                      size:
                          45,

                      color:
                          Color(0xff2864D7),

                    ),

                  ),


                  const SizedBox(
                    height:20,
                  ),


                  const Text(

                    'تسجيل دخول المدير',

                    style:

                    TextStyle(

                      fontSize:
                          20,

                      fontWeight:
                          FontWeight.w900,

                    ),

                  ),


                  const SizedBox(
                    height:25,
                  ),



                  TextField(

                    controller:
                        emailController,

                    keyboardType:
                        TextInputType.emailAddress,


                    decoration:

                    InputDecoration(

                      labelText:
                          'البريد الإلكتروني',

                      prefixIcon:

                          const Icon(
                            Icons.email_outlined,
                          ),

                      border:

                      OutlineInputBorder(

                        borderRadius:
                            BorderRadius.circular(14),

                      ),

                    ),

                  ),


                  const SizedBox(
                    height:15,
                  ),



                  TextField(

                    controller:
                        passwordController,


                    obscureText:
                        hidePassword,


                    decoration:

                    InputDecoration(

                      labelText:
                          'كلمة المرور',


                      prefixIcon:
                          const Icon(
                            Icons.lock_outline,
                          ),


                      suffixIcon:

                      IconButton(

                        icon:

                        Icon(

                          hidePassword
                              ? Icons.visibility
                              : Icons.visibility_off,

                        ),


                        onPressed: () {

                          setState(() {

                            hidePassword =
                                !hidePassword;

                          });

                        },

                      ),


                      border:

                      OutlineInputBorder(

                        borderRadius:
                            BorderRadius.circular(14),

                      ),

                    ),

                  ),



                  const SizedBox(
                    height:25,
                  ),



                  SizedBox(

                    width:
                        double.infinity,


                    height:
                        50,


                    child:

                    ElevatedButton(

                      onPressed:
                          loading
                              ? null
                              : _login,


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


                      child:

                      loading

                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )

                          :

                      const Text(

                        'دخول',

                        style:

                        TextStyle(

                          fontWeight:
                              FontWeight.w800,

                        ),

                      ),

                    ),

                  ),


                ],

              ),

            ),

          ),

        ),

      ),

    );

  }


  @override
  void dispose() {

    emailController.dispose();
    passwordController.dispose();

    super.dispose();

  }

}