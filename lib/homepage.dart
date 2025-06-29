import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sql_helper.dart';
import 'calendar_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // full list from DB
  List<Map<String, dynamic>> _allDiaries = [];
  // list shown after filtering
  List<Map<String, dynamic>> _diaries = [];
  bool _loading = true;

  final _feelCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _selectedFilter = 'All'; // mood filter

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    _allDiaries = await SQLHelper.getDiaries();
    _applyFilter();
  }

  void _applyFilter() {
    setState(() {
      if (_selectedFilter == 'All') {
        _diaries = _allDiaries;
      } else {
        _diaries = _allDiaries
            .where((e) => e['feeling']
                .toString()
                .toLowerCase()
                .contains(_selectedFilter.toLowerCase()))
            .toList();
      }
      _loading = false;
    });
  }

  String _emoji(String feeling) {
    final f = feeling.toLowerCase();
    if (f.contains('happy')) return '😊';
    if (f.contains('sad')) return '😢';
    if (f.contains('angry')) return '😡';
    if (f.contains('excited')) return '🤩';
    return '📝';
  }

  Future<void> _showForm([int? id]) async {
    if (id != null) {
      final entry = _allDiaries.firstWhere((d) => d['id'] == id);
      _feelCtrl.text = entry['feeling'];
      _descCtrl.text = entry['description'];
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(id == null ? 'New Entry' : 'Update Entry',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: _feelCtrl,
              decoration: const InputDecoration(
                labelText: 'Feeling',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: Text(id == null ? 'Create' : 'Update'),
              onPressed: () async {
                if (_feelCtrl.text.trim().isEmpty) return;
                if (id == null) {
                  await SQLHelper.createDiary(
                    _feelCtrl.text.trim(),
                    _descCtrl.text.trim(),
                  );
                } else {
                  await SQLHelper.updateDiary(
                    id,
                    _feelCtrl.text.trim(),
                    _descCtrl.text.trim(),
                  );
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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: Image.asset('assets/logo-nb.png'),
        ),
        title: const Text('MyDiary'),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Calendar',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CalendarPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Theme & Dark mode',
            onPressed: () => Navigator.pushNamed(context, '/theme'),
          ),
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
          : Column(
              children: [
                const SizedBox(height: 10),
                // Mood filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: ['All', 'Happy', 'Sad', 'Angry', 'Excited']
                        .map((mood) {
                      final isSelected = _selectedFilter == mood;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: ChoiceChip(
                          label: Text(mood),
                          selected: isSelected,
                          onSelected: (_) {
                            _selectedFilter = mood;
                            _applyFilter();
                          },
                          selectedColor: scheme.primary,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? scheme.onPrimary
                                : scheme.onSurface,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(),
                // Diary list
                Expanded(
                  child: _diaries.isEmpty
                      ? const Center(child: Text('No diary entries yet.'))
                      : ListView.builder(
                          itemCount: _diaries.length,
                          itemBuilder: (context, index) {
                            final diary = _diaries[index];
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 15),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor:
                                                scheme.primaryContainer,
                                            child: Text(
                                              _emoji(diary['feeling']),
                                              style: const TextStyle(
                                                  fontSize: 20),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: scheme.secondaryContainer,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              diary['feeling'],
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: scheme
                                                      .onSecondaryContainer),
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            diary['date'] ?? '',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        diary['description'] ?? '',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit,
                                                color: Colors.blue),
                                            onPressed: () =>
                                                _showForm(diary['id']),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.red),
                                            onPressed: () =>
                                                _delete(diary['id']),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
