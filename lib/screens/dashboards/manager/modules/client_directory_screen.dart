import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/app_theme.dart';
import '../../../../services/api_service.dart';

class ClientDirectoryScreen extends StatefulWidget {
  const ClientDirectoryScreen({super.key});

  @override
  State<ClientDirectoryScreen> createState() => _ClientDirectoryScreenState();
}

class _ClientDirectoryScreenState extends State<ClientDirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _clients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchClients();
  }

  Future<void> _fetchClients() async {
    setState(() => _isLoading = true);
    final res = await ApiService.getClientProfiles();
    if (mounted) {
      setState(() {
        _clients = res['data'] ?? [];
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleAccess(dynamic client, bool currentAccess) async {
    final res = await ApiService.togglePortalAccess(client['id'], !currentAccess);
    if (mounted) {
      if (res['error'] == false) {
        _fetchClients();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
      }
    }
  }

  void _showAddClientDialog() {
    // Required fields as per API:
    // company_name, email, password, contact_person_name, phone, designation
    // industry, services_opted, client_type, address_line_1, city, state, pin_code, country
    // billing_email, payment_terms, payment_status, manager_id, department_id
    
    final companyNameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final contactPersonController = TextEditingController();
    final phoneController = TextEditingController();
    final designationController = TextEditingController();
    final industryController = TextEditingController();
    final servicesController = TextEditingController();
    final clientTypeController = TextEditingController();
    final addressController = TextEditingController();
    final cityController = TextEditingController();
    final stateController = TextEditingController();
    final pinCodeController = TextEditingController();
    final countryController = TextEditingController();
    final billingEmailController = TextEditingController();
    final paymentTermsController = TextEditingController();
    final paymentStatusController = TextEditingController();
    final managerIdController = TextEditingController();
    final departmentIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.white,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Add New Client",
                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.navy),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildInputField("Company Name", Icons.business, companyNameController),
                      const SizedBox(height: 12),
                      _buildInputField("Email", Icons.email, emailController),
                      const SizedBox(height: 12),
                      _buildInputField("Password", Icons.lock, passwordController, isPassword: true),
                      const SizedBox(height: 12),
                      _buildInputField("Contact Person Name", Icons.person, contactPersonController),
                      const SizedBox(height: 12),
                      _buildInputField("Phone", Icons.phone, phoneController),
                      const SizedBox(height: 12),
                      _buildInputField("Designation", Icons.work, designationController),
                      const SizedBox(height: 12),
                      _buildInputField("Industry", Icons.factory, industryController),
                      const SizedBox(height: 12),
                      _buildInputField("Services Opted", Icons.miscellaneous_services, servicesController),
                      const SizedBox(height: 12),
                      _buildInputField("Client Type", Icons.category, clientTypeController),
                      const SizedBox(height: 12),
                      _buildInputField("Address Line 1", Icons.location_on, addressController),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildInputField("City", Icons.map, cityController)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildInputField("State", Icons.map, stateController)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildInputField("Pin Code", Icons.numbers, pinCodeController)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildInputField("Country", Icons.public, countryController)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInputField("Billing Email", Icons.receipt_long, billingEmailController),
                      const SizedBox(height: 12),
                      _buildInputField("Payment Terms", Icons.payment, paymentTermsController),
                      const SizedBox(height: 12),
                      _buildInputField("Payment Status", Icons.info, paymentStatusController),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildInputField("Manager ID", Icons.person_search, managerIdController)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildInputField("Dept ID", Icons.groups, departmentIdController)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final res = await ApiService.createClientProfile({
                          'company_name': companyNameController.text,
                          'email': emailController.text,
                          'password': passwordController.text,
                          'contact_person_name': contactPersonController.text,
                          'phone': phoneController.text,
                          'designation': designationController.text,
                          'industry': industryController.text,
                          'services_opted': servicesController.text,
                          'client_type': clientTypeController.text,
                          'address_line_1': addressController.text,
                          'city': cityController.text,
                          'state': stateController.text,
                          'pin_code': pinCodeController.text,
                          'country': countryController.text,
                          'billing_email': billingEmailController.text,
                          'payment_terms': paymentTermsController.text,
                          'payment_status': paymentStatusController.text,
                          'manager_id': managerIdController.text,
                          'department_id': departmentIdController.text,
                        });
                        if (mounted) {
                          if (res['error'] == false) {
                            _fetchClients();
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy),
                      child: const Text("Save Client", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String hint, IconData icon, TextEditingController controller, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: AppColors.grey400, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.grey400, size: 20),
        filled: true,
        fillColor: AppColors.offWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _fetchClients,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: _clients.length,
                    itemBuilder: (context, index) => _buildClientCard(_clients[index]),
                  ),
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddClientDialog,
        backgroundColor: AppColors.navy,
        icon: const Icon(Icons.add_rounded, color: AppColors.white),
        label: const Text("Add Client", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.offWhite,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text("Client Directory", style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.navy)),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Search clients...",
          prefixIcon: const Icon(Icons.search_rounded),
          fillColor: AppColors.white,
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildClientCard(dynamic client) {
    final bool isActive = client['client_portal_access'] == true || client['client_portal_access'] == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.navy.withOpacity(0.1),
                  child: Text(client['company_name']?[0] ?? 'C', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: AppColors.navy)),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(client['company_name'] ?? 'Unknown', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.navy)),
                      Text(client['industry'] ?? 'General', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(client['email'] ?? 'No email', style: const TextStyle(fontSize: 12, color: AppColors.grey600)),
                      Text(client['phone'] ?? 'No phone', style: const TextStyle(fontSize: 12, color: AppColors.grey600)),
                    ],
                  ),
                ),
                Switch(
                  value: isActive,
                  onChanged: (val) => _toggleAccess(client, isActive),
                  activeColor: AppColors.success,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

