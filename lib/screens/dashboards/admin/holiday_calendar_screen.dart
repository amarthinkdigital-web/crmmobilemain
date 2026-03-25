import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../services/api_service.dart';
import '../../../theme/app_theme.dart';

class HolidayCalendarScreen extends StatefulWidget {
  const HolidayCalendarScreen({super.key});

  @override
  State<HolidayCalendarScreen> createState() => _HolidayCalendarScreenState();
}

class _HolidayCalendarScreenState extends State<HolidayCalendarScreen> {
  List<dynamic> _holidays = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchHolidays();
  }

  Future<void> _fetchHolidays() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await ApiService.getAdminOfficialLeaves();

    if (mounted) {
      if (response['error'] == false) {
        setState(() {
          _holidays = response['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load holidays';
          _isLoading = false;
        });
      }
    }
  }

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController dateController = TextEditingController();

  void _showHolidaySheet({dynamic holiday}) {
    final bool isEdit = holiday != null;
    if (isEdit) {
      titleController.text = holiday['title']?.toString() ?? '';
      final dt = _getDateTime(holiday);
      dateController.text = dt != null ? DateFormat('yyyy-MM-dd').format(dt) : '';
      descriptionController.text = holiday['description']?.toString() ?? '';
    } else {
      _clearControllers();
    }

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
                    isEdit ? "Edit Holiday" : "Add Holiday",
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
                "Holiday Title",
                "Enter holiday title",
                titleController,
                Icons.event_note_rounded,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                "Date",
                "Select date",
                dateController,
                Icons.calendar_today_rounded,
                isReadOnly: true,
                onTap: () async {
                  final initialDate = isEdit ? (_getDateTime(holiday) ?? DateTime.now()) : DateTime.now();
                  final date = await showDatePicker(
                    context: context,
                    initialDate: initialDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    dateController.text = DateFormat('yyyy-MM-dd').format(date);
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildInputField(
                "Description",
                "Enter brief description",
                descriptionController,
                Icons.description_rounded,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isEmpty || dateController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Title and Date are required"),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    final body = {
                      'title': titleController.text,
                      'name': titleController.text,
                      'subject': titleController.text,
                      'description': descriptionController.text,
                      'date': dateController.text,
                      'leave_date': dateController.text,
                      'leaveDate': dateController.text,
                      'start_date': dateController.text,
                      'startDate': dateController.text,
                      'holiday_date': dateController.text,
                      'event_date': dateController.text,
                      'from_date': dateController.text,
                      'work_date': dateController.text,
                    };

                    Map<String, dynamic> res;
                    if (isEdit) {
                      res = await ApiService.updateAdminOfficialLeave(holiday['id'], body);
                    } else {
                      res = await ApiService.createAdminOfficialLeave(body);
                    }

                    if (mounted) {
                      if (res['error'] == false) {
                        Navigator.pop(context);
                        _fetchHolidays();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isEdit ? "Holiday updated" : "Holiday created"),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Error: ${res['message'] ?? 'Operation failed'}"),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    isEdit ? "Update Holiday" : "Add Holiday",
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
    titleController.clear();
    dateController.clear();
    descriptionController.clear();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: RefreshIndicator(
        onRefresh: _fetchHolidays,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_errorMessage != null)
                Center(
                  child: Column(
                    children: [
                      Text(_errorMessage!, style: GoogleFonts.inter(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _fetchHolidays, child: const Text("Retry")),
                    ],
                  ),
                )
              else
                _buildHolidaysTable(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showHolidaySheet(),
        backgroundColor: AppColors.navy,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("Add Holiday", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Holiday Calendar",
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          "Manage organization-wide holiday schedule",
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.grey400,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildHolidaysTable() {
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
              "Leave List Table",
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
                columnSpacing: 35,
                columns: [
                  _buildDataColumn("Sr. No."),
                  _buildDataColumn("Date"),
                  _buildDataColumn("Title"),
                  _buildDataColumn("Description"),
                  _buildDataColumn("Action"),
                ],
                rows: _holidays.asMap().entries.map((entry) {
                   final index = entry.key;
                   final holiday = entry.value;
                   return _buildRow(index + 1, holiday);
                }).toList(),
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

  DataRow _buildRow(int index, dynamic h) {
    return DataRow(
      cells: [
        DataCell(
          Text(index.toString(), style: GoogleFonts.inter(fontSize: 12)),
        ),
        DataCell(
          Text(
            _formatDate(h),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
        ),
        DataCell(
          Text(
            h['title']?.toString() ?? '',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 200,
            child: Text(
              h['description']?.toString() ?? '',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.grey600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          Row(
            children: [
              _buildActionIcon(
                Icons.visibility_outlined,
                AppColors.info,
                "View",
                () => _showHolidayDetails(h),
              ),
              const SizedBox(width: 8),
              _buildActionIcon(
                Icons.edit_outlined, 
                AppColors.goldDark, 
                "Edit",
                () => _showHolidaySheet(holiday: h),
              ),
              const SizedBox(width: 8),
              _buildActionIcon(
                Icons.delete_outline_rounded,
                AppColors.error,
                "Delete",
                () => _deleteHoliday(h['id']),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showHolidayDetails(dynamic holiday) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(holiday['title']?.toString() ?? 'Holiday Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Date: ${_formatDate(holiday)}"),
            const SizedBox(height: 8),
            Text("Description: ${holiday['description'] ?? ''}"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }

  Future<void> _deleteHoliday(dynamic id) async {
    if (id == null) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Holiday"),
        content: const Text("Are you sure you want to delete this holiday?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await ApiService.deleteAdminOfficialLeave(id);
      if (mounted) {
        if (res['error'] == false) {
          _fetchHolidays();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Holiday deleted")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? "Failed to delete holiday")),
          );
        }
      }
    }
  }

  Widget _buildActionIcon(IconData icon, Color color, String tooltip, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
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

  DateTime? _getDateTime(dynamic h) {
    if (h == null) return null;
    String dateStr = '';
    
    if (h is Map) {
      final knownKeys = [
        'date', 'leave_date', 'leaveDate', 'start_date', 'holiday_date', 'startDate', 'from_date', 
        'from', 'start', 'event_date', 'date_from', 'work_date', 'workdate'
      ];
      for (var key in knownKeys) {
        if (h[key] != null && h[key].toString().isNotEmpty) {
          var val = h[key];
          if (val is Map) {
            dateStr = (val['formatted'] ?? val['date'] ?? val['val'] ?? val.toString()).toString();
          } else {
            dateStr = val.toString();
          }
          break;
        }
      }

      if (dateStr.isEmpty) {
        for (var entry in h.entries) {
          final key = entry.key.toString().toLowerCase();
          if (key.contains('date') || key == 'day' || key.contains('start') || key.contains('time')) {
            final val = entry.value;
            if (val != null && val.toString().isNotEmpty) {
              if (val is Map) {
                dateStr = (val['formatted'] ?? val['date'] ?? val['val'] ?? val.toString()).toString();
              } else {
                dateStr = val.toString();
              }
              break;
            }
          }
        }
      }
    } else {
      dateStr = h.toString();
    }

    if (dateStr.isEmpty) return null;

    try {
      if (dateStr.contains('-')) {
        if (dateStr.split('-').first.length == 4) {
          return DateFormat('yyyy-MM-dd').parse(dateStr.split(' ').first);
        } else {
          return DateFormat('dd-MM-yyyy').parse(dateStr.split(' ').first);
        }
      } else if (dateStr.contains('/')) {
        if (dateStr.split('/').first.length == 4) {
          return DateFormat('yyyy/MM/dd').parse(dateStr.split(' ').first);
        } else {
          return DateFormat('dd/MM/yyyy').parse(dateStr.split(' ').first);
        }
      } else {
        return DateTime.tryParse(dateStr);
      }
    } catch (e) {
      return DateTime.tryParse(dateStr);
    }
  }

  String _formatDate(dynamic h) {
    final dt = _getDateTime(h);
    if (dt != null) {
      return DateFormat('dd-MM-yyyy').format(dt);
    }
    return '';
  }
}
