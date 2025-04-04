import 'package:flutter/material.dart';
import 'eventHistory.dart'; // Import the Event (HistoryPage)
import 'settings.dart'; // Import the SettingsHeaderScreen

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentIndex = 0; // Tracks the current tab index

  // Pages for each tab
  final List<Widget> _pages = [
    const Center(child: Text('Продажа/Покупка', style: TextStyle(fontSize: 24))), // Продажа/Покупка
    const Event(), // История opens Event (from eventHistory.dart)
    const Center(child: Text('Статистика', style: TextStyle(fontSize: 24))), // Статистика
    const SettingsHeaderScreen(), // Настройки opens SettingsHeaderScreen (from settings.dart)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex], // Display the selected page
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex, // Current selected tab
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Update the selected tab
          });
        },
        type: BottomNavigationBarType.fixed, // Fixed navigation bar
        selectedItemColor: Colors.blueAccent, // Color for selected item
        unselectedItemColor: Colors.grey, // Color for unselected items
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_vert),
            label: 'Продажа/Покупка',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'История',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Статистика',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Настройки',
          ),
        ],
      ),
    );
  }
}