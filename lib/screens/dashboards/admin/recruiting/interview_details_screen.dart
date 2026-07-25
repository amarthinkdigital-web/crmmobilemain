import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/app_theme.dart';
import '../../../../services/recruiting_api_service.dart';
import '../../../../models/interview_model.dart';

class InterviewDetailsScreen extends StatefulWidget {
  final int interviewId;
  final int initialTab;

  const InterviewDetailsScreen({
    super.key,
    required this.interviewId,
    this.initialTab = 0,
  });

  @override
  State<InterviewDetailsScreen> createState() => _InterviewDetailsScreenState();
}

class _InterviewDetailsScreenState extends State<InterviewDetailsScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Interview? _interview;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
    _fetchDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetails() async {
    setState(() => _isLoading = true);
    final response = await RecruitingApiService.getInterviewDetails(widget.interviewId);
    
    if (mounted) {
      if (response['error'] == false) {
        _interview = Interview.fromJson(response['data']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Failed to load details')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: const Text('Candidate Details'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.white,
          indicatorColor: AppColors.gold,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Received Tasks'),
            Tab(text: 'Follow Ups'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.navy))
          : _interview == null
              ? const Center(child: Text("Candidate not found"))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildReceivedTasksTab(),
                    _buildFollowUpsTab(),
                  ],
                ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.grey100),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.infoBg,
                  child: Text(
                    _interview!.name.isNotEmpty ? _interview!.name[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 24, color: AppColors.info, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_interview!.name, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.navy)),
                      const SizedBox(height: 4),
                      Text("Apply for: ${_interview!.applyFor}", style: GoogleFonts.inter(fontSize: 14, color: AppColors.grey600)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.email, size: 14, color: AppColors.grey400),
                          const SizedBox(width: 4),
                          Text(_interview!.email, style: const TextStyle(color: AppColors.grey600)),
                          const SizedBox(width: 16),
                          const Icon(Icons.phone, size: 14, color: AppColors.grey400),
                          const SizedBox(width: 4),
                          Text(_interview!.phone, style: const TextStyle(color: AppColors.grey600)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_interview!.status, style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text("Interview Details", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: 16),
          Container(
             padding: const EdgeInsets.all(24),
             decoration: BoxDecoration(
               color: AppColors.white,
               borderRadius: BorderRadius.circular(16),
               border: Border.all(color: AppColors.grey100),
             ),
             child: Column(
               children: [
                 _buildDetailRow("Date", _interview!.interviewDate),
                 const Divider(height: 24),
                 _buildDetailRow("Time", "${_interview!.interviewTimeFrom} - ${_interview!.interviewTimeTo}"),
                 const Divider(height: 24),
                 _buildDetailRow("Mode", _interview!.interviewMode.toUpperCase()),
                 if (_interview!.interviewMode == 'online') ...[
                   const Divider(height: 24),
                   _buildDetailRow("Meeting Link", _interview!.meetingLink ?? 'N/A'),
                 ],
                 const Divider(height: 24),
                 _buildDetailRow("City", _interview!.city),
                 const Divider(height: 24),
                 _buildDetailRow("Task Notes", _interview!.taskDescription ?? 'None'),
               ],
             ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 120, child: Text(label, style: const TextStyle(color: AppColors.grey400, fontWeight: FontWeight.w600))),
        Expanded(child: Text(value, style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w500))),
      ],
    );
  }

  Widget _buildReceivedTasksTab() {
    return const Center(child: Text("Received tasks functionality placeholder"));
  }

  Widget _buildFollowUpsTab() {
    return _interview!.followUps.isEmpty
        ? const Center(child: Text("No follow-ups recorded."))
        : ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: _interview!.followUps.length,
            itemBuilder: (context, index) {
              final fu = _interview!.followUps[index];
              return Card(
                child: ListTile(
                  title: Text(fu.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(fu.notes ?? ''),
                  trailing: Text(fu.followDate),
                ),
              );
            },
          );
  }
}
