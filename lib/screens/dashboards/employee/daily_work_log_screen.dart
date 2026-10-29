import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../services/api_service.dart';

// Backend stores rich-text (HTML) in worksheet fields — strip tags for display.
String _stripHtml(String? input) {
  if (input == null || input.isEmpty) return '';
  var text = input;
  // Block/line-break tags become newlines
  text = text.replaceAll(RegExp(r'<\s*br\s*/?\s*>', caseSensitive: false), '\n');
  text = text.replaceAll(
      RegExp(r'</\s*(p|div|li|h[1-6]|tr)\s*>', caseSensitive: false), '\n');
  // Drop any remaining tags
  text = text.replaceAll(RegExp(r'<[^>]*>'), '');
  // Decode common HTML entities
  text = text
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'")
      .replaceAll('&rsquo;', '’')
      .replaceAll('&lsquo;', '‘')
      .replaceAll('&hellip;', '…')
      .replaceAll('&mdash;', '—')
      .replaceAll('&ndash;', '–');
  // Collapse excess blank lines
  text = text.replaceAll(RegExp(r'[ \t]+\n'), '\n');
  text = text.replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n');
  return text.trim();
}

class DailyWorkLogScreen extends StatefulWidget {
  const DailyWorkLogScreen({super.key});

  @override
  State<DailyWorkLogScreen> createState() => _DailyWorkLogScreenState();
}

class _DailyWorkLogScreenState extends State<DailyWorkLogScreen> {
  List<Map<String, dynamic>> _worksheets = [];
  bool _isLoading = true;

  int _total = 0, _pending = 0, _approved = 0, _rejected = 0;
  String _activeFilter = 'all'; // all, pending, approved, rejected

  @override
  void initState() {
    super.initState();
    _fetchWorksheets();
  }

  Future<void> _fetchWorksheets() async {
    setState(() => _isLoading = true);
    final res = await ApiService.getEmployeeDailyWorksheets();
    if (mounted) {
      setState(() {
        if (res['error'] == false) {
          _worksheets = List<Map<String, dynamic>>.from(res['data'] ?? []);
          final stats = res['stats'] ?? {};
          _total = stats['total'] ?? _worksheets.length;
          _pending = stats['pending'] ?? _worksheets.where((w) => _getApprovalStatus(w) == 'pending').length;
          _approved = stats['approved'] ?? _worksheets.where((w) => _getApprovalStatus(w) == 'approved').length;
          _rejected = stats['rejected'] ?? _worksheets.where((w) => _getApprovalStatus(w) == 'rejected').length;
        }
        _isLoading = false;
      });
    }
  }

  String _getApprovalStatus(Map<String, dynamic> w) {
    final s = (w['approval_status'] ?? w['status'] ?? '').toString().toLowerCase();
    if (s.contains('approved')) return 'approved';
    if (s.contains('rejected')) return 'rejected';
    return 'pending';
  }

  List<Map<String, dynamic>> get _filteredWorksheets {
    if (_activeFilter == 'all') return _worksheets;
    return _worksheets.where((w) => _getApprovalStatus(w) == _activeFilter).toList();
  }

  void _openSubmitWorksheet({Map<String, dynamic>? editWorksheet}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubmitWorksheetScreen(editWorksheet: editWorksheet),
      ),
    );
    if (result == true) _fetchWorksheets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: RefreshIndicator(
        onRefresh: _fetchWorksheets,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildFilterCards(),
                    const SizedBox(height: 20),
                    _buildListHeader(),
                    const SizedBox(height: 12),
                    _isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(48),
                              child: CircularProgressIndicator(color: AppColors.navy),
                            ),
                          )
                        : _filteredWorksheets.isEmpty
                            ? _buildEmptyState()
                            : _buildTable(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D2137), Color(0xFF1A3A5C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Daily Worksheets',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Track submissions, who they were sent to, approval status, and reviewer feedback.',
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _openSubmitWorksheet(),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(
              'Submit Worksheet',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0D2137),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCards() {
    final items = <({String label, String key, int count})>[
      (label: 'Total', key: 'all', count: _total),
      (label: 'Pending', key: 'pending', count: _pending),
      (label: 'Approved', key: 'approved', count: _approved),
      (label: 'Rejected', key: 'rejected', count: _rejected),
    ];
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: items.asMap().entries.map((entry) {
          final item = entry.value;
          final isActive = _activeFilter == item.key;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: entry.key < items.length - 1 ? 6 : 0),
              child: _buildFilterSegment(item.label, item.count, isActive, item.key),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilterSegment(String label, int count, bool isActive, String key) {
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = key),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: isActive ? AppColors.navy.withValues(alpha: 0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: isActive ? AppColors.navy : Colors.transparent),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.1,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? AppColors.navy : Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListHeader() {
    final label = _activeFilter == 'all'
        ? 'All Worksheets'
        : '${_activeFilter[0].toUpperCase()}${_activeFilter.substring(1)} Worksheets';
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.navy),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.navy.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_filteredWorksheets.length}',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.navy),
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: _isLoading ? null : _fetchWorksheets,
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.navy),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.description_outlined, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No worksheets found', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[500])),
            const SizedBox(height: 8),
            Text('Submit your first worksheet by tapping the button above.', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400]), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8F9FA)),
            headingRowHeight: 44,
            dataRowMinHeight: 56,
            dataRowMaxHeight: 70,
            columnSpacing: 24,
            horizontalMargin: 20,
            dividerThickness: 1,
            columns: [
              DataColumn(label: Text('Work Date', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.navy))),
              DataColumn(label: Text('Projects / Other Work', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.navy))),
              DataColumn(label: Text('Status', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.navy))),
              DataColumn(label: Text('Submitted To', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.navy))),
              DataColumn(label: Text('Reviewed By', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.navy))),
              DataColumn(label: Text('Actions', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.navy))),
            ],
            rows: _filteredWorksheets.map((w) => _buildRow(w)).toList(),
          ),
        ),
      ),
    );
  }

  DataRow _buildRow(Map<String, dynamic> w) {
    final workDate = w['work_date'] ?? '-';
    String displayDate = workDate;
    String dayName = '';
    try {
      final dt = DateTime.parse(workDate).toLocal();
      displayDate = DateFormat('dd MMM yyyy').format(dt);
      dayName = DateFormat('EEEE').format(dt);
    } catch (_) {}

    // Backend returns 'items' (multi-project), not 'projects'
    final items = w['items'] as List? ?? w['projects'] as List? ?? [];
    String projectDisplay;
    if (items.isNotEmpty) {
      projectDisplay = items.map((p) => p['project_name'] ?? p['project']?['name'] ?? p['name'] ?? '').where((n) => n.toString().isNotEmpty).join(', ');
    } else {
      projectDisplay = w['project']?['name'] ?? w['project_name'] ?? w['other_work'] ?? 'N/A';
    }

    final approvalStatus = _getApprovalStatus(w);
    final submittedTo = w['team_leader']?['name'] ?? w['user']?['team_leader']?['name'] ?? '—';
    final submittedToRole = w['team_leader']?['designation'] ?? w['user']?['team_leader']?['designation'] ?? 'TEAM LEADER';
    final reviewedBy = w['approver']?['name'] ?? w['reviewed_by']?['name'] ?? '—';

    return DataRow(
      cells: [
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(displayDate, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.navy)),
              if (dayName.isNotEmpty)
                Text(dayName, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500])),
            ],
          ),
        ),
        DataCell(
          SizedBox(
            width: 240,
            child: Row(
              children: [
                Icon(Icons.layers_rounded, size: 16, color: Colors.blue[400]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _stripHtml(projectDisplay),
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
        DataCell(_buildStatusBadge(approvalStatus)),
        DataCell(
          submittedTo == '—'
              ? Text('—', style: GoogleFonts.inter(color: Colors.grey[400]))
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(submittedTo, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
                      child: Text(submittedToRole.toString().toUpperCase(), style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.grey[600])),
                    ),
                  ],
                ),
        ),
        DataCell(
          Text(reviewedBy, style: GoogleFonts.inter(fontSize: 13, color: reviewedBy == '—' ? Colors.grey[400] : AppColors.navy, fontWeight: FontWeight.w500)),
        ),
        DataCell(
          Row(
            children: [
              _actionIcon(Icons.visibility_outlined, Colors.blue, 'View', () => _showViewDialog(w)),
              const SizedBox(width: 8),
              if (approvalStatus == 'pending')
                _actionIcon(Icons.edit_outlined, Colors.orange, 'Edit', () => _openSubmitWorksheet(editWorksheet: w)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg, fg;
    IconData icon;
    String label;
    switch (status) {
      case 'approved':
        bg = Colors.green.shade50; fg = Colors.green.shade700; icon = Icons.check_circle_outline; label = 'Approved';
        break;
      case 'rejected':
        bg = Colors.red.shade50; fg = Colors.red.shade700; icon = Icons.cancel_outlined; label = 'Rejected';
        break;
      default:
        bg = Colors.orange.shade50; fg = Colors.orange.shade700; icon = Icons.access_time_rounded; label = 'Pending';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
        ],
      ),
    );
  }

  Widget _actionIcon(IconData icon, Color color, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  void _showViewDialog(Map<String, dynamic> w) {
    showDialog(context: context, builder: (_) => _ViewWorksheetDialog(
      worksheet: w,
      onEdit: () {
        Navigator.pop(context);
        _openSubmitWorksheet(editWorksheet: w);
      },
    ));
  }
}

// ==============================
// Submit / Edit Worksheet Screen
// ==============================
class SubmitWorksheetScreen extends StatefulWidget {
  final Map<String, dynamic>? editWorksheet;
  const SubmitWorksheetScreen({super.key, this.editWorksheet});

  @override
  State<SubmitWorksheetScreen> createState() => _SubmitWorksheetScreenState();
}

class _SubmitWorksheetScreenState extends State<SubmitWorksheetScreen> {
  bool _isLoadingProjects = true;
  bool _isSubmitting = false;
  List<dynamic> _projects = [];
  List<dynamic> _selectedProjects = [];
  Map<int, TextEditingController> _todaysWorkControllers = {};
  Map<int, TextEditingController> _nextPlanControllers = {};
  final _otherWorkController = TextEditingController();
  DateTime _workDate = DateTime.now().subtract(const Duration(days: 1));

  @override
  void initState() {
    super.initState();
    _fetchProjects();
    if (widget.editWorksheet != null) {
      final w = widget.editWorksheet!;
      if (w['work_date'] != null) {
        _workDate = (DateTime.tryParse(w['work_date'].toString()) ?? _workDate).toLocal();
      }
      _otherWorkController.text = _stripHtml(w['other_work']?.toString());
    }
  }

  Future<void> _fetchProjects() async {
    setState(() => _isLoadingProjects = true);
    final res = await ApiService.getEmployeeProjects();
    if (mounted) {
      setState(() {
        _isLoadingProjects = false;
        if (res['error'] == false) {
          _projects = res['data'] ?? [];
          // Pre-populate if editing
          if (widget.editWorksheet != null) {
            // Backend uses 'items' for multi-project worksheets
            final existingItems = widget.editWorksheet!['items'] as List? ?? widget.editWorksheet!['projects'] as List? ?? [];
            for (var ep in existingItems) {
              final projectId = ep['project_id'] ?? ep['id'];
              final matched = _projects.firstWhere(
                (p) => p['id'] == projectId || p['id']?.toString() == projectId?.toString(),
                orElse: () => null,
              );
              if (matched != null && !_selectedProjects.any((s) => s['id'] == matched['id'])) {
                _selectedProjects.add(matched);
                final id = matched['id'] as int;
                _todaysWorkControllers[id] = TextEditingController(text: _stripHtml(ep['todays_work']?.toString()));
                // Backend uses 'next_step', not 'next_plan'
                _nextPlanControllers[id] = TextEditingController(text: _stripHtml((ep['next_step'] ?? ep['next_plan'])?.toString()));
              }
            }
          }
        }
      });
    }
  }

  void _toggleProject(dynamic project) {
    final id = project['id'] as int;
    setState(() {
      if (_selectedProjects.any((p) => p['id'] == id)) {
        _selectedProjects.removeWhere((p) => p['id'] == id);
        _todaysWorkControllers[id]?.dispose();
        _nextPlanControllers[id]?.dispose();
        _todaysWorkControllers.remove(id);
        _nextPlanControllers.remove(id);
      } else {
        _selectedProjects.add(project);
        _todaysWorkControllers[id] = TextEditingController();
        _nextPlanControllers[id] = TextEditingController();
      }
    });
  }

  bool _isProjectSelected(dynamic project) {
    return _selectedProjects.any((p) => p['id'] == project['id']);
  }

  Future<void> _submit() async {
    if (_selectedProjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one project'), backgroundColor: Colors.red),
      );
      return;
    }

    // Validate today's work for all selected projects
    for (final project in _selectedProjects) {
      final id = project['id'] as int;
      if (_todaysWorkControllers[id]?.text.trim().isEmpty ?? true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please fill Today's Work for: ${project['name'] ?? project['project_name'] ?? 'Project'}"), backgroundColor: Colors.red),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    final projectsPayload = _selectedProjects.map((p) {
      final id = p['id'] as int;
      return {
        'project_id': id,
        'todays_work': _todaysWorkControllers[id]?.text.trim() ?? '',
        'next_step': _nextPlanControllers[id]?.text.trim() ?? '',
      };
    }).toList();

    final body = {
      'work_date': DateFormat('yyyy-MM-dd').format(_workDate),
      'projects': projectsPayload,
      'other_work': _otherWorkController.text.trim(),
    };

    final res = widget.editWorksheet != null
        ? await ApiService.updateEmployeeDailyWorksheet(widget.editWorksheet!['id'], body)
        : await ApiService.submitEmployeeDailyWorksheet(body);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (res['error'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.editWorksheet != null ? 'Worksheet updated!' : 'Worksheet submitted for approval!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Error submitting worksheet'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _otherWorkController.dispose();
    for (final c in _todaysWorkControllers.values) c.dispose();
    for (final c in _nextPlanControllers.values) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2137),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.editWorksheet != null ? 'Edit Daily Worksheet' : 'Submit Daily Worksheet',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            Text(
              'Select projects, describe today\'s work, and add other activities if needed.',
              style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: _isLoadingProjects
          ? const Center(child: CircularProgressIndicator(color: AppColors.navy))
          : LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 900;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: isDesktop
                      ? _buildDesktopLayout()
                      : _buildMobileLayout(),
                );
              },
            ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Panel — Worksheet Setup
        SizedBox(
          width: 320,
          child: _buildLeftPanel(),
        ),
        const SizedBox(width: 24),
        // Right Panel — Projects + Forms
        Expanded(
          child: _buildMainContent(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Left Panel — Worksheet Setup (Full width on mobile)
        _buildLeftPanel(),
        const SizedBox(height: 20),
        // Right Panel — Projects + Forms
        _buildMainContent(),
      ],
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        _buildProjectsSection(),
        const SizedBox(height: 20),
        if (_selectedProjects.isEmpty)
          _buildEmptyProjectState()
        else
          ..._selectedProjects.map((p) => _buildProjectForm(p)),
        const SizedBox(height: 20),
        _buildOtherWorkSection(),
        const SizedBox(height: 24),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildEmptyProjectState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.work_outline_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No projects selected',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select one or more projects above to start filling your worksheet.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date Picker Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D2137).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calendar_today_rounded,
                      color: Color(0xFF0D2137),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Worksheet Setup',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Work Date',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.offWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time_rounded, color: Colors.grey[500], size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${_getYesterdayLabel()} — ${DateFormat('dd MMM yyyy').format(_workDate)}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.navy,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Tips Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.blue.shade100],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline_rounded, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Quick Tips',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.blue[800],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _tip('Select projects you worked on today'),
              _tip('Describe your work for each project'),
              _tip('Add non-project activities if needed'),
              _tip('Submit for your leader to review'),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _workDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF0D2137), onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => _workDate = d);
  }

  String _getYesterdayLabel() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    if (_workDate.year == yesterday.year && _workDate.month == yesterday.month && _workDate.day == yesterday.day) {
      return 'Yesterday';
    }
    if (_workDate.year == DateTime.now().year && _workDate.month == DateTime.now().month && _workDate.day == DateTime.now().day) {
      return 'Today';
    }
    return DateFormat('EEEE').format(_workDate);
  }

  Widget _tip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.blue[600],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.blue[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D2137).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.work_rounded,
                  color: Color(0xFF0D2137),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Projects',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap to select the projects you worked on today',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedProjects.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D2137).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_selectedProjects.length} selected',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0D2137),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _projects.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.folder_off_rounded, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(
                          'No projects available',
                          style: GoogleFonts.inter(
                            color: Colors.grey[600],
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Contact your manager to assign projects',
                          style: GoogleFonts.inter(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: MediaQuery.of(context).size.width > 600 ? 3.5 : 4,
                  ),
                  itemCount: _projects.length,
                  itemBuilder: (_, i) {
                    final p = _projects[i];
                    final selected = _isProjectSelected(p);
                    final dept = p['department']?['name'] ?? p['department_name'] ?? p['category'] ?? '';
                    return _buildProjectCard(p, selected, dept);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(dynamic project, bool selected, String dept) {
    return GestureDetector(
      onTap: () => _toggleProject(project),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0D2137).withValues(alpha: 0.05) : AppColors.offWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF0D2137) : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF0D2137) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: selected ? const Color(0xFF0D2137) : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    project['name']?.toString() ?? project['project_name']?.toString() ?? 'Project',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.navy,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (dept.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        dept.toString().toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.blue[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectForm(dynamic project) {
    final id = project['id'] as int;
    final dept = project['department']?['name'] ?? project['department_name'] ?? project['category'] ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Project Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0D2137),
                  const Color(0xFF1A3A5C),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.folder_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project['name']?.toString() ?? project['project_name']?.toString() ?? 'Project',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      if (dept.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            dept.toString().toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'SELECTED',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Project Form Fields
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildTextArea(
                  "Today's Work *",
                  _todaysWorkControllers[id]!,
                  hint: "Describe what you worked on today for this project...",
                  icon: Icons.description_rounded,
                ),
                const SizedBox(height: 16),
                _buildTextArea(
                  "Next Work / Plan",
                  _nextPlanControllers[id]!,
                  hint: "What will you work on next?",
                  required: false,
                  icon: Icons.next_plan_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherWorkSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.more_horiz_rounded,
                  color: Colors.orange[700],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Other Work',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Optional',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Non-project activities like meetings, training, support',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextArea(
            'Other Work Details',
            _otherWorkController,
            hint: 'Describe any non-project activities...',
            required: false,
            icon: Icons.note_add_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildTextArea(String label, TextEditingController controller, {String? hint, bool required = true, IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: 4,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.navy),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400]),
            fillColor: AppColors.offWhite,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0D2137), width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded, size: 18),
            label: Text(
              widget.editWorksheet != null ? 'Update Worksheet' : 'Submit for Approval',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D2137),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================
// View Worksheet Dialog
// ==============================
class _ViewWorksheetDialog extends StatelessWidget {
  final Map<String, dynamic> worksheet;
  final VoidCallback? onEdit;
  const _ViewWorksheetDialog({required this.worksheet, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final w = worksheet;
    final workDate = w['work_date'] ?? '-';
    String displayDate = workDate;
    try { displayDate = DateFormat('dd MMM yyyy, EEEE').format(DateTime.parse(workDate).toLocal()); } catch (_) {}
    // Backend uses 'items' for multi-project worksheets
    final items = w['items'] as List? ?? w['projects'] as List? ?? [];
    final otherWork = _stripHtml(w['other_work']?.toString());
    final submittedTo = w['team_leader']?['name'] ?? w['user']?['team_leader']?['name'] ?? '—';
    final reviewedBy = w['approver']?['name'] ?? w['reviewed_by']?['name'] ?? '—';
    // Backend uses 'leader_comment', not 'feedback' or 'reviewer_feedback'
    final feedback = _stripHtml(w['leader_comment']?.toString() ?? w['feedback']?.toString() ?? w['reviewer_feedback']?.toString());
    final status = (w['approval_status'] ?? w['status'] ?? 'pending').toString().toLowerCase();

    Color statusColor = Colors.orange;
    if (status.contains('approved')) statusColor = Colors.green;
    if (status.contains('rejected')) statusColor = Colors.red;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF0D2137), Color(0xFF1A3A5C)]),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Worksheet Details', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                        Text(displayDate, style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: statusColor.withValues(alpha: 0.4))),
                    child: Text(status.toUpperCase(), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
                  ),
                  const SizedBox(width: 8),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow('Submitted To', submittedTo),
                    _infoRow('Reviewed By', reviewedBy),
                    if (feedback.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.orange.shade200)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Reviewer Feedback', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.orange.shade700)),
                            const SizedBox(height: 4),
                            Text(feedback, style: GoogleFonts.inter(fontSize: 13, color: Colors.orange.shade900)),
                          ],
                        ),
                      ),
                    ],
                    if (items.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text('Projects', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy)),
                      const SizedBox(height: 8),
                      ...items.map((p) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.offWhite,
                          borderRadius: BorderRadius.circular(10),
                          border: Border(left: const BorderSide(color: Color(0xFF0D2137), width: 3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_stripHtml(p['project_name'] ?? p['project']?['name'] ?? p['name'] ?? 'Project'), style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.navy)),
                            if (p['todays_work']?.toString().isNotEmpty == true) ...[
                              const SizedBox(height: 8),
                              Text("Today's Work:", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600])),
                              Text(_stripHtml(p['todays_work']?.toString()), style: GoogleFonts.inter(fontSize: 13)),
                            ],
                            // Backend uses 'next_step', not 'next_plan'
                            if ((p['next_step'] ?? p['next_plan'])?.toString().isNotEmpty == true) ...[
                              const SizedBox(height: 8),
                              Text("Next Plan:", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600])),
                              Text(_stripHtml((p['next_step'] ?? p['next_plan'])?.toString()), style: GoogleFonts.inter(fontSize: 13)),
                            ],
                          ],
                        ),
                      )),
                    ],
                    if (otherWork.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text('Other Work (Non-Project)', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
                        child: Text(otherWork, style: GoogleFonts.inter(fontSize: 13)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (status == 'pending' && onEdit != null) ...[
                    OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: Text('Edit Worksheet', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange.shade700,
                        side: BorderSide(color: Colors.orange.shade700),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D2137), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: Text('Close', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text('$label:', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[600]))),
          Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navy)),
        ],
      ),
    );
  }
}
