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
  List<Map<String, dynamic>> _allDiaries = [];
  List<Map<String, dynamic>> _diaries = [];
  bool _loading = true;

  final _feelCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  String _selectedFilter = 'All';
  final _quickMoods = ['Happy', 'Sad', 'Angry', 'Excited'];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_applyFilter);
    _refresh();
  }

  @override
  void dispose() {
    _feelCtrl.dispose();
    _descCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── Load diaries from DB ───
  Future<void> _refresh() async {
    _allDiaries = await SQLHelper.getDiaries();
    _applyFilter();
  }

  // ─── Apply search & mood filter ───
  void _applyFilter() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _diaries = _allDiaries.where((d) {
        final feel = d['feeling'].toString().toLowerCase();
        final desc = d['description'].toString().toLowerCase();
        final okMood = _selectedFilter == 'All' ||
            feel.contains(_selectedFilter.toLowerCase());
        final okSearch =
            query.isEmpty || feel.contains(query) || desc.contains(query);
        return okMood && okSearch;
      }).toList();
      _loading = false;
    });
  }

  // ─── Emoji helper ───
  String _emoji(String s) {
    s = s.toLowerCase();
    if (s.contains('happy')) return '😊';
    if (s.contains('sad')) return '😢';
    if (s.contains('angry')) return '😡';
    if (s.contains('excited')) return '🤩';
    return '📝';
  }

  // ─── Create / Update entry ───
  Future<void> _showForm([int? id]) async {
    if (id != null) {
      final e = _allDiaries.firstWhere((d) => d['id'] == id);
      _feelCtrl.text = e['feeling'];
      _descCtrl.text = e['description'];
    } else {
      _feelCtrl.clear();
      _descCtrl.clear();
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: StatefulBuilder(
          builder: (ctx, setSheet) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(id == null ? 'New Entry' : 'Update Entry',
                  style:
                      const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: _feelCtrl,
                decoration: const InputDecoration(
                    labelText: 'Feeling', border: OutlineInputBorder()),
                onChanged: (_) => setSheet(() {}), // refresh chip highlight
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: _quickMoods.map((m) {
                  final sel =
                      _feelCtrl.text.toLowerCase() == m.toLowerCase();
                  return ChoiceChip(
                    label: Text(m),
                    selected: sel,
                    onSelected: (_) =>
                        setSheet(() => _feelCtrl.text = sel ? '' : m),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Description', border: OutlineInputBorder()),
              ),
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
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  _refresh();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _delete(int id) async {
    await SQLHelper.deleteDiary(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Entry deleted')));
    _refresh();
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('loggedIn', false);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  // ─── UI ───
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading:
            Padding(padding: const EdgeInsets.all(8), child: Image.asset('assets/logo-nb.png')),
        title: const Text('MyDiary'),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Calendar',
            onPressed: () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarPage())),
          ),
          PopupMenuButton<String>(
            onSelected: (v) =>
                v == 'theme' ? Navigator.pushNamed(context, '/theme') : _logout(),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'theme',
                child: ListTile(
                  leading: Icon(Icons.color_lens),
                  title: Text('Theme & Dark mode'),
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Logout'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 10),
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: ['All', ..._quickMoods].map((m) {
                      final sel = _selectedFilter == m;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: ChoiceChip(
                          label: Text(m),
                          selected: sel,
                          onSelected: (_) {
                            setState(() {
                              _selectedFilter = sel ? 'All' : m;
                            });
                            _applyFilter();
                          },
                          selectedColor: scheme.primary,
                          labelStyle: TextStyle(
                              color:
                                  sel ? scheme.onPrimary : scheme.onSurface),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search diary...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const Divider(height: 0),
                // Diary list
                Expanded(
                  child: _diaries.isEmpty
                      ? const Center(child: Text('No diary entries found.'))
                      : ListView.builder(
                          itemCount: _diaries.length,
                          itemBuilder: (ctx, i) {
                            final d = _diaries[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: scheme.primaryContainer,
                                  child: Text(_emoji(d['feeling']),
                                      style: const TextStyle(fontSize: 20)),
                                ),
                                title: Text(d['feeling']),
                                subtitle: Text(d['description']),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () => _showForm(d['id'])),
                                    IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () => _delete(d['id'])),
                                  ],
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
