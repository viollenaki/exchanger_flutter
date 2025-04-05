import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'currencies.dart';

class AddCurrencyScreen extends StatefulWidget {
  const AddCurrencyScreen({super.key});

  @override
  State<AddCurrencyScreen> createState() => _AddCurrencyScreenState();
}

class _AddCurrencyScreenState extends State<AddCurrencyScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  List<Map<String, String>> _filteredCurrencies = [];
  Map<String, String>? _selectedCurrency;
  bool _isLoading = false;
  bool _isValidCode = false;

  void _filterCurrencies(String query) {
    setState(() {
      _filteredCurrencies = query.isEmpty
          ? []
          : currencies.where((currency) {
              final nameMatch = currency["name"]!.toLowerCase().contains(query.toLowerCase());
              final codeMatch = currency["code"]!.toLowerCase().contains(query.toLowerCase());
              return nameMatch || codeMatch;
            }).toList();
    });
  }

  void _validateCode(String code) {
    final cleanCode = code.trim().toUpperCase();
    final existingCurrency = currencies.firstWhere(
      (c) => c["code"] == cleanCode,
      orElse: () => {},
    );

    setState(() {
      _isValidCode = existingCurrency.isNotEmpty;
      if (_isValidCode && _searchController.text.isEmpty) {
        _searchController.text = existingCurrency["name"]!;
      }
    });
  }

  void _selectCurrency(Map<String, String> currency) {
    setState(() {
      _selectedCurrency = currency;
      _searchController.text = currency["name"]!;
      _codeController.text = currency["code"]!;
      _isValidCode = true;
      _filteredCurrencies = [];
    });
  }

  Future<void> _sendDataToServer() async {
    final code = _codeController.text.trim().toUpperCase();
    final name = _searchController.text.trim();
    final amount = double.tryParse(_amountController.text);

    if (code.isEmpty || amount == null) {
      _showSnackBar('Заполните код валюты и сумму', Colors.red);
      return;
    }

    if (!_isValidCode && name.isEmpty) {
      _showSnackBar('Введите название для нового кода валюты', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      const url = 'https://dair12.pythonanywhere.com/add_currency/';
      const userId = 12;

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'name': _isValidCode ? (_selectedCurrency?["name"] ?? name) : name,
          'code': code,
          'amount': amount,
        }),
      );

      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200) {
        _clearFields();
        _showSnackBar('Успешно: ${responseData['message']}', Colors.green);
      } else {
        _showSnackBar('Ошибка: ${responseData['error']}', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Ошибка соединения: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearFields() {
    _searchController.clear();
    _codeController.clear();
    _amountController.clear();
    _selectedCurrency = null;
    _isValidCode = false;
  }

  void _showSnackBar(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить валюту'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Поиск валюты',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _isValidCode
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                ),
                onChanged: (value) {
                  _filterCurrencies(value);
                  if (_selectedCurrency != null && value != _selectedCurrency!["name"]) {
                    setState(() => _selectedCurrency = null);
                  }
                },
              ),

              if (_filteredCurrencies.isNotEmpty)
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: _filteredCurrencies.length,
                    itemBuilder: (context, index) {
                      final currency = _filteredCurrencies[index];
                      return ListTile(
                        title: Text(currency["name"]!),
                        subtitle: Text(currency["code"]!),
                        onTap: () => _selectCurrency(currency),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 20),
              TextField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: 'Код валюты',
                  border: const OutlineInputBorder(),
                  errorText: _codeController.text.isNotEmpty && !_isValidCode
                      ? 'Неизвестный код'
                      : null,
                ),
                maxLength: 3,
                textCapitalization: TextCapitalization.characters,
                onChanged: (value) => _validateCode(value),
              ),

              const SizedBox(height: 20),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Сумма',
                  border: OutlineInputBorder(),
                  suffixText: 'ед.',
                ),
              ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_codeController.text.isNotEmpty &&
                              _amountController.text.isNotEmpty &&
                              (_isValidCode || _searchController.text.isNotEmpty) &&
                              !_isLoading)
                      ? _sendDataToServer
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Добавить валюту',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
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
}