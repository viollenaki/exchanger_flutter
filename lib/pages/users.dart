import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart';
import 'dart:async';

class Users extends StatefulWidget {
  const Users({super.key});

  @override
  State<Users> createState() => _UsersState();
}

class _UsersState extends State<Users> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }
  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      fetchUsers().then((_) {
        setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Остановка таймера при закрытии окна
    super.dispose();
  }


  Future<void> addUser(String username, String password) async {
    final url = Uri.parse('https://dair12.pythonanywhere.com/add_user/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user': username.replaceAll(' ', ''), 'password': password}),
      );
      if (response.statusCode == 200) {
      } else {
        throw Exception('Failed to add user');
      }
    } catch (e) {
      print('Error adding user: $e');
    }
  }

  Future<void> deleteUser(String username) async {
    final url = Uri.parse('https://dair12.pythonanywhere.com/delete_user/');
    try {
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user': username}),
      );
      if (response.statusCode == 200) {
      } else {
        throw Exception('Failed to delete user');
      }
    } catch (e) {
      print('Error deleting user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            size: 30,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Users',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          Transform.translate(
            offset: const Offset(-20.0, 0.0), // Сдвиг влево на 8 пикселей
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Text(
                  '$onlineUsers/$totalUsers',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
        backgroundColor: Colors.grey[850],
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: users.isEmpty
                  ? const Center(
                child: CircularProgressIndicator(),
              )
                  : ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  return _buildUserTile(users[index]);
                },
              ),

            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _showAddUserDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[400],
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildUserTile(Map<String, bool> user) {
    final String name = user.keys.first;
    final bool isOnline = user.values.first;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          if (name == currentUser) // Проверяем, совпадает ли имя с currentUser
            Transform.translate(
              offset: const Offset(-8.0, 0), // Сдвиг влево на 8 пикселей
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'You',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          else if (isOnline) // Если пользователь онлайн Online
            Transform.translate(
              offset: const Offset(-8.0, 0), // Сдвиг влево на 8 пикселей
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Online',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          else // В остальных случаях показываем иконку удаления
            IconButton(
              onPressed: () {
                _showDeleteConfirmationDialog(name);
              },
              icon: const Icon(
                Icons.delete,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }




  void _showAddUserDialog() {
    String username = '';
    String password = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) {
                  username = value;
                },
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              TextField(
                onChanged: (value) {
                  password = value;
                },
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  totalUsers+=1;
                  users.add({username:false});});
                addUser(username, password);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }


  void _showDeleteConfirmationDialog(String username) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this user?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  totalUsers-=1;
                  users.removeWhere((user) => user.keys.first == username);});
                deleteUser(username);
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }
}