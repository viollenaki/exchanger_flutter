import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreatePinScreen extends StatefulWidget {
  const CreatePinScreen({super.key});

  @override
  _CreatePinScreenState createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  final List<String> _pin = [];
  final List<String> _confirmPin = [];
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
        Navigator.pop(context); // Return to settings
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
                  for (var row in [
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9'],
                    ['<', '0', 'OK']
                  ])
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: row.map((item) {
                        if (item == '<') {
                          return _buildKeyboardButton('', 28,
                              icon: Icons.backspace_outlined);
                        } else if (item == 'OK') {
                          return GestureDetector(
                            onTap: _submitPin,
                            child: const Text(
                              'OK',
                              style: TextStyle(
                                  fontSize: 28, color: Colors.blueAccent),
                            ),
                          );
                        } else {
                          return _buildKeyboardButton(item, 28);
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

  const VerifyPinScreen({this.isForDisablingPin = false, super.key});

  @override
  _VerifyPinScreenState createState() => _VerifyPinScreenState();
}

class _VerifyPinScreenState extends State<VerifyPinScreen> {
  final List<String> _pin = [];
  String? _buttonPressed;

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
