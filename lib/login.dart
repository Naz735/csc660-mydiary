import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'register.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String? _error;

  Future<void> _login() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUser = prefs.getString('username');
    final storedPass = prefs.getString('password');

    if (_userCtrl.text == storedUser && _passCtrl.text == storedPass) {
      await prefs.setBool('loggedIn', true);
      // ignore: use_build_context_synchronously
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      setState(() => _error = 'Invalid credentials');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
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

            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),

            ElevatedButton(onPressed: _login, child: const Text('Login')),

            TextButton(
              // push (not replacement) so back arrow remains on Register page
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterPage())),
              child: const Text("Don't have an account? Register"),
            ),
          ],
        ),
      ),
    );
  }
}
