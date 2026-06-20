import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    // Initialize Timezone
    tz.initializeTimeZones();
    // Default to local timezone based on device if possible, but for simplicity, we'll use a fixed or let tz handle it.
    // For production, you might want to use flutter_timezone package to get device timezone. 
    // Here we assume UTC or whatever default tz sets up, but ideally we need local timezone.
    // We'll use a generic approach for now.

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );

    _isInitialized = true;
  }

  Future<void> requestPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
        
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> cancelAllReminders() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> scheduleSmartReminders({required bool hasJournalToday}) async {
    await cancelAllReminders(); // Clear existing

    // 4x a day: 09:00, 13:00, 17:00, 20:00
    final List<int> reminderHours = [9, 13, 17, 20];
    int idCounter = 100;

    final now = tz.TZDateTime.now(tz.local);

    for (int hour in reminderHours) {
      // Calculate next scheduled time
      tz.TZDateTime scheduledDate =
          tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, 0);

      // If user HAS written a journal today, all reminders for today should be skipped, start from tomorrow.
      // If user HAS NOT written a journal today, skip only the ones that already passed today.
      if (hasJournalToday || scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: idCounter++,
        title: 'Waktunya Menulis Jurnal! 📝',
        body: 'Bagaimana harimu? Luangkan waktu sejenak untuk menuliskannya.',
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_journal_reminder',
            'Pengingat Jurnal Harian',
            channelDescription: 'Notifikasi untuk mengingatkan Anda menulis jurnal setiap hari.',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // Repeats daily at the same time
      );
    }
  }

  Future<void> setNotificationToggle(bool value, {bool hasJournalToday = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isNotificationEnabled', value);

    if (value) {
      await requestPermissions();
      await scheduleSmartReminders(hasJournalToday: hasJournalToday);
    } else {
      await cancelAllReminders();
    }
  }

  Future<bool> getNotificationToggle() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isNotificationEnabled') ?? true; // Default true if you want, or false
  }
}
