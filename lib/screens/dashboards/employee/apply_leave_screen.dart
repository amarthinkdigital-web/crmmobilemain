import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../services/api_service.dart';

class ApplyLeaveScreen extends StatefulWidget {
  const ApplyLeaveScreen({super.key});

  @override
  State<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
  String? _selectedLeaveType;
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _reasonController = TextEditingController();

  bool _isSubmitting = false;
  bool _isLoadingLeaves = true;
  List<Map<String, dynamic>> _myLeaves = [];

  final List<String> _leaveTypes = ['Paid Leave', 'Unpaid Leave'];

  @override
  void initState() {
    super.initState();
    _fetchMyLeaves();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _fetchMyLeaves() async {
    setState(() => _isLoadingLeaves = true);
    final res = await ApiService.getEmployeeLeaves();
    if (!mounted) return;
    if (res['error'] == false) {
      setState(() {
        _myLeaves = (res['data'] as List).cast<Map<String, dynamic>>();
        _isLoadingLeaves = false;
      });
    } else {
      setState(() => _isLoadingLeaves = false);
    }
  }

  Future<void> _submitLeave() async {
    if (_selectedLeaveType == null || _startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }
    
    setState(() => _isSubmitting = true);
    final String parsedLeaveType = _selectedLeaveType!.split(' ').first.toLowerCase();

    final payload = {
      'leave_type': parsedLeaveType,
      'type': parsedLeaveType, 
      'leave': parsedLeaveType,
      'start_date': DateFormat('yyyy-MM-dd').format(_startDate!),
      'end_date': DateFormat('yyyy-MM-dd').format(_endDate!),
      'reason': _reasonController.text,
    };

    final res = await ApiService.submitEmployeeLeave(payload);
    if (!mounted) return;
    
    setState(() => _isSubmitting = false);
    
    if (res['error'] == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Leave request submitted successfully!')),
      );
      setState(() {
        _selectedLeaveType = null;
        _startDate = null;
        _endDate = null;
        _reasonController.clear();
      });
      _fetchMyLeaves(); // refresh list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Failed to submit leave request')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.navy,
              onPrimary: AppColors.white,
              onSurface: AppColors.navy,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.navy),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildLeaveForm(),
            const SizedBox(height: 32),
            _buildMyLeavesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Apply for Leave',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Submit a new leave request for approval',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.grey400,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.grey100),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('Leave Type'),
          const SizedBox(height: 8),
          _buildDropdown(),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Start Date'),
                    const SizedBox(height: 8),
                    _buildDateButton(true),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('End Date'),
                    const SizedBox(height: 8),
                    _buildDateButton(false),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildFieldLabel('Reason (Optional)'),
          const SizedBox(height: 8),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter reason for leave...',
              hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.grey400),
              fillColor: AppColors.offWhite,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitLeave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Submit Application',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.navy,
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedLeaveType,
          isExpanded: true,
          hint: Text('Select leave type', style: GoogleFonts.inter(fontSize: 14, color: AppColors.grey400)),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.navy),
          items: _leaveTypes.map((String type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Text(type, style: GoogleFonts.inter(fontSize: 14, color: AppColors.navy)),
            );
          }).toList(),
          onChanged: (String? value) {
            setState(() {
              _selectedLeaveType = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildDateButton(bool isStartDate) {
    String dateText = isStartDate
        ? (_startDate == null ? 'Select start' : DateFormat('MMM dd, yyyy').format(_startDate!))
        : (_endDate == null ? 'Select end' : DateFormat('MMM dd, yyyy').format(_endDate!));

    return InkWell(
      onTap: () => _selectDate(context, isStartDate),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.offWhite,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                dateText,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: (_startDate != null && isStartDate) || (_endDate != null && !isStartDate) ? FontWeight.w600 : FontWeight.w400,
                  color: (_startDate != null && isStartDate) || (_endDate != null && !isStartDate) ? AppColors.navy : AppColors.grey400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.calendar_today_rounded, size: 18, color: isStartDate ? AppColors.navy : AppColors.gold),
          ],
        ),
      ),
    );
  }

  Widget _buildMyLeavesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Leave History',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoadingLeaves)
          const Center(child: CircularProgressIndicator())
        else if (_myLeaves.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.grey200),
            ),
            child: Text(
              "No leaves applied yet.",
              style: GoogleFonts.inter(color: AppColors.grey400),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _myLeaves.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final leave = _myLeaves[index];
              return _buildLeaveHistoryCard(leave);
            },
          ),
      ],
    );
  }

  Widget _buildLeaveHistoryCard(Map<String, dynamic> leave) {
    String type = leave['leave_type'] ?? leave['type'] ?? 'Leave';
    String status = leave['status'] ?? 'Pending';
    String start = leave['start_date'] ?? '-';
    String end = leave['end_date'] ?? '-';
    // Admin rejection strings could come back as reject_reason from our earlier API updates
    String reason = leave['reject_reason'] ?? leave['admin_remark'] ?? leave['reason'] ?? 'No reason provided';
    
    Color statusColor = AppColors.warning;
    final lower = status.toLowerCase();
    if (lower.contains('approve')) statusColor = AppColors.success;
    if (lower.contains('reject')) statusColor = AppColors.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                type,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.date_range, size: 16, color: AppColors.grey400),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$start  —  $end',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.grey600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.supervisor_account_outlined, size: 16, color: AppColors.grey400),
              const SizedBox(width: 8),
                Builder(
                  builder: (context) {
                    final emp = leave['employee'] ?? leave['user'];
                    
                    // Priority logic: Team Leader -> Reporting Manager -> HR Contact
                    final dynamic approver = (emp is Map)
                        ? (emp['team_leader'] ?? emp['manager'] ?? emp['hr'])
                        : (leave['team_leader'] ?? leave['manager'] ?? leave['hr']);
                    
                    final String name = approver != null
                        ? (approver is Map
                            ? (approver['name'] ?? '${approver['first_name'] ?? ''} ${approver['last_name'] ?? ''}')
                            : approver.toString())
                        : 'HR / Admin Panel';
                    
                    return Expanded(
                      child: Text(
                        'Approver: $name',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.grey600, fontWeight: FontWeight.w600),
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.notes, size: 16, color: AppColors.grey400),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  reason,
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.grey600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
