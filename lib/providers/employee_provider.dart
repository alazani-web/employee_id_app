import 'dart:convert'; // ✅ كود صحيح
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/employee.dart';

class EmployeeProvider extends ChangeNotifier {
  List<Employee> _employees = [];

  EmployeeProvider() {
    _loadEmployeesFromStorage();
  }

  List<Employee> get employees => _employees;
  int get employeeCount => _employees.length;

  // إضافة موظف
  Future<void> addEmployee(Employee employee) async {
    employee.logs.add("تمت إضافة الموظف بتاريخ ${DateTime.now().toString().split(' ')[0]}");
    _employees.add(employee);
    notifyListeners();
    await _saveEmployeesToStorage();
  }

  // تعديل بيانات موظف
  Future<void> updateEmployee(Employee updatedEmp) async {
    final index = _employees.indexWhere((e) => e.id == updatedEmp.id);
    if (index != -1) {
      updatedEmp.logs.add("تم تعديل البيانات بتاريخ ${DateTime.now().toString().split(' ')[0]}");
      _employees[index] = updatedEmp;
      notifyListeners();
      await _saveEmployeesToStorage();
    }
  }

  // تجديد هوية موظف
  Future<void> renewEmployeeId(String id, String newExpiryDate) async {
    final index = _employees.indexWhere((e) => e.id == id);
    if (index != -1) {
      final emp = _employees[index];
      emp.logs.add("تم تجديد الهوية حتى $newExpiryDate بتاريخ ${DateTime.now().toString().split(' ')[0]}");
      _employees[index] = emp.copyWith(
        expiryDate: newExpiryDate,
        status: "سارية",
      );
      notifyListeners();
      await _saveEmployeesToStorage();
    }
  }

  // حذف موظف
  Future<void> removeEmployee(String id) async {
    _employees.removeWhere((emp) => emp.id == id);
    notifyListeners();
    await _saveEmployeesToStorage();
  }

  // حفظ في SharedPreferences
  Future<void> _saveEmployeesToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> encodedList = _employees.map((emp) => jsonEncode(emp.toJson())).toList();
    await prefs.setStringList('saved_employees', encodedList);
  }

  // تحميل البيانات
  Future<void> _loadEmployeesFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? encodedList = prefs.getStringList('saved_employees');

    if (encodedList != null && encodedList.isNotEmpty) {
      _employees = encodedList.map((item) => Employee.fromJson(jsonDecode(item))).toList();
    } else {
      _employees = [
        Employee(
          id: "1",
          name: "أحمد المحمد",
          idNumber: "1092837465",
          expiryDate: "2027-05-20",
          status: "سارية",
        ),
        Employee(
          id: "2",
          name: "سارة الخالد",
          idNumber: "1029384756",
          expiryDate: "2026-11-10",
          status: "سارية",
        ),
        Employee(
          id: "3",
          name: "إبراهيم طاهر الكشميري",
          idNumber: "2535922492",
          expiryDate: "2026-10-16",
          status: "تحتاج متابعة",
        ),
      ];
      await _saveEmployeesToStorage();
    }
    notifyListeners();
  }
}