import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class MemberDirectoryScreen extends StatelessWidget {
  const MemberDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final members = [
      {'name': 'Alex Johnson', 'role': 'Senior Developer', 'dept': 'Engineering', 'email': 'alex.j@thinkdigital.com'},
      {'name': 'Sarah Jenkins', 'role': 'Sales Manager', 'dept': 'Sales', 'email': 'sarah.j@thinkdigital.com'},
      {'name': 'Marcus Wright', 'role': 'Support Lead', 'dept': 'Support', 'email': 'marcus.w@thinkdigital.com'},
      {'name': 'Sophie Chen', 'role': 'UI Designer', 'dept': 'Design', 'email': 'sophie.c@thinkdigital.com'},
      {'name': 'Mike Ross', 'role': 'Accountant', 'dept': 'Finance', 'email': 'mike.r@thinkdigital.com'},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildSearchAndFilters(),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: members.length,
              itemBuilder: (context, index) {
                return _buildMemberCard(members[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Member Directory',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          'Browse and connect with your team members',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.grey400),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.grey100),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: AppColors.grey400, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search members...',
                      border: InputBorder.none,
                      filled: false,
                      hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.grey400),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.filter_list_rounded, color: AppColors.white, size: 20),
        ),
      ],
    );
  }

  Widget _buildMemberCard(Map<String, String> member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.gold.withOpacity(0.1),
                child: Text(
                  member['name']![0],
                  style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.gold, fontSize: 18),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member['name']!,
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navy),
                    ),
                    Text(
                      member['role']!,
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.grey400),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.navy.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  member['dept']!,
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.navy),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.grey100),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.mail_outline_rounded, size: 14, color: AppColors.grey400),
                  const SizedBox(width: 6),
                  Text(member['email']!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.grey600)),
                ],
              ),
              Row(
                children: [
                  _buildMiniAction(Icons.chat_bubble_outline_rounded),
                  const SizedBox(width: 8),
                  _buildMiniAction(Icons.call_outlined),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniAction(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: AppColors.navy),
    );
  }
}
