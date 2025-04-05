import 'package:currencies/pages/addCurrencyScreen.dart';
import 'package:flutter/material.dart';
import 'package:currencies/pages/home.dart';
import 'package:currencies/pages/login.dart';
import 'package:currencies/pages/pinCode.dart';
import 'package:currencies/pages/settings.dart'; // Import Settings page
import 'package:currencies/theme/theme_provider.dart'; // Import ThemeProvider
import 'package:provider/provider.dart'; // For state management
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
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(), // Provide ThemeProvider
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: themeProvider.currentTheme, // Apply dynamic theme
            home: isUserLoggedIn
                ? (storedPin == null ? const Home() : VerifyPinScreen())
                : const Login(),
            routes: {
              '/home': (context) => const Home(),
              '/createPin': (context) => CreatePinScreen(),
              '/verifyPin': (context) => VerifyPinScreen(),
              '/settings': (context) => const Settings(), // Add Settings route
              '/currencyScreen': (context) => const AddCurrencyScreen(), // Add CurrencyScreen route
            },
          );
        },
      ),
    );
  }
}
