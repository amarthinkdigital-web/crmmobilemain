import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../services/api_service.dart';
import '../../../models/domain_hosting_model.dart';

class ServiceHostingScreen extends StatefulWidget {
  const ServiceHostingScreen({super.key});

  @override
  State<ServiceHostingScreen> createState() => _ServiceHostingScreenState();
}

class _ServiceHostingScreenState extends State<ServiceHostingScreen> {
  List<ClientHosting> _hostings = [];
  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> _projects = [];
  bool _isLoading = true;
  String _errorMessage = '';

  final TextEditingController domainController = TextEditingController();
  final TextEditingController serviceController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController purchaseDateController = TextEditingController();
  final TextEditingController expiryDateController = TextEditingController();

  int? selectedClientId;
  int? selectedProjectId;
  String selectedStatus = 'Active';
  String selectedPaymentMode = 'Online';

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
        ApiService.getAdminHostings(),
        ApiService.getAdminClients(),
        ApiService.getAdminProjects(),
      ]);

      if (mounted) {
        setState(() {
          bool anyError = false;
          String errorMsg = '';

          if (results[0]['error'] == false) {
            _hostings = (results[0]['data'] as List)
                .map((e) => ClientHosting.fromJson(e))
                .toList();
          } else {
            anyError = true;
            errorMsg += "Hostings: ${results[0]['message']} ";
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

          _errorMessage = anyError ? errorMsg : '';
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

  void _showAddHostingSheet({ClientHosting? existing}) {
    if (existing != null) {
      domainController.text = existing.domainName ?? '';
      serviceController.text = existing.hostingService ?? '';
      amountController.text = existing.paymentAmount ?? '';
      expiryDateController.text = existing.expiryDate != null
          ? DateFormat('yyyy-MM-dd').format(existing.expiryDate!)
          : '';
      purchaseDateController.text = existing.purchaseDate != null
          ? DateFormat('yyyy-MM-dd').format(existing.purchaseDate!)
          : '';
      selectedClientId = existing.clientId;
      selectedProjectId = existing.projectId;
      selectedPaymentMode = existing.paymentMode ?? 'Online';
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
                        existing == null ? "Add New Hosting" : "Edit Hosting",
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
                        "Domain/Server Name",
                        "example.com",
                        domainController,
                        Icons.language_rounded,
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        "Hosting Service",
                        "e.g. AWS, Hostinger",
                        serviceController,
                        Icons.cloud_queue_rounded,
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
                              expiryDateController,
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
                                    expiryDateController.text = DateFormat(
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
                              "Payment Amount",
                              "0.00",
                              amountController,
                              Icons.payments_outlined,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildPaymentModeDropdown(
                              (val) => setModalState(
                                () => selectedPaymentMode = val,
                              ),
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
                                ? "Register Hosting"
                                : "Update Hosting",
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
                          if (_hostings.isEmpty)
                            _buildEmptyState()
                          else
                            _buildHostingTable(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddHostingSheet(),
        backgroundColor: AppColors.navy,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("Add Hosting", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Service Hosting",
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          "Manage client hosting and cloud infrastructure",
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
    int total = _hostings.length;
    int active = _hostings
        .where((h) => h.status == 'Active' || h.status == 'Running')
        .length;
    int soon = _hostings
        .where((h) => h.status?.contains('Soon') ?? false)
        .length;
    double totalSpend = 0;
    for (var h in _hostings) {
      totalSpend += double.tryParse(h.paymentAmount ?? '0') ?? 0;
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.15,
      children: [
        _buildStatTile(
          "Total Servers",
          total.toString(),
          Icons.dns_rounded,
          AppColors.navy,
        ),
        _buildStatTile(
          "Active/Running",
          active.toString(),
          Icons.bolt_rounded,
          AppColors.success,
        ),
        _buildStatTile(
          "Near Expiry",
          soon.toString(),
          Icons.timer_rounded,
          AppColors.warning,
        ),
        _buildStatTile(
          "Total Spend",
          "₹${totalSpend.toStringAsFixed(0)}",
          Icons.payments_rounded,
          AppColors.gold,
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

  Widget _buildHostingTable() {
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
              "Hosting List",
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
                  _buildDataColumn("Domain/Server"),
                  _buildDataColumn("Service"),
                  _buildDataColumn("Amount"),
                  _buildDataColumn("Expiry Date"),
                  _buildDataColumn("Status"),
                  _buildDataColumn("Action"),
                ],
                rows: _hostings.map((h) => _buildRow(h)).toList(),
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

  DataRow _buildRow(ClientHosting h) {
    return DataRow(
      cells: [
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                h.domainName ?? 'N/A',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                h.companyName ?? (h.client?['company_name'] ?? 'N/A'),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.grey400,
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Text(
            h.hostingService ?? 'N/A',
            style: GoogleFonts.inter(fontSize: 12),
          ),
        ),
        DataCell(
          Text(
            "₹${h.paymentAmount ?? '0'}",
            style: GoogleFonts.inter(fontSize: 12),
          ),
        ),
        DataCell(
          Text(
            h.expiryDate != null
                ? DateFormat('dd MMM yyyy').format(h.expiryDate!)
                : 'N/A',
            style: GoogleFonts.inter(fontSize: 12),
          ),
        ),
        DataCell(_buildStatusBadge(h.status ?? 'Active')),
        DataCell(
          Row(
            children: [
              _buildActionIcon(
                Icons.edit_outlined,
                AppColors.goldDark,
                "Edit",
                () => _showAddHostingSheet(existing: h),
              ),
              const SizedBox(width: 8),
              _buildActionIcon(
                Icons.delete_outline_rounded,
                AppColors.error,
                "Delete",
                () => _deleteHosting(h.id!),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = AppColors.navy;
    if (status.contains("Active") || status.contains("Running"))
      color = AppColors.success;
    if (status.contains("Soon") || status.contains("Pending"))
      color = AppColors.warning;
    if (status.contains("Expired") || status.contains("Stopped"))
      color = AppColors.error;

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
            const Icon(
              Icons.cloud_off_rounded,
              size: 80,
              color: AppColors.grey100,
            ),
            const SizedBox(height: 16),
            Text(
              "No hosting records found",
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

  Future<void> _handleSave(int? id) async {
    String? companyName;
    if (selectedClientId != null) {
      final client = _clients.firstWhere(
        (c) => c['id'] == selectedClientId,
        orElse: () => {},
      );
      companyName = client['company_name'];
    }

    final body = {
      "project_id": selectedProjectId,
      "client_id": selectedClientId,
      "company_name": companyName ?? "N/A",
      "domain_name": domainController.text,
      "hosting_service": serviceController.text,
      "purchase_date": purchaseDateController.text,
      "expiry_date": expiryDateController.text,
      "payment_amount": double.tryParse(amountController.text) ?? 0.0,
      "payment_mode": selectedPaymentMode,
      "status": selectedStatus,
    };

    setState(() => _isLoading = true);

    final response = id != null
        ? await ApiService.updateAdminHosting(id, body)
        : await ApiService.createAdminHosting(body);

    setState(() => _isLoading = false);

    if (response['error'] == false) {
      if (mounted) Navigator.pop(context); // Close modal only on success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(id != null ? "Hosting updated" : "Hosting added"),
        ),
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

  Future<void> _deleteHosting(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text(
          "Are you sure you want to delete this hosting record?",
        ),
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
      final response = await ApiService.deleteAdminHosting(id);
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
    serviceController.clear();
    amountController.clear();
    purchaseDateController.clear();
    expiryDateController.clear();
    selectedClientId = null;
    selectedProjectId = null;
    selectedStatus = 'Active';
    selectedPaymentMode = 'Online';
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
                "Running",
                "Stopped",
                "Pending",
                "Expired",
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

  Widget _buildPaymentModeDropdown(Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Payment Mode",
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
              value: selectedPaymentMode,
              isExpanded: true,
              items: [
                "Online",
                "Offline",
                "Cash",
                "Cheque",
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
}
