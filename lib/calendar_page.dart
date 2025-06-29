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

  @override
  void initState() {
    super.initState();
    _events = {};
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final data = await SQLHelper.getDiaries();
    Map<DateTime, List<Map<String, dynamic>>> events = {};

    for (var e in data) {
      final date = DateTime.parse(e['date']);
      final key = DateTime(date.year, date.month, date.day);
      events.putIfAbsent(key, () => []).add(e);
    }

    setState(() {
      _events = events;
      _selectedEvents = events[_selectedDay ?? _focusedDay] ?? [];
    });
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return _events[d] ?? [];
  }

  String _emoji(String feeling) {
    final f = feeling.toLowerCase();
    if (f.contains('happy')) return '😊';
    if (f.contains('sad')) return '😢';
    if (f.contains('angry')) return '😡';
    if (f.contains('excited')) return '🤩';
    return '📝';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            eventLoader: _getEventsForDay,
            selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
                _selectedEvents = _getEventsForDay(selected);
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
                    itemBuilder: (context, i) {
                      final e = _selectedEvents[i];
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 15),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: scheme.primaryContainer,
                                child: Text(
                                  _emoji(e['feeling']),
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e['feeling'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      e['description'],
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                e['date'].toString().substring(11, 16),
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
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
