import 'package:flutter/material.dart';
import 'package:currencies/pages/home.dart';
import 'package:currencies/pages/login.dart';
import 'package:currencies/pages/pinCode.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final String? storedPin = prefs.getString('pin');
  final String? savedUsername = prefs.getString('username');
  final String? savedPassword = prefs.getString('password');

  runApp(MyApp(
    storedPin: storedPin,
    isUserLoggedIn: savedUsername != null && savedPassword != null,
  ));
}

class MyApp extends StatelessWidget {
  final String? storedPin;
  final bool isUserLoggedIn;

  const MyApp({super.key, this.storedPin, required this.isUserLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: isUserLoggedIn
          ? (storedPin == null ? const Home() : VerifyPinScreen())
          : const Login(),
      routes: {
        '/home': (context) => const Home(),
        '/createPin': (context) => CreatePinScreen(),
        '/verifyPin': (context) => VerifyPinScreen(),
      },
    );
  }
}
