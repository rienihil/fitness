import 'package:flutter/material.dart';
import 'package:my_app/screens/workout_screen.dart';
import 'package:my_app/screens/yoga_screen.dart';

class WorkoutSelectScreen extends StatelessWidget {
  const WorkoutSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workout Types')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            _buildWorkoutCard(
              context,
              title: 'Yoga',
              image: 'assets/images/yoga.png',
                onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const YogaScreen(),
                    ),
                  );
                }
            ),
            const SizedBox(height: 16),
            _buildWorkoutCard(
              context,
              title: 'Exercises',
              image: 'assets/images/exercise.png',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorkoutScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutCard(BuildContext context,
      {required String title,
        required String image,
        required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.hardEdge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Ink.image(
              image: AssetImage(image),
              height: 180,
              fit: BoxFit.cover,
              child: InkWell(onTap: onTap),
            ),
            Container(
              height: 180,
              color: Colors.black.withOpacity(0.4),
              alignment: Alignment.center,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}