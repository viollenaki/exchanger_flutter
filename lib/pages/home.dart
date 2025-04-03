import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../main.dart';
import 'dart:convert';


class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  String? _selectedCurrency;
  double? _total;

  bool _isDownPressed = false;
  bool _isUpPressed = false;

  void _showClearConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Are you sure?',
            style: TextStyle(color: Colors.black),
          ),
          content: const Text(
            'Are you sure you want to delete all transactions?',
            style: TextStyle(color: Colors.black),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Закрыть диалог без действия
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Закрыть диалог
                _clearTransactions(); // Удалить транзакции
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }


  void _calculateTotal() {
    final quantity = double.tryParse(_quantityController.text);
    final course = double.tryParse(_courseController.text);
    if (quantity != null && course != null) {
      setState(() {
        _total = quantity * course;
      });
    }
  }

  bool _isFormValid() {
    final int? quantity = int.tryParse(_quantityController.text);
    final double? course = double.tryParse(_courseController.text);
    return quantity != null &&
        course != null &&
        _selectedCurrency != null &&
        (_isDownPressed || _isUpPressed);
  }

  Future<void> _clearTransactions() async {
    final url = Uri.parse('https://dair12.pythonanywhere.com/clear_transactions/');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user': currentUser,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('All transactions have been deleted successfully.')),
        );
        await fetchGlobalTransactions(currentUser!);
      } else {
        _showErrorDialog('Failed to delete transactions: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('An error occurred: $e');
    }
  }


  Future<void> _submitTransaction() async {
    final operation = _isDownPressed ? 'buy' : 'sell';
    final currency = _selectedCurrency;
    final quantity = int.tryParse(_quantityController.text);
    final rate = _courseController.text;

    final parsedRate = double.tryParse(rate);

    if (parsedRate == null) {
      _showErrorDialog('Invalid rate. Please enter a valid number.');
      return;
    }
    if (quantity == null) {
      _showErrorDialog('Invalid quantity. Please enter a valid number.');
      return;
    }

    final totalCost = quantity * parsedRate;

    // Проверка, превышает ли сумма balance
    if (totalCost > balance && operation=='buy') {
      _showErrorDialog('Insufficient balance. Transaction cost exceeds your balance.');
      return;
    }

    if ( quantity> (currencyHoldings[currency] ?? 0) && operation=='sell'){
      _showErrorDialog('Insufficient balance. Transaction cost exceeds your balance.');
      return;
    }

    _showSuccessDialog();
    _clearForm();

    if (currency != null && quantity != null) {
      final url = Uri.parse(
          'https://dair12.pythonanywhere.com/transaction/$operation/$currency/$quantity/$rate/');
      try {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'user': currentUser,
          }),
        );

        if (response.statusCode == 200) {
          if (operation=='buy'){balance-=totalCost;
          }else{balance+=totalCost;}
          await fetchGlobalTransactions(currentUser!);
          currencyHoldings= await fetchUserInventory(currentUser!);
        } else {
          _showErrorDialog('Failed to submit transaction: ${response.statusCode}');
        }
      } catch (e) {
        _showErrorDialog('An error occurred: $e');
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success', style: TextStyle(color: Colors.black)),
          content: const Text('The transaction was successful.', style: TextStyle(color: Colors.black)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error', style: TextStyle(color: Colors.black)),
          content: Text(message, style: const TextStyle(color: Colors.black)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _clearForm() {
    setState(() {
      _quantityController.clear();
      _courseController.clear();
      _selectedCurrency = null;
      _isDownPressed = false;
      _isUpPressed = false;
      _total = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 25), // Смещение иконки левее
            child: IconButton(
              icon: const Icon(Icons.history, color: Colors.white),
              onPressed: () {
                Navigator.pushNamed(context, '/event'); // Переход на экран событий
              },
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.grey[850],
              ),
              child: const Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.black),
              title: const Text('Porfile',style: TextStyle(color: Colors.black)),
              onTap: (){
                Navigator.pushNamed(context, '/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.currency_exchange, color: Colors.black),
              title: const Text('Currency', style: TextStyle(color: Colors.black)),
              onTap: () async {
                final result = await Navigator.pushNamed(context, '/currencyinf');
                if (result == true) {
                  setState(() {
                    _total = null;
                    _selectedCurrency = null;
                  });
                }
              },
            ),
            // ListTile(
            //   leading: const Icon(Icons.info, color: Colors.black),
            //   title: const Text('Report',style: TextStyle(color: Colors.black)),
            //   onTap: (){},
            // ),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.black),
              title: const Text('Information',style: TextStyle(color: Colors.black)),
              onTap: (){
                Navigator.pushNamed(context, '/information');
              },
            ),
            ListTile(
              leading: const Icon(Icons.group, color: Colors.black),
              title: const Text('Users',style: TextStyle(color: Colors.black)),
              onTap: (){
                Navigator.pushNamed(context, '/users');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.black),
              title: const Text('Logout',style: TextStyle(color: Colors.black)),
              onTap: (){
                logout(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.black),
              title: const Text('Clear',style: TextStyle(color: Colors.black)),
              onTap: (){
                _showClearConfirmationDialog();
              },
            )
          ],
        ),
      ),
      body: Container(
        color: Colors.grey[850],
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isDownPressed = !_isDownPressed;
                      if (_isDownPressed) _isUpPressed = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                  ),
                  child: Icon(
                    Icons.arrow_downward,
                    color: _isDownPressed ? Colors.white : Colors.grey,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isUpPressed = !_isUpPressed;
                      if (_isUpPressed) _isDownPressed = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                  ),
                  child: Icon(
                    Icons.arrow_upward,
                    color: _isUpPressed ? Colors.white : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<String>(
                value: _selectedCurrency,
                items: globalCurrencies.map((currency) {
                  return DropdownMenuItem(
                    value: currency,
                    child: Text(currency, style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
                decoration: const InputDecoration(
                  labelText: 'Currency',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide.none),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide.none),
                ),
                onChanged: (value) {
                  setState(() {
                    _selectedCurrency = value;
                  });
                },
                dropdownColor: Colors.grey[800],
                style: const TextStyle(color: Colors.white),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Quantity',
                hintStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.grey[700],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) {
                _calculateTotal();
                setState(() {});
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _courseController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Rate',
                hintStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.grey[700],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) {
                _calculateTotal();
                setState(() {});
              },
            ),
            const SizedBox(height: 16),
            if (_total != null)
              Text(
                'Total: ${_total!.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isFormValid() ? _submitTransaction : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[700],
                disabledBackgroundColor: Colors.grey[600],
              ),
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}