import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/app_theme.dart';

class SupportTicketsScreen extends StatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen> {
  final List<Map<String, dynamic>> _tickets = [
    {
      'id': '#TK-1024',
      'subject': 'Login Issue on Mobile App',
      'category': 'Technical',
      'priority': 'High',
      'status': 'Open',
      'client': 'Sarah Williams',
      'assigned': 'Mike Admin',
      'lastUpdated': '2 hours ago',
    },
    {
      'id': '#TK-1025',
      'subject': 'Payment Gateway Failure',
      'category': 'Billing',
      'priority': 'Critical',
      'status': 'In Progress',
      'client': 'Global Industries',
      'assigned': 'Tech Support',
      'lastUpdated': '30 mins ago',
    },
    {
      'id': '#TK-1026',
      'subject': 'How to export reports?',
      'category': 'Inquiry',
      'priority': 'Low',
      'status': 'Resolved',
      'client': 'Michael Chen',
      'assigned': 'Alex Support',
      'lastUpdated': 'Yesterday',
    },
    {
      'id': '#TK-1027',
      'subject': 'New Feature Request',
      'category': 'Feature',
      'priority': 'Medium',
      'status': 'Open',
      'client': 'InnoSoft',
      'assigned': 'Product Manager',
      'lastUpdated': '3 days ago',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildQuickStats(),
          _buildTicketFilters(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: _tickets.length,
              itemBuilder: (context, index) {
                final ticket = _tickets[index];
                return _buildTicketCard(ticket);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.navy,
        child: const Icon(Icons.add_rounded, color: AppColors.white),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        "Support Tickets",
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.navy,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.history_rounded, color: AppColors.navy),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildQuickStatItem("Open", "14", AppColors.info),
          _buildQuickStatItem("Critical", "3", AppColors.error),
          _buildQuickStatItem("Resolved", "98", AppColors.success),
        ],
      ),
    );
  }

  Widget _buildQuickStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.grey400,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTicketFilters() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _buildFilterChip("Unassigned", false),
          const SizedBox(width: 10),
          _buildFilterChip("My Tickets", true),
          const SizedBox(width: 10),
          _buildFilterChip("Mentioned", false),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.navy : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? AppColors.navy : AppColors.grey100),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          color: isSelected ? AppColors.white : AppColors.grey600,
        ),
      ),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.grey100),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.offWhite,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ticket['id'],
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPriorityColor(ticket['priority']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ticket['priority'].toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: _getPriorityColor(ticket['priority']),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            ticket['subject'],
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                "${ticket['category']} • Submitted by ${ticket['client']}",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.grey400,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: AppColors.grey100),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.grey400),
                  const SizedBox(width: 6),
                  Text(
                    ticket['assigned'],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.grey600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: AppColors.grey400),
                  const SizedBox(width: 6),
                  Text(
                    ticket['lastUpdated'],
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.grey400,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(ticket['status']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ticket['status'],
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _getStatusColor(ticket['status']),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    if (priority == 'Critical') return AppColors.error;
    if (priority == 'High') return AppColors.warning;
    if (priority == 'Medium') return AppColors.info;
    return AppColors.grey400;
  }

  Color _getStatusColor(String status) {
    if (status == 'Resolved') return AppColors.success;
    if (status == 'In Progress') return AppColors.info;
    return AppColors.warning;
  }
}
