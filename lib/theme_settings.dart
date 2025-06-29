import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeSettingsPage extends StatefulWidget {
  final Function(bool, MaterialColor) onThemeChanged;

  const ThemeSettingsPage({super.key, required this.onThemeChanged});

  @override
  State<ThemeSettingsPage> createState() => _ThemeSettingsPageState();
}

class _ThemeSettingsPageState extends State<ThemeSettingsPage> {
  bool _isDark = false;
  MaterialColor _selectedColor = Colors.indigo;

  final _colors = {
    'Indigo': Colors.indigo,
    'Green': Colors.green,
    'Teal': Colors.teal,
    'Orange': Colors.orange,
    'Purple': Colors.purple,
  };

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDark = prefs.getBool('isDark') ?? false;
      final colorName = prefs.getString('themeColor') ?? 'Indigo';
      _selectedColor = _colors[colorName] ?? Colors.indigo;
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', _isDark);
    await prefs.setString('themeColor', _colors.entries.firstWhere((e) => e.value == _selectedColor).key);
    widget.onThemeChanged(_isDark, _selectedColor);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Theme Settings')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text("Dark Mode"),
              value: _isDark,
              onChanged: (val) {
                setState(() => _isDark = val);
                _savePrefs();
              },
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<MaterialColor>(
              value: _selectedColor,
              decoration: const InputDecoration(labelText: "Theme Color"),
              items: _colors.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.value,
                  child: Text(entry.key),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedColor = val);
                  _savePrefs();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
