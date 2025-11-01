import 'package:flutter/material.dart';
import 'dart:async';

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  // use late with a default or just initialize to 0
  int _length = 0;       // remaining seconds
  int _startTimer = 0;   // original start value (seconds)
  Timer? _periodicTimer;

  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _periodicTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void startTimer() {
    // avoid starting multiple timers
    if (_periodicTimer?.isActive ?? false) return;

    const oneSecond = Duration(seconds: 1);
    _periodicTimer = Timer.periodic(oneSecond, (Timer timer) {
      if (_length <= 0) {
        // Cancel and update state once when timer finishes
        timer.cancel();
        setState(() {
          _periodicTimer = null;
          _length = 0;
        });
        // optionally: trigger a callback, sound, notification, etc.
      } else {
        setState(() {
          _length--;
        });
      }
    });
  }

  // sets the timer (seconds) and updates UI immediately
  void setTimer(int length) {
    setState(() {
      _length = length;
      _startTimer = length;
      _controller.text = length.toString();
    });
  }

  void pauseTimer() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  // resets to the original start value; optional auto-start
  void resetTimer({bool autoStart = false}) {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    setState(() {
      _length = _startTimer;
    });
    if (autoStart) startTimer();
  }

  String _formatTime(int seconds) {
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}
