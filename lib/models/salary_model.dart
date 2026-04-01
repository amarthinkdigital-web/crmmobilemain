import 'dart:convert';

class Salary {
  final int? id;
  final int? userId;
  final int? month;
  final int? year;
  final String? baseSalary;
  final String? netSalary;
  final String? status;
  final String? payableDays;
  final String? totalAbsent;
  final String? totalPl;
  final String? deductionReason;
  final User? user;
  final DateTime? paidAt;
  final DateTime? createdAt;

  Salary({
    this.id,
    this.userId,
    this.month,
    this.year,
    this.baseSalary,
    this.netSalary,
    this.status,
    this.payableDays,
    this.totalAbsent,
    this.totalPl,
    this.deductionReason,
    this.user,
    this.paidAt,
    this.createdAt,
  });

  factory Salary.fromJson(Map<String, dynamic> json) {
    return Salary(
      id: json['id'] is String ? int.tryParse(json['id']) : json['id'],
      userId: json['user_id'] is String ? int.tryParse(json['user_id']) : json['user_id'],
      month: json['month'] is String ? int.tryParse(json['month']) : json['month'],
      year: json['year'] is String ? int.tryParse(json['year']) : json['year'],
      baseSalary: json['base_salary']?.toString(),
      netSalary: json['net_salary']?.toString(),
      status: json['status'],
      payableDays: json['payable_days']?.toString(),
      totalAbsent: json['total_absent']?.toString(),
      totalPl: json['total_pl']?.toString(),
      deductionReason:
          json['deduction_reason']?.toString() ??
          json['deduction_reasons']?.toString(),
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  List<String> get deductionReasons {
    if (deductionReason == null || deductionReason!.isEmpty) return [];
    try {
      // If it's a JSON string of a list
      if (deductionReason!.startsWith('[')) {
        final decoded = jsonDecode(deductionReason!);
        if (decoded is List) return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return [deductionReason!];
  }
}

class User {
  final int? id;
  final String? name;
  final String? email;

  User({this.id, this.name, this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is String ? int.tryParse(json['id']) : json['id'],
      name: json['name'],
      email: json['email'],
    );
  }
}
