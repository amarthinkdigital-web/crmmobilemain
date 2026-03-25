import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';

class ServiceDomainsScreen extends StatefulWidget {
  const ServiceDomainsScreen({super.key});

  @override
  State<ServiceDomainsScreen> createState() => _ServiceDomainsScreenState();
}

class _ServiceDomainsScreenState extends State<ServiceDomainsScreen> {
  final List<Map<String, dynamic>> _domains = [
    {
      'domain': 'thinkdigital.com',
      'client': 'Think Digital HQ',
      'provider': 'GoDaddy',
      'expiryDate': '2026-12-15',
      'status': 'Active',
    },
    {
      'domain': 'techsolutions.in',
      'client': 'Tech Solutions Ltd.',
      'provider': 'Namecheap',
      'expiryDate': '2026-05-01',
      'status': 'Expiring Soon',
    },
    {
      'domain': 'globallogistics.co',
      'client': 'Global Logistics Co.',
      'provider': 'GoDaddy',
      'expiryDate': '2026-01-20',
      'status': 'Expired',
    },
    {
      'domain': 'creativeminds.io',
      'client': 'Creative Minds Agency',
      'provider': 'Cloudflare',
      'expiryDate': '2026-09-10',
      'status': 'Active',
    },
  ];

  final TextEditingController domainController = TextEditingController();
  final TextEditingController clientController = TextEditingController();
  final TextEditingController providerController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  String selectedStatus = 'Active';

  void _showAddDomainSheet() {
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
                    "Add New Domain",
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
                "Domain Name",
                "Enter domain URL",
                domainController,
                Icons.language_rounded,
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
                "Provider",
                "Enter registrar/provider",
                providerController,
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
                      _domains.add({
                        "domain": domainController.text,
                        "client": clientController.text,
                        "provider": providerController.text,
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
                    "Add Domain",
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
    domainController.clear();
    clientController.clear();
    providerController.clear();
    dateController.clear();
    selectedStatus = 'Active';
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
                "Active",
                "Expiring Soon",
                "Expired",
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
            _buildDomainsTable(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDomainSheet,
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

  Widget _buildDomainsTable() {
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
                  AppColors.navy.withValues(alpha: 0.05),
                ),
                columnSpacing: 30,
                columns: [
                  _buildDataColumn("Domain Name"),
                  _buildDataColumn("Client"),
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

  DataRow _buildRow(Map<String, dynamic> d) {
    return DataRow(
      cells: [
        DataCell(
          Text(
            d['domain'],
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
        ),
        DataCell(Text(d['client'], style: GoogleFonts.inter(fontSize: 12))),
        DataCell(Text(d['provider'], style: GoogleFonts.inter(fontSize: 12))),
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
    if (status == "Active") color = AppColors.success;
    if (status == "Expiring Soon") color = AppColors.warning;
    if (status == "Expired") color = AppColors.error;

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
