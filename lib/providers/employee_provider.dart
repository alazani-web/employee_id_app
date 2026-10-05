import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/employee.dart';
import '../services/notification_service.dart';
import '../utils/renewal_calculator.dart';

class EmployeeProvider extends ChangeNotifier {
  static const String _storageKey = 'saved_employees';

  final List<Employee> _employees = [];
  late final Future<void> _initialization;

  EmployeeProvider() {
    _initialization = _loadEmployeesFromStorage();
  }

  List<Employee> get employees => List.unmodifiable(_employees);

  int get employeeCount => _employees.length;

  String _normalizeIdNumber(String value) {
    var result = value.trim();

    const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
    const westernDigits = '0123456789';

    for (int i = 0; i < arabicDigits.length; i++) {
      result = result.replaceAll(arabicDigits[i], westernDigits[i]);
    }

    result = result.replaceAll(RegExp(r'(?<=\d)\.0+$'), '');
    return result.replaceAll(RegExp(r'[\s\-_/]+'), '');
  }

  Future<void> _syncEmployeeNotification(Employee employee) async {
    final expiry = RenewalCalculator.parseDate(employee.expiryDate);
    if (expiry == null || employee.id.isEmpty) return;

    try {
      await NotificationService.instance.scheduleEmployee(
        employeeId: employee.id,
        employeeName: employee.name,
        identityExpiry: expiry,
      );
    } catch (e) {
      debugPrint('Employee notification error: $e');
    }
  }

  // ------------------------------------------------------------
  // إضافة موظف واحد
  // ------------------------------------------------------------
  Future<void> addEmployee(Employee employee) async {
    await _initialization;

    final idNumber = _normalizeIdNumber(employee.idNumber);

    // منع التكرار إذا كان رقم الهوية موجوداً بالفعل.
    if (idNumber.isNotEmpty &&
        _employees.any((e) => _normalizeIdNumber(e.idNumber) == idNumber)) {
      return;
    }

    employee.logs.add(
      'تمت إضافة الموظف بتاريخ ${_today()}',
    );

    _employees.add(employee);
    notifyListeners();
    await _saveEmployeesToStorage();
    await _syncEmployeeNotification(employee);
  }

  // ------------------------------------------------------------
  // إضافة مجموعة موظفين دفعة واحدة
  // هذه هي الدالة المستخدمة في الاستيراد الجماعي.
  // ------------------------------------------------------------
  Future<int> addEmployeesBatch(List<Employee> newEmployees) async {
    await _initialization;

    if (newEmployees.isEmpty) return 0;

    final existingIds = _employees
        .map((e) => _normalizeIdNumber(e.idNumber))
        .where((id) => id.isNotEmpty)
        .toSet();

    final batchIds = <String>{};
    final validEmployees = <Employee>[];

    for (final employee in newEmployees) {
      final idNumber = _normalizeIdNumber(employee.idNumber);

      // إذا كان للموظف رقم هوية، نمنع تكراره داخل البيانات الحالية
      // وكذلك داخل الملف نفسه.
      if (idNumber.isNotEmpty) {
        if (existingIds.contains(idNumber) || batchIds.contains(idNumber)) {
          continue;
        }
        batchIds.add(idNumber);
      }

      employee.logs.add(
        'تمت إضافة الموظف بتاريخ ${_today()}',
      );

      validEmployees.add(employee);
    }

    if (validEmployees.isEmpty) return 0;

    _employees.addAll(validEmployees);
    notifyListeners();
    await _saveEmployeesToStorage();
    for (final employee in validEmployees) {
      await _syncEmployeeNotification(employee);
    }

    return validEmployees.length;
  }

  // ------------------------------------------------------------
  // تعديل موظف
  // ------------------------------------------------------------
  Future<void> updateEmployee(Employee updatedEmployee) async {
    await _initialization;

    final index = _employees.indexWhere(
      (employee) => employee.id == updatedEmployee.id,
    );

    if (index == -1) return;

    updatedEmployee.logs.add(
      'تم تعديل البيانات بتاريخ ${_today()}',
    );

    _employees[index] = updatedEmployee;
    notifyListeners();
    await _saveEmployeesToStorage();
    await _syncEmployeeNotification(updatedEmployee);
  }

  // ------------------------------------------------------------
  // تجديد هوية موظف
  // ------------------------------------------------------------
  Future<void> renewEmployeeId(
    String id,
    String newExpiryDate,
  ) async {
    await _initialization;

    final index = _employees.indexWhere((employee) => employee.id == id);
    if (index == -1) return;

    final employee = _employees[index];

    employee.logs.add(
      'تم تجديد الهوية حتى $newExpiryDate بتاريخ ${_today()}',
    );

    _employees[index] = employee.copyWith(
      expiryDate: newExpiryDate,
      status: 'سارية',
    );

    notifyListeners();
    await _saveEmployeesToStorage();
    await _syncEmployeeNotification(_employees[index]);
  }

  // ------------------------------------------------------------
  // حذف موظف
  // ------------------------------------------------------------
  Future<void> removeEmployee(String id) async {
    await _initialization;

    final oldLength = _employees.length;
    _employees.removeWhere((employee) => employee.id == id);

    if (_employees.length == oldLength) return;

    try {
      await NotificationService.instance.cancelItemNotifications(
        type: NotificationType.employee,
        itemId: id,
      );
    } catch (_) {}

    notifyListeners();
    await _saveEmployeesToStorage();
  }

  // ------------------------------------------------------------
  // حفظ البيانات
  // ------------------------------------------------------------
  Future<void> _saveEmployeesToStorage() async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = _employees
        .map((employee) => jsonEncode(employee.toJson()))
        .toList();

    await prefs.setStringList(_storageKey, encoded);
  }

  // ------------------------------------------------------------
  // تحميل البيانات
  // مهم جداً: ننتظر اكتمال التحميل قبل السماح بأي إضافة أو تعديل.
  // هذا يمنع أن يتم استيراد الموظفين ثم يقوم التحميل القديم بمسحهم.
  // ------------------------------------------------------------
  Future<void> reloadFromStorage() async {
    await _loadEmployeesFromStorage();
  }

  Future<void> _loadEmployeesFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_storageKey);

      _employees.clear();

      if (saved != null && saved.isNotEmpty) {
        for (final item in saved) {
          try {
            final json = jsonDecode(item);
            if (json is Map<String, dynamic>) {
              _employees.add(Employee.fromJson(json));
            } else if (json is Map) {
              _employees.add(
                Employee.fromJson(Map<String, dynamic>.from(json)),
              );
            }
          } catch (e) {
            debugPrint('Employee load item error: $e');
          }
        }
      }

      // لا نضيف بيانات تجريبية. يبدأ النظام ببيانات المستخدم الفعلية فقط.
    } catch (e, stackTrace) {
      // لا نترك الـ Provider في حالة تمنع الاستيراد إذا حدث خطأ في التخزين.
      debugPrint('Employee storage error: $e');
      debugPrint(stackTrace.toString());
      _employees.clear();
    }

    notifyListeners();
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
