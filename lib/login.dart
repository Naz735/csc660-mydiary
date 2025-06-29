import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';       // 🥳 toast
import 'register.dart';
import 'reset_password.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _rememberMe = false;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tryAutoLogin();
  }

  // ───────────────────── Helpers ─────────────────────
  void _showWelcomeToast(String user) {
    Fluttertoast.showToast(
      msg: "Welcome back, $user!",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  Future<void> _tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberedUser = prefs.getString('remembered_user');
    final rememberedPass = prefs.getString('remembered_pass');

    if (rememberedUser != null && rememberedPass != null) {
      // Fill the fields for UX
      _userCtrl.text = rememberedUser;
      _passCtrl.text = rememberedPass;
      _rememberMe = true;

      // Check vs stored login
      final storedUser = prefs.getString('username');
      final storedPass = prefs.getString('password');

      if (rememberedUser == storedUser && rememberedPass == storedPass) {
        await prefs.setBool('loggedIn', true);
        _showWelcomeToast(rememberedUser);              // 🎉 toast
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
        return; // skip showing login screen
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _login() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUser = prefs.getString('username');
    final storedPass = prefs.getString('password');

    if (_userCtrl.text == storedUser && _passCtrl.text == storedPass) {
      await prefs.setBool('loggedIn', true);

      if (_rememberMe) {
        await prefs.setString('remembered_user', _userCtrl.text);
        await prefs.setString('remembered_pass', _passCtrl.text);
      } else {
        await prefs.remove('remembered_user');
        await prefs.remove('remembered_pass');
      }

      _showWelcomeToast(_userCtrl.text);                // 🎉 toast

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      setState(() => _error = 'Invalid username or password.');
    }
  }

  // ───────────────────── UI ─────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Image.asset('assets/logo-nb.png', width: 120, height: 120),
            const SizedBox(height: 30),

            TextField(
              controller: _userCtrl,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),

            // Remember Me
            CheckboxListTile(
              value: _rememberMe,
              onChanged: (val) => setState(() => _rememberMe = val ?? false),
              contentPadding: EdgeInsets.zero,
              title: const Text("Remember me"),
              controlAffinity: ListTileControlAffinity.leading,
            ),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _login,
                child: const Text('Login'),
              ),
            ),
            const SizedBox(height: 10),

            // Register | Forgot Password
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  ),
                  child: const Text("Register"),
                ),
                const Text('|'),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ResetPwPage()),
                  ),
                  child: const Text("Forgot password?"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
