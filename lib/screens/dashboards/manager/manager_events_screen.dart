import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../theme/app_theme.dart';

class ManagerEventsScreen extends StatefulWidget {
  const ManagerEventsScreen({super.key});

  @override
  State<ManagerEventsScreen> createState() => _ManagerEventsScreenState();
}

class _ManagerEventsScreenState extends State<ManagerEventsScreen> {
  List<dynamic> _events = [];
  bool _isLoading = true;
  String? _errorMessage;

  String? _currentUserName;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _fetchEvents();
  }

  Future<void> _loadUserInfo() async {
    final name = await AuthService.getUserName();
    final id = await AuthService.getUserId();
    if (mounted) {
      setState(() {
        _currentUserName = name;
        _currentUserId = id;
      });
    }
  }

  Future<void> _fetchEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final res = await ApiService.getManagerEvents();
    if (mounted) {
      if (res['error'] == false) {
        setState(() {
          _events = res['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = res['message'];
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(dynamic e) {
    if (e == null) return '';
    final keys = ['start_date', 'startDate', 'date', 'start', 'event_date', 'from_date'];
    for (final k in keys) {
      if (e[k] != null && e[k].toString().isNotEmpty) {
        final raw = e[k].toString().split(' ').first;
        try {
          final dt = DateTime.parse(raw);
          return DateFormat('dd-MM-yyyy').format(dt);
        } catch (_) {
          return raw;
        }
      }
    }
    return '';
  }

  String _formatEndDate(dynamic e) {
    if (e == null) return '';
    final keys = ['end_date', 'endDate', 'end', 'to_date'];
    for (final k in keys) {
      if (e[k] != null && e[k].toString().isNotEmpty) {
        final raw = e[k].toString().split(' ').first;
        try {
          final dt = DateTime.parse(raw);
          return DateFormat('dd-MM-yyyy').format(dt);
        } catch (_) {
          return raw;
        }
      }
    }
    return '';
  }

  String _getVisibility(dynamic e) {
    if (e == null) return 'Public';
    final val = (e['scope'] ?? e['visibility_scope'] ?? e['visibility'] ?? e['type'] ?? e['access'] ?? 'Public').toString();
    if (val.toLowerCase() == 'private' || val.toLowerCase() == 'only me') return 'Only Me';
    if (val.toLowerCase() == 'custom') return 'Custom';
    return 'Public';
  }

  void _showEventSheet({dynamic event}) {
    final bool isEdit = event != null;
    final titleController = TextEditingController(text: isEdit ? (event['title'] ?? '').toString() : '');
    final descController = TextEditingController(text: isEdit ? (event['description'] ?? '').toString() : '');
    final startController = TextEditingController(
      text: isEdit ? (event['start_date'] ?? event['startDate'] ?? event['date'] ?? '').toString().split(' ').first : '',
    );
    final endController = TextEditingController(
      text: isEdit ? (event['end_date'] ?? event['endDate'] ?? '').toString().split(' ').first : '',
    );

    const visibilityOptions = ['Public', 'Only Me', 'Custom'];
    final rawVisibility = isEdit ? _getVisibility(event) : 'Public';
    final initialVisibility = visibilityOptions.contains(rawVisibility) ? rawVisibility : 'Public';

    bool isSaving = false;
    String visibility = initialVisibility;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
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
                        isEdit ? 'Edit Event' : 'Create Event',
                        style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.navy),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildInputField('Event Title', 'Enter title', titleController, Icons.event_note_rounded),
                  const SizedBox(height: 16),
                  Builder(builder: (context) {
                    final rawCreator = isEdit 
                      ? (event['creator_name'] ?? event['created_by_name'] ?? event['user_name'] ?? event['user']?['name'] ?? event['creator']?['name'] ?? event['created_by']?['name'] ?? event['user_fullname'] ?? 'Admin')
                      : (_currentUserName ?? 'Self');
                    final creatorName = rawCreator.toString();
                    final isSelf = !isEdit || (_currentUserName != null && creatorName.toLowerCase() == _currentUserName!.toLowerCase());
                    return _buildInputField(
                      'Created By', '', TextEditingController(text: isSelf ? 'Self' : creatorName),
                      Icons.person_outline_rounded, isReadOnly: true,
                    );
                  }),
                  const SizedBox(height: 16),
                  _buildInputField('Description', 'Enter description', descController, Icons.description_rounded, maxLines: 2),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputField(
                          'Start Date', 'Select date', startController,
                          Icons.calendar_today_rounded,
                          isReadOnly: true,
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.tryParse(startController.text) ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (date != null) {
                              startController.text = DateFormat('yyyy-MM-dd').format(date);
                              setSheetState(() {});
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInputField(
                          'End Date', 'Select date', endController,
                          Icons.event_available_rounded,
                          isReadOnly: true,
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.tryParse(endController.text) ?? (DateTime.tryParse(startController.text) ?? DateTime.now()),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (date != null) {
                              endController.text = DateFormat('yyyy-MM-dd').format(date);
                              setSheetState(() {});
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Visibility', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(12)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: visibilityOptions.contains(visibility) ? visibility : visibilityOptions.first,
                        isExpanded: true,
                        items: visibilityOptions
                            .map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                        onChanged: isSaving ? null : (v) {
                          if (v != null) setSheetState(() => visibility = v);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : () async {
                        if (titleController.text.isEmpty || startController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Title and Start Date are required'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }

                        setSheetState(() => isSaving = true);

                        // Map frontend labels to backend values
                        String backendVisibility = visibility.toLowerCase();
                        if (backendVisibility == 'only me') backendVisibility = 'private';

                        final body = {
                          'title': titleController.text,
                          'name': titleController.text,
                          'description': descController.text,
                          'start_date': startController.text,
                          'end_date': endController.text.isEmpty ? startController.text : endController.text,
                          'visibility_scope': backendVisibility,
                        };
                        
                        try {
                          Map<String, dynamic> res;
                          if (isEdit) {
                            res = await ApiService.updateManagerEvent(event['id'], body);
                          } else {
                            res = await ApiService.createManagerEvent(body);
                          }
                          
                          if (mounted) {
                            if (res['error'] == false) {
                              Navigator.pop(context);
                              _fetchEvents();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isEdit ? 'Event updated successfully' : 'Event created successfully'),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } else {
                              setSheetState(() => isSaving = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(res['message'] ?? 'Operation failed'),
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            setSheetState(() => isSaving = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      child: isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              isEdit ? 'Update Event' : 'Create Event',
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteEvent(dynamic id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final res = await ApiService.deleteManagerEvent(id);
      if (mounted) {
        if (res['error'] == false) {
          _fetchEvents();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event deleted'), backgroundColor: AppColors.success),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Failed to delete'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  void _showEventDetails(dynamic event) {
    ApiService.markManagerEventViewed(event['id']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          event['title']?.toString() ?? 'Event Details',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.navy),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((event['description'] ?? '').toString().isNotEmpty) ...[
              Text('Description:', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
              Text(event['description'].toString(), style: GoogleFonts.inter(fontSize: 13)),
              const SizedBox(height: 8),
            ],
            Text('Start Date: ${_formatDate(event)}', style: GoogleFonts.inter(fontSize: 13)),
            Text('End Date: ${_formatEndDate(event)}', style: GoogleFonts.inter(fontSize: 13)),
            Text('Visibility: ${_getVisibility(event)}', style: GoogleFonts.inter(fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: RefreshIndicator(
        onRefresh: _fetchEvents,
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
                      ElevatedButton(onPressed: _fetchEvents, child: const Text('Retry')),
                    ],
                  ),
                )
              else
                _buildEventsTable(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEventSheet(),
        backgroundColor: AppColors.navy,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Create Event', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Manager Events',
          style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.navy, letterSpacing: -0.5),
        ),
        Text(
          'Manage company and team-wide events and meetings',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.grey400, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildEventsTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Event List Table',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navy),
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(AppColors.navy.withValues(alpha: 0.05)),
                columnSpacing: 30,
                columns: [
                  _col('Sr. No.'),
                  _col('Title'),
                  _col('Created By'),
                  _col('Start Date'),
                  _col('End Date'),
                  _col('Visibility'),
                  _col('Action'),
                ],
                rows: _events.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final e = entry.value;
                  return DataRow(
                    cells: [
                      DataCell(Text((idx + 1).toString(), style: GoogleFonts.inter(fontSize: 12))),
                      DataCell(Text(
                        e['title']?.toString() ?? '',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navy),
                      )),
                      DataCell(Builder(builder: (context) {
                        final rawCreator = e['creator_name'] ?? e['created_by_name'] ?? e['user_name'] ?? e['user']?['name'] ?? e['creator']?['name'] ?? e['created_by']?['name'] ?? e['user_fullname'] ?? 'Admin';
                        final creatorName = rawCreator.toString();
                        final creatorId = e['user_id']?.toString() ?? e['created_by_id']?.toString() ?? e['created_by']?.toString();
                        
                        final bool isSelf = (_currentUserId != null && creatorId == _currentUserId) || 
                                          (_currentUserName != null && creatorName.toLowerCase() == _currentUserName!.toLowerCase());
                        
                        return Text(
                          isSelf ? 'Self' : creatorName,
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: isSelf ? FontWeight.w700 : FontWeight.w500, color: isSelf ? AppColors.success : AppColors.grey600),
                        );
                      })),
                      DataCell(Text(_formatDate(e), style: GoogleFonts.inter(fontSize: 12))),
                      DataCell(Text(_formatEndDate(e), style: GoogleFonts.inter(fontSize: 12))),
                      DataCell(_buildVisibilityBadge(_getVisibility(e))),
                      DataCell(Builder(builder: (context) {
                        final rawCreator = e['creator_name'] ?? e['created_by_name'] ?? e['user_name'] ?? e['user']?['name'] ?? e['creator']?['name'] ?? e['created_by']?['name'] ?? e['user_fullname'] ?? '';
                        final creatorName = rawCreator.toString();
                        final creatorId = e['user_id']?.toString() ?? e['created_by_id']?.toString() ?? e['created_by']?.toString();
                        
                        final bool isSelf = (_currentUserId != null && creatorId == _currentUserId) || 
                                          (_currentUserName != null && creatorName.toLowerCase() == _currentUserName!.toLowerCase());
                        
                        return Row(
                          children: [
                            _actionIcon(Icons.visibility_outlined, AppColors.info, 'View', () => _showEventDetails(e)),
                            if (isSelf) ...[
                              const SizedBox(width: 6),
                              _actionIcon(Icons.edit_outlined, AppColors.goldDark, 'Edit', () => _showEventSheet(event: e)),
                              const SizedBox(width: 6),
                              _actionIcon(Icons.delete_outline_rounded, AppColors.error, 'Delete', () => _deleteEvent(e['id'])),
                            ],
                          ],
                        );
                      })),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataColumn _col(String label) {
    return DataColumn(
      label: Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy)),
    );
  }

  Widget _buildVisibilityBadge(String visibility) {
    Color color = AppColors.navy;
    if (visibility == 'Public') color = AppColors.success;
    if (visibility == 'Only Me') color = AppColors.error;
    if (visibility == 'Custom') color = AppColors.goldDark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        visibility,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _actionIcon(IconData icon, Color color, String tooltip, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    String hint,
    TextEditingController controller,
    IconData icon, {
    bool isReadOnly = false,
    VoidCallback? onTap,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: isReadOnly,
          maxLines: maxLines,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.grey400, size: 20),
            filled: true,
            fillColor: AppColors.offWhite,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}
