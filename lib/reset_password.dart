import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ResetPwPage extends StatefulWidget {
  const ResetPwPage({super.key});
  @override State<ResetPwPage> createState() => _ResetPwPageState();
}

class _ResetPwPageState extends State<ResetPwPage> {
  String? _question;
  final _answerCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  String? _msg;

  @override
  void initState() {
    super.initState();
    _loadQuestion();
  }

  Future<void> _loadQuestion() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _question = prefs.getString('secret_question') ?? 'No question set');
  }

  Future<void> _verifyAndReset() async {
    final prefs = await SharedPreferences.getInstance();
    final storedAns = prefs.getString('secret_answer') ?? '';
    if (_answerCtrl.text.trim().toLowerCase() == storedAns.toLowerCase()) {
      await prefs.setString('password', _newPassCtrl.text.trim());
      if (!mounted) return;
      setState(() => _msg = 'Password updated! Go back and log in.');
    } else {
      setState(() => _msg = 'Wrong answer.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(_question ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(controller: _answerCtrl,
              decoration: const InputDecoration(labelText: 'Your answer')),
            const SizedBox(height: 20),
            TextField(controller: _newPassCtrl, obscureText: true,
              decoration: const InputDecoration(labelText: 'New password')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _verifyAndReset,
              child: const Text('Update Password'),
            ),
            if (_msg != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_msg!,
                    style: TextStyle(
                      color: _msg == 'Password updated! Go back and log in.'
                          ? Colors.green
                          : Colors.red,
                    )),
              ),
          ],
        ),
      ),
    );
  }
}
