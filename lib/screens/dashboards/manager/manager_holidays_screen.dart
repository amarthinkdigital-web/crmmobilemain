import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../services/api_service.dart';
import '../../../theme/app_theme.dart';

class ManagerHolidaysScreen extends StatefulWidget {
  final String userRole;
  const ManagerHolidaysScreen({super.key, this.userRole = 'Manager'});

  @override
  State<ManagerHolidaysScreen> createState() => _ManagerHolidaysScreenState();
}

class _ManagerHolidaysScreenState extends State<ManagerHolidaysScreen> {
  List<dynamic> _holidays = [];
  bool _isLoading = true;
  String? _errorMessage;

  bool get _isHRManager => widget.userRole.toLowerCase().contains('hr');

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

    final response = await ApiService.getManagerOfficialLeaves();

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
                _buildTableSection(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Leave List",
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Official company holidays for the year 2026",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.grey400,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (_isHRManager)
          ElevatedButton.icon(
            onPressed: () => _showHolidayDialog(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text("Add Holiday"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
      ],
    );
  }

  Widget _buildTableSection() {
    return Container(
      width: double.infinity,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              AppColors.navy.withValues(alpha: 0.05),
            ),
            columnSpacing: 40,
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

  DataRow _buildRow(int index, dynamic holiday) {
    return DataRow(
      cells: [
        DataCell(
          Text(
            index.toString(),
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        DataCell(
          Text(
            _formatDate(holiday),
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.grey600,
            ),
          ),
        ),
        DataCell(
          Text(
            holiday['title']?.toString() ?? '',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            ),
          ),
        ),
        DataCell(
          Text(
            holiday['description']?.toString() ?? '',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.grey600),
          ),
        ),
        DataCell(
          Row(
            children: [
              _buildActionBtn("View", Icons.visibility_rounded, AppColors.navy, () {
                _showHolidayDetails(holiday);
              }),
              if (_isHRManager) ...[
                const SizedBox(width: 8),
                _buildActionBtn("Edit", Icons.edit_rounded, Colors.blue, () {
                  _showHolidayDialog(holiday: holiday);
                }),
                const SizedBox(width: 8),
                _buildActionBtn("Delete", Icons.delete_rounded, Colors.red, () {
                  _deleteHoliday(holiday['id']);
                }),
              ],
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

  Future<void> _showHolidayDialog({dynamic holiday}) async {
    final titleController = TextEditingController(text: holiday?['title']?.toString() ?? '');
    final dt = _getDateTime(holiday);
    final dateController = TextEditingController(text: dt != null ? DateFormat('yyyy-MM-dd').format(dt) : '');
    final descController = TextEditingController(text: holiday?['description']?.toString() ?? '');

    final bool isEdit = holiday != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? "Edit Holiday" : "Add New Holiday"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Title"),
              ),
              TextField(
                controller: dateController,
                decoration: const InputDecoration(labelText: "Date (YYYY-MM-DD)"),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: dt ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    dateController.text = "${pickedDate.toLocal()}".split(' ')[0];
                  }
                },
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: "Description"),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
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
                'description': descController.text,
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
                res = await ApiService.updateManagerOfficialLeave(holiday['id'], body);
              } else {
                res = await ApiService.createManagerOfficialLeave(body);
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
            child: Text(isEdit ? "Update" : "Create"),
          ),
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
      final res = await ApiService.deleteManagerOfficialLeave(id);
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

  Widget _buildActionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
          color: color.withValues(alpha: 0.05),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
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
