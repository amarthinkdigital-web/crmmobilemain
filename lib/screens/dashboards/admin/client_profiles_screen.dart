import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class ClientProfilesScreen extends StatefulWidget {
  const ClientProfilesScreen({super.key});

  @override
  State<ClientProfilesScreen> createState() => _ClientProfilesScreenState();
}

class _ClientProfilesScreenState extends State<ClientProfilesScreen> {
  final List<Map<String, dynamic>> _allClients = [
    {
      'name': 'Tech Solutions Ltd.',
      'contact': 'Sarah Jenkins',
      'email': 'sarah@techsol.com',
      'status': 'Active',
      'revenue': r'$45,000',
      'avatar': 'TS',
      'color': Colors.blue,
      'type': 'Premium',
    },
    {
      'name': 'Global Logistics Co.',
      'contact': 'Mike Ross',
      'email': 'mike@globallog.com',
      'status': 'Pending',
      'revenue': r'$12,200',
      'avatar': 'GL',
      'color': Colors.orange,
      'type': 'Enterprise',
    },
    {
      'name': 'Creative Minds Agency',
      'contact': 'Elena Gilbert',
      'email': 'elena@creative-minds.io',
      'status': 'Inactive',
      'revenue': r'$8,500',
      'avatar': 'CM',
      'color': Colors.purple,
      'type': 'Standard',
    },
    {
      'name': 'Innovate Software',
      'contact': 'David Chen',
      'email': 'david@innovate.tech',
      'status': 'Active',
      'revenue': r'$32,100',
      'avatar': 'IS',
      'color': Colors.teal,
      'type': 'Premium',
    },
    {
      'name': 'Future Retail Group',
      'contact': 'Alice Wong',
      'email': 'alice@futureretail.com',
      'status': 'Active',
      'revenue': r'$15,700',
      'avatar': 'FR',
      'color': Colors.pink,
      'type': 'Standard',
    },
  ];

  late List<Map<String, dynamic>> _filteredClients;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredClients = _allClients;
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _filteredClients = _allClients
          .where((client) =>
              client['name'].toLowerCase().contains(_searchController.text.toLowerCase()) ||
              client['contact'].toLowerCase().contains(_searchController.text.toLowerCase()))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Client Profiles',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Manage your organization\'s clients',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.grey400),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_business_rounded, color: AppColors.gold, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSearchBar(),
          const SizedBox(height: 20),
          Expanded(
            child: _filteredClients.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filteredClients.length,
                    itemBuilder: (context, index) {
                      final client = _filteredClients[index];
                      return _buildClientCard(client);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search clients or contacts...',
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.grey400),
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildClientCard(Map<String, dynamic> client) {
    Color statusColor;
    switch (client['status']) {
      case 'Active':
        statusColor = AppColors.success;
        break;
      case 'Pending':
        statusColor = AppColors.warning;
        break;
      default:
        statusColor = AppColors.grey400;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey100),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: client['color'].withValues(alpha: 0.1),
                child: Text(
                  client['avatar'],
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: client['color'],
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            client['name'],
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildBadge(client['type'], AppColors.navy.withValues(alpha: 0.05), AppColors.navy),
                      ],
                    ),
                    Text(
                      'Contact: ${client['contact']}',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.grey400),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    client['revenue'],
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.gold,
                    ),
                  ),
                  _buildBadge(client['status'], statusColor.withValues(alpha: 0.1), statusColor),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.grey100),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  Icons.email_outlined,
                  'Email',
                  () {},
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  Icons.phone_outlined,
                  'Call',
                  () {},
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  Icons.arrow_forward_rounded,
                  'Details',
                  () {},
                  isPrimary: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap, {bool isPrimary = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.navy : AppColors.offWhite,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isPrimary ? AppColors.white : AppColors.grey600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isPrimary ? AppColors.white : AppColors.grey600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: AppColors.grey200),
          const SizedBox(height: 16),
          Text(
            'No clients found',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.grey400,
            ),
          ),
        ],
      ),
    );
  }
}
