import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

enum NotificationType {
  employee,
  visit,
  document,
  insurance,
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ============================================================
  // تهيئة الخدمة
  // ============================================================

  Future<void> initialize() async {
    if (_initialized) return;

    // تهيئة المناطق الزمنية
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Android 13+
    await _requestPermissions();

    _initialized = true;
  }

  // ============================================================
  // الصلاحيات
  // ============================================================

  Future<void> _requestPermissions() async {
    final androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  // ============================================================
  // عند الضغط على الإشعار
  // ============================================================

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;

    if (payload == null || payload.isEmpty) {
      return;
    }

    // لاحقًا يمكن ربط payload بالتنقل داخل التطبيق.
    if (kDebugMode) {
      debugPrint('Notification clicked: $payload');
    }
  }

  // ============================================================
  // إنشاء ID ثابت للإشعار
  // ============================================================

  int _notificationId(
    NotificationType type,
    String itemId,
    int daysBefore,
  ) {
    final key = '${type.name}_${itemId}_$daysBefore';

    int hash = 0;

    for (final character in key.codeUnits) {
      hash = ((hash * 31) + character) & 0x7fffffff;
    }

    return hash;
  }

  // ============================================================
  // جدولة إشعار واحد
  // ============================================================

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    await initialize();

    final localDate = tz.TZDateTime.from(
      scheduledDate,
      tz.local,
    );

    // لا نضع إشعارًا في الماضي
    if (localDate.isBefore(tz.TZDateTime.now(tz.local))) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'expiry_reminders',
      'تنبيهات الاستحقاق',
      channelDescription:
          'تنبيهات انتهاء الهويات والزيارات والوثائق والتأمين',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: localDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  // ============================================================
  // جدولة تنبيهات عنصر
  // ============================================================

  Future<void> scheduleItemReminders({
    required NotificationType type,
    required String itemId,
    required String itemName,
    required DateTime expiryDate,
    List<int> daysBefore = const [30, 15, 7, 3, 1],
  }) async {
    await initialize();

    for (final days in daysBefore) {
      final notificationDate = expiryDate.subtract(
        Duration(days: days),
      );

      final id = _notificationId(
        type,
        itemId,
        days,
      );

      final title = _titleForType(type);

      final body = _bodyForType(
        type: type,
        itemName: itemName,
        daysBefore: days,
      );

      await scheduleNotification(
        id: id,
        title: title,
        body: body,
        scheduledDate: notificationDate,
        payload: '${type.name}:$itemId',
      );
    }

    // إشعار يوم الانتهاء
    final expiryId = _notificationId(
      type,
      itemId,
      0,
    );

    await scheduleNotification(
      id: expiryId,
      title: _expiredTitleForType(type),
      body: '$itemName انتهى اليوم.',
      scheduledDate: expiryDate,
      payload: '${type.name}:$itemId',
    );
  }

  // ============================================================
  // عناوين الإشعارات
  // ============================================================

  String _titleForType(NotificationType type) {
    switch (type) {
      case NotificationType.employee:
        return 'تنبيه انتهاء الهوية';

      case NotificationType.visit:
        return 'تنبيه موعد الزيارة';

      case NotificationType.document:
        return 'تنبيه انتهاء الوثيقة';

      case NotificationType.insurance:
        return 'تنبيه انتهاء التأمين';
    }
  }

  String _expiredTitleForType(NotificationType type) {
    switch (type) {
      case NotificationType.employee:
        return 'انتهت الهوية';

      case NotificationType.visit:
        return 'انتهى موعد الزيارة';

      case NotificationType.document:
        return 'انتهت الوثيقة';

      case NotificationType.insurance:
        return 'انتهى التأمين';
    }
  }

  // ============================================================
  // نص الإشعار
  // ============================================================

  String _bodyForType({
    required NotificationType type,
    required String itemName,
    required int daysBefore,
  }) {
    final remaining = _remainingText(daysBefore);

    switch (type) {
      case NotificationType.employee:
        return 'هوية $itemName ستنتهي $remaining.';

      case NotificationType.visit:
        return 'موعد زيارة $itemName سيكون $remaining.';

      case NotificationType.document:
        return 'وثيقة $itemName ستنتهي $remaining.';

      case NotificationType.insurance:
        return 'تأمين $itemName سينتهي $remaining.';
    }
  }

  String _remainingText(int days) {
    if (days == 30) {
      return 'خلال 30 يومًا';
    }

    if (days == 15) {
      return 'خلال 15 يومًا';
    }

    if (days == 7) {
      return 'خلال أسبوع';
    }

    if (days == 3) {
      return 'خلال 3 أيام';
    }

    if (days == 1) {
      return 'غدًا';
    }

    return 'اليوم';
  }

  // ============================================================
  // الموظفين
  // ============================================================

  Future<void> scheduleEmployee({
    required String employeeId,
    required String employeeName,
    required DateTime identityExpiry,
  }) async {
    await scheduleItemReminders(
      type: NotificationType.employee,
      itemId: employeeId,
      itemName: employeeName,
      expiryDate: identityExpiry,
    );
  }

  // ============================================================
  // الزيارات
  // ============================================================

  Future<void> scheduleVisit({
    required String visitId,
    required String visitName,
    required DateTime visitDate,
  }) async {
    await scheduleItemReminders(
      type: NotificationType.visit,
      itemId: visitId,
      itemName: visitName,
      expiryDate: visitDate,
      daysBefore: const [7, 3, 1],
    );
  }

  // ============================================================
  // الوثائق
  // ============================================================

  Future<void> scheduleDocument({
    required String documentId,
    required String documentName,
    required DateTime expiryDate,
  }) async {
    await scheduleItemReminders(
      type: NotificationType.document,
      itemId: documentId,
      itemName: documentName,
      expiryDate: expiryDate,
    );
  }

  // ============================================================
  // التأمين
  // ============================================================

  Future<void> scheduleInsurance({
    required String insuranceId,
    required String insuranceName,
    required DateTime expiryDate,
  }) async {
    await scheduleItemReminders(
      type: NotificationType.insurance,
      itemId: insuranceId,
      itemName: insuranceName,
      expiryDate: expiryDate,
    );
  }

  // ============================================================
  // إلغاء إشعارات عنصر محدد
  // ============================================================

  Future<void> cancelItemNotifications({
    required NotificationType type,
    required String itemId,
  }) async {
    await initialize();

    const reminderDays = [30, 15, 7, 3, 1, 0];

    for (final days in reminderDays) {
      final id = _notificationId(
        type,
        itemId,
        days,
      );

      await _notifications.cancel(id: id);
    }
  }

  // ============================================================
  // إعادة جدولة عنصر
  // ============================================================

  Future<void> rescheduleItem({
    required NotificationType type,
    required String itemId,
    required String itemName,
    required DateTime expiryDate,
  }) async {
    await cancelItemNotifications(
      type: type,
      itemId: itemId,
    );

    await scheduleItemReminders(
      type: type,
      itemId: itemId,
      itemName: itemName,
      expiryDate: expiryDate,
    );
  }

  // ============================================================
  // إلغاء جميع الإشعارات
  // ============================================================

  Future<void> cancelAll() async {
    await initialize();

    await _notifications.cancelAll();
  }

  // ============================================================
  // معرفة الإشعارات المجدولة
  // ============================================================

  Future<List<PendingNotificationRequest>>
      pendingNotifications() async {
    await initialize();

    return _notifications.pendingNotificationRequests();
  }
}