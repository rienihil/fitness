import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';

import '../data/exercise_data.dart';
import '../service/offline_service.dart';
import '../widgets/workout_calendar.dart';
import '../service/exercise_tracking_service.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final Exercise exercise;
  final int initialDurationInSeconds = 30;

  const ExerciseDetailScreen({required this.exercise});

  @override
  _ExerciseDetailScreenState createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  late VideoPlayerController _videoController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ExerciseTrackingService _trackingService = ExerciseTrackingService();

  Timer? _timer;
  int _remainingTime = 0;
  bool _isRunning = false;
  final TextEditingController _durationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _remainingTime = widget.initialDurationInSeconds;
    _durationController.text = _remainingTime.toString();

    _videoController = VideoPlayerController.asset(widget.exercise.videoAsset, videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true))
      ..initialize().then((_) {
        _videoController.setVolume(0);
        _videoController.setLooping(true);
        _videoController.play();
        setState(() {});
      });
  }

  void startTimer() {
    final inputSeconds = int.tryParse(_durationController.text) ?? widget.initialDurationInSeconds;
    setState(() {
      _remainingTime = inputSeconds;
      _isRunning = true;
    });

    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
        await _audioPlayer.play(AssetSource('sounds/tick.mp3'));
      } else {
        timer.cancel();
        // Track completed exercise
        await _trackExerciseCompleted(inputSeconds);
        // Mark workout done for calendar
        WorkoutCalendar.markTodayWorkoutDone();
        setState(() {
          _isRunning = false;
        });
        await _audioPlayer.play(AssetSource('sounds/beep.mp3'));
      }
    });
  }

  // Track completed exercise with our tracking service
  Future<void> _trackExerciseCompleted(int duration) async {
    await _trackingService.trackExercise(
      exerciseName: widget.exercise.name,
      category: widget.exercise.muscle,
      durationInSeconds: duration,
    );

    // Show snackbar to inform user
    final isOnline = OfflineService().isOnline;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isOnline
              ? 'Exercise saved to your history!'
              : 'Exercise saved locally. Will sync when online.',
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void stopTimer() {
    _timer?.cancel();
    _audioPlayer.stop();
    setState(() {
      _isRunning = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _videoController.dispose();
    _durationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.exercise.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Video preview
            _videoController.value.isInitialized
                ? AspectRatio(
              aspectRatio: _videoController.value.aspectRatio,
              child: VideoPlayer(_videoController),
            )
                : CircularProgressIndicator(),

            SizedBox(height: 20),
            Text(widget.exercise.description, style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),

            // Duration Input
            TextField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Duration (seconds)',
                border: OutlineInputBorder(),
              ),
              enabled: !_isRunning,
            ),
            SizedBox(height: 20),

            Text('$_remainingTime s',
                style: TextStyle(fontSize: 40, color: Colors.deepPurple, fontWeight: FontWeight.bold)),

            SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isRunning ? null : startTimer,
                  icon: Icon(Icons.play_arrow),
                  label: Text('Start'),
                ),
                SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _isRunning ? stopTimer : null,
                  icon: Icon(Icons.stop),
                  label: Text('Stop'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}