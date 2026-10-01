import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/employee.dart';

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
  }

  // ------------------------------------------------------------
  // حذف موظف
  // ------------------------------------------------------------
  Future<void> removeEmployee(String id) async {
    await _initialization;

    final oldLength = _employees.length;
    _employees.removeWhere((employee) => employee.id == id);

    if (_employees.length == oldLength) return;

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

      // البيانات التجريبية تظهر فقط عند أول تشغيل وعدم وجود بيانات محفوظة.
      if ((saved == null || saved.isEmpty) && _employees.isEmpty) {
        _employees.addAll([
          Employee(
            id: '1',
            name: 'أحمد المحمد',
            idNumber: '1092837465',
            expiryDate: '2027-05-20',
            status: 'سارية',
          ),
          Employee(
            id: '2',
            name: 'سارة الخالد',
            idNumber: '1029384756',
            expiryDate: '2026-11-10',
            status: 'سارية',
          ),
          Employee(
            id: '3',
            name: 'إبراهيم طاهر الكشميري',
            idNumber: '2535922492',
            expiryDate: '2026-10-16',
            status: 'تحتاج متابعة',
          ),
        ]);

        await _saveEmployeesToStorage();
      }
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
