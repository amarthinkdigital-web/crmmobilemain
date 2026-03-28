import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../theme/app_theme.dart';
import '../../../../services/api_service.dart';

class ProjectDetailsScreen extends StatefulWidget {
  const ProjectDetailsScreen({super.key});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  List<dynamic> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProjects();
  }

  Future<void> _fetchProjects() async {
    setState(() => _isLoading = true);
    final res = await ApiService.getProjects();
    if (mounted) {
      if (res['error'] == false) {
        setState(() {
          _projects = res['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
      }
    }
  }

  void _showAddProjectDialog() async {
    final nameController = TextEditingController();
    final typeController = TextEditingController();
    final progressController = TextEditingController(text: "0");
    final startDateController = TextEditingController();
    final endDateController = TextEditingController();
    
    // Fetch clients for selection
    final clientRes = await ApiService.getClientProfiles();
    final clients = clientRes['data'] ?? [];
    dynamic selectedClient;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Create Project", style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.navy)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<dynamic>(
                    value: selectedClient,
                    hint: const Text("Select Client"),
                    items: clients.map<DropdownMenuItem<dynamic>>((c) => DropdownMenuItem(value: c, child: Text(c['company_name'] ?? 'N/A'))).toList(),
                    onChanged: (val) => setDialogState(() => selectedClient = val),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.offWhite,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInputField("Project Name", Icons.title, nameController),
                  const SizedBox(height: 12),
                  _buildInputField("Type (e.g. Design)", Icons.category, typeController),
                  const SizedBox(height: 12),
                  _buildInputField("Initial Progress %", Icons.trending_up, progressController, inputType: TextInputType.number),
                  const SizedBox(height: 12),
                  TextField(
                    controller: startDateController,
                    readOnly: true,
                    onTap: () async {
                      final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                      if (d != null) startDateController.text = DateFormat('yyyy-MM-dd').format(d);
                    },
                    decoration: _inputDecoration("Start Date", Icons.calendar_today),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: endDateController,
                    readOnly: true,
                    onTap: () async {
                      final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                      if (d != null) endDateController.text = DateFormat('yyyy-MM-dd').format(d);
                    },
                    decoration: _inputDecoration("End Date", Icons.event),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel"))),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (selectedClient == null || nameController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
                              return;
                            }
                            final res = await ApiService.createProject({
                              'client_profile_id': selectedClient['id'].toString(),
                              'project_name': nameController.text,
                              'project_type': typeController.text,
                              'progress': progressController.text,
                              'start_date': startDateController.text,
                              'end_date': endDateController.text,
                            });
                            if (mounted) {
                              if (res['error'] == false) {
                                _fetchProjects();
                                Navigator.pop(context);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: const Text("Save"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String hint, IconData icon, TextEditingController c, {TextInputType inputType = TextInputType.text}) {
    return TextField(controller: c, keyboardType: inputType, decoration: _inputDecoration(hint, icon));
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: AppColors.grey400),
      filled: true,
      fillColor: AppColors.offWhite,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: RefreshIndicator(
        onRefresh: _fetchProjects,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            _buildSliverAppBar(),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: _isLoading 
                ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                : _projects.isEmpty
                  ? const SliverFillRemaining(child: Center(child: Text("No projects found.")))
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildProjectCard(_projects[index]),
                        childCount: _projects.length,
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProjectDialog,
        backgroundColor: AppColors.navy,
        icon: const Icon(Icons.add, color: AppColors.white),
        label: const Text("New Project", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.navy,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Text("All Projects Portfolio", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.white)),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.navy, Color(0xFF1A237E)]),
          ),
          child: Opacity(
            opacity: 0.1,
            child: Icon(Icons.folder_copy, size: 100, color: Colors.white.withOpacity(0.5)),
          ),
        ),
      ),
    );
  }

  Widget _buildProjectCard(dynamic p) {
    final progress = double.tryParse(p['progress']?.toString() ?? '0') ?? 0;
    
    String formatDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return 'N/A';
      try {
        DateTime dt = DateTime.parse(dateStr);
        // Using toLocal() to ensure the date matches the user's timezone
        // and doesn't shift 1 day before due to UTC conversion.
        return DateFormat('dd MMM yyyy').format(dt.toLocal());
      } catch (e) {
        return dateStr;
      }
    }

    final String startDate = formatDate(p['start_date']);
    final String endDate = formatDate(p['end_date']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        p['project_name'] ?? 'Untitled Project',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildTag(p['project_type'] ?? 'General'),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.offWhite,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.navy),
                      const SizedBox(width: 10),
                      Text(
                        "$startDate  →  $endDate",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.grey600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Current Progress",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    Text(
                      "${progress.toInt()}%",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: progress >= 100 ? AppColors.success : AppColors.navy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 10,
                    backgroundColor: AppColors.offWhite,
                    valueColor: AlwaysStoppedAnimation(
                      progress >= 100 ? AppColors.success : AppColors.navy,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    progress >= 100 ? "Completed" : "Active Development",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: progress >= 100 ? AppColors.success : AppColors.gold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.offWhite),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(Icons.edit_rounded, "Edit", Colors.blue),
                _buildActionButton(Icons.delete_rounded, "Delete", AppColors.error),
                _buildActionButton(Icons.visibility_rounded, "View", AppColors.navy),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: const TextStyle(color: AppColors.gold, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
