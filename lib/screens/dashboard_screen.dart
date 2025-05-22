import 'package:flutter/material.dart';
import '../widgets/water_tracker.dart';
import '../widgets/step_counter_widget.dart';
import '../widgets/workout_calendar.dart';
import 'exercise_history_screen.dart'; // Добавляем импорт

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _showSavedMessage = false;

  void _reloadData() {
    // Здесь можно добавить логику для обновления данных
    setState(() {
      _showSavedMessage = true;
    });

    // Скрываем сообщение через 2 секунды
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showSavedMessage = false;
        });
      }
    });
  }

  void _navigateToExerciseHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExerciseHistoryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard"),
        actions: [
          // Добавляем кнопку истории в AppBar
          IconButton(
            icon: Icon(Icons.history),
            tooltip: 'Exercise History',
            onPressed: _navigateToExerciseHistory,
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Today's Summary",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        // Добавляем кнопку истории упражнений
                        IconButton(
                          onPressed: _reloadData,
                          icon: Icon(Icons.refresh),
                          tooltip: 'Reload',
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: const [
                      StepCounterWidget(),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                WorkoutCalendar(),
                SizedBox(height: 24),
                WaterTracker(),
                SizedBox(height: 24),
                // Добавляем кнопку просмотра истории
                ElevatedButton.icon(
                  onPressed: _navigateToExerciseHistory,
                  icon: Icon(Icons.history),
                  label: Text('View Exercise History'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
          if (_showSavedMessage)
            Positioned(
              top: 70,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade200,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    "Progress Saved",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}