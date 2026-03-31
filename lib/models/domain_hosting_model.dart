import 'dart:convert';

class ClientDomain {
  final int? id;
  final String? domainName;
  final String? companyName;
  final DateTime? purchaseDate;
  final DateTime? expiryDate;
  final int? planYears;
  final String? domainProvider;
  final String? domainUsername;
  final String? domainPassword;
  final String? status;
  final String? renewCharges;
  final int? clientId;
  final int? projectId;
  final Map<String, dynamic>? client;
  final Map<String, dynamic>? project;

  ClientDomain({
    this.id,
    this.domainName,
    this.companyName,
    this.purchaseDate,
    this.expiryDate,
    this.planYears,
    this.domainProvider,
    this.domainUsername,
    this.domainPassword,
    this.status,
    this.renewCharges,
    this.clientId,
    this.projectId,
    this.client,
    this.project,
  });

  factory ClientDomain.fromJson(Map<String, dynamic> json) {
    return ClientDomain(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? ''),
      domainName: json['domain_name']?.toString(),
      companyName: json['company_name']?.toString(),
      purchaseDate: json['purchase_date'] != null
          ? DateTime.tryParse(json['purchase_date'].toString())
          : null,
      expiryDate: json['expiry_date'] != null
          ? DateTime.tryParse(json['expiry_date'].toString())
          : null,
      planYears: json['plan_years'] is int
          ? json['plan_years']
          : int.tryParse(json['plan_years']?.toString() ?? ''),
      domainProvider: json['domain_provider']?.toString(),
      domainUsername: json['domain_username']?.toString(),
      domainPassword: json['domain_password']?.toString(),
      status: json['status']?.toString(),
      renewCharges: json['renew_charges']?.toString(),
      clientId: json['client_id'] is int
          ? json['client_id']
          : int.tryParse(json['client_id']?.toString() ?? ''),
      projectId: json['project_id'] is int
          ? json['project_id']
          : int.tryParse(json['project_id']?.toString() ?? ''),
      client: json['client'] is Map<String, dynamic> ? json['client'] : null,
      project: json['project'] is Map<String, dynamic> ? json['project'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'domain_name': domainName,
      'company_name': companyName,
      'purchase_date': purchaseDate?.toIso8601String().split('T')[0],
      'expiry_date': expiryDate?.toIso8601String().split('T')[0],
      'plan_years': planYears,
      'domain_provider': domainProvider,
      'domain_username': domainUsername,
      'domain_password': domainPassword,
      'status': status,
      'renew_charges': renewCharges,
      'client_id': clientId,
      'project_id': projectId,
    };
  }
}

class ClientHosting {
  final int? id;
  final String? domainName;
  final String? companyName;
  final String? hostingService;
  final DateTime? purchaseDate;
  final DateTime? expiryDate;
  final String? paymentAmount;
  final String? paymentMode;
  final String? status;
  final int? clientId;
  final int? projectId;
  final Map<String, dynamic>? client;
  final Map<String, dynamic>? project;

  ClientHosting({
    this.id,
    this.domainName,
    this.companyName,
    this.hostingService,
    this.purchaseDate,
    this.expiryDate,
    this.paymentAmount,
    this.paymentMode,
    this.status,
    this.clientId,
    this.projectId,
    this.client,
    this.project,
  });

  factory ClientHosting.fromJson(Map<String, dynamic> json) {
    return ClientHosting(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? ''),
      domainName: json['domain_name']?.toString(),
      companyName: json['company_name']?.toString(),
      hostingService: json['hosting_service']?.toString(),
      purchaseDate: json['purchase_date'] != null
          ? DateTime.tryParse(json['purchase_date'].toString())
          : null,
      expiryDate: json['expiry_date'] != null
          ? DateTime.tryParse(json['expiry_date'].toString())
          : null,
      paymentAmount: json['payment_amount']?.toString(),
      paymentMode: json['payment_mode']?.toString(),
      status: json['status']?.toString(),
      clientId: json['client_id'] is int
          ? json['client_id']
          : int.tryParse(json['client_id']?.toString() ?? ''),
      projectId: json['project_id'] is int
          ? json['project_id']
          : int.tryParse(json['project_id']?.toString() ?? ''),
      client: json['client'] is Map<String, dynamic> ? json['client'] : null,
      project: json['project'] is Map<String, dynamic> ? json['project'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'domain_name': domainName,
      'company_name': companyName,
      'hosting_service': hostingService,
      'purchase_date': purchaseDate?.toIso8601String().split('T')[0],
      'expiry_date': expiryDate?.toIso8601String().split('T')[0],
      'payment_amount': paymentAmount,
      'payment_mode': paymentMode,
      'status': status,
      'client_id': clientId,
      'project_id': projectId,
    };
  }
}
