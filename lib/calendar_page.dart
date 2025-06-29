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

    for (var entry in data) {
      final date = DateTime.parse(entry['date']);
      final key = DateTime(date.year, date.month, date.day);
      events.putIfAbsent(key, () => []).add(entry);
    }

    setState(() {
      _events = events;
      _selectedEvents = events[_selectedDay ?? _focusedDay] ?? [];
    });
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _events[date] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            eventLoader: _getEventsForDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
                _selectedEvents = _getEventsForDay(selected);
              });
            },
            calendarStyle: CalendarStyle(
              markerDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
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
                      final entry = _selectedEvents[i];
                      return ListTile(
                        title: Text(entry['feeling']),
                        subtitle: Text(entry['description']),
                        trailing: Text(entry['date']),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
