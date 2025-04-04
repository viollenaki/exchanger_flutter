import 'package:currencies/pages/pinCode.dart';
import 'package:flutter/material.dart';
import 'package:currencies/pages/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:currencies/theme/theme_provider.dart';
import 'package:currencies/widgets/custom_drawer.dart';

void main() {
  runApp(const MaterialApp(
    home: SettingsHeaderScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

class SettingsHeaderScreen extends StatefulWidget {
  const SettingsHeaderScreen({super.key});

  @override
  _SettingsHeaderScreenState createState() => _SettingsHeaderScreenState();
}

class _SettingsHeaderScreenState extends State<SettingsHeaderScreen> {
  String selectedTheme = 'Светлая'; // Default selected theme
  bool isPinEnabled = false; // Default state for PIN toggle

  @override
  void initState() {
    super.initState();
    _loadPinState();
  }

  Future<void> _loadPinState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isPinEnabled = prefs.containsKey('pin'); // Check if PIN exists
    });
  }

  Future<void> _handlePinToggle(bool newValue) async {
    final prefs = await SharedPreferences.getInstance();

    if (newValue) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CreatePinScreen()),
      );
      if (result == true) {
        setState(() {
          isPinEnabled = prefs.containsKey('pin');
        });
      }
    } else {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const VerifyPinScreen(
            isForDisablingPin: true,
          ),
        ),
      );
      if (result == true) {
        await prefs.remove('pin');
        setState(() {
          isPinEnabled = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> settingsItems = [
      {
        'icon': Icons.language,
        'title': 'Язык',
        'onTap': (BuildContext context) {
          _showLanguageSelection(context);
        },
      },
      {
        'icon': Icons.color_lens_outlined,
        'title': 'Тема',
        'onTap': (BuildContext context) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Settings()),
          );
        },
      },
      {
        'icon': Icons.pin,
        'title': "Пин-код",
        'onTap': null, // Handled by toggle switch
      },
      {
        'icon': Icons.logout,
        'title': 'Выйти',
        'onTap': (BuildContext context) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Подтверждение'),
                content: const Text('Вы уверены, что хотите выйти?'),
                actions: [
                  TextButton(
                    child: const Text('Отмена'),
                    onPressed: () {
                      Navigator.of(context).pop(); // Закрыть диалог
                    },
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    child: const Text('Выйти',
                        style: TextStyle(color: Colors.white)),
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('pin');
                      await prefs.remove('username');
                      await prefs.remove('password');

                      Navigator.of(context).pop(); // Закрыть диалог
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const Login()),
                        (Route<dynamic> route) => false,
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isTablet = constraints.maxWidth > 600;
          final double horizontalPadding = isTablet ? 64 : 16;
          final double headerHeight = isTablet ? 180 : 140;
          final double titleFontSize = isTablet ? 26 : 22;

          return Column(
            children: [
              // Header with wave
              ClipPath(
                clipper: WaveClipper(),
                child: Container(
                  height: headerHeight,
                  width: double.infinity,
                  color: Colors.blueAccent,
                  child: SafeArea(
                    child: Stack(
                      children: [
                        // Back button
                        // Positioned(
                        //   left: 16,
                        //   top: 16,
                        //   child: IconButton(
                        //     icon: const Icon(Icons.arrow_back,
                        //         color: Colors.white),
                        //     onPressed: () {
                        //       Navigator.pop(
                        //           context); // Navigate back to the previous screen
                        //     },
                        //   ),
                        // ),
                        // Title
                        Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: Text(
                              "Настройки",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Settings list
              Expanded(
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 600),
                    padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding, vertical: 12),
                    child: ListView.builder(
                      itemCount: settingsItems.length,
                      itemBuilder: (context, index) {
                        final item = settingsItems[index];
                        if (item['title'] == 'Тема') {
                          return _buildThemeDropdown(selectedTheme, (newTheme) {
                            setState(() {
                              selectedTheme = newTheme;
                            });
                            debugPrint('Selected Theme: $selectedTheme');
                          });
                        }
                        if (item['title'] == 'Пин-код') {
                          return _buildPinToggle(
                              isPinEnabled, _handlePinToggle);
                        }
                        return SettingsItem(
                          icon: item['icon'],
                          title: item['title'],
                          onTap: () {
                            if (item['onTap'] != null) {
                              item['onTap'](context);
                            } else {
                              debugPrint('Tapped on ${item['title']}');
                            }
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Custom Dropdown visually consistent with other items
  Widget _buildThemeDropdown(
      String selectedTheme, ValueChanged<String> onChanged) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.color_lens_outlined,
                color: Colors.blueAccent, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedTheme,
                isExpanded: true,
                icon: const SizedBox.shrink(), // Hide default dropdown icon
                items: ['Светлая', 'Тёмная']
                    .map((theme) => DropdownMenuItem<String>(
                          value: theme,
                          child: Text(
                            theme,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ))
                    .toList(),
                onChanged: (value) => onChanged(value!),
              ),
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
        ],
      ),
    );
  }

  Widget _buildPinToggle(bool isPinEnabled, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.pin, color: Colors.blueAccent, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Пин-код',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Switch(
            value: isPinEnabled,
            onChanged: onChanged,
            activeColor: Colors.blueAccent,
          )
        ],
      ),
    );
  }

  void _showLanguageSelection(BuildContext context) {
    String selectedLanguage = 'Русский';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Язык приложения',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  RadioListTile<String>(
                    title: const Text('Русский'),
                    value: 'Русский',
                    groupValue: selectedLanguage,
                    onChanged: (value) {
                      setState(() {
                        selectedLanguage = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('English'),
                    value: 'English',
                    groupValue: selectedLanguage,
                    onChanged: (value) {
                      setState(() {
                        selectedLanguage = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Қазақша'),
                    value: 'Қазақша',
                    groupValue: selectedLanguage,
                    onChanged: (value) {
                      setState(() {
                        selectedLanguage = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        debugPrint('Selected Language: $selectedLanguage');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Сохранить',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// Виджет одного пункта настройки
class SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const SettingsItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.blueAccent, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}

// Волнистая форма заголовка
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 10);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 35,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class Settings extends StatelessWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      drawer: CustomDrawer(
        drawerHeaderColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appearance Settings
            _buildSectionHeader(context, 'Внешний вид'),
            _buildSettingsCard(
              context,
              Column(
                children: [
                  _buildSettingRow(
                    context,
                    'Темный режим',
                    Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (value) {
                        themeProvider.toggleTheme();
                      },
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Security Settings
            _buildSectionHeader(context, 'Безопасность'),
            _buildSettingsCard(
              context,
              Column(
                children: [
                  _buildSettingRow(
                    context,
                    'PIN-код',
                    IconButton(
                      icon: Icon(Icons.arrow_forward_ios, size: 18),
                      onPressed: () {
                        Navigator.pushNamed(context, '/createPin');
                      },
                    ),
                  ),
                  Divider(),
                  _buildSettingRow(
                    context,
                    'Отпечаток пальца',
                    Switch(
                      value: false, // Replace with actual fingerprint state
                      onChanged: (value) {
                        // Implementation for fingerprint toggle
                      },
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Language Settings
            _buildSectionHeader(context, 'Язык и регион'),
            _buildSettingsCard(
              context,
              Column(
                children: [
                  _buildSettingRow(
                    context,
                    'Язык приложения',
                    DropdownButton<String>(
                      value: 'Русский',
                      underline: SizedBox(),
                      items: ['Русский', 'English'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        // Implementation for language change
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // About Section
            _buildSectionHeader(context, 'О приложении'),
            _buildSettingsCard(
              context,
              Column(
                children: [
                  _buildSettingRow(
                    context,
                    'Версия',
                    Text('1.0.0', style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, Widget content) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: content,
      ),
    );
  }

  Widget _buildSettingRow(BuildContext context, String title, Widget trailing) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 16),
          ),
          trailing,
        ],
      ),
    );
  }
}
