import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:flutter/services.dart';

class TimerService {
  final FlutterLocalNotificationsPlugin _notifPlugin =
  FlutterLocalNotificationsPlugin();

  final ValueNotifier<int> remainingSecondsNotifier = ValueNotifier<int>(0);

  int _startSeconds = 0;
  DateTime? _endTimeUtc;
  Timer? _uiTimer;

  static const String _kStartKey = 'timer_start_seconds';
  static const String _kRemKey = 'timer_remaining_seconds';
  static const String _kEndKey = 'timer_end_utc';
  static const int _notificationId = 0;

  TimerService() {
    // Initialize timezone database (required by zonedSchedule).
    tzdata.initializeTimeZones();
    _initNotifications();
    _restoreState();
  }

  Future<void> _initNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosInit = DarwinInitializationSettings();
    final settings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _notifPlugin.initialize(settings,
        onDidReceiveNotificationResponse: (response) {
          // handle tap if you want
        });

    // Request permissions on iOS. On Android, POST_NOTIFICATIONS permission must be
    // added to AndroidManifest.xml; for Android 13+ you should request at runtime.
    // NOT DONE YET, WILL NOT WORK
    await _notifPlugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  void setTimer(int seconds) {
    _startSeconds = seconds;
    remainingSecondsNotifier.value = seconds;
    _saveState();
  }

  Future<void> start() async {
    // If already running and finish time is in future, don't restart
    if (_endTimeUtc != null && _endTimeUtc!.isAfter(DateTime.now().toUtc())) {
      return;
    }

    final remaining = remainingSecondsNotifier.value;
    _endTimeUtc = DateTime.now().toUtc().add(Duration(seconds: remaining));
    await _scheduleNotificationAt(_endTimeUtc!);
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
    await _cancelScheduledNotification();
    _saveState();
  }

  Future<void> reset({bool autoStart = false}) async {
    _uiTimer?.cancel();
    _uiTimer = null;
    _endTimeUtc = null;
    remainingSecondsNotifier.value = _startSeconds;
    await _cancelScheduledNotification();
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
      remainingSecondsNotifier.value = 0;
      _uiTimer?.cancel();
      _uiTimer = null;
      _endTimeUtc = null;
      _saveState();
      // You can add a callback here if you want to notify the UI immediately
    } else {
      remainingSecondsNotifier.value = remaining;
    }
  }

  Future<void> _scheduleNotificationAt(DateTime endUtc) async {
    final tzDate = tz.TZDateTime.from(endUtc.toLocal(), tz.local);

    try {
      await _notifPlugin.zonedSchedule(
        _notificationId,
        'Timer finished',
        'Your timer has completed.',
        tzDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'timer_channel_id',
            'Timer',
            channelDescription: 'Timer notifications',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        // keep androidScheduleMode if you want exact; it may fail on some devices
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } on PlatformException catch (e) {
      // Exact alarms not permitted (or other platform error).
      // Log for debugging, but do NOT rethrow — allow the timer to continue.
      debugPrint('Notification scheduling failed: ${e.code} — ${e.message}');
      // Optionally: fallback to a non-exact schedule (inexact) or skip notification.
      // Do nothing further here so the timer still starts.
    } catch (e) {
      // Catch any other unexpected error to prevent crash.
      debugPrint('Notification scheduling unexpected error: $e');
    }
  }

  Future<void> _cancelScheduledNotification() async {
    await _notifPlugin.cancel(_notificationId);
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kStartKey, _startSeconds);
    await prefs.setInt(_kRemKey, remainingSecondsNotifier.value);
    await prefs.setString(
        _kEndKey, _endTimeUtc?.toIso8601String() ?? '');
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
          // still running: start UI ticker
          _startUiTicker();
        } else {
          // finished while app was closed
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _timerService = TimerService();
    // Rebuild when remaining seconds changes
    _timerService.remainingSecondsNotifier.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timerService.dispose();
    _controller.dispose();
    super.dispose();
  }

  // When the app resumes, the TimerService already uses wall-clock time,
  // but we ensure the UI ticker is running if necessary by reloading state.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // The TimerService persists state, so we can rely on it to recompute remaining time.
      // No extra action necessary here unless you want to force a UI update:
      if (mounted) setState(() {});
    }
  }

  String _formatTime(int seconds) {
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // UI wrappers that call the service
  void startTimer() => _timerService.start();
  void setTimer(int length) {
    _timerService.setTimer(length);
    _controller.text = length.toString();
  }

  void pauseTimer() => _timerService.pause();

  void resetTimer({bool autoStart = false}) =>
      _timerService.reset(autoStart: autoStart);

  @override
  Widget build(BuildContext context) {
    final remaining = _timerService.remainingSecondsNotifier.value;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1E22),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scaleFactor = (constraints.maxHeight / 800).clamp(0.7, 1.0);

            return Transform.scale(
              scale: scaleFactor,
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Timer display
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
                        const Text(
                          '=',
                          style: TextStyle(
                            fontSize: 40,
                            color: Colors.white54,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Preset buttons
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          children: [
                            _PulseButton(label: '0', onTap: () => setTimer(0)),
                            _PulseButton(
                                label: '10', onTap: () => setTimer(10 * 60)),
                            _PulseButton(
                                label: '30', onTap: () => setTimer(30 * 60)),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // Control buttons
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

/// A text button that briefly scales up when pressed.
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

/// An icon button that briefly scales up when pressed.
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
