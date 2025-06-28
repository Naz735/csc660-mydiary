import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sql_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _diaries = [];
  bool _loading = true;

  final _feelCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    _diaries = await SQLHelper.getDiaries();
    if (mounted) setState(() => _loading = false);
  }

  String _emoji(String feeling) {
    final f = feeling.toLowerCase();
    if (f.contains('happy')) return '😊';
    if (f.contains('sad'))   return '😢';
    if (f.contains('angry')) return '😡';
    if (f.contains('excited')) return '🤩';
    return '📝';
  }

  Future<void> _showForm([int? id]) async {
    if (id != null) {
      final e = _diaries.firstWhere((d) => d['id'] == id);
      _feelCtrl.text = e['feeling'];
      _descCtrl.text = e['description'];
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          top: 20, left: 20, right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(id == null ? 'New Entry' : 'Update Entry',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(controller: _feelCtrl,
              decoration: const InputDecoration(labelText: 'Feeling',
                  border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _descCtrl, maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description',
                  border: OutlineInputBorder())),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: Text(id == null ? 'Create' : 'Update'),
              onPressed: () async {
                if (_feelCtrl.text.trim().isEmpty) return;
                if (id == null) {
                  await SQLHelper.createDiary(
                      _feelCtrl.text.trim(), _descCtrl.text.trim());
                } else {
                  await SQLHelper.updateDiary(
                      id, _feelCtrl.text.trim(), _descCtrl.text.trim());
                }
                _feelCtrl.clear();
                _descCtrl.clear();
                if (mounted) Navigator.pop(context);
                _refresh();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(int id) async {
    await SQLHelper.deleteDiary(id);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Entry deleted')));
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: Image.asset('assets/logo.png'),
        ),
        title: const Text('MyDiary'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('loggedIn', false);
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _diaries.isEmpty
              ? const Center(child: Text('No diary entries yet'))
              : ListView.builder(
                  itemCount: _diaries.length,
                  itemBuilder: (ctx, i) {
                    final e = _diaries[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo.shade100,
                          child: Text(_emoji(e['feeling']),
                              style: const TextStyle(fontSize: 20)),
                        ),
                        title: Text(e['feeling'],
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e['description']),
                            const SizedBox(height: 4),
                            Text(e['date'] ?? '',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showForm(e['id'])),
                            IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () => _delete(e['id'])),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Entry'),
        onPressed: () => _showForm(),
      ),
    );
  }
}
