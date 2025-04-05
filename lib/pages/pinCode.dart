import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:currencies/globals.dart' as globals;
import 'package:shared_preferences/shared_preferences.dart';

class CreatePinScreen extends StatefulWidget {
  @override
  _CreatePinScreenState createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  List<String> _pin = [];
  List<String> _confirmPin = [];
  bool _isConfirming = false;
  String? _buttonPressed;

  void _addDigit(String digit) {
    setState(() {
      if (_isConfirming) {
        if (_confirmPin.length < 4) _confirmPin.add(digit);
        if (_confirmPin.length == 4) _submitPin(); // Automatically submit
      } else {
        if (_pin.length < 4) _pin.add(digit);
        if (_pin.length == 4) {
          setState(() {
            _isConfirming = true; // Move to confirmation step
          });
        }
      }
    });
  }

  void _removeDigit() {
    setState(() {
      if (_isConfirming) {
        if (_confirmPin.isNotEmpty) _confirmPin.removeLast();
      } else {
        if (_pin.isNotEmpty) _pin.removeLast();
      }
    });
  }

  void _submitPin() async {
    if (_isConfirming) {
      if (_pin.join() == _confirmPin.join()) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pin', _pin.join());
        Navigator.pop(context,true); // Return to settings
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PINs do not match')),
        );
        setState(() {
          _confirmPin.clear();
        });
      }
    } else {
      setState(() {
        _isConfirming = true;
      });
    }
  }

  Widget _buildPinCircle(int index, int length) {
    bool filled = index < length;
    return Container(
      width: 20.0,
      height: 20.0,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? Colors.black : Colors.transparent,
        border: Border.all(color: Colors.black, width: 2),
      ),
    );
  }

  Widget _buildKeyboardButton(String value, double fontSize, {IconData? icon}) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _buttonPressed = value; // Track the pressed button
        });
      },
      onTapUp: (_) {
        setState(() {
          _buttonPressed = null; // Reset the pressed button
        });
      },
      onTap: () {
        if (icon != null) {
          _removeDigit();
        } else {
          _addDigit(value);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        height: 70,
        width: 70,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _buttonPressed == value
              ? Colors.grey[300]
              : Colors.transparent, // Background effect on tap
          boxShadow: _buttonPressed == value
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Header
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 20),
                Text(
                  _isConfirming ? 'Подтвердите пин-код' : 'Создайте пин-код',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    4,
                    (i) => _buildPinCircle(
                      i,
                      _isConfirming ? _confirmPin.length : _pin.length,
                    ),
                  ),
                ),
              ],
            ),
            // Keyboard
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Column(
                children: [
                  // Внутри build → Column → for (var row in ...) → Row(...)

                  for (var row in [
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9'],
                    ['<', '0', ''] // убрали OK, оставили пустое место
                  ])
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: row.map((item) {
                        if (item == '<') {
                          return Expanded(
                            child: _buildKeyboardButton('', 28, icon: Icons.backspace_outlined),
                          );
                        } else if (item.isEmpty) {
                          return const Expanded(child: SizedBox());
                        } else {
                          return Expanded(
                            child: _buildKeyboardButton(item, 28),
                          );
                        }
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VerifyPinScreen extends StatefulWidget {
  final bool isForDisablingPin;

  const VerifyPinScreen({this.isForDisablingPin = false, Key? key})
      : super(key: key);

  @override
  _VerifyPinScreenState createState() => _VerifyPinScreenState();
}

class _VerifyPinScreenState extends State<VerifyPinScreen> {
  List<String> _pin = [];
  String? _buttonPressed;

  Future<void> remindPin() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString('pin');
    final userId = globals.user_id;

    if (userId == null || pin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка: user_id или pin не найдены')),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('https://dair12.pythonanywhere.com/send-pin/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'pin': pin,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message']), backgroundColor: Colors.blue),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['error'] ?? 'Ошибка'), backgroundColor: Colors.red),
      );
    }
  }

  void _addDigit(String digit) {
    if (_pin.length < 4) {
      setState(() {
        _pin.add(digit);
      });
      if (_pin.length == 4) _verifyPin();
    }
  }

  void _removeDigit() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin.removeLast();
      });
    }
  }

  void _verifyPin() async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedPin = prefs.getString('pin');

    if (_pin.join() == storedPin) {
      if (widget.isForDisablingPin) {
        Navigator.pop(context, true); // Return success for disabling PIN
      } else {
        Navigator.pushReplacementNamed(context, '/home'); // Navigate to home
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect PIN')),
      );
      setState(() {
        _pin.clear();
      });
    }
  }

  Widget _buildPinCircle(int index, int pinLength) {
    bool filled = index < pinLength;
    return Container(
      width: 20,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? Colors.black : Colors.transparent,
        border: Border.all(color: Colors.black, width: 2),
      ),
    );
  }

  Widget _buildKeyboardButton(String value, double fontSize, {IconData? icon}) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _buttonPressed = value; // Track the pressed button
        });
      },
      onTapUp: (_) {
        setState(() {
          _buttonPressed = null; // Reset the pressed button
        });
      },
      onTap: () {
        if (icon != null) {
          _removeDigit();
        } else {
          _addDigit(value);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        height: 70,
        width: 70,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _buttonPressed == value
              ? Colors.grey[300]
              : Colors.transparent, // Background effect on tap
          boxShadow: _buttonPressed == value
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Header
            Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  widget.isForDisablingPin
                      ? 'Введите текущий пин-код'
                      : 'Введите пин-код',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:
                      List.generate(4, (i) => _buildPinCircle(i, _pin.length)),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: remindPin,
                  child: const Text(
                    'Remind PIN code',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 16,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            // Keyboard
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Column(
                children: [
                  for (var row in [
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9'],
                    ['<', '0', '']
                  ])
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: row.map((item) {
                        if (item == '<') {
                          return Expanded(
                            child: _buildKeyboardButton('', 28,
                                icon: Icons.backspace_outlined),
                          );
                        } else if (item.isEmpty) {
                          return const Expanded(child: SizedBox());
                        } else {
                          return Expanded(
                            child: _buildKeyboardButton(item, 28),
                          );
                        }
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
