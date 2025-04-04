import 'package:flutter/material.dart';
import 'currencies.dart'; // Импортируем список валют

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
      appBar: AppBar(
        title: const Text('Профиль'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
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
            if (_selectedCurrency != null)
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number, // Поле для числового ввода
                decoration: InputDecoration(
                  hintText: 'Введите сумму в ${_selectedCurrency!["name"]}',
                  border: const OutlineInputBorder(),
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
                  : const SizedBox.shrink(), // Скрываем список, если он пуст
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _selectedCurrency != null && _amountController.text.isNotEmpty
                  ? () {
                      // Логика добавления выбранной валюты и суммы
                      print(
                          'Добавлена валюта: ${_selectedCurrency!["name"]}, сумма: ${_amountController.text}');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Добавлена валюта: ${_selectedCurrency!["name"]}, сумма: ${_amountController.text}'),
                        ),
                      );
                      setState(() {
                        _selectedCurrency = null; // Сбрасываем выбранную валюту
                        _searchController.clear(); // Очищаем поле ввода
                        _amountController.clear(); // Очищаем сумму
                      });
                    }
                  : null, // Кнопка неактивна, если валюта или сумма не выбраны
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
          ],
        ),
      ),
    );
  }
}