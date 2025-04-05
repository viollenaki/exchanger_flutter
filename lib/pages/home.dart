import 'package:currencies/pages/settings.dart';
import 'package:currencies/pages/addCurrencyScreen.dart';
import 'package:flutter/material.dart';
import 'eventHistory.dart'; // Import the HistoryPage

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentIndex = 0; // Tracks the current tab index

  // Controllers for the "Продажа/Покупка" tab
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController courseController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  bool isBuySelected = true;
  String? selectedCurrency;

  // Warm style palette
  final Color warmBlue = const Color(0xFF4B607F);
  final Color softBeige = const Color(0xFFE8D8C9);
  final Color brightGreen = const Color(0xFF4CAF50); // slightly softened green
  final Color brightRed = const Color(0xFFF44336);   // slightly softened red

  // Pages for each tab
  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    pages = [
      _buildBuySellPage(), // "Продажа/Покупка" tab
      const Event(), // История opens Event (from eventHistory.dart)
      const Center(child: Text('Статистика', style: TextStyle(fontSize: 24))),
      const SettingsHeaderScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          pages[_currentIndex], // Display the selected page
          if (_currentIndex == 0) // Показываем иконку только на главной странице
            Positioned(
              top: 48,
              left: 16,
              child: GestureDetector(
                onTap: () {
                  // Действие при нажатии на иконку профиля
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddCurrencyScreen()),
                  );
                },
                child: const Icon(
                  Icons.account_circle,
                  size: 32,
                  color: Colors.black54, // Цвет иконки
                ),
              ),
            ),
        ],
      ),
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

  // "Продажа/Покупка" tab content
  Widget _buildBuySellPage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            warmBlue,
            softBeige,
          ],
        ),
      ),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // "Купить" and "Продать" buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _toggleButton(
                    "Купить",
                    isBuySelected, // Active when `isBuySelected` is true
                    () {
                      setState(() {
                        isBuySelected = true; // Set to "Купить"
                      });
                    },
                    brightGreen, // Green color for "Купить"
                  ),
                  _toggleButton(
                    "Продать",
                    !isBuySelected, // Active when `isBuySelected` is false
                    () {
                      setState(() {
                        isBuySelected = false; // Set to "Продать"
                      });
                    },
                    brightRed, // Red color for "Продать"
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Currency dropdown
              _buildDropdown(),

              const SizedBox(height: 16),
              _inputField(controller: quantityController, hint: 'Amount'),
              const SizedBox(height: 16),
              _inputField(controller: courseController, hint: 'Exchange Rate'),
              const SizedBox(height: 16),
              _inputField(controller: descriptionController, hint: 'Description'),
              const SizedBox(height: 24),

              // Add Event button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: warmBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Add Event',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Toggle button: Купить / Продать
  Widget _toggleButton(String label, bool isActive, VoidCallback onTap, Color activeColor) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap, // Ensure the onTap callback is called
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200), // Smooth transition
          height: 45,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.grey[200], // Active color or grey
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.black, // White text for active
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // Dropdown field
  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedCurrency,
      decoration: InputDecoration(
        labelText: selectedCurrency == null ? 'Валюта' : null,
        labelStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: Colors.grey[200],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: ['USD', 'EUR', 'KGS', 'YNTYMAK'].map((currency) {
        return DropdownMenuItem(
          value: currency,
          child: Text(currency),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => selectedCurrency = value);
      },
      icon: const Icon(Icons.arrow_drop_down),
      dropdownColor: Colors.white,
    );
  }

  // Input field
  Widget _inputField({required TextEditingController controller, required String hint}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: Colors.grey[200],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
