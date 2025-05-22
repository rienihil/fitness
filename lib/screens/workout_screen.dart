import 'package:flutter/material.dart';
import '../data/exercise_data.dart';
import 'exercise_detail_screen.dart'; // Your detail screen file

class WorkoutScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final muscles = exercises.map((e) => e.muscle).toSet().toList();
    final equipment = exercises.map((e) => e.equipment).toSet().toList();

    String? selectedMuscle;
    String? selectedEquipment;

    List<Exercise> getFiltered() {
      return exercises.where((e) {
        return (selectedMuscle == null || e.muscle == selectedMuscle) &&
            (selectedEquipment == null || e.equipment == selectedEquipment);
      }).toList();
    }

    return StatefulBuilder(
      builder: (context, setState) => Scaffold(
        appBar: AppBar(title: Text('Workout Exercises')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(children: [
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: Text('Muscle'),
                    value: selectedMuscle,
                    onChanged: (val) => setState(() => selectedMuscle = val),
                    items: [null, ...muscles].map((m) => DropdownMenuItem(
                      value: m,
                      child: Text(m ?? 'All'),
                    )).toList(),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: Text('Equipment'),
                    value: selectedEquipment,
                    onChanged: (val) => setState(() => selectedEquipment = val),
                    items: [null, ...equipment].map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e ?? 'All'),
                    )).toList(),
                  ),
                ),
              ]),
            ),
            // List
            Expanded(
              child: ListView.builder(
                itemCount: getFiltered().length,
                itemBuilder: (context, index) {
                  final ex = getFiltered()[index];
                  return ListTile(
                    title: Text(ex.name),
                    subtitle: Text('${ex.muscle} • ${ex.equipment}'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ExerciseDetailScreen(exercise: ex),
                        ),
                      );
                    },
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