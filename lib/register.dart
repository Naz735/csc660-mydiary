import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  Future<void> _register() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', _userCtrl.text);
    await prefs.setString('password', _passCtrl.text);
    await prefs.setBool('loggedIn', false);
    if (!mounted) return;
    Navigator.pop(context); // go back to Login
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Image.asset('assets/logo.png', width: 120, height: 120),
            const SizedBox(height: 20),

            TextField(controller: _userCtrl,
              decoration: const InputDecoration(labelText: 'Username')),
            TextField(controller: _passCtrl, obscureText: true,
              decoration: const InputDecoration(labelText: 'Password')),
            const SizedBox(height: 20),

            ElevatedButton(onPressed: _register, child: const Text('Register')),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Already have an account? Log in'),
            ),
          ],
        ),
      ),
    );
  }
}
