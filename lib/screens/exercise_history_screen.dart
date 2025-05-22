// Fix for exercise_history_screen.dart with Local Storage logging
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../service/exercise_tracking_service.dart';
import '../service/offline_service.dart';

class ExerciseHistoryScreen extends StatefulWidget {
  @override
  _ExerciseHistoryScreenState createState() => _ExerciseHistoryScreenState();
}

class _ExerciseHistoryScreenState extends State<ExerciseHistoryScreen> {
  final ExerciseTrackingService _trackingService = ExerciseTrackingService();
  final OfflineService _offlineService = OfflineService();
  List<Map<String, dynamic>> _exercises = [];
  bool _isLoading = true;
  bool _isSyncing = false;
  DateTime _selectedDate = DateTime.now();

  // Logging method for Local Storage operations
  void _logLocalStorage(String operation, {Map<String, dynamic>? data, String? error}) {
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(DateTime.now());
    final logMessage = '[$timestamp] LOCAL_STORAGE: $operation';

    print('═══════════════════════════════════════');
    print(logMessage);

    if (data != null) {
      print('Data: ${data.toString()}');
    }

    if (error != null) {
      print('Error: $error');
    }

    print('Storage Status:');
    print('  - Pending sync items: ${_offlineService.pendingSyncCount}');
    print('  - Online status: ${_offlineService.isOnline}');
    print('  - User authenticated: ${_offlineService.isUserAuthenticated()}');
    print('═══════════════════════════════════════');
  }

  @override
  void initState() {
    super.initState();
    _logLocalStorage('Screen initialized');

    // Initialize the offline service
    _offlineService.initialize().then((_) {
      _logLocalStorage('Offline service initialized');
      _loadExerciseHistory();
    }).catchError((error) {
      _logLocalStorage('Offline service initialization failed', error: error.toString());
    });

    // Listen for online status changes
    _offlineService.syncStream.listen((isOnline) {
      _logLocalStorage('Online status changed', data: {'isOnline': isOnline});

      if (isOnline) {
        _logLocalStorage('Device came online - attempting auto-sync');
        // Try auto-sync when coming back online
        _syncDataWithFirebase(showSnackbar: false);
      }
      // Refresh UI to update online/offline indicator
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadExerciseHistory() async {
    if (!mounted) return;

    _logLocalStorage('Loading exercise history', data: {
      'selectedDate': _selectedDate.toIso8601String(),
    });

    setState(() {
      _isLoading = true;
    });

    try {
      final exercises = await _trackingService.getExerciseHistoryForDate(_selectedDate);

      _logLocalStorage('Exercise history loaded successfully', data: {
        'exerciseCount': exercises.length,
        'exercises': exercises.map((e) => {
          'name': e['name'],
          'synced': e['synced'],
          'timestamp': e['timestamp'],
        }).toList(),
      });

      if (!mounted) return;

      setState(() {
        _exercises = exercises;
        _isLoading = false;
      });
    } catch (error) {
      _logLocalStorage('Failed to load exercise history', error: error.toString());

      if (!mounted) return;

      setState(() {
        _exercises = [];
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load exercise history: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _syncDataWithFirebase({bool showSnackbar = true}) async {
    _logLocalStorage('Sync attempt started', data: {
      'showSnackbar': showSnackbar,
      'alreadySyncing': _isSyncing,
    });

    // Check if already syncing
    if (_isSyncing) {
      _logLocalStorage('Sync skipped - already syncing');
      return;
    }

    // Check Firebase authentication
    if (!_offlineService.isUserAuthenticated()) {
      _logLocalStorage('Sync failed - user not authenticated');
      if (showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot sync: You are not signed in. Please sign in first.'),
              duration: Duration(seconds: 3),
            )
        );
      }
      return;
    }

    // Check if device is online
    if (!_offlineService.isOnline) {
      _logLocalStorage('Sync failed - device offline');
      if (showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot sync: Device is offline. Will try again when online.'),
              duration: Duration(seconds: 2),
            )
        );
      }
      return;
    }

    _logLocalStorage('Starting sync process');

    setState(() {
      _isSyncing = true;
    });

    if (showSnackbar) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Syncing data with server...'))
      );
    }

    try {
      final success = await _trackingService.syncExerciseHistory();

      _logLocalStorage('Sync completed', data: {
        'success': success,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Refresh the exercise list after sync
      await _loadExerciseHistory();

      if (showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success
                  ? 'All data synced successfully!'
                  : 'Some data failed to sync. Will try again later.'),
              duration: Duration(seconds: 2),
              backgroundColor: success ? Colors.green : Colors.orange,
            )
        );
      }
    } catch (error) {
      _logLocalStorage('Sync failed with error', error: error.toString());

      if (showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sync failed: $error'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.red,
            )
        );
      }
    } finally {
      setState(() {
        _isSyncing = false;
      });
      _logLocalStorage('Sync process ended');
    }
  }

  Widget _buildDateSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left),
          onPressed: () {
            final newDate = _selectedDate.subtract(Duration(days: 1));
            _logLocalStorage('Date changed (previous)', data: {
              'oldDate': _selectedDate.toIso8601String(),
              'newDate': newDate.toIso8601String(),
            });

            setState(() {
              _selectedDate = newDate;
            });
            _loadExerciseHistory();
          },
        ),
        TextButton(
          onPressed: () async {
            _logLocalStorage('Date picker opened');

            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );

            if (picked != null && picked != _selectedDate) {
              _logLocalStorage('Date changed (picker)', data: {
                'oldDate': _selectedDate.toIso8601String(),
                'newDate': picked.toIso8601String(),
              });

              setState(() {
                _selectedDate = picked;
              });
              _loadExerciseHistory();
            } else {
              _logLocalStorage('Date picker cancelled or same date selected');
            }
          },
          child: Text(
            DateFormat.yMMMd().format(_selectedDate),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: Icon(Icons.chevron_right),
          onPressed: _selectedDate.isBefore(DateTime.now()) ? () {
            final newDate = _selectedDate.add(Duration(days: 1));
            _logLocalStorage('Date changed (next)', data: {
              'oldDate': _selectedDate.toIso8601String(),
              'newDate': newDate.toIso8601String(),
            });

            setState(() {
              _selectedDate = newDate;
            });
            _loadExerciseHistory();
          } : null,
        ),
      ],
    );
  }

  Widget _buildSyncStatus() {
    return Container(
      padding: EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _offlineService.isOnline ? Icons.cloud_done : Icons.cloud_off,
            color: _offlineService.isOnline ? Colors.green : Colors.grey,
          ),
          SizedBox(width: 8),
          Text(
            _offlineService.isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              color: _offlineService.isOnline ? Colors.green : Colors.grey,
            ),
          ),
          if (!_offlineService.isOnline) ...[
            SizedBox(width: 8),
            Text(
              '(${_offlineService.pendingSyncCount} items pending sync)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
          Spacer(),
          if (_offlineService.isOnline)
            _isSyncing
                ? CircularProgressIndicator(strokeWidth: 2)
                : TextButton.icon(
              icon: Icon(Icons.sync),
              label: Text('Sync now'),
              onPressed: () {
                _logLocalStorage('Manual sync triggered by user');
                _syncDataWithFirebase();
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Exercise History'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _logLocalStorage('Manual refresh triggered by user');
              _loadExerciseHistory();
            },
          ),
          // Debug button to show local storage info
          IconButton(
            icon: Icon(Icons.bug_report),
            onPressed: () {
              _logLocalStorage('Debug info requested', data: {
                'currentExercises': _exercises.length,
                'selectedDate': _selectedDate.toIso8601String(),
                'isLoading': _isLoading,
                'isSyncing': _isSyncing,
              });

              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Local Storage Debug'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Exercises loaded: ${_exercises.length}'),
                      Text('Pending sync: ${_offlineService.pendingSyncCount}'),
                      Text('Online: ${_offlineService.isOnline}'),
                      Text('Authenticated: ${_offlineService.isUserAuthenticated()}'),
                      Text('Selected date: ${DateFormat.yMMMd().format(_selectedDate)}'),
                      SizedBox(height: 8),
                      Text('Check console for detailed logs'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSyncStatus(),
          _buildDateSelector(),
          Divider(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _exercises.isEmpty
                ? Center(child: Text('No exercises for this date'))
                : ListView.builder(
              itemCount: _exercises.length,
              itemBuilder: (context, index) {
                final exercise = _exercises[index];
                final exerciseTime = DateTime.fromMillisecondsSinceEpoch(
                    exercise['timestamp'] as int);

                return ListTile(
                  leading: Icon(
                    exercise['category'].toString().contains('Yoga')
                        ? Icons.self_improvement
                        : Icons.fitness_center,
                  ),
                  title: Text(exercise['name']),
                  subtitle: Text(
                      '${exercise['category']} • ${exercise['durationInSeconds']} seconds'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(DateFormat.Hm().format(exerciseTime)),
                      SizedBox(width: 8),
                      Icon(
                        exercise['synced'] == true ? Icons.cloud_done : Icons.cloud_queue,
                        size: 16,
                        color: exercise['synced'] == true ? Colors.green : Colors.grey,
                      ),
                    ],
                  ),
                  onTap: () {
                    _logLocalStorage('Exercise item tapped', data: {
                      'exerciseName': exercise['name'],
                      'synced': exercise['synced'],
                      'timestamp': exercise['timestamp'],
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _logLocalStorage('Screen disposed');
    super.dispose();
  }
}