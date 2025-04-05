import 'package:flutter/material.dart';
import 'package:currencies/pages/addCurrencyScreen.dart';
import 'package:currencies/pages/settings.dart';
import 'package:currencies/pages/currency_screen.dart';
import 'package:provider/provider.dart';
import 'package:currencies/theme/theme_provider.dart';

class CustomDrawer extends StatelessWidget {
  final Color? drawerHeaderColor;

  const CustomDrawer({Key? key, this.drawerHeaderColor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    // Use the theme's primary color if no drawerHeaderColor is specified
    final headerColor = drawerHeaderColor ?? Theme.of(context).primaryColor;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: headerColor,
            ),
            child: Text(
              'Меню',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.attach_money),
            title: Text('Добавление валюты'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AddCurrencyScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.bar_chart),
            title: Text('Курсы валют'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CurrencyScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Настройки'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Settings()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Выйти'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
