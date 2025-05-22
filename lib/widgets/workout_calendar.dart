import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:convert';

class WorkoutCalendar extends StatefulWidget {
  const WorkoutCalendar({super.key});

  @override
  State<WorkoutCalendar> createState() => _WorkoutCalendarState();

  static Future<void> markTodayWorkoutDone() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);

    final jsonString = prefs.getString('workoutDays') ?? '{}';
    final Map<String, bool> days = Map<String, bool>.from(json.decode(jsonString));

    days[today] = true;

    await prefs.setString('workoutDays', json.encode(days));
  }
}

class _WorkoutCalendarState extends State<WorkoutCalendar> {
  Map<String, bool> _completedDays = {};

  @override
  void initState() {
    super.initState();
    _loadWorkoutData();
  }

  Future<void> _loadWorkoutData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('workoutDays') ?? '{}';
    setState(() {
      _completedDays = Map<String, bool>.from(json.decode(jsonString));
    });
  }

  Color _getDayColor(DateTime day) {
    final key = _formatDate(day);
    final isDone = _completedDays[key] ?? false;
    if (isDone) return Colors.green;
    return Colors.grey.shade300;
  }

  String _formatDate(DateTime date) => date.toIso8601String().substring(0, 10);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text("Training calendar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            TableCalendar(
              firstDay: DateTime.utc(2025, 1, 1),
              lastDay: DateTime.utc(2025, 12, 31),
              focusedDay: DateTime.now(),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  return Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getDayColor(day),
                    ),
                    child: Text(
                      '${day.day}',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}