import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';

class ServiceHostingScreen extends StatefulWidget {
  const ServiceHostingScreen({super.key});

  @override
  State<ServiceHostingScreen> createState() => _ServiceHostingScreenState();
}

class _ServiceHostingScreenState extends State<ServiceHostingScreen> {
  final List<Map<String, dynamic>> _hostingData = [
    {
      'projectDomain': 'thinkdigital.com',
      'client': 'Think Digital HQ',
      'serviceType': 'VPS Premium',
      'expiryDate': '2026-12-20',
      'status': 'Online',
    },
    {
      'projectDomain': 'techsolutions.in',
      'client': 'Tech Solutions Ltd.',
      'serviceType': 'Shared Hosting',
      'expiryDate': '2026-05-15',
      'status': 'Maintenance',
    },
    {
      'projectDomain': 'staging.internal',
      'client': 'Internal',
      'serviceType': 'VPS Standard',
      'expiryDate': '2026-08-10',
      'status': 'Offline',
    },
  ];

  final TextEditingController projectDomainController = TextEditingController();
  final TextEditingController clientController = TextEditingController();
  final TextEditingController serviceTypeController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  String selectedStatus = 'Online';

  void _showAddHostingSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 32,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Add Hosting Service",
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildInputField(
                "Project & Domain Name",
                "Enter project/domain",
                projectDomainController,
                Icons.public_rounded,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                "Client",
                "Enter client name",
                clientController,
                Icons.business_rounded,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                "Service Type",
                "Enter service (e.g., VPS)",
                serviceTypeController,
                Icons.dns_rounded,
              ),
              const SizedBox(height: 16),
              _buildInputField(
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
                    dateController.text = DateFormat('yyyy-MM-dd').format(date);
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildStatusDropdown(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _hostingData.add({
                        "projectDomain": projectDomainController.text,
                        "client": clientController.text,
                        "serviceType": serviceTypeController.text,
                        "expiryDate": dateController.text,
                        "status": selectedStatus,
                      });
                    });
                    _clearControllers();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    "Add Service",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _clearControllers() {
    projectDomainController.clear();
    clientController.clear();
    serviceTypeController.clear();
    dateController.clear();
    selectedStatus = 'Online';
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
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.grey400, size: 20),
            filled: true,
            fillColor: AppColors.offWhite,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
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
                "Online",
                "Maintenance",
                "Offline",
              ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => setState(() => selectedStatus = v!),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildHostingTable(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddHostingSheet,
        backgroundColor: AppColors.navy,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("Add Service", style: TextStyle(color: Colors.white)),
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
          "Monitor and manage server infrastructure & services",
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.grey400,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
            color: Colors.black.withValues(alpha: 0.02),
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
              "Hosting Services List",
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
                  AppColors.navy.withValues(alpha: 0.05),
                ),
                columnSpacing: 30,
                columns: [
                  _buildDataColumn("Project & Domain Name"),
                  _buildDataColumn("Client"),
                  _buildDataColumn("Service Type"),
                  _buildDataColumn("Expiry Date"),
                  _buildDataColumn("Status"),
                  _buildDataColumn("Action"),
                ],
                rows: _hostingData.map((d) => _buildRow(d)).toList(),
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

  DataRow _buildRow(Map<String, dynamic> d) {
    return DataRow(
      cells: [
        DataCell(
          Text(
            d['projectDomain'],
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
        ),
        DataCell(Text(d['client'], style: GoogleFonts.inter(fontSize: 12))),
        DataCell(
          Text(d['serviceType'], style: GoogleFonts.inter(fontSize: 12)),
        ),
        DataCell(Text(d['expiryDate'], style: GoogleFonts.inter(fontSize: 12))),
        DataCell(_buildStatusBadge(d['status'])),
        DataCell(
          Row(
            children: [
              _buildActionIcon(
                Icons.visibility_outlined,
                AppColors.info,
                "View",
              ),
              const SizedBox(width: 8),
              _buildActionIcon(Icons.edit_outlined, AppColors.goldDark, "Edit"),
              const SizedBox(width: 8),
              _buildActionIcon(
                Icons.delete_outline_rounded,
                AppColors.error,
                "Delete",
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = AppColors.navy;
    if (status == "Online") color = AppColors.success;
    if (status == "Maintenance") color = AppColors.warning;
    if (status == "Offline") color = AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
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

  Widget _buildActionIcon(IconData icon, Color color, String tooltip) {
    return InkWell(
      onTap: () {},
      child: Tooltip(
        message: tooltip,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}
