import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../globals.dart';
import 'package:currencies/pages/settings.dart';
import 'package:currencies/pages/addCurrencyScreen.dart';
import 'eventHistory.dart';
import 'package:currencies/widgets/custom_drawer.dart';
import 'information.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentIndex = 0;
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController courseController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController currencyController = TextEditingController();
  String? userId; // Add userId variable

  bool isBuySelected = true;
  List<dynamic> currencies = [];
  List<String> filteredCurrencies = [];
  bool isLoading = false;
  String? message;
  bool isError = false;
  final _formKey = GlobalKey<FormState>();

  final Color warmBlue = const Color(0xFF4B607F);
  final Color brightGreen = const Color(0xFF4CAF50);
  final Color brightRed = const Color(0xFFF44336);

  @override
  void initState() {
    super.initState();
    _loadCurrencies();
    _getUserId(); // Get user ID on initialization
    currencyController.addListener(_updateForm);
    quantityController.addListener(_updateForm);
    courseController.addListener(_updateForm);
    descriptionController.addListener(_updateForm);
  }

  @override
  void dispose() {
    currencyController.removeListener(_updateForm);
    quantityController.removeListener(_updateForm);
    courseController.removeListener(_updateForm);
    descriptionController.removeListener(_updateForm);
    super.dispose();
  }

  void _updateForm() => setState(() {});

  // Add method to get user ID from SharedPreferences
  Future<void> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('user_id');
    });
  }

  Future<void> _loadCurrencies() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final localUserId = prefs.getString('user_id');

      final response = await http.post(
        Uri.parse('https://dair12.pythonanywhere.com/list_currencies/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': localUserId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          currencies = data;
          filteredCurrencies =
              data.map<String>((c) => c[1].toString()).toList();
        });
      }
    } catch (e) {
      print('Error loading currencies: $e');
    }
    setState(() => isLoading = false);
  }

  Future<void> _submitTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      message = null;
      isError = false;
    });

    final selectedCurrency = currencies.firstWhere(
      (c) => c[1] == currencyController.text,
      orElse: () => null,
    );

    if (selectedCurrency == null) {
      setState(() {
        message = 'Error: Invalid currency selected';
        isError = true;
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final localUserId = prefs.getString('user_id');

    final transaction = {
      'operation': isBuySelected ? 'buy' : 'sell',
      'currency': selectedCurrency[1],
      'quantity': quantityController.text,
      'rate': courseController.text,
      'user_id': localUserId,
      'description': descriptionController.text,
      'created_at': DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
    };

    try {
      final response = await http.post(
        Uri.parse('https://dair12.pythonanywhere.com/transaction/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(transaction),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        // Очищаем поля кроме валюты
        quantityController.clear();
        courseController.clear();
        descriptionController.clear();

        setState(() {
          message = 'Операция прошла успешно!';
          isError = false;
        });
      } else {
        throw Exception(responseData['error'] ?? 'Unknown error');
      }
    } catch (e) {
      setState(() {
        message = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
        isError = true;
      });
    }
  }

  Widget _buildCurrencySearch() {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) return const Iterable.empty();
        return filteredCurrencies.where((currency) => currency
            .toLowerCase()
            .contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: (String value) {
        currencyController.text = value;
        setState(() {});
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        // Синхронизируем контроллер автозаполнения с currencyController
        if (controller.text != currencyController.text) {
          controller.text = currencyController.text;
        }

        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Валюта',
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      // Очищаем оба контроллера
                      controller.clear();
                      currencyController.clear();
                      setState(() {
                        filteredCurrencies = currencies
                            .map<String>((c) => c[1].toString())
                            .toList();
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.grey[200],
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (value) {
            // Поддерживаем синхронизацию с currencyController
            currencyController.text = value;
            setState(() {
              filteredCurrencies = currencies
                  .map<String>((c) => c[1].toString())
                  .where((currency) =>
                      currency.toLowerCase().contains(value.toLowerCase()))
                  .toList();
            });
          },
          validator: (value) =>
              value!.isEmpty ? 'Пожалуйста, выберите валюту' : null,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.3,
                minWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    title: Text(option),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  bool get _isFormValid {
    return currencyController.text.isNotEmpty &&
        quantityController.text.isNotEmpty &&
        courseController.text.isNotEmpty &&
        descriptionController.text.isNotEmpty &&
        _formKey.currentState?.validate() == true;
  }

  Widget _buildBuySellPage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Form(
          key: _formKey,
          child: Column(
            children: [
              SizedBox(
                height: constraints.maxHeight * 0.20,
                width: double.infinity,
                child: Image.asset(
                  'assets/background.jpg',
                  fit: BoxFit.cover,
                ),
              ),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _toggleButton(
                              "Купить",
                              isBuySelected,
                              () => setState(() => isBuySelected = true),
                              brightGreen,
                            ),
                            _toggleButton(
                              "Продать",
                              !isBuySelected,
                              () => setState(() => isBuySelected = false),
                              brightRed,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildCurrencySearch(),
                        const SizedBox(height: 16),
                        _inputField(
                          controller: quantityController,
                          hint: 'Amount',
                          isNumber: true,
                          isInteger: true,
                        ),
                        const SizedBox(height: 16),
                        _inputField(
                          controller: courseController,
                          hint: 'Exchange Rate',
                          isNumber: true,
                        ),
                        const SizedBox(height: 16),
                        _inputField(
                          controller: descriptionController,
                          hint: 'Description',
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isFormValid ? _submitTransaction : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _isFormValid ? warmBlue : Colors.grey[400],
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
                        if (message != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              message!,
                              style: TextStyle(
                                color: isError ? Colors.red : Colors.green,
                                fontSize: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _toggleButton(
      String label, bool isActive, VoidCallback onTap, Color activeColor) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 45,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    bool isNumber = false,
    bool isInteger = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber
          ? (isInteger
              ? TextInputType.number
              : TextInputType.numberWithOptions(decimal: true))
          : TextInputType.text,
      inputFormatters: isNumber
          ? [if (isInteger) FilteringTextInputFormatter.digitsOnly]
          : null,
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: Colors.grey[200],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) {
        if (value!.isEmpty) return 'Это поле обязательно';
        if (isNumber) {
          if (isInteger) {
            if (int.tryParse(value) == null) return 'Только целые числа';
          } else {
            if (double.tryParse(value) == null) return 'Некорректный формат';
          }
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CustomDrawer(drawerHeaderColor: warmBlue),
      body: Stack(
        children: [
          _buildCurrentPage(),
          if (_currentIndex == 0)
            Positioned(
              top: 48,
              left: 16,
              child: Builder(
                builder: (context) => GestureDetector(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  child: const Icon(
                    Icons.menu,
                    size: 35,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
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

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return _buildBuySellPage();
      case 1:
        return const Event();
      case 2:
        return const Information();
      case 3:
        return const SettingsHeaderScreen();
      default:
        return _buildBuySellPage();
    }
  }
}
