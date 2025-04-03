import 'package:flutter/material.dart';
import 'package:currencies/pages/home.dart';
import 'package:currencies/pages/event.dart';
import 'package:currencies/pages/infoсurrency.dart';
import 'package:currencies/pages/information.dart';
import 'package:currencies/pages/users.dart';
import 'package:currencies/pages/login.dart';
import 'package:currencies/pages/profile.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

//global

Future<void> logout(BuildContext context) async {
  if (currentUser != null) {
    await http.post(
      Uri.parse('https://dair12.pythonanywhere.com/logout_user/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': currentUser}),
    );
  }
  Navigator.pushNamed(context, '/');
}

List<Map<String, bool>> users = [];
int totalUsers = 0;
int onlineUsers = 0;
Future<void> fetchUsers() async {
  final url = Uri.parse('https://dair12.pythonanywhere.com/get_all_users/');
  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      // Преобразование данных в нужный формат
      users = data.map<Map<String, bool>>((item) {
        return {
          item['user']: item['is_online'],
        };
      }).toList();
      totalUsers = users.length;
      onlineUsers = users.where((user) => user.values.first).length;
    } else {
      throw Exception('Failed to load users');
    }
  } catch (e) {
    print('Error fetching users: $e');
  }
}


String? currentUser;
double balance = 1000;
Map<String, int> currencyHoldings = {};
Future<Map<String, int>> fetchUserInventory(String username) async {
  // URL вашего API
  const String apiUrl = 'https://dair12.pythonanywhere.com/get_user_inventory/';

  try {
    // Отправка POST-запроса с именем пользователя
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user': username}),
    );

    // Проверка статуса ответа
    if (response.statusCode == 200) {
      // Парсинг ответа
      final List<dynamic> inventoryData = jsonDecode(response.body)['inventory'];

      // Преобразование списка в Map<String, int>
      Map<String, int> currencyHoldings = {
        for (var item in inventoryData) item['currency']: (item['quantity'] as num).toInt()
      };

      return currencyHoldings;
    } else {
      throw Exception('Failed to fetch inventory: ${response.body}');
    }
  } catch (e) {
    throw Exception('Error fetching inventory: $e');
  }
}

List<String> globalCurrencies = [];

Future<void> fetchGlobalCurrencies() async {
  final response = await http.get(Uri.parse('https://dair12.pythonanywhere.com/list_currencies/'));
  globalCurrencies = List<String>.from(json.decode(response.body));
}

List<Map<String, dynamic>> globalTransactions = [];

Future<void> fetchGlobalTransactions(String user) async {
  final url = Uri.parse('https://dair12.pythonanywhere.com/transactions/');
  final response = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({'user': user}),
  );

  if (response.statusCode == 200) {
    globalTransactions = List<Map<String, dynamic>>.from(json.decode(response.body));
  } else {
    print('Failed to fetch transactions');
  }
}

List<Map<String, dynamic>> globalInform = [];

Future<void> fetchGlobalInform() async {
  Map<String, Map<String, dynamic>> currencyData = {};

  for (var transaction in globalTransactions) {
    String currency = transaction['currency'];
    String operation = transaction['operation'];
    double quantity = transaction['quantity'] * 1.0;
    double rate = transaction['rate'] * 1.0;
    double amount = quantity * rate;

    if (!currencyData.containsKey(currency)) {
      currencyData[currency] = {
        'sales': 0.0,
        'salesCount': 0,
        'salesTotal': 0.0,
        'purchases': 0.0,
        'purchasesCount': 0,
        'purchasesTotal': 0.0
      };
    }

    if (operation == 'sell') {
      currencyData[currency]!['sales'] += amount;
      currencyData[currency]!['salesCount'] += 1;
      currencyData[currency]!['salesTotal'] += quantity;
    } else if (operation == 'buy') {
      currencyData[currency]!['purchases'] += amount;
      currencyData[currency]!['purchasesCount'] += 1;
      currencyData[currency]!['purchasesTotal'] += quantity;
    }
  }

  globalInform.clear();

  currencyData.forEach((currency, data) {
    double salesAverage = data['salesCount'] > 0
        ? data['sales'] / data['salesTotal']
        : 0.0;
    double purchasesAverage = data['purchasesCount'] > 0
        ? data['purchases'] / data['purchasesTotal']
        : 0.0;
    double profit = data['salesTotal']*(salesAverage-purchasesAverage);//data['sales'] - data['purchases'];

    globalInform.add({
      'Currency': currency,
      'Sales': data['sales'].toStringAsFixed(2),
      'Average sales': salesAverage.toStringAsFixed(2),
      'Purchases': data['purchases'].toStringAsFixed(2),
      'Average purchases': purchasesAverage.toStringAsFixed(2),
      'Profit': profit.toStringAsFixed(2)
    });
  });
}
//______

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await fetchGlobalCurrencies();
  fetchUsers();

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
  initialRoute: '/',
  routes:{
    '/':(context)=>Login(),
    '/home':(context)=>Home(),
    '/event':(context)=>Event(),
    '/currencyinf':(context)=>Currency(),
    '/information':(context)=>Information(),
    '/users':(context)=>Users(),
    '/profile':(context)=>Profile()
  },
));}