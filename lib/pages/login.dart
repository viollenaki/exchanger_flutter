import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Для обработки JSON
import 'package:shared_preferences/shared_preferences.dart'; // For local storage

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final PageController _pageController =
      PageController(); // Контроллер для переключения страниц
  int _tabIndex = 0; // Индекс текущей вкладки (Login или Register)

  @override
  void initState() {
    super.initState();
    _checkSavedCredentials(); // Check for saved credentials on app launch
  }

  Future<void> _checkSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedUsername = prefs.getString('username');
    final String? savedPassword = prefs.getString('password');

    if (savedUsername != null && savedPassword != null) {
      _loginUser(savedUsername, savedPassword, autoLogin: true);
    }
  }

  Future<void> _loginUser(String username, String password,
      {bool autoLogin = false}) async {
    if (!autoLogin) {
      // Manual login: validate input fields
      if (username.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all fields')),
        );
        return;
      }
    }

    final url = Uri.parse("https://dair12.pythonanywhere.com/login_user/");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "identifier": username,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData.containsKey('message')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message'])),
          );

          // Save user credentials locally
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('username', username);
          await prefs.setString('password', password);

          // Navigate to home page
          final int userId = responseData['id'];
          final String userEmail = responseData['email'];
          final double userBalance = responseData['balance'];

          Navigator.pushReplacementNamed(context, '/home', arguments: {
            'id': userId,
            'email': userEmail,
            'balance': userBalance,
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid login credentials')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect to the server: $e')),
      );
    }
  }

  // Виджет для отображения вкладок (Login и Register)
  Widget _buildMainTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _tabButton('Login', 0), // Кнопка для вкладки Login
          const SizedBox(width: 4),
          _tabButton('Register', 1), // Кнопка для вкладки Register
        ],
      ),
    );
  }

  // Виджет для кнопки вкладки
  Widget _tabButton(String title, int index) {
    final bool selected = _tabIndex == index; // Проверка, выбрана ли вкладка

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(
              () => _tabIndex = index); // Обновление текущего индекса вкладки
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: selected ? Colors.blueAccent : Colors.blue[900],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Виджет для текстового поля ввода
  Widget _buildTextInput(IconData icon, String hint,
      {bool obscure = false, TextEditingController? controller}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller, // Контроллер для получения текста
        obscureText: obscure, // Скрытие текста (например, для пароля)
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.blue), // Иконка перед текстом
          hintText: hint, // Подсказка
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // Форма для входа
  Widget _buildLoginForm() {
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildTextInput(Icons.person, "Username",
              controller: usernameController), // Поле ввода имени пользователя
          _buildTextInput(Icons.lock, "Password",
              obscure: true,
              controller: passwordController), // Поле ввода пароля
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => _loginUser(usernameController.text.trim(),
                passwordController.text.trim()), // Вызов функции входа
            child: const Text("Login", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Форма для регистрации
  Widget _buildRegisterForm() {
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    // Функция для регистрации пользователя
    Future<void> _registerUser() async {
      final String username = usernameController.text;
      final String email = emailController.text;
      final String password = passwordController.text;
      final String confirmPassword = confirmPasswordController.text;

      if (password != confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Passwords do not match')), // Проверка совпадения паролей
        );
        return;
      }

      final url = Uri.parse("https://dair12.pythonanywhere.com/add_user/");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user": username,
          "password": password,
          "email": email,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Registration successful: ${responseData['message']}')),
        );
      } else {
        final responseData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${responseData['error']}')),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildTextInput(Icons.person, "Username",
              controller: usernameController), // Поле ввода имени пользователя
          _buildTextInput(Icons.email, "Email",
              controller: emailController), // Поле ввода email
          _buildTextInput(Icons.lock, "Password",
              obscure: true,
              controller: passwordController), // Поле ввода пароля
          _buildTextInput(Icons.lock_outline, "Confirm Password",
              obscure: true,
              controller:
                  confirmPasswordController), // Поле подтверждения пароля
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _registerUser, // Вызов функции регистрации
            child:
                const Text("Register", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1), // Синий фон
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isLandscape = constraints.maxWidth >
                constraints.maxHeight; // Проверка ориентации экрана

            return Column(
              children: [
                const SizedBox(height: 30),
                if (!isLandscape)
                  const Text(
                    'Welcome', // Приветственное сообщение
                    style: TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (!isLandscape) const SizedBox(height: 10),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(40)), // Скругленные углы
                    ),
                    child: isLandscape
                        ? Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Welcome',
                                        style: TextStyle(
                                          fontSize: 28,
                                          color: Colors.blueAccent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      _buildMainTabs(), // Вкладки Login и Register
                                      const SizedBox(height: 20),
                                      Expanded(
                                        child: PageView(
                                          controller: _pageController,
                                          onPageChanged: (index) =>
                                              setState(() => _tabIndex = index),
                                          children: [
                                            _buildLoginForm(), // Форма логина
                                            _buildRegisterForm(), // Форма регистрации
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Container(
                                  alignment: Alignment.center,
                                  // Дополнительное содержимое
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 20),
                              _buildMainTabs(), // Вкладки Login и Register
                              const SizedBox(height: 20),
                              Expanded(
                                child: PageView(
                                  controller: _pageController,
                                  onPageChanged: (index) =>
                                      setState(() => _tabIndex = index),
                                  children: [
                                    _buildLoginForm(), // Форма логина
                                    _buildRegisterForm(), // Форма регистрации
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
