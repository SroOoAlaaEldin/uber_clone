import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:uber_clone/gps_screen.dart';
import 'package:uber_clone/home_screen.dart' show HomeScreen;
import 'package:uber_clone/phone_login_screen.dart';
import 'package:uber_clone/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl, // من اليمين لليسار
          child: child!,
        );
      },
      home: SplashScreen(),
      routes: {
        '/login': (context) => PhoneLoginScreen(),
        '/gps': (context) => GpsScreen(label: '',),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}
