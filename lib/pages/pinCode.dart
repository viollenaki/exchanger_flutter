import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PinCodeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PinCodeScreen extends StatefulWidget {
  @override
  _PinCodeScreenState createState() => _PinCodeScreenState();
}

class _PinCodeScreenState extends State<PinCodeScreen> {
  List<String> _pin = [];

  void _addDigit(String digit) {
    if (_pin.length < 4) {
      setState(() {
        _pin.add(digit);
      });
    }
  }

  void _removeDigit() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin.removeLast();
      });
    }
  }

  Widget _buildPinCircle(int index, double size) {
    bool filled = index < _pin.length;
    return Container(
      width: size,
      height: size,
      margin: EdgeInsets.symmetric(horizontal: size * 0.4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? Colors.black : Colors.transparent,
        border: Border.all(color: Colors.black, width: 2),
      ),
    );
  }

  Widget _buildKeyboardButton(String value, double fontSize, {IconData? icon}) {
    return GestureDetector(
      onTap: () {
        if (icon != null) {
          _removeDigit();
        } else {
          _addDigit(value);
        }
      },
      child: Container(
        alignment: Alignment.center,
        height: 70,
        child: icon != null
            ? Icon(icon, color: Colors.black, size: fontSize)
            : Text(
                value,
                style: TextStyle(fontSize: fontSize, color: Colors.black),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Light mode background
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth > 600;
          final fontSize = isTablet ? 36.0 : 28.0;
          final pinSize = isTablet ? 30.0 : 20.0;
          final padding = isTablet ? 80.0 : 48.0;

          return SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribute elements
              children: [
                // Back button and header
                Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: Colors.black), // Black back icon
                          onPressed: () {
                            Navigator.pop(context); // Go back to the previous screen
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: isTablet ? 40 : 20),
                    Text(
                      'Создайте пин-код для входа',
                      style: TextStyle(
                        fontSize: isTablet ? 32 : 24,
                        color: Colors.black, // Black text
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (i) => _buildPinCircle(i, pinSize)),
                    ),
                  ],
                ),

                // Numeric keyboard
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  child: Column(
                    children: [
                      for (var row in [
                        ['1', '2', '3'],
                        ['4', '5', '6'],
                        ['7', '8', '9'],
                        ['Забыли?', '0', '<']
                      ])
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: row.map((item) {
                            if (item == '<') {
                              return Expanded(
                                child: _buildKeyboardButton('', fontSize, icon: Icons.backspace_outlined),
                              );
                            } else if (item == 'Забыли?') {
                              return Expanded(
                                child: TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    item,
                                    style: TextStyle(color: Colors.grey[600], fontSize: fontSize * 0.6),
                                  ),
                                ),
                              );
                            } else {
                              return Expanded(
                                child: _buildKeyboardButton(item, fontSize),
                              );
                            }
                          }).toList(),
                        ),
                      SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
