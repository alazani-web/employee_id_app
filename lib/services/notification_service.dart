import 'dart:convert';



import 'package:flutter/foundation.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:flutter_timezone/flutter_timezone.dart';

import 'package:shared_preferences/shared_preferences.dart';

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



  Future<void> initialize() async {

    if (_initialized) return;



    tz.initializeTimeZones();



    try {

      final timezoneInfo = await FlutterTimezone.getLocalTimezone();

      tz.setLocalLocation(

        tz.getLocation(timezoneInfo.identifier),

      );

    } catch (e) {

      if (kDebugMode) {

        debugPrint('Timezone initialization failed: $e');

      }

      // لا نضع UTC كخيار افتراضي للتطبيق السعودي.

      // timezone package تستخدم موقعها الافتراضي إذا تعذر الاكتشاف.

    }



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



    final androidImplementation =

        _notifications.resolvePlatformSpecificImplementation<

            AndroidFlutterLocalNotificationsPlugin>();



    await androidImplementation?.requestNotificationsPermission();



    _initialized = true;

  }



  void _onNotificationTap(NotificationResponse response) {

    if (kDebugMode) {

      debugPrint('Notification clicked: ${response.payload}');

    }

  }



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



  Future<void> scheduleNotification({

    required int id,

    required String title,

    required String body,

    required DateTime scheduledDate,

    String? payload,

  }) async {

    await initialize();



    final now = tz.TZDateTime.now(tz.local);

    final localDate = tz.TZDateTime(

      tz.local,

      scheduledDate.year,

      scheduledDate.month,

      scheduledDate.day,

      scheduledDate.hour,

      scheduledDate.minute,

    );



    if (!localDate.isAfter(now)) return;



    const androidDetails = AndroidNotificationDetails(

      'expiry_reminders',

      'تنبيهات الاستحقاق',

      channelDescription:

          'تنبيهات انتهاء الهويات والزيارات والوثائق والتأمين',

      importance: Importance.high,

      priority: Priority.high,

      icon: '@mipmap/ic_launcher',

      enableVibration: true,

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

    if (kDebugMode) {
      try {
        final pending = await _notifications.pendingNotificationRequests();
        final found = pending.any((item) => item.id == id);
        debugPrint(
          'NOTIFICATION SCHEDULED => id=$id | pending=$found | '
          'date=$localDate | payload=$payload | total=${pending.length}',
        );
      } catch (e) {
        debugPrint('NOTIFICATION PENDING CHECK ERROR => $e');
      }
    }

  }




  /// جدولة تذكير يومي يبدأ بعد انتهاء العنصر ويستمر
  /// حتى يتم تجديده أو حذف العنصر.
  Future<void> _scheduleDailyExpiredReminder({
    required NotificationType type,
    required String itemId,
    required String itemName,
    required DateTime expiryDate,
  }) async {
    await initialize();

    final now = tz.TZDateTime.now(tz.local);

    final expiryDay = tz.TZDateTime(
      tz.local,
      expiryDate.year,
      expiryDate.month,
      expiryDate.day,
      9,
      0,
    );

    // يبدأ التذكير اليومي من اليوم التالي للانتهاء.
    // إذا كان العنصر منتهيًا بالفعل، يبدأ من أقرب 9 صباحًا قادمة.
    tz.TZDateTime firstReminder;

    if (expiryDay.isAfter(now)) {
      firstReminder = tz.TZDateTime(
        tz.local,
        expiryDate.year,
        expiryDate.month,
        expiryDate.day + 1,
        9,
        0,
      );
    } else {
      final tomorrow = now.add(const Duration(days: 1));
      firstReminder = tz.TZDateTime(
        tz.local,
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        9,
        0,
      );
    }

    final cleanName =
        itemName.trim().isEmpty ? 'العنصر' : itemName.trim();

    const androidDetails = AndroidNotificationDetails(
      'expiry_reminders',
      'تنبيهات الاستحقاق',
      channelDescription:
          'تنبيهات انتهاء الهويات والزيارات والوثائق والتأمين',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.zonedSchedule(
      id: _notificationId(type, itemId, -1),
      title: _expiredTitleForType(type),
      body: _expiredDailyBodyForType(
        type: type,
        itemName: cleanName,
      ),
      scheduledDate: firstReminder,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '${type.name}:$itemId',
    );
  }

  String _expiredDailyBodyForType({
    required NotificationType type,
    required String itemName,
  }) {
    switch (type) {
      case NotificationType.employee:
        return 'هوية $itemName منتهية. سيستمر التذكير يوميًا حتى يتم التجديد.';
      case NotificationType.visit:
        return 'موعد زيارة $itemName منتهٍ. سيستمر التذكير يوميًا حتى يتم التحديث.';
      case NotificationType.document:
        return 'وثيقة $itemName منتهية. سيستمر التذكير يوميًا حتى يتم التجديد.';
      case NotificationType.insurance:
        return 'تأمين $itemName منتهٍ. سيستمر التذكير يوميًا حتى يتم التجديد.';
    }
  }

  Future<bool> _notificationsEnabled() async {

    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool('notifications_enabled') ?? true;

  }



  Future<void> scheduleItemReminders({

    required NotificationType type,

    required String itemId,

    required String itemName,

    required DateTime expiryDate,

    List<int> daysBefore = const [30, 15, 7, 3, 1],

  }) async {

    await initialize();



    await cancelItemNotifications(

      type: type,

      itemId: itemId,

    );



    if (!await _notificationsEnabled()) {

      return;

    }



    final cleanName =

        itemName.trim().isEmpty ? 'العنصر' : itemName.trim();



    for (final days in daysBefore) {

      final target = DateTime(

        expiryDate.year,

        expiryDate.month,

        expiryDate.day,

      ).subtract(Duration(days: days));



      final notificationDate = DateTime(

        target.year,

        target.month,

        target.day,

        9,

        0,

      );



      await scheduleNotification(

        id: _notificationId(type, itemId, days),

        title: _titleForType(type),

        body: _bodyForType(

          type: type,

          itemName: cleanName,

          daysBefore: days,

        ),

        scheduledDate: notificationDate,

        payload: '${type.name}:$itemId',

      );

    }



    final expiry = DateTime(

      expiryDate.year,

      expiryDate.month,

      expiryDate.day,

      9,

      0,

    );



    await scheduleNotification(

      id: _notificationId(type, itemId, 0),

      title: _expiredTitleForType(type),

      body: '$cleanName انتهى اليوم.',

      scheduledDate: expiry,

      payload: '${type.name}:$itemId',

    );



    // بعد انتهاء العنصر، يستمر التذكير يوميًا الساعة 9 صباحًا

    // إلى أن يتم التجديد أو حذف العنصر.

    await _scheduleDailyExpiredReminder(

      type: type,

      itemId: itemId,

      itemName: cleanName,

      expiryDate: expiryDate,

    );

  }



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



  String _bodyForType({

    required NotificationType type,

    required String itemName,

    required int daysBefore,

  }) {

    final remaining = daysBefore == 30

        ? 'خلال 30 يومًا'

        : daysBefore == 15

            ? 'خلال 15 يومًا'

            : daysBefore == 7

                ? 'خلال أسبوع'

                : daysBefore == 3

                    ? 'خلال 3 أيام'

                    : daysBefore == 1

                        ? 'غدًا'

                        : 'اليوم';



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



  Future<void> scheduleEmployee({

    required String employeeId,

    required String employeeName,

    required DateTime identityExpiry,

  }) {

    return scheduleItemReminders(

      type: NotificationType.employee,

      itemId: employeeId,

      itemName: employeeName,

      expiryDate: identityExpiry,

    );

  }



  Future<void> scheduleVisit({

    required String visitId,

    required String visitName,

    required DateTime visitDate,

  }) {

    return scheduleItemReminders(

      type: NotificationType.visit,

      itemId: visitId,

      itemName: visitName,

      expiryDate: visitDate,

      daysBefore: const [7, 3, 1],

    );

  }



  Future<void> scheduleInsurance({

    required String insuranceId,

    required String insuranceName,

    required DateTime expiryDate,

  }) {

    return scheduleItemReminders(

      type: NotificationType.insurance,

      itemId: insuranceId,

      itemName: insuranceName,

      expiryDate: expiryDate,

      daysBefore: const [30, 15, 7, 3, 1],

    );

  }



  Future<void> scheduleDocument({

    required String documentId,

    required String documentName,

    required DateTime expiryDate,

  }) {

    return scheduleItemReminders(

      type: NotificationType.document,

      itemId: documentId,

      itemName: documentName,

      expiryDate: expiryDate,

    );

  }



  Future<void> cancelItemNotifications({

    required NotificationType type,

    required String itemId,

  }) async {

    await initialize();



    // إلغاء الإشعارات الحالية بالطريقة الجديدة.

    // نلغي جميع الفواصل المستخدمة في هذا النوع حتى لا يبقى أي موعد قديم.

    for (final days in const [30, 15, 7, 3, 1, 0, -1]) {

      await _notifications.cancel(

        id: _notificationId(type, itemId, days),

      );

    }



    // مهم: قد تكون هناك إشعارات قديمة تم جدولتها بمعرّف مختلف

    // (مثلاً قبل تعديل طريقة إنشاء الـ ID). لذلك نبحث في الإشعارات

    // المجدولة نفسها بواسطة الـ payload ونلغي أي إشعار يخص هذا العنصر.

    try {

      final pending = await _notifications.pendingNotificationRequests();

      final expectedPayload = '${type.name}:$itemId';



      for (final notification in pending) {

        if (notification.payload == expectedPayload) {

          await _notifications.cancel(id: notification.id);

        }

      }

    } catch (e) {

      if (kDebugMode) {

        debugPrint('Notification payload cancellation error: $e');

      }

    }

  }



  Future<void> rescheduleItem({

    required NotificationType type,

    required String itemId,

    required String itemName,

    required DateTime expiryDate,

  }) async {

    await cancelItemNotifications(type: type, itemId: itemId);

    await scheduleItemReminders(

      type: type,

      itemId: itemId,

      itemName: itemName,

      expiryDate: expiryDate,

    );

  }



  Future<void> cancelAll() async {

    await initialize();

    await _notifications.cancelAll();

  }



  Future<void> showTestNotification() async {

    await initialize();



    const details = NotificationDetails(

      android: AndroidNotificationDetails(

        'expiry_test',

        'اختبار الإشعارات',

        channelDescription: 'إشعار اختبار النظام',

        importance: Importance.max,

        priority: Priority.high,

        icon: '@mipmap/ic_launcher',

      ),

    );



    await _notifications.show(

      id: 999999,

      title: 'نظام إدارة الهويات',

      body: 'الإشعارات تعمل بشكل صحيح.',

      notificationDetails: details,

    );

  }



  Future<List<PendingNotificationRequest>> pendingNotifications() async {

    await initialize();

    return _notifications.pendingNotificationRequests();

  }




  /// اختبار جدولة حقيقي باستخدام zonedSchedule بعد دقيقة.
  Future<void> scheduleDebugScheduledNotification({
    int minutesFromNow = 1,
  }) async {
    await initialize();

    final scheduled =
        DateTime.now().add(Duration(minutes: minutesFromNow));

    await scheduleNotification(
      id: 999998,
      title: 'اختبار الإشعار المجدول',
      body: 'إذا ظهر هذا الإشعار فجدولة Android تعمل بشكل صحيح.',
      scheduledDate: scheduled,
      payload: 'debug_scheduled_notification',
    );

    if (kDebugMode) {
      try {
        final pending = await _notifications.pendingNotificationRequests();
        final found = pending.any((item) => item.id == 999998);
        debugPrint(
          'SCHEDULE TEST => foundInPending=$found | pendingCount=${pending.length}',
        );
      } catch (e) {
        debugPrint('SCHEDULE TEST ERROR => $e');
      }
    }
  }

  /// فحص الإشعارات المجدولة حاليًا.
  Future<int> debugPendingNotificationCount() async {
    await initialize();

    final pending =
        await _notifications.pendingNotificationRequests();

    if (kDebugMode) {
      debugPrint('PENDING NOTIFICATIONS => ${pending.length}');
      for (final item in pending.take(30)) {
        debugPrint(
          'PENDING => id=${item.id} | title=${item.title} | '
          'payload=${item.payload}',
        );
      }
    }

    return pending.length;
  }

  /// إعادة بناء الإشعارات من البيانات المحلية عند تشغيل التطبيق.

  /// هذا مهم حتى لا تعتمد الإشعارات على كون المستخدم ضغط زرًا داخل الشاشة.

  Future<void> syncStoredData() async {

    await initialize();



    final prefs = await SharedPreferences.getInstance();



    if (!(prefs.getBool('notifications_enabled') ?? true)) {

      await cancelAll();

      return;

    }



    final employees = prefs.getStringList('saved_employees') ?? const [];

    for (final raw in employees) {

      try {

        final map = jsonDecode(raw);

        if (map is! Map) continue;



        final expiry = _parseDate(map['expiryDate']?.toString() ?? '');

        if (expiry == null) continue;



        await scheduleEmployee(

          employeeId: map['id']?.toString() ?? '',

          employeeName: map['name']?.toString() ?? 'الموظف',

          identityExpiry: expiry,

        );

      } catch (e) {

        if (kDebugMode) debugPrint('Employee notification sync error: $e');

      }

    }



    final visits = prefs.getStringList('saved_visits') ?? const [];

    for (final raw in visits) {

      try {

        final map = jsonDecode(raw);

        if (map is! Map) continue;



        final id = map['id']?.toString() ?? '';

        final name = map['visitorName']?.toString() ?? 'الزائر';



        final expiry = _parseDate(map['expiryDate']?.toString() ?? '');

        if (expiry != null) {

          await scheduleVisit(

            visitId: id,

            visitName: name,

            visitDate: expiry,

          );

        }



        final insurance = _parseDate(

          map['insuranceExpiryDate']?.toString() ?? '',

        );



        if (insurance != null) {

          await scheduleInsurance(

            insuranceId: id,

            insuranceName: name,

            expiryDate: insurance,

          );

        }

      } catch (e) {

        if (kDebugMode) debugPrint('Visit notification sync error: $e');

      }

    }



    final rawDocuments =

        prefs.getString('employee_id_app_documents_v2');



    if (rawDocuments != null && rawDocuments.isNotEmpty) {

      try {

        final decoded = jsonDecode(rawDocuments);

        if (decoded is List) {

          for (final item in decoded) {

            if (item is! Map) continue;



            final expiry = _parseDate(

              item['expiry']?.toString() ?? '',

            );



            if (expiry == null) continue;



            final id =

                item['id']?.toString() ??

                item['number']?.toString() ??

                item['name']?.toString() ??

                '';



            await scheduleDocument(

              documentId: id,

              documentName:

                  item['name']?.toString() ?? 'الوثيقة',

              expiryDate: expiry,

            );

          }

        }

      } catch (e) {

        if (kDebugMode) debugPrint('Document notification sync error: $e');

      }

    }

  }



  DateTime? _parseDate(String value) {

    final normalized = value.trim().replaceAll('/', '-');

    if (normalized.isEmpty) return null;



    final direct = DateTime.tryParse(normalized);

    if (direct != null) {

      return DateTime(direct.year, direct.month, direct.day);

    }



    final parts = normalized.split('-');

    if (parts.length != 3) return null;



    final a = int.tryParse(parts[0]);

    final b = int.tryParse(parts[1]);

    final c = int.tryParse(parts[2]);



    if (a == null || b == null || c == null) return null;



    if (a > 31) {

      return DateTime.tryParse(

        '${a.toString().padLeft(4, '0')}-'

        '${b.toString().padLeft(2, '0')}-'

        '${c.toString().padLeft(2, '0')}',

      );

    }



    return DateTime.tryParse(

      '${c.toString().padLeft(4, '0')}-'

      '${b.toString().padLeft(2, '0')}-'

      '${a.toString().padLeft(2, '0')}',

    );

  }

}
