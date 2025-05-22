import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WaterTracker extends StatefulWidget {
  const WaterTracker({super.key});

  @override
  State<WaterTracker> createState() => _WaterTrackerState();
}

class _WaterTrackerState extends State<WaterTracker> {
  int _waterIntake = 0;
  final int _dailyGoal = 2000;

  final List<int> _portionOptions = [100, 150, 200, 250, 300];
  int _selectedPortion = 200;

  @override
  void initState() {
    super.initState();
    _loadWaterData();
  }

  Future<void> _loadWaterData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString('waterDate');
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (savedDate == today) {
      _waterIntake = prefs.getInt('waterIntake') ?? 0;
    } else {
      _waterIntake = 0;
      prefs.setString('waterDate', today);
      prefs.setInt('waterIntake', 0);
    }

    setState(() {});
  }

  Future<void> _addWater() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _waterIntake += _selectedPortion;
      prefs.setInt('waterIntake', _waterIntake);

      final today = DateTime.now().toIso8601String().substring(0, 10);
      prefs.setString('waterDate', today);
    });
  }

  @override
  Widget build(BuildContext context) {
    double progress = _waterIntake / _dailyGoal;
    progress = progress.clamp(0.0, 1.0);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Water Tracker", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            LinearProgressIndicator(value: progress),
            SizedBox(height: 8),
            Text("$_waterIntake / $_dailyGoal ml"),
            SizedBox(height: 12),

            Row(
              children: [
                Text("Portion: "),
                DropdownButton<int>(
                  value: _selectedPortion,
                  items: _portionOptions.map((value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text("$value ml"),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPortion = value!;
                    });
                  },
                ),
              ],
            ),

            SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _addWater,
              icon: Icon(Icons.local_drink),
              label: Text("Add $_selectedPortion ml"),
            ),
          ],
        ),
      ),
    );
  }
}