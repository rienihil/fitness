import 'package:flutter/material.dart';
import '../data/yoga_data.dart';
import 'yoga_detail_screen.dart';

class YogaScreen extends StatefulWidget {
  const YogaScreen({super.key});

  @override
  State<YogaScreen> createState() => _YogaScreenState();
}

class _YogaScreenState extends State<YogaScreen> {
  String selectedFilter = 'All';

  List<String> get types {
    final areas = yogaPoses.map((e) => e.type).toSet().toList();
    areas.sort();
    return ['All', ...areas];
  }

  List<YogaPose> get filteredPoses {
    if (selectedFilter == 'All') return yogaPoses;
    return yogaPoses.where((pose) => pose.type == selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yoga Poses')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButton<String>(
              value: selectedFilter,
              items: types
                  .map((area) => DropdownMenuItem(
                value: area,
                child: Text(area),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedFilter = value!;
                });
              },
              isExpanded: true,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredPoses.length,
              itemBuilder: (context, index) {
                final pose = filteredPoses[index];
                return ListTile(
                  leading: const Icon(Icons.self_improvement),
                  title: Text(pose.name),
                  subtitle: Text(pose.type),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => YogaDetailScreen(pose: pose),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
