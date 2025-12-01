import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:permission_handler/permission_handler.dart';

class TimerService {
  final ValueNotifier<int> remainingSecondsNotifier = ValueNotifier<int>(0);
  int _startSeconds = 0;
  DateTime? _endTimeUtc;
  Timer? _uiTimer;
  static const String _kStartKey = 'timer_start_seconds';
  static const String _kRemKey = 'timer_remaining_seconds';
  static const String _kEndKey = 'timer_end_utc';
  VoidCallback? onTimerEnd;

  TimerService({this.onTimerEnd}) {
    tzdata.initializeTimeZones();
    _restoreState();
  }

  void setTimer(int seconds) {
    _startSeconds = seconds;
    remainingSecondsNotifier.value = seconds;
    _saveState();
  }

  Future<void> start() async {
    if (_endTimeUtc != null && _endTimeUtc!.isAfter(DateTime.now().toUtc())) {
      return;
    }

    final remaining = remainingSecondsNotifier.value;
    _endTimeUtc = DateTime.now().toUtc().add(Duration(seconds: remaining));
    _startUiTicker();
    _saveState();
  }

  Future<void> pause() async {
    _uiTimer?.cancel();
    _uiTimer = null;

    if (_endTimeUtc != null) {
      final nowUtc = DateTime.now().toUtc();
      final rem = _endTimeUtc!.difference(nowUtc).inSeconds;
      remainingSecondsNotifier.value = rem > 0 ? rem : 0;
    }

    _endTimeUtc = null;
    _saveState();
  }

  Future<void> reset({bool autoStart = false}) async {
    _uiTimer?.cancel();
    _uiTimer = null;
    _endTimeUtc = null;
    remainingSecondsNotifier.value = _startSeconds;
    _saveState();

    if (autoStart) await start();
  }

  void _startUiTicker() {
    _uiTimer?.cancel();
    _tickOnce();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tickOnce());
  }

  void _tickOnce() {
    if (_endTimeUtc == null) return;

    final nowUtc = DateTime.now().toUtc();
    final remaining = _endTimeUtc!.difference(nowUtc).inSeconds;

    if (remaining <= 0) {
      onTimerEnd?.call();
      remainingSecondsNotifier.value = 0;
      _uiTimer?.cancel();
      _uiTimer = null;
      _endTimeUtc = null;
      _saveState();
    } else {
      remainingSecondsNotifier.value = remaining;
    }
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kStartKey, _startSeconds);
    await prefs.setInt(_kRemKey, remainingSecondsNotifier.value);
    await prefs.setString(_kEndKey, _endTimeUtc?.toIso8601String() ?? '');
  }

  Future<void> _restoreState() async {
    final prefs = await SharedPreferences.getInstance();

    _startSeconds = prefs.getInt(_kStartKey) ?? 0;
    final rem = prefs.getInt(_kRemKey) ?? _startSeconds;
    remainingSecondsNotifier.value = rem;

    final endStr = prefs.getString(_kEndKey) ?? '';
    if (endStr.isNotEmpty) {
      _endTimeUtc = DateTime.tryParse(endStr)?.toUtc();
      if (_endTimeUtc != null) {
        final nowUtc = DateTime.now().toUtc();
        if (_endTimeUtc!.isAfter(nowUtc)) {
          _startUiTicker();
        } else {
          remainingSecondsNotifier.value = 0;
          _endTimeUtc = null;
        }
      }
    }
  }

  Future<void> dispose() async {
    _uiTimer?.cancel();
    remainingSecondsNotifier.dispose();
  }
}

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});
  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> with WidgetsBindingObserver {
  late final TimerService _timerService;
  final TextEditingController _controller = TextEditingController();
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) {
        onSelectNotification(notificationResponse.payload);
        print("Notification tapped!");
      },
    );

    if (Platform.isAndroid) {
      _requestNotificationPermission();
    }

    WidgetsBinding.instance.addObserver(this);
    _timerService = TimerService(onTimerEnd: showNotification);

    _timerService.remainingSecondsNotifier.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _requestNotificationPermission() async {
    if (Platform.isAndroid) {
      if (await Permission.notification.isDenied) {
        PermissionStatus status = await Permission.notification.request();
        print("Notification status: $status");
      }
    }
  }

  Future<void> onSelectNotification(String? payload) async {
    if (payload != null) print('Notification payload: $payload');
  }

  Future<void> showNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your channel description',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Timer End!',
      'Your timer has just finished!',
      platformChannelSpecifics,
      payload: 'Notification Payload',
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timerService.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) setState(() {});
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void startTimer() => _timerService.start();
  void setTimer(int length) {
    _timerService.setTimer(length);
    _controller.text = length.toString();
  }

  void pauseTimer() => _timerService.pause();
  void resetTimer({bool autoStart = false}) =>
      _timerService.reset(autoStart: autoStart);

  Future<void> _openCustomTimePicker() async {
    int minutes = 0;
    int seconds = 0;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2E32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Set Custom Time",
              style: TextStyle(color: Colors.white)),
          content: SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Text("Minutes",
                        style: TextStyle(color: Colors.white70)),
                    Expanded(
                      child: StatefulBuilder(
                        builder: (context, setState) {
                          return DropdownButton<int>(
                            value: minutes,
                            dropdownColor: const Color(0xFF2A2E32),
                            style: const TextStyle(color: Colors.white),
                            items: List.generate(
                              60,
                                  (i) => DropdownMenuItem(
                                value: i,
                                child: Text(i.toString().padLeft(2, '0')),
                              ),
                            ),
                            onChanged: (v) => setState(() => minutes = v!),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text("Seconds",
                        style: TextStyle(color: Colors.white70)),
                    Expanded(
                      child: StatefulBuilder(
                        builder: (context, setState) {
                          return DropdownButton<int>(
                            value: seconds,
                            dropdownColor: const Color(0xFF2A2E32),
                            style: const TextStyle(color: Colors.white),
                            items: List.generate(
                              60,
                                  (i) => DropdownMenuItem(
                                value: i,
                                child: Text(i.toString().padLeft(2, '0')),
                              ),
                            ),
                            onChanged: (v) => setState(() => seconds = v!),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
              const Text("Cancel", style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () {
                final totalSeconds = minutes * 60 + seconds;
                setTimer(totalSeconds);
                Navigator.pop(context);
              },
              child: const Text("Set", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _timerService.remainingSecondsNotifier.value;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1E22),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scaleFactor =
            (constraints.maxHeight / 800).clamp(0.7, 1.0);

            return Transform.scale(
              scale: scaleFactor,
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: Column(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width * 0.5,
                          height: MediaQuery.of(context).size.width * 0.5,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _formatTime(remaining),
                            style: const TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          children: [
                            _PulseButton(label: '0', onTap: () => setTimer(0)),
                            _PulseButton(
                                label: '10',
                                onTap: () => setTimer(10 * 60)),
                            _PulseButton(
                                label: '30',
                                onTap: () => setTimer(30 * 60)),
                            _PulseButton(
                              label: 'Set',
                              onTap: _openCustomTimePicker,
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 20,
                          children: [
                            _PulseIconButton(
                                icon: Icons.play_arrow, onTap: startTimer),
                            _PulseIconButton(
                                icon: Icons.pause, onTap: pauseTimer),
                            _PulseIconButton(
                                icon: Icons.replay, onTap: () => resetTimer()),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PulseButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _PulseButton({required this.label, required this.onTap});
  @override
  State<_PulseButton> createState() => _PulseButtonState();
}

class _PulseButtonState extends State<_PulseButton> {
  bool _pressed = false;
  void _animatePulse() async {
    setState(() => _pressed = true);
    await Future.delayed(const Duration(milliseconds: 100));
    setState(() => _pressed = false);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 1.1 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _animatePulse,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.brown[800],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            widget.label,
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      ),
    );
  }
}

class _PulseIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _PulseIconButton({required this.icon, required this.onTap});
  @override
  State<_PulseIconButton> createState() => _PulseIconButtonState();
}

class _PulseIconButtonState extends State<_PulseIconButton> {
  bool _pressed = false;
  void _animatePulse() async {
    setState(() => _pressed = true);
    await Future.delayed(const Duration(milliseconds: 100));
    setState(() => _pressed = false);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 1.2 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _animatePulse,
        child: Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: Colors.white10,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(widget.icon, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}
