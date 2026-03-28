import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../theme/app_theme.dart';
import '../../../../services/api_service.dart';
import './client_directory_screen.dart';

class BusinessLeadsScreen extends StatefulWidget {
  const BusinessLeadsScreen({super.key});

  @override
  State<BusinessLeadsScreen> createState() => _BusinessLeadsScreenState();
}

class _BusinessLeadsScreenState extends State<BusinessLeadsScreen> {
  List<dynamic> _leads = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeads();
  }

  Future<void> _fetchLeads() async {
    setState(() => _isLoading = true);
    final res = await ApiService.getLeads();
    if (mounted) {
      setState(() {
        _leads = res['data'] ?? [];
        _isLoading = false;
      });
      if (res['error'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'])),
        );
      }
    }
  }

  Future<void> _updateStatus(dynamic lead, String status) async {
    final res = await ApiService.updateLeadStatus(lead['id'], status.toLowerCase());
    if (mounted) {
      if (res['error'] == false) {
        _fetchLeads();
        if (status.toLowerCase() == 'done') {
          _showCreateClientPromotion(lead);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'])),
        );
      }
    }
  }

  void _showCreateClientPromotion(dynamic lead) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Lead Completed!"),
        content: const Text("Would you like to create a client profile for this lead now?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Later"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ClientDirectoryScreen(),
                ),
              );
            },
            child: const Text("Create Profile"),
          ),
        ],
      ),
    );
  }

  void _showAddLeadDialog() {
    final companyController = TextEditingController();
    final personController = TextEditingController();
    final contactController = TextEditingController();
    final sourceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Create Lead",
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Enter lead details below",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.grey400,
                ),
              ),
              const SizedBox(height: 24),
              _buildInputField("Company Name", Icons.business_rounded, companyController),
              const SizedBox(height: 16),
              _buildInputField("Person Name", Icons.person_rounded, personController),
              const SizedBox(height: 16),
              _buildInputField("Contact", Icons.phone_rounded, contactController),
              const SizedBox(height: 16),
              _buildInputField("Source", Icons.share_rounded, sourceController),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: AppColors.grey100),
                        ),
                      ),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: AppColors.grey600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final res = await ApiService.createLead({
                          'company_name': companyController.text,
                          'contact_person': personController.text,
                          'contact': contactController.text,
                          'source': sourceController.text,
                          'status': 'pending',
                        });
                        if (mounted) {
                          if (res['error'] == false) {
                            _fetchLeads();
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(res['message'])),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(
                        "Submit Lead",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
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

  void _showFollowUpDialog(dynamic lead) {
    final dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add Follow-up for ${lead['company_name']}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dateController,
              decoration: const InputDecoration(labelText: "Follow-up Date (YYYY-MM-DD)"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Description"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final res = await ApiService.addFollowUp(lead['id'], {
                'follow_up_date': dateController.text,
                'description': descController.text,
              });
              if (mounted) {
                if (res['error'] == false) {
                  _fetchLeads();
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
                }
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String hint, IconData icon, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: AppColors.grey200, fontSize: 13, fontWeight: FontWeight.w500),
        prefixIcon: Icon(icon, color: AppColors.grey400, size: 20),
        filled: true,
        fillColor: AppColors.offWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: RefreshIndicator(
        onRefresh: _fetchLeads,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            _buildSliverAppBar(),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_leads.isEmpty)
              const SliverFillRemaining(
                child: Center(child: Text("No leads found.")),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildLeadCard(_leads[index]),
                    childCount: _leads.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddLeadDialog,
        backgroundColor: AppColors.navy,
        label: Text(
          "Add Lead",
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.white),
        ),
        icon: const Icon(Icons.add_rounded, color: AppColors.white),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      elevation: 0,
      centerTitle: false,
      backgroundColor: AppColors.offWhite,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        "All Leads",
        style: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: AppColors.navy,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildLeadCard(dynamic lead) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: AppColors.grey100.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lead['company_name'] ?? 'N/A',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.person_rounded, size: 14, color: AppColors.grey400),
                              const SizedBox(width: 6),
                              Text(
                                lead['contact_person'] ?? 'N/A',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.grey600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _buildStatusDropdown(lead),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildInfoItem(Icons.phone_rounded, lead['contact'] ?? 'N/A'),
                    const SizedBox(width: 20),
                    _buildInfoItem(Icons.share_rounded, lead['source'] ?? 'N/A'),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.grey100),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(Icons.history_rounded, "Follow-up", Colors.orange, () => _showFollowUpDialog(lead)),
                _buildActionButton(Icons.delete_outline_rounded, "Delete", AppColors.error, () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.offWhite,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.navy),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDropdown(dynamic lead) {
    final status = lead['status']?.toString().toLowerCase() ?? 'pending';
    final items = [
      {'val': 'pending', 'label': 'Pending'},
      {'val': 'cancel', 'label': 'Cancel'},
      {'val': 'done', 'label': 'Done'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.any((i) => i['val'] == status) ? status : 'pending',
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: _getStatusColor(status)),
          onChanged: (val) {
            if (val != null) _updateStatus(lead, val);
          },
          items: items.map((i) {
            return DropdownMenuItem<String>(
              value: i['val'],
              child: Text(
                i['label']!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _getStatusColor(status),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'done': return AppColors.success;
      case 'cancel': return AppColors.error;
      case 'pending': return AppColors.warning;
      default: return AppColors.grey400;
    }
  }
}

