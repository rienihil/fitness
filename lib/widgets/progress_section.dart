import 'package:flutter/material.dart';

class ProgressSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Weekly Progress", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        _buildProgress("Cardio", 0.7),
        _buildProgress("Strength", 0.5),
      ],
    );
  }

  Widget _buildProgress(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          LinearProgressIndicator(value: value),
        ],
      ),
    );
  }
}
