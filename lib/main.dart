import 'package:currencies/pages/addCurrencyScreen.dart';
import 'package:flutter/material.dart';
import 'package:currencies/pages/home.dart';
import 'package:currencies/pages/login.dart';
import 'package:currencies/pages/pinCode.dart';
import 'package:currencies/pages/settings.dart';
import 'package:currencies/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final String? storedPin = prefs.getString('pin');
  final String? savedUsername = prefs.getString('username');
  final String? savedPassword = prefs.getString('password');

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(
        storedPin: storedPin,
        isUserLoggedIn: savedUsername != null && savedPassword != null,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String? storedPin;
  final bool isUserLoggedIn;

  const MyApp({Key? key, this.storedPin, required this.isUserLoggedIn})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: themeProvider.currentTheme,
          home: isUserLoggedIn
              ? (storedPin == null ? const Home() : VerifyPinScreen())
              : const Login(),
          routes: {
            '/home': (context) => const Home(),
            '/createPin': (context) => CreatePinScreen(),
            '/verifyPin': (context) => VerifyPinScreen(),
            '/settings': (context) => const Settings(),
            '/currencyScreen': (context) => const AddCurrencyScreen(),
          },
        );
      },
    );
  }
}
