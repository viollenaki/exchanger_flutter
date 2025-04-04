import 'package:flutter/material.dart';

class CurrencyScreen extends StatelessWidget {
  const CurrencyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Курсы валют'),
        backgroundColor: Colors.blueAccent,
      ),
      body: const Center(
        child: Text(
          'Пустое окно',
          style: TextStyle(fontSize: 24, color: Colors.black54),
        ),
      ),
    );
  }
}