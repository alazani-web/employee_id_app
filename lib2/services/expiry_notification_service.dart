import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// أنواع الأشياء التي يمكن مراقبة انتهائها.
enum ExpiryNotificationType {
  identity,
  visit,
  document,
  insurance,
}

/// بيانات الشيء الذي نريد جدولة إشعارات له.
class ExpiryNotificationItem {
  final String id;
  final String name;
  final DateTime expiryDate;
  final ExpiryNotificationType type;

  const ExpiryNotificationItem({
    required this.id,
    required this.name,
    required this.expiryDate,
    required this.type,
  });
}

/// خدمة إشعارات انتهاء الهويات والزيارات والوثائق والتأمين.
class ExpiryNotificationService {
  ExpiryNotificationService._();

  static final ExpiryNotificationService instance =
      ExpiryNotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // الأيام التي نرسل فيها التنبيه قبل الانتهاء.
  static const List<int> alertDays = <int>[
    30,
    15,
    7,
    3,
    1,
    0,
  ];

  // ============================================================
  // التهيئة
  // ============================================================

  Future<void> initialize() async {
    if (_initialized) return;

    // تهيئة timezone
    tz.initializeTimeZones();

    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();

      final locationName = timezoneInfo.identifier;

      final location = tz.getLocation(locationName);

      tz.setLocalLocation(location);
    } catch (e) {
      // في حال تعذر معرفة المنطقة الزمنية
      // نستخدم المنطقة المحلية الافتراضية.
      if (kDebugMode) {
        debugPrint('Timezone initialization failed: $e');
      }

      tz.setLocalLocation(tz.UTC);
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Android 13+
    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();

    _initialized = true;
  }

  // ============================================================
  // عند الضغط على الإشعار
  // ============================================================

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;

    if (payload == null || payload.isEmpty) {
      return;
    }

    if (kDebugMode) {
      debugPrint('Expiry notification clicked: $payload');
    }
  }

  // ============================================================
  // جدولة إشعارات عنصر واحد
  // ============================================================

  Future<void> scheduleForItem(
    ExpiryNotificationItem item,
  ) async {
    await initialize();

    // نحذف إشعارات هذا العنصر القديمة أولًا.
    await cancelForItem(item.id);

    final expiry = DateTime(
      item.expiryDate.year,
      item.expiryDate.month,
      item.expiryDate.day,
    );

    final now = DateTime.now();

    for (final daysBefore in alertDays) {
      final notificationDate = expiry.subtract(
        Duration(days: daysBefore),
      );

      // نجعل الإشعار الساعة 9 صباحًا.
      final scheduledDate = DateTime(
        notificationDate.year,
        notificationDate.month,
        notificationDate.day,
        9,
        0,
      );

      // لا نبرمج إشعارًا في الماضي.
      if (!scheduledDate.isAfter(now)) {
        continue;
      }

      final id = _notificationId(
        item.id,
        daysBefore,
      );

      final title = _buildTitle(item.type);

      final body = _buildBody(
        item: item,
        daysBefore: daysBefore,
      );

      final tzDate = tz.TZDateTime.from(
        scheduledDate,
        tz.local,
      );

      final notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId(item.type),
          _channelName(item.type),
          channelDescription: _channelDescription(item.type),
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(body),
        ),
      );

      await _notifications.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzDate,
        notificationDetails: notificationDetails,
        androidScheduleMode:
            AndroidScheduleMode.inexactAllowWhileIdle,
        payload: _buildPayload(item),
      );
    }
  }

  // ============================================================
  // جدولة مجموعة كاملة
  // ============================================================

  Future<void> scheduleAll(
    List<ExpiryNotificationItem> items,
  ) async {
    await initialize();

    for (final item in items) {
      await scheduleForItem(item);
    }
  }

  // ============================================================
  // إلغاء إشعارات عنصر واحد
  // ============================================================

  Future<void> cancelForItem(String itemId) async {
    await initialize();

    for (final daysBefore in alertDays) {
      final id = _notificationId(
        itemId,
        daysBefore,
      );

      await _notifications.cancel(
        id: id,
      );
    }
  }

  // ============================================================
  // إلغاء جميع الإشعارات
  // ============================================================

  Future<void> cancelAll() async {
    await initialize();

    await _notifications.cancelAll();
  }

  // ============================================================
  // إشعار فوري للاختبار
  // ============================================================

  Future<void> showTestNotification() async {
    await initialize();

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'expiry_notifications',
        'تنبيهات الانتهاء',
        channelDescription:
            'تنبيهات انتهاء الهويات والزيارات والوثائق والتأمين',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );

    await _notifications.show(
      id: 999999,
      title: 'نظام إدارة الهويات',
      body: 'تم تفعيل نظام إشعارات انتهاء الصلاحية بنجاح.',
      notificationDetails: notificationDetails,
    );
  }

  // ============================================================
  // العنوان
  // ============================================================

  String _buildTitle(
    ExpiryNotificationType type,
  ) {
    switch (type) {
      case ExpiryNotificationType.identity:
        return 'تنبيه انتهاء الهوية';

      case ExpiryNotificationType.visit:
        return 'تنبيه موعد الزيارة';

      case ExpiryNotificationType.document:
        return 'تنبيه انتهاء الوثيقة';

      case ExpiryNotificationType.insurance:
        return 'تنبيه انتهاء التأمين';
    }
  }

  // ============================================================
  // نص الإشعار
  // ============================================================

  String _buildBody({
    required ExpiryNotificationItem item,
    required int daysBefore,
  }) {
    final name = item.name.trim().isEmpty
        ? 'العنصر'
        : item.name.trim();

    if (daysBefore == 0) {
      return 'تنبيه: $name يستحق اليوم.';
    }

    if (daysBefore == 1) {
      return 'تنبيه: $name يستحق غدًا.';
    }

    return 'تنبيه: متبقي $daysBefore يوم على استحقاق $name.';
  }

  // ============================================================
  // قناة الإشعار
  // ============================================================

  String _channelId(
    ExpiryNotificationType type,
  ) {
    switch (type) {
      case ExpiryNotificationType.identity:
        return 'identity_expiry';

      case ExpiryNotificationType.visit:
        return 'visit_expiry';

      case ExpiryNotificationType.document:
        return 'document_expiry';

      case ExpiryNotificationType.insurance:
        return 'insurance_expiry';
    }
  }

  String _channelName(
    ExpiryNotificationType type,
  ) {
    switch (type) {
      case ExpiryNotificationType.identity:
        return 'تنبيهات الهويات';

      case ExpiryNotificationType.visit:
        return 'تنبيهات الزيارات';

      case ExpiryNotificationType.document:
        return 'تنبيهات الوثائق';

      case ExpiryNotificationType.insurance:
        return 'تنبيهات التأمين';
    }
  }

  String _channelDescription(
    ExpiryNotificationType type,
  ) {
    switch (type) {
      case ExpiryNotificationType.identity:
        return 'تنبيهات اقتراب انتهاء الهويات';

      case ExpiryNotificationType.visit:
        return 'تنبيهات مواعيد الزيارات';

      case ExpiryNotificationType.document:
        return 'تنبيهات اقتراب انتهاء الوثائق';

      case ExpiryNotificationType.insurance:
        return 'تنبيهات اقتراب انتهاء التأمين';
    }
  }

  // ============================================================
  // Payload
  // ============================================================

  String _buildPayload(
    ExpiryNotificationItem item,
  ) {
    return '${item.type.name}|${item.id}';
  }

  // ============================================================
  // إنشاء ID ثابت للإشعار
  // ============================================================

  int _notificationId(
    String itemId,
    int daysBefore,
  ) {
    var hash = 0;

    for (final codeUnit in itemId.codeUnits) {
      hash = ((hash * 31) + codeUnit) & 0x7fffffff;
    }

    return (hash + daysBefore + 1000) & 0x7fffffff;
  }
}