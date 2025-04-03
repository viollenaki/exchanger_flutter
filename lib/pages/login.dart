import 'package:flutter/material.dart';
import '../main.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _checkUsersAndLogin(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });
    await _login(context);

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _login(BuildContext context) async {
    final response = await http.post(
      Uri.parse('https://dair12.pythonanywhere.com/get_password_by_username/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'user': _usernameController.text}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['password'] == _passwordController.text) {
        await http.post(
          Uri.parse('https://dair12.pythonanywhere.com/login_user/'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'username': _usernameController.text}),
        );
        currentUser = _usernameController.text;
        balance = data['balance'];
        await fetchGlobalCurrencies();
        fetchUsers();
        await fetchGlobalTransactions(currentUser!);
        currencyHoldings = await fetchUserInventory(currentUser!);
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid username or password')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error logging in')),
      );
    }
  }

  void _showRegistrationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController _newUserController = TextEditingController();
        final TextEditingController _newPasswordController = TextEditingController();

        return AlertDialog(
          title: const Text('Register New User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _newUserController,
                decoration: const InputDecoration(hintText: 'Username'),
              ),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'Password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final newUser = _newUserController.text;
                final newPassword = _newPasswordController.text;

                if (newUser.isNotEmpty && newPassword.isNotEmpty) {
                  final response = await http.post(
                    Uri.parse('https://dair12.pythonanywhere.com/add_user/'),
                    headers: {'Content-Type': 'application/json'},
                    body: json.encode({'user': newUser, 'password': newPassword}),
                  );

                  if (response.statusCode == 200) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User registered successfully')),
                    );
                  } else {
                    print(response.statusCode);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error registering user')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill out all fields')),
                  );
                }
              },
              child: const Text('Register'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[850],
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Login',
                    style: TextStyle(fontSize: 32, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      hintText: 'Username',
                      filled: true,
                      fillColor: Colors.grey[300],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      filled: true,
                      fillColor: Colors.grey[300],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                    onPressed: () => _checkUsersAndLogin(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    ),
                    child: const Text('Login'),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.person_add, color: Colors.white),
              onPressed: () => _showRegistrationDialog(context),
            ),
          ),
        ],
      ),
    );
  }
}
