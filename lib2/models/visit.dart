import 'dart:convert';

class Visit {
  final String id;
  String visitorName;
  String passportNumber;
  String visaNumber;
  String borderNumber;
  String expiryDate;
  String insuranceExpiryDate;
  String notes;
  String status;
  List<String> logs;

  Visit({
    required this.id,
    required this.visitorName,
    this.passportNumber = '',
    this.visaNumber = '',
    this.borderNumber = '',
    required this.expiryDate,
    this.insuranceExpiryDate = '',
    this.notes = '',
    this.status = 'سارية',
    List<String>? logs,
  }) : logs = logs ?? [];

  Visit copyWith({
    String? id,
    String? visitorName,
    String? passportNumber,
    String? visaNumber,
    String? borderNumber,
    String? expiryDate,
    String? insuranceExpiryDate,
    String? notes,
    String? status,
    List<String>? logs,
  }) {
    return Visit(
      id: id ?? this.id,
      visitorName: visitorName ?? this.visitorName,
      passportNumber: passportNumber ?? this.passportNumber,
      visaNumber: visaNumber ?? this.visaNumber,
      borderNumber: borderNumber ?? this.borderNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      insuranceExpiryDate: insuranceExpiryDate ?? this.insuranceExpiryDate,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      logs: logs ?? List<String>.from(this.logs),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'visitorName': visitorName,
      'passportNumber': passportNumber,
      'visaNumber': visaNumber,
      'borderNumber': borderNumber,
      'expiryDate': expiryDate,
      'insuranceExpiryDate': insuranceExpiryDate,
      'notes': notes,
      'status': status,
      'logs': logs,
    };
  }

  factory Visit.fromJson(Map<String, dynamic> json) {
    return Visit(
      id: (json['id'] ?? '').toString(),
      visitorName: (json['visitorName'] ?? json['name'] ?? '').toString(),
      passportNumber: (json['passportNumber'] ?? json['passport'] ?? '').toString(),
      visaNumber: (json['visaNumber'] ?? '').toString(),
      borderNumber: (json['borderNumber'] ?? '').toString(),
      expiryDate: (json['expiryDate'] ?? '').toString(),
      insuranceExpiryDate: (json['insuranceExpiryDate'] ?? '').toString(),
      notes: (json['notes'] ?? '').toString(),
      status: (json['status'] ?? 'سارية').toString(),
      logs: json['logs'] is List
          ? List<String>.from(
              (json['logs'] as List).map((e) => e.toString()),
            )
          : [],
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory Visit.fromJsonString(String value) =>
      Visit.fromJson(jsonDecode(value) as Map<String, dynamic>);
}
