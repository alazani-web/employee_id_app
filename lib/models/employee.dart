class Employee {
  final String id;
  final String name;
  final String idNumber;
  final String expiryDate; // YYYY-MM-DD
  final String jobTitle;
  final String phoneNumber;
  final String status; // سارية، تحتاج متابعة، منتهية
  final List<String> logs;

  Employee({
    required this.id,
    required this.name,
    required this.idNumber,
    this.expiryDate = "",
    this.jobTitle = "موظف",
    this.phoneNumber = "",
    this.status = "سارية",
    List<String>? logs,
  }) : logs = logs ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'idNumber': idNumber,
      'expiryDate': expiryDate,
      'jobTitle': jobTitle,
      'phoneNumber': phoneNumber,
      'status': status,
      'logs': logs,
    };
  }

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      idNumber: json['idNumber'] ?? '',
      expiryDate: json['expiryDate'] ?? '',
      jobTitle: json['jobTitle'] ?? 'موظف',
      phoneNumber: json['phoneNumber'] ?? '',
      status: json['status'] ?? 'سارية',
      logs: List<String>.from(json['logs'] ?? []),
    );
  }

  Employee copyWith({
    String? name,
    String? idNumber,
    String? expiryDate,
    String? jobTitle,
    String? phoneNumber,
    String? status,
    List<String>? logs,
  }) {
    return Employee(
      id: id,
      name: name ?? this.name,
      idNumber: idNumber ?? this.idNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      jobTitle: jobTitle ?? this.jobTitle,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      status: status ?? this.status,
      logs: logs ?? List.from(this.logs),
    );
  }
}