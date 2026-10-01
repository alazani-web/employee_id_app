import 'dart:convert';

import 'package:flutter/foundation.dart';
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

  // إضافة موظف واحد
  Future<void> addEmployee(Employee employee) async {
    await _initialization;

    final idNumber = employee.idNumber.trim();

    if (idNumber.isNotEmpty &&
        _employees.any(
          (existing) => existing.idNumber.trim() == idNumber,
        )) {
      return;
    }

    employee.logs.add(
      'تمت إضافة الموظف بتاريخ ${_today()}',
    );

    _employees.add(employee);

    notifyListeners();

    await _saveEmployeesToStorage();
  }

  // إضافة مجموعة موظفين دفعة واحدة
  Future<int> addEmployeesBatch(List<Employee> newEmployees) async {
    await _initialization;

    if (newEmployees.isEmpty) {
      return 0;
    }

    final existingIdNumbers = _employees
        .map((employee) => employee.idNumber.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    final batchIdNumbers = <String>{};
    final validEmployees = <Employee>[];

    for (final employee in newEmployees) {
      final idNumber = employee.idNumber.trim();

      if (idNumber.isNotEmpty) {
        if (existingIdNumbers.contains(idNumber) ||
            batchIdNumbers.contains(idNumber)) {
          continue;
        }

        batchIdNumbers.add(idNumber);
      }

      employee.logs.add(
        'تمت إضافة الموظف بتاريخ ${_today()}',
      );

      validEmployees.add(employee);
    }

    if (validEmployees.isEmpty) {
      return 0;
    }

    _employees.addAll(validEmployees);

    notifyListeners();

    await _saveEmployeesToStorage();

    return validEmployees.length;
  }

  // تعديل بيانات موظف
  Future<void> updateEmployee(Employee updatedEmployee) async {
    await _initialization;

    final index = _employees.indexWhere(
      (employee) => employee.id == updatedEmployee.id,
    );

    if (index == -1) {
      return;
    }

    updatedEmployee.logs.add(
      'تم تعديل البيانات بتاريخ ${_today()}',
    );

    _employees[index] = updatedEmployee;

    notifyListeners();

    await _saveEmployeesToStorage();
  }

  // تجديد هوية موظف
  Future<void> renewEmployeeId(
    String id,
    String newExpiryDate,
  ) async {
    await _initialization;

    final index = _employees.indexWhere(
      (employee) => employee.id == id,
    );

    if (index == -1) {
      return;
    }

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

  // حذف موظف
  Future<void> removeEmployee(String id) async {
    await _initialization;

    final oldLength = _employees.length;

    _employees.removeWhere(
      (employee) => employee.id == id,
    );

    if (_employees.length == oldLength) {
      return;
    }

    notifyListeners();

    await _saveEmployeesToStorage();
  }

  // حفظ جميع الموظفين
  Future<void> _saveEmployeesToStorage() async {
    final prefs = await SharedPreferences.getInstance();

    final encodedEmployees = _employees
        .map(
          (employee) => jsonEncode(
            employee.toJson(),
          ),
        )
        .toList();

    await prefs.setStringList(
      _storageKey,
      encodedEmployees,
    );
  }

  // تحميل الموظفين
  Future<void> _loadEmployeesFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedEmployees = prefs.getStringList(
        _storageKey,
      );

      _employees.clear();

      if (savedEmployees != null && savedEmployees.isNotEmpty) {
        for (final item in savedEmployees) {
          try {
            final decoded = jsonDecode(item);

            if (decoded is Map<String, dynamic>) {
              _employees.add(
                Employee.fromJson(decoded),
              );
            } else if (decoded is Map) {
              _employees.add(
                Employee.fromJson(
                  Map<String, dynamic>.from(decoded),
                ),
              );
            }
          } catch (e) {
            debugPrint(
              'خطأ في تحميل موظف من التخزين: $e',
            );
          }
        }
      }

      // إنشاء بيانات تجريبية فقط عند عدم وجود بيانات محفوظة
      if ((savedEmployees == null || savedEmployees.isEmpty) &&
          _employees.isEmpty) {
        _employees.addAll(
          [
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
          ],
        );

        await _saveEmployeesToStorage();
      }
    } catch (e, stackTrace) {
      debugPrint(
        'خطأ في تحميل بيانات الموظفين: $e',
      );
      debugPrint(
        stackTrace.toString(),
      );

      _employees.clear();
    }

    notifyListeners();
  }

  String _today() {
    final now = DateTime.now();

    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }
}
