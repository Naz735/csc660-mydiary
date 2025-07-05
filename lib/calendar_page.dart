import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'sql_helper.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late Map<DateTime, List<Map<String, dynamic>>> _events;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> _selectedEvents = [];

  final _quickMoods = ['Happy', 'Sad', 'Angry', 'Excited'];

  @override
  void initState() {
    super.initState();
    _events = {};
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final data = await SQLHelper.getDiaries();
    final Map<DateTime, List<Map<String, dynamic>>> ev = {};
    for (var e in data) {
      final dt = DateTime.parse(e['date']);
      final key = DateTime(dt.year, dt.month, dt.day);
      ev.putIfAbsent(key, () => []).add(e);
    }
    setState(() {
      _events = ev;
      _selectedEvents = ev[_selectedDay ?? _focusedDay] ?? [];
    });
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  String _emoji(String feeling) {
    final f = feeling.toLowerCase();
    if (f.contains('happy')) return '😊';
    if (f.contains('sad')) return '😢';
    if (f.contains('angry')) return '😡';
    if (f.contains('excited')) return '🤩';
    return '📝';
  }

  Future<void> _openDetail(Map<String, dynamic> entry) async {
    final id = entry['id'] as int;
    final feelCtrl = TextEditingController(text: entry['feeling']);
    final descCtrl = TextEditingController(text: entry['description']);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Diary Detail'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: feelCtrl, decoration: const InputDecoration(labelText: 'Feeling')),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: _quickMoods.map((m) {
                  final sel = feelCtrl.text.toLowerCase() == m.toLowerCase();
                  return ChoiceChip(
                    label: Text(m),
                    selected: sel,
                    onSelected: (_) {
                      feelCtrl.text = sel ? '' : m;
                      setState(() {});
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, maxLines: 4, decoration: const InputDecoration(labelText: 'Description')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await SQLHelper.updateDiary(id, feelCtrl.text, descCtrl.text);
              await _loadEvents();
              if (!mounted) return;
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
          TextButton(
            onPressed: () async {
              await SQLHelper.deleteDiary(id);
              await _loadEvents();
              if (!mounted) return;
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickMonthYear() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _focusedDay,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() {
        _focusedDay = picked;
        _selectedDay = picked;
        _selectedEvents = _getEventsForDay(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: Column(
        children: [
          GestureDetector(
            onTap: _pickMonthYear,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: scheme.surfaceVariant,
              width: double.infinity,
              child: Center(
                child: Text(
                  '${_focusedDay.month}/${_focusedDay.year}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ),
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            eventLoader: _getEventsForDay,
            selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
            onDaySelected: (sel, foc) {
              setState(() {
                _selectedDay = sel;
                _focusedDay = foc;
                _selectedEvents = _getEventsForDay(sel);
              });
            },
            calendarStyle: CalendarStyle(
              markerDecoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: _selectedEvents.isEmpty
                ? const Center(child: Text('No entries'))
                : ListView.builder(
                    itemCount: _selectedEvents.length,
                    itemBuilder: (ctx, i) {
                      final e = _selectedEvents[i];
                      return InkWell(
                        onTap: () => _openDetail(e),
                        child: Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: scheme.primaryContainer,
                              child: Text(_emoji(e['feeling'])),
                            ),
                            title: Text(e['feeling']),
                            subtitle: Text(
                              e['description'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              e['date'].toString().substring(11, 16),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
