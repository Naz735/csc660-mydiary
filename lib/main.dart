import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart' show SharedPreferences;
import 'homepage.dart';
import 'login.dart';
import 'theme_settings.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDark = false;
  MaterialColor _themeColor = Colors.indigo;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDark') ?? false;
    final colorName = prefs.getString('themeColor') ?? 'Indigo';

    final colorMap = {
      'Indigo': Colors.indigo,
      'Green': Colors.green,
      'Teal': Colors.teal,
      'Orange': Colors.orange,
      'Purple': Colors.purple,
    };

    setState(() {
      _isDark = isDark;
      _themeColor = colorMap[colorName] ?? Colors.indigo;
    });
  }

  void _updateTheme(bool isDark, MaterialColor color) {
    setState(() {
      _isDark = isDark;
      _themeColor = color;
    });
  }

  Future<Widget> _startupPage() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('loggedIn') ?? false;
    return loggedIn ? const HomePage() : const LoginPage();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyDiary',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: _themeColor,
        brightness: _isDark ? Brightness.dark : Brightness.light,
        useMaterial3: true,
      ),
      routes: {
        '/login': (_) => const LoginPage(),
        '/home': (_) => const HomePage(),
        '/theme': (_) => ThemeSettingsPage(onThemeChanged: _updateTheme),
      },
      home: FutureBuilder(
        future: _startupPage(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return snap.data!;
        },
      ),
    );
  }
}
