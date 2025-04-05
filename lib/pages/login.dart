import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Для обработки JSON
import 'package:shared_preferences/shared_preferences.dart'; // For local storage
import '../globals.dart'; // Import globals.dart

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final PageController _pageController =
      PageController(); // Контроллер для переключения страниц
  int _tabIndex = 0; // Индекс текущей вкладки (Login или Register)
  String? _errorMessage;
  String? _successMessage;
  // Login
  final TextEditingController _loginUsernameController =
      TextEditingController();
  final TextEditingController _loginPasswordController =
      TextEditingController();

// Register
  final TextEditingController _regUsernameController = TextEditingController();
  final TextEditingController _regEmailController = TextEditingController();
  final TextEditingController _regPasswordController = TextEditingController();
  final TextEditingController _regConfirmPasswordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkSavedCredentials(); // Check for saved credentials on app launch
  }

  Future<void> _sendResetPasswordRequest(String email) async {
    if (email.isEmpty) {
      setState(() {
        _errorMessage = "Email is required to reset password";
      });
      return;
    }

    final url =
        Uri.parse("https://dair12.pythonanywhere.com/request_password_reset/");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _errorMessage = null;
          _successMessage = responseData['message'];
        });

        // Показать синее сообщение
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message']),
            backgroundColor: Colors.blueAccent,
          ),
        );

        // Вернуться на вкладку Login
        _pageController.jumpToPage(0);
        setState(() {
          _tabIndex = 0;
        });
      } else {
        setState(() {
          _errorMessage = responseData['error'] ?? 'An error occurred.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to connect to server: $e';
      });
    }
  }

  void _showResetPasswordDialog() {
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Reset Password"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Enter your email"),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  hintText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Закрыть окно
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final email = emailController.text.trim();
                Navigator.pop(context); // Закрыть окно
                _sendResetPasswordRequest(email);
              },
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
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
      if (username.isEmpty || password.isEmpty) {
        setState(() {
          _errorMessage = 'Please fill in all fields';
        });
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

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (responseData.containsKey('message')) {
          // Save login response to globals
          user_id = responseData['id'].toString();
          username = responseData['user'];
          email = responseData['email'];

          // Успешный вход
          setState(() {
            _errorMessage = null;
            _successMessage = null;
          });

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('username', username);
          await prefs.setString('password', password);
          await prefs.setString('user_id', responseData['id'].toString());
          await prefs.setString('email', responseData['email']);

          Navigator.pushReplacementNamed(context, '/home', arguments: {
            'id': responseData['id'],
            'email': responseData['email'],
            'balance': responseData['balance'],
          });
        }
      } else {
        // Сервер вернул ошибку
        setState(() {
          _errorMessage = responseData['error'] ?? 'Unknown error occurred.';
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _errorMessage = 'Failed to connect to the server: $e';
      });
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
          setState(() {
            _tabIndex = index; // Обновление текущего индекса вкладки
            _errorMessage = null;
            _successMessage = null;
          });
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
    final theme = Theme.of(context); // Access current theme
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller, // Контроллер для получения текста
        obscureText: obscure, // Скрытие текста (например, для пароля)
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: theme.primaryColor), // Use theme color
          hintText: hint, // Подсказка
          filled: true,
          fillColor: theme.inputDecorationTheme.fillColor, // Use theme color
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
    // используй контроллеры из state:
    final usernameController = _loginUsernameController;
    final passwordController = _loginPasswordController;

    return SingleChildScrollView(
        child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildTextInput(Icons.person, "Username",
              controller: usernameController), // Поле ввода имени пользователя
          _buildTextInput(Icons.lock, "Password",
              obscure: true,
              controller: passwordController), // Поле ввода пароля
          if (_successMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                _successMessage!,
                style: const TextStyle(color: Colors.blueAccent, fontSize: 14),
              ),
            ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
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
          TextButton(
            onPressed: () => _showResetPasswordDialog(),
            child: const Text(
              "Reset password",
              style: TextStyle(color: Colors.blueAccent),
            ),
          ),
        ],
      ),
    ));
  }

  // Форма для регистрации
  Widget _buildRegisterForm() {
    final usernameController = _regUsernameController;
    final emailController = _regEmailController;
    final passwordController = _regPasswordController;
    final confirmPasswordController = _regConfirmPasswordController;

    // Функция для регистрации пользователя
    Future<void> _registerUser() async {
      final String username = usernameController.text.trim();
      final String email = emailController.text.trim();
      final String password = passwordController.text.trim();
      final String confirmPassword = confirmPasswordController.text.trim();

      if (username.isEmpty ||
          email.isEmpty ||
          password.isEmpty ||
          confirmPassword.isEmpty) {
        setState(() {
          _errorMessage = 'Please fill in all fields';
        });
        return;
      }

      if (password != confirmPassword) {
        setState(() {
          _errorMessage = 'Passwords do not match';
        });
        return;
      }

      final url = Uri.parse("https://dair12.pythonanywhere.com/add_user/");
      try {
        final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "user": username,
            "password": password,
            "email": email,
          }),
        );

        final responseData = jsonDecode(response.body);

        if (response.statusCode == 200) {
          setState(() {
            _errorMessage = null;
            _successMessage = responseData['message'];
          });

          // Можно показать SnackBar об успехе или перейти во вкладку логина
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Registration successful: ${responseData['message']}')),
          );

          // Переключиться на логин-вкладку:
          _pageController.jumpToPage(0);
        } else {
          setState(() {
            _errorMessage = responseData['error'] ?? 'Registration failed';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Failed to connect to server: $e';
        });
      }
    }

    return SingleChildScrollView(
        child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildTextInput(Icons.person, "Username",
              controller: usernameController),
          _buildTextInput(Icons.email, "Email", controller: emailController),
          _buildTextInput(Icons.lock, "Password",
              obscure: true, controller: passwordController),
          _buildTextInput(Icons.lock_outline, "Confirm Password",
              obscure: true, controller: confirmPasswordController),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _registerUser,
            child:
                const Text("Register", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Access current theme
    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor, // Use scaffoldBackgroundColor
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
                                          onPageChanged: (index) {
                                            setState(() {
                                              _tabIndex = index;
                                              _errorMessage = null;
                                              _successMessage = null;
                                            });
                                          },
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
