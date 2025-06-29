import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ResetPwPage extends StatefulWidget {
  const ResetPwPage({super.key});
  @override
  State<ResetPwPage> createState() => _ResetPwPageState();
}

class _ResetPwPageState extends State<ResetPwPage> {
  // Same list used in register.dart
  final _securityQuestions = [
    "What is your pet's name?",
    "What is your mother's maiden name?",
    "What was the name of your first school?",
    "What is your favorite food?",
  ];

  String? _storedQuestion;      // question saved at register time
  String? _selectedQuestion;    // dropdown selection
  final _answerCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  String? _msg;

  @override
  void initState() {
    super.initState();
    _loadStoredQuestion();
  }

  Future<void> _loadStoredQuestion() async {
    final prefs = await SharedPreferences.getInstance();
    final q = prefs.getString('secret_question');
    setState(() {
      _storedQuestion = q;
      _selectedQuestion = q;
    });
  }

  Future<void> _verifyAndReset() async {
    final prefs = await SharedPreferences.getInstance();
    final storedAns = prefs.getString('secret_answer') ?? '';

    if (_selectedQuestion == null || _selectedQuestion!.isEmpty) {
      setState(() => _msg = 'Please select your secret question.');
      return;
    }

    if (_answerCtrl.text.trim().isEmpty || _newPassCtrl.text.trim().isEmpty) {
      setState(() => _msg = 'Answer and new password are required.');
      return;
    }

    if (_selectedQuestion != _storedQuestion) {
      setState(() => _msg = 'Selected question does not match our records.');
      return;
    }

    if (_answerCtrl.text.trim().toLowerCase() != storedAns.toLowerCase()) {
      setState(() => _msg = 'Wrong answer.');
      return;
    }

    // All good – update password
    await prefs.setString('password', _newPassCtrl.text.trim());
    if (!mounted) return;
    setState(() => _msg = 'Password updated! Go back and log in.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedQuestion,
              decoration: const InputDecoration(labelText: 'Select your question'),
              items: _securityQuestions
                  .map((q) => DropdownMenuItem(value: q, child: Text(q)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedQuestion = val),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _answerCtrl,
              decoration: const InputDecoration(labelText: 'Your answer'),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _newPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _verifyAndReset,
              child: const Text('Update Password'),
            ),

            if (_msg != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _msg!,
                  style: TextStyle(
                    color: _msg == 'Password updated! Go back and log in.'
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
