import 'package:flutter/material.dart';
import 'package:currencies/pages/addCurency.dart';
import 'package:currencies/pages/settings.dart';
import 'package:currencies/pages/currency_screen.dart'; // Импорт нового экрана

class CustomDrawer extends StatelessWidget {
  final Color drawerHeaderColor;

  const CustomDrawer({Key? key, required this.drawerHeaderColor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: drawerHeaderColor, // Цвет заголовка
            ),
            child: const Text(
              'Меню',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Добавление валюты'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddCurrencyScreen()), // Corrected widget
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Курсы валют'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CurrencyScreen()), // Используем новый экран
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Выйти'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}