import 'package:flutter/material.dart';
import 'package:currencies/pages/userProfile.dart';
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
            leading: const Icon(Icons.account_circle),
            title: const Text('Профиль'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserProfile()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
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