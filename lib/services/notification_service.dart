import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/models.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'booking_reminder';
  static const _channelName = 'Захиалгын сануулга';

  static Future<void> init() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ulaanbaatar'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Android 13+ notification permission
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> scheduleBookingReminder({
    required SportVenue venue,
    required DateTime date,
    required TimeSlot timeSlot,
  }) async {
    final parts = timeSlot.time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    // Захиалгын цагийг шууд Asia/Ulaanbaatar бүсэд байгуулна, ингэснээр
    // утасны системийн timezone-оос үл хамаарч зөв wall-clock цагт ирнэ
    final bookingTzTime = tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );

    final tzReminderTime = bookingTzTime.subtract(const Duration(hours: 1));

    if (tzReminderTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    final notifId = Object.hash(
      venue.id,
      '${date.year}-${date.month}-${date.day}',
      timeSlot.time,
    ) & 0x7FFFFFFF;

    await _plugin.zonedSchedule(
      notifId,
      '⏰ Захиалгын сануулга',
      '${venue.name} заалд ${timeSlot.time} цагаас захиалга байна — 1 цаг үлдлээ',
      tzReminderTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Захиалгын цагаас 1 цагийн өмнө сануулга',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(
            '${venue.name} заалд ${timeSlot.time}–${timeSlot.endTime} цагаас захиалга байна.\nБайршил: ${venue.location}',
            summaryText: venue.type,
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelBookingReminder({
    required String venueId,
    required DateTime date,
    required String timeSlot,
  }) async {
    final notifId = Object.hash(
      venueId,
      '${date.year}-${date.month}-${date.day}',
      timeSlot,
    ) & 0x7FFFFFFF;
    await _plugin.cancel(notifId);
  }
}
