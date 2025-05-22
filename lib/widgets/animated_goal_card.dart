import 'package:flutter/material.dart';

class AnimatedGoalCard extends StatelessWidget {
  final String title;
  final String value;

  AnimatedGoalCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 500),
      margin: EdgeInsets.only(right: 12),
      padding: EdgeInsets.all(16),
      width: 150,
      decoration: BoxDecoration(
        color: Colors.deepPurple[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(title, style: TextStyle(color: Colors.grey[700])),
        ],
      ),
    );
  }
}
