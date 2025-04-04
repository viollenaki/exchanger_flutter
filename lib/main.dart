import 'package:flutter/material.dart';
import 'package:currencies/pages/home.dart';
import 'package:currencies/pages/login.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    initialRoute: '/', // Начальный маршрут
    routes: {
      '/': (context) => const Login(), // Маршрут для Login
      '/home': (context) => const Home(), // Маршрут для Home
    },
  ));
}