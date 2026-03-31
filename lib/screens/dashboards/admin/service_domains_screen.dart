import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../services/api_service.dart';
import '../../../models/domain_hosting_model.dart';

class ServiceDomainsScreen extends StatefulWidget {
  const ServiceDomainsScreen({super.key});

  @override
  State<ServiceDomainsScreen> createState() => _ServiceDomainsScreenState();
}

class _ServiceDomainsScreenState extends State<ServiceDomainsScreen> {
  List<ClientDomain> _domains = [];
  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> _projects = [];
  bool _isLoading = true;
  String _errorMessage = '';

  final TextEditingController domainController = TextEditingController();
  final TextEditingController companyController = TextEditingController();
  final TextEditingController providerController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController renewChargesController = TextEditingController();
  final TextEditingController planYearsController = TextEditingController();
  final TextEditingController purchaseDateController = TextEditingController();

  int? selectedClientId;
  int? selectedProjectId;
  String selectedStatus = 'Active';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final results = await Future.wait([
        ApiService.getAdminDomains(),
        ApiService.getAdminClients(),
        ApiService.getAdminProjects(),
      ]);

      if (mounted) {
        setState(() {
          bool anyError = false;
          String errorMsg = '';

          if (results[0]['error'] == false) {
            _domains = (results[0]['data'] as List)
                .map((e) => ClientDomain.fromJson(e))
                .toList();
          } else {
            anyError = true;
            errorMsg += "Domains: ${results[0]['message']} ";
          }

          if (results[1]['error'] == false) {
            _clients = (results[1]['data'] as List).map((e) {
              final map = Map<String, dynamic>.from(e);
              map['id'] = int.tryParse(map['id']?.toString() ?? '');
              return map;
            }).toList();
          } else {
            anyError = true;
            errorMsg += "Clients: ${results[1]['message']} ";
          }

          if (results[2]['error'] == false) {
            _projects = (results[2]['data'] as List).map((e) {
              final map = Map<String, dynamic>.from(e);
              map['id'] = int.tryParse(map['id']?.toString() ?? '');
              return map;
            }).toList();
          } else {
            anyError = true;
            errorMsg += "Projects: ${results[2]['message']} ";
          }

          if (anyError) {
            _errorMessage = errorMsg;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "App Error: ${e.toString()}";
        });
      }
    }
  }

  void _showAddDomainSheet({ClientDomain? existing}) {
    if (existing != null) {
      domainController.text = existing.domainName ?? '';
      companyController.text = existing.companyName ?? '';
      providerController.text = existing.domainProvider ?? '';
      usernameController.text = existing.domainUsername ?? '';
      passwordController.text = existing.domainPassword ?? '';
      dateController.text = existing.expiryDate != null
          ? DateFormat('yyyy-MM-dd').format(existing.expiryDate!)
          : '';
      purchaseDateController.text = existing.purchaseDate != null
          ? DateFormat('yyyy-MM-dd').format(existing.purchaseDate!)
          : '';
      renewChargesController.text = existing.renewCharges ?? '';
      planYearsController.text = existing.planYears?.toString() ?? '1';
      selectedClientId = existing.clientId;
      selectedProjectId = existing.projectId;
      selectedStatus = existing.status ?? 'Active';
    } else {
      _clearControllers();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    children: [
                      Text(
                        existing == null ? "Add New Domain" : "Edit Domain",
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildDropdownField(
                        "Client",
                        _clients,
                        selectedClientId,
                        "company_name",
                        (val) => setModalState(() => selectedClientId = val),
                      ),
                      const SizedBox(height: 16),
                      _buildDropdownField(
                        "Project",
                        _projects,
                        selectedProjectId,
                        "project_name",
                        (val) => setModalState(() => selectedProjectId = val),
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        "Domain Name",
                        "example.com",
                        domainController,
                        Icons.language_rounded,
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        "Domain Provider",
                        "e.g. GoDaddy",
                        providerController,
                        Icons.dns_rounded,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputField(
                              "Username",
                              "Provider username",
                              usernameController,
                              Icons.person_outline,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildInputField(
                              "Password",
                              "Provider password",
                              passwordController,
                              Icons.lock_outline,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputField(
                              "Purchase Date",
                              "Select date",
                              purchaseDateController,
                              Icons.calendar_today_rounded,
                              isReadOnly: true,
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2030),
                                );
                                if (date != null) {
                                  setModalState(() {
                                    purchaseDateController.text = DateFormat(
                                      'yyyy-MM-dd',
                                    ).format(date);
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildInputField(
                              "Expiry Date",
                              "Select date",
                              dateController,
                              Icons.calendar_today_rounded,
                              isReadOnly: true,
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2030),
                                );
                                if (date != null) {
                                  setModalState(() {
                                    dateController.text = DateFormat(
                                      'yyyy-MM-dd',
                                    ).format(date);
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputField(
                              "Plan Years",
                              "1",
                              planYearsController,
                              Icons.timer_outlined,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildInputField(
                              "Renew Charges",
                              "0.00",
                              renewChargesController,
                              Icons.payments_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildStatusDropdown(
                        (val) => setModalState(() => selectedStatus = val),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => _handleSave(existing?.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.navy,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            existing == null
                                ? "Register Domain"
                                : "Update Details",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave(int? id) async {
    final body = {
      "project_id": selectedProjectId,
      "client_id": selectedClientId,
      "company_name": _clients.firstWhere(
        (c) => c['id'] == selectedClientId,
        orElse: () => {
          'company_name': companyController.text.isNotEmpty
              ? companyController.text
              : 'N/A',
        },
      )['company_name'],
      "domain_name": domainController.text,
      "purchase_date": purchaseDateController.text,
      "expiry_date": dateController.text,
      "plan_years": int.tryParse(planYearsController.text) ?? 1,
      "domain_provider": providerController.text,
      "domain_username": usernameController.text,
      "domain_password": passwordController.text,
      "status": selectedStatus,
      "renew_charges": double.tryParse(renewChargesController.text) ?? 0.0,
    };

    setState(() => _isLoading = true);

    final response = id != null
        ? await ApiService.updateAdminDomain(id, body)
        : await ApiService.createAdminDomain(body);

    setState(() => _isLoading = false);

    if (response['error'] == false) {
      if (mounted) Navigator.pop(context); // Close modal only on success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(id != null ? "Domain updated" : "Domain added")),
      );
      _fetchData();
    } else {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Operation Failed"),
            content: Text(response['message'] ?? "Unknown error occurred"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _deleteDomain(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this domain?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final response = await ApiService.deleteAdminDomain(id);
      if (response['error'] == false) {
        _fetchData();
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? "Failed to delete")),
        );
      }
    }
  }

  void _clearControllers() {
    domainController.clear();
    companyController.clear();
    providerController.clear();
    usernameController.clear();
    passwordController.clear();
    dateController.clear();
    purchaseDateController.clear();
    renewChargesController.clear();
    planYearsController.text = '1';
    selectedClientId = null;
    selectedProjectId = null;
    selectedStatus = 'Active';
  }

  Widget _buildDropdownField(
    String label,
    List<Map<String, dynamic>> items,
    int? value,
    String displayKey,
    Function(int?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.offWhite,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: items.any((e) => e['id'] == value) ? value : null,
              isExpanded: true,
              hint: Text("Select $label"),
              items: items
                  .map(
                    (e) => DropdownMenuItem<int>(
                      value: e['id'],
                      child: Text(e[displayKey] ?? 'Unknown'),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(
    String label,
    String hint,
    TextEditingController controller,
    IconData icon, {
    bool isReadOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: isReadOnly,
          onTap: onTap,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.grey400, size: 20),
            filled: true,
            fillColor: AppColors.offWhite,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown(Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Status",
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.offWhite,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedStatus,
              isExpanded: true,
              items: [
                "Active",
                "Expiring Soon",
                "Expired",
                "Pending",
              ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(
        children: [
          if (_errorMessage.isNotEmpty)
            Container(
              width: double.infinity,
              color: Colors.red.withOpacity(0.1),
              padding: const EdgeInsets.all(12),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.gold),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 24),
                          _buildStatCards(),
                          const SizedBox(height: 24),
                          if (_domains.isEmpty)
                            _buildEmptyState()
                          else
                            _buildDomainsTable(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDomainSheet(),
        backgroundColor: AppColors.navy,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("Add Domain", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Service Domains",
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          "Monitor and manage client domain registrations",
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.grey400,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCards() {
    int total = _domains.length;
    int active = _domains.where((d) => d.status == 'Active').length;
    int soon = _domains
        .where((d) => d.status?.contains('Soon') ?? false)
        .length;
    int expired = _domains.where((d) => d.status == 'Expired').length;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.15,
      children: [
        _buildStatTile(
          "Total Domains",
          total.toString(),
          Icons.language_rounded,
          AppColors.navy,
        ),
        _buildStatTile(
          "Active",
          active.toString(),
          Icons.check_circle_rounded,
          AppColors.success,
        ),
        _buildStatTile(
          "Expiring Soon",
          soon.toString(),
          Icons.warning_amber_rounded,
          AppColors.warning,
        ),
        _buildStatTile(
          "Expired",
          expired.toString(),
          Icons.error_outline_rounded,
          AppColors.error,
        ),
      ],
    );
  }

  Widget _buildStatTile(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.grey200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.navy,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey400,
                ),
                maxLines: 1,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDomainsTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              "Domain List",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  AppColors.navy.withOpacity(0.05),
                ),
                columnSpacing: 30,
                columns: [
                  _buildDataColumn("Domain Name"),
                  _buildDataColumn("Client/Company"),
                  _buildDataColumn("Provider"),
                  _buildDataColumn("Expiry Date"),
                  _buildDataColumn("Status"),
                  _buildDataColumn("Action"),
                ],
                rows: _domains.map((d) => _buildRow(d)).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataColumn _buildDataColumn(String label) {
    return DataColumn(
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.navy,
        ),
      ),
    );
  }

  DataRow _buildRow(ClientDomain d) {
    return DataRow(
      cells: [
        DataCell(
          Text(
            d.domainName ?? 'N/A',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
        ),
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                d.companyName ?? (d.client?['company_name'] ?? 'N/A'),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (d.project != null)
                Text(
                  d.project?['project_name'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.grey400,
                  ),
                ),
            ],
          ),
        ),
        DataCell(
          Text(
            d.domainProvider ?? 'N/A',
            style: GoogleFonts.inter(fontSize: 12),
          ),
        ),
        DataCell(
          Text(
            d.expiryDate != null
                ? DateFormat('dd MMM yyyy').format(d.expiryDate!)
                : 'N/A',
            style: GoogleFonts.inter(fontSize: 12),
          ),
        ),
        DataCell(_buildStatusBadge(d.status ?? 'Active')),
        DataCell(
          Row(
            children: [
              _buildActionIcon(
                Icons.edit_outlined,
                AppColors.goldDark,
                "Edit",
                () => _showAddDomainSheet(existing: d),
              ),
              const SizedBox(width: 8),
              _buildActionIcon(
                Icons.delete_outline_rounded,
                AppColors.error,
                "Delete",
                () => _deleteDomain(d.id!),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = AppColors.navy;
    if (status.contains("Active")) color = AppColors.success;
    if (status.contains("Soon")) color = AppColors.warning;
    if (status.contains("Expired")) color = AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _buildActionIcon(
    IconData icon,
    Color color,
    String tooltip,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 100),
        child: Column(
          children: [
            const Icon(Icons.dns_outlined, size: 80, color: AppColors.grey100),
            const SizedBox(height: 16),
            Text(
              "No domains found",
              style: GoogleFonts.inter(
                fontSize: 18,
                color: AppColors.grey400,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _fetchData, child: const Text("Refresh")),
          ],
        ),
      ),
    );
  }
}
