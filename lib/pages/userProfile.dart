import 'package:flutter/material.dart';
import 'currencies.dart'; // Импортируем список валют

// Волнистая форма заголовка
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 10);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 35,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _amountController = TextEditingController(); // Контроллер для суммы
  List<Map<String, String>> _filteredCurrencies = [];
  Map<String, String>? _selectedCurrency;

  void _filterCurrencies(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCurrencies = [];
      } else {
        _filteredCurrencies = currencies
            .where((currency) =>
                currency["name"]!.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _selectCurrency(Map<String, String> currency) {
    setState(() {
      _selectedCurrency = currency;
      _searchController.text = currency["name"]!; // Устанавливаем текст в поле
      _filteredCurrencies = []; // Очищаем список после выбора
    });
  }
                          
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ClipPath(
            clipper: WaveClipper(),
            child: Container(
              height: 150,
              color: Colors.blueAccent,
              child: Stack(
                children: [
                  Positioned(
                    left: 16,
                    top: 50,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context); // Возвращаемся на предыдущий экран
                      },
                    ),
                  ),
                  // Removed the Center widget with the Icon
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Добавить валюту',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Введите название валюты',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _filterCurrencies,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: _selectedCurrency != null
                          ? 'Введите сумму в ${_selectedCurrency!["name"]}'
                          : 'Введите сумму',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _selectedCurrency != null &&
                            _amountController.text.isNotEmpty
                        ? () {
                            print(
                                'Добавлена валюта: ${_selectedCurrency!["name"]}, сумма: ${_amountController.text}');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Добавлена валюта: ${_selectedCurrency!["name"]}, сумма: ${_amountController.text}'),
                              ),
                            );
                            setState(() {
                              _selectedCurrency = null;
                              _searchController.clear();
                              _amountController.clear();
                            });
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Добавить валюту',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _filteredCurrencies.isNotEmpty
                        ? ListView.builder(
                            itemCount: _filteredCurrencies.length,
                            itemBuilder: (context, index) {
                              final currency = _filteredCurrencies[index];
                              return ListTile(
                                title: Text(currency["name"]!),
                                onTap: () => _selectCurrency(currency),
                              );
                            },
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}