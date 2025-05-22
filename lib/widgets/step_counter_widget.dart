import 'package:flutter/material.dart';
import '../widgets/animated_goal_card.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StepCounterWidget extends StatefulWidget {
  const StepCounterWidget({super.key});

  @override
  State<StepCounterWidget> createState() => _StepCounterWidgetState();
}

class _StepCounterWidgetState extends State<StepCounterWidget> {
  late Stream<StepCount> _stepCountStream;
  int _stepsRaw = 0;
  int _stepsToday = 0;
  int _startOfDaySteps = 0;
  double _calories = 0.0;

  @override
  void initState() {
    super.initState();
    _initPermissions();
    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen(_onStepCount).onError(_onStepCountError);
  }

  void _initPermissions() async {
    if (!await Permission.activityRecognition.request().isGranted) {
      setState(() {
        _stepsToday = -1;
      });
    }
  }

  void _onStepCount(StepCount event) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = prefs.getString('stepDate');
    int startSteps = prefs.getInt('startOfDaySteps') ?? 0;

    if (savedDate != today) {
      prefs.setString('stepDate', today);
      prefs.setInt('startOfDaySteps', event.steps);
      startSteps = event.steps;
    }

    final stepsToday = event.steps - startSteps;

    setState(() {
      _stepsRaw = event.steps;
      _startOfDaySteps = startSteps;
      _stepsToday = stepsToday.clamp(0, 999999);
      _calories = _stepsToday * 0.04;
    });
  }

  void _onStepCountError(error) {
    setState(() {
      _stepsToday = 0;
      _calories = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedGoalCard(
          title: "Steps",
          value: _stepsToday.toString(),
        ),
        SizedBox(width: 12),
        AnimatedGoalCard(
          title: "Calories Burned",
          value: "${_calories.toStringAsFixed(1)} kcal",
        ),
      ],
    );
  }
}
