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

    var localDate = tz.TZDateTime(
      tz.local,
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      scheduledDate.hour,
      scheduledDate.minute,
    );

    // إذا كان موعد التنبيه هو اليوم ولكن وقته مضى، لا نهمل التنبيه.
    // نرسله بعد ثوانٍ قليلة حتى يظهر فورًا بعد إضافة الموظف.
    // أما إذا كان يوم التنبيه قد مضى بالكامل، ننتقل للموعد التالي.
    final today = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
    );

    final scheduledDay = tz.TZDateTime(
      tz.local,
      localDate.year,
      localDate.month,
      localDate.day,
    );

    if (scheduledDay.isBefore(today)) {
      return;
    }

    if (!localDate.isAfter(now)) {
      localDate = now.add(const Duration(seconds: 5));
    }



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
  }) async {
    await scheduleItemReminders(
      type: NotificationType.employee,
      itemId: employeeId,
      itemName: employeeName,
      expiryDate: identityExpiry,
    );

    await showEmployeeExpiryAlertIfNeeded(
      employeeId: employeeId,
      employeeName: employeeName,
      identityExpiry: identityExpiry,
    );
  }

  /// يظهر تنبيهًا فوريًا لموظف جديد إذا كانت هويته قريبة من الانتهاء.
  /// يتم تسجيل التنبيه لكل دورة انتهاء حتى لا يتكرر عند كل تشغيل للتطبيق.
  Future<void> showEmployeeExpiryAlertIfNeeded({
    required String employeeId,
    required String employeeName,
    required DateTime identityExpiry,
  }) async {
    await initialize();

    if (!await _notificationsEnabled()) return;
    if (employeeId.trim().isEmpty) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDay = DateTime(
      identityExpiry.year,
      identityExpiry.month,
      identityExpiry.day,
    );

    final daysRemaining = expiryDay.difference(today).inDays;
    final prefs = await SharedPreferences.getInstance();
    final alertWindow = prefs.getInt('notification_days') ?? 30;

    if (daysRemaining < 0 || daysRemaining > alertWindow) return;

    final expiryKey =
        '${identityExpiry.year}-${identityExpiry.month.toString().padLeft(2, '0')}-${identityExpiry.day.toString().padLeft(2, '0')}';
    final markerKey = 'expiry_alert_shown_employee_${employeeId}_$expiryKey';

    if (prefs.getBool(markerKey) ?? false) return;

    final cleanName =
        employeeName.trim().isEmpty ? 'الموظف' : employeeName.trim();

    final body = daysRemaining == 0
        ? 'هوية $cleanName تنتهي اليوم.'
        : daysRemaining == 1
            ? 'هوية $cleanName ستنتهي غدًا.'
            : 'هوية $cleanName ستنتهي خلال $daysRemaining يومًا.';

    final id = _notificationId(
      NotificationType.employee,
      employeeId,
      1000 + daysRemaining,
    );

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'expiry_reminders',
        'تنبيهات الاستحقاق',
        channelDescription:
            'تنبيهات انتهاء الهويات والزيارات والوثائق والتأمين',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
      ),
    );

    await _notifications.show(
      id: id,
      title: 'تنبيه انتهاء الهوية',
      body: body,
      notificationDetails: details,
      payload: '${NotificationType.employee.name}:$employeeId',
    );

    await prefs.setBool(markerKey, true);

    if (kDebugMode) {
      debugPrint(
        'IMMEDIATE EMPLOYEE ALERT => $cleanName | days=$daysRemaining | id=$id',
      );
    }
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




  /// يعرض فورًا إشعارات الهويات القريبة من الانتهاء.
  /// هذا مخصص لزر "اختبار الإشعار الآن" حتى يختبر المستخدم
  /// التنبيهات الفعلية الموجودة في بيانات الموظفين، وليس إشعارًا تجريبيًا عامًا.
  Future<int> showCurrentIdentityExpiryAlerts({
    int withinDays = 30,
  }) async {
    await initialize();

    final prefs = await SharedPreferences.getInstance();

    if (!(prefs.getBool('notifications_enabled') ?? true)) {
      return 0;
    }

    final employees =
        prefs.getStringList('saved_employees') ?? const <String>[];

    final now = DateTime.now();
    int shownCount = 0;

    for (final raw in employees) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map) continue;

        final id = decoded['id']?.toString().trim() ?? '';
        final name = decoded['name']?.toString().trim() ?? 'الموظف';
        final expiry =
            _parseDate(decoded['expiryDate']?.toString() ?? '');

        if (expiry == null || id.isEmpty) continue;

        final today = DateTime(now.year, now.month, now.day);
        final expiryDay =
            DateTime(expiry.year, expiry.month, expiry.day);

        final daysRemaining = expiryDay.difference(today).inDays;

        // نعرض المنتهية والقريبة من الانتهاء حتى عدد الأيام المحدد.
        if (daysRemaining > withinDays) continue;

        final int notificationId =
            _notificationId(NotificationType.employee, id, 900);

        final String title;
        final String body;

        if (daysRemaining < 0) {
          title = 'انتهت الهوية';
          body = 'هوية $name منتهية منذ ${daysRemaining.abs()} يوم.';
        } else if (daysRemaining == 0) {
          title = 'انتهت الهوية اليوم';
          body = 'هوية $name تنتهي اليوم.';
        } else if (daysRemaining == 1) {
          title = 'تنبيه انتهاء الهوية';
          body = 'هوية $name ستنتهي غدًا.';
        } else {
          title = 'تنبيه انتهاء الهوية';
          body = 'هوية $name ستنتهي خلال $daysRemaining يومًا.';
        }

        await _notifications.show(
          id: notificationId,
          title: title,
          body: body,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'expiry_test',
              'اختبار تنبيهات الاستحقاق',
              channelDescription:
                  'عرض فوري للهويات القريبة من الانتهاء للاختبار',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              enableVibration: true,
            ),
          ),
          payload: '${NotificationType.employee.name}:$id',
        );

        shownCount++;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Current identity alert error: $e');
        }
      }
    }

    if (kDebugMode) {
      debugPrint(
        'CURRENT IDENTITY ALERT TEST => shown=$shownCount '
        '| totalEmployees=${employees.length} '
        '| withinDays=$withinDays',
      );
    }

    return shownCount;
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
