import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // Use default launcher icon as the notification icon
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings: settings);

    // Request permissions for Android 13+
    final androidImplementation = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    _initialized = true;
  }

  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    await init();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'payment_channel',
      'Thông báo thanh toán',
      channelDescription: 'Thông báo về tình trạng thanh toán và nâng cấp gói cước',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}
