import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../data/yoga_data.dart';
import '../service/exercise_tracking_service.dart';
import '../service/offline_service.dart';

class YogaDetailScreen extends StatefulWidget {
  final YogaPose pose;
  final int initialDurationInSeconds = 30;

  const YogaDetailScreen({required this.pose});

  @override
  _YogaDetailScreenState createState() => _YogaDetailScreenState();
}

class _YogaDetailScreenState extends State<YogaDetailScreen> {
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

    _videoController = VideoPlayerController.asset(widget.pose.videoAsset, videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true))
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
        await _audioPlayer.play(AssetSource('sounds/yoga_sound.mp3'));
      } else {
        timer.cancel();
        // Track completed yoga pose
        await _trackYogaCompleted(inputSeconds);
        setState(() {
          _isRunning = false;
        });
        await _audioPlayer.play(AssetSource('sounds/beep.mp3'));
      }
    });
  }

  // Track completed yoga pose with our tracking service
  Future<void> _trackYogaCompleted(int duration) async {
    await _trackingService.trackExercise(
      exerciseName: widget.pose.name,
      category: 'Yoga - ${widget.pose.targetArea}',
      durationInSeconds: duration,
    );

    // Show snackbar to inform user
    final isOnline = OfflineService().isOnline;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isOnline
              ? 'Yoga pose saved to your history!'
              : 'Yoga pose saved locally. Will sync when online.',
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
      appBar: AppBar(title: Text(widget.pose.name)),
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
            Text(widget.pose.description, style: TextStyle(fontSize: 16)),
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