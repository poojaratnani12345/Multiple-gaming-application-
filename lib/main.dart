// lib/main.dart
// ignore_for_file: unused_import

import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:multi_combo_game/page/home_page.dart';
import 'package:multi_combo_game/page/login_page.dart';
import 'package:multi_combo_game/page/welcome_page.dart';
import 'package:multi_combo_game/utils/dimention.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  try {
    await Firebase.initializeApp();
    print('Firebase Initialized Successfully');
  } catch (e) {
    print('Error Initializing Firebase: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(375, 812), // Set this to your base design size (e.g., iPhone 11 dimensions)
      minTextAdapt: true,
      builder: (context, child) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          initialRoute: '/', // Set the initial route
          getPages: [
            GetPage(
              name: '/',
              page: () => AnimatedSplashScreen(
                backgroundColor: Dimensions.mainColor,
                splash: Lottie.asset('assets/spalsh_animation.json'),
                nextScreen: WelcomePage(),
                splashIconSize: 500.w, // Scale splash size
                duration: 3000,
                splashTransition: SplashTransition.fadeTransition,
                animationDuration: const Duration(seconds: 1),
              ),
            ),
            GetPage(
              name: '/login',
              page: () => LoginPage(),
            ),
            GetPage(
              name: '/home',
              page: () => HomePage(username: ''),
            ),
          ],
        );
      },
    );
  }
}
