import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../globals.dart'; // Import globals.dart

void main() {
  runApp(const MaterialApp(home: AddCurrencyScreen()));
}

class AddCurrencyScreen extends StatefulWidget {
  const AddCurrencyScreen({super.key});

  @override
  State<AddCurrencyScreen> createState() => _AddCurrencyScreenState();
}

class _AddCurrencyScreenState extends State<AddCurrencyScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  List<dynamic> _userInventory = [];
  bool _isLoadingBalance = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserInventory();
  }

  Future<void> _fetchUserInventory() async {
    try {
      const url = 'https://dair12.pythonanywhere.com/get_user_inventory/';

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': user_id}), // Use global user_id
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _userInventory = data['inventory'];
          _isLoadingBalance = false;
        });
      }
    } catch (e) {
      print('Ошибка загрузки баланса: $e');
    }
  }

  Future<void> _sendDataToServer() async {
    final code = _codeController.text.trim().toLowerCase();
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text);

    if (code.isEmpty || name.isEmpty || amount == null || amount <= 0) {
      _showSnackBar('Заполните все поля корректно', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      const url = 'https://dair12.pythonanywhere.com/add_currency/';

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': user_id, // Use global user_id
          'name': name,
          'code': code,
          'amount': amount,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        _clearFields();
        _showSnackBar('Успешно: ${responseData['message']}', Colors.green);
        await _fetchUserInventory();
      } else {
        _showSnackBar('Ошибка: ${responseData['error']}', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Ошибка соединения: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCurrency(int currencyId) async {
    try {
      const url = 'https://dair12.pythonanywhere.com/delete_currency/';

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': user_id, // Use global user_id
          'currency_id': currencyId,
        }),
      );

      if (response.statusCode == 200) {
        await _fetchUserInventory();
      }
    } catch (e) {
      print('Ошибка удаления: $e');
    }
  }

  Future<void> _updateAmount(int currencyId, double amount) async {
    try {
      const url = 'https://dair12.pythonanywhere.com/add_inventory_amount/';

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': user_id, // Use global user_id
          'currency_id': currencyId,
          'amount': amount,
        }),
      );

      if (response.statusCode == 200) {
        await _fetchUserInventory();
      }
    } catch (e) {
      print('Ошибка изменения суммы: $e');
    }
  }

  bool _shouldActivateButton() {
    final amount = double.tryParse(_amountController.text);
    return (_codeController.text.length == 3 &&
        _nameController.text.isNotEmpty &&
        amount != null &&
        amount > 0 &&
        !_isLoading);
  }

  void _clearFields() {
    _nameController.clear();
    _codeController.clear();
    _amountController.clear();
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

  void _showEditDialog(BuildContext context, int currencyId, bool isAdding) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isAdding ? 'Добавить средства' : 'Списать средства'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Сумма'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(controller.text);
              if (amount != null && amount > 0) {
                _updateAmount(currencyId, isAdding ? amount : -amount);
                Navigator.pop(context);
              }
            },
            child: const Text('Подтвердить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление валютами'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Форма добавления валюты
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Название валюты',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: 'Код валюты (3 буквы)',
                  border: const OutlineInputBorder(),
                  errorText: _codeController.text.isNotEmpty &&
                          _codeController.text.length != 3
                      ? 'Код должен содержать 3 символа'
                      : null,
                ),
                maxLength: 3,
                textCapitalization: TextCapitalization.characters,
                onChanged: (value) {
                  final newValue = value.toUpperCase();
                  if (newValue != value) {
                    _codeController.value = _codeController.value.copyWith(
                      text: newValue,
                      selection:
                          TextSelection.collapsed(offset: newValue.length),
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Сумма',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 30),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _shouldActivateButton() ? _sendDataToServer : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Добавить валюту'),
                ),
              ),

              // Заголовок и список валют
              const Padding(
                padding: EdgeInsets.only(top: 30, bottom: 15),
                child: Text(
                  'Текущие валюты:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _isLoadingBalance
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _userInventory.length,
                        itemBuilder: (context, index) {
                          final currency = _userInventory[index];
                          return Dismissible(
                            key: Key(currency['currency_id'].toString()),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child:
                                  const Icon(Icons.delete, color: Colors.white),
                            ),
                            confirmDismiss: (direction) async {
                              return await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text(
                                    'Удалить валюту?',
                                    style: TextStyle(
                                      // Увеличенный шрифт
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: const Text(
                                    'Вы уверены что хотите удалить эту валюту?',
                                    style: TextStyle(
                                      // Увеличенный шрифт
                                      fontSize: 18,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text(
                                        'Отмена',
                                        style: TextStyle(
                                            fontSize: 16), // Стандартный размер
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        _deleteCurrency(
                                            currency['currency_id']);
                                        Navigator.pop(context, true);
                                      },
                                      child: const Text(
                                        'Удалить',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: ListTile(
                              title: Text(
                                currency['currency'],
                                style: const TextStyle(
                                  // Увеличенный шрифт
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                '${currency['quantity']} ${currency['currency_code'].toString().toUpperCase()}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 28),
                                    onPressed: () => _showEditDialog(context,
                                        currency['currency_id'], false),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 28),
                                    onPressed: () => _showEditDialog(
                                        context, currency['currency_id'], true),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
