import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../services/api_service.dart';

class DepartmentsScreen extends StatefulWidget {
  const DepartmentsScreen({super.key});

  @override
  State<DepartmentsScreen> createState() => _DepartmentsScreenState();
}

class _DepartmentsScreenState extends State<DepartmentsScreen> {
  List<dynamic> _departments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
  }

  Future<void> _fetchDepartments() async {
    setState(() => _isLoading = true);
    final res = await ApiService.getDepartments();
    if (mounted) {
      if (res['error'] == false) {
        setState(() {
          _departments = res['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showToast(res['message'] ?? 'Failed to load departments', isError: true);
      }
    }
  }

  void _showToast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _addDepartment() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Department', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter department name',
            filled: true,
            fillColor: AppColors.offWhite,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.grey400)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final name = controller.text;
                Navigator.pop(context);
                setState(() => _isLoading = true);
                final res = await ApiService.createDepartment(name);
                if (res['error'] == false) {
                  _showToast("Department created!");
                  _fetchDepartments();
                } else {
                  setState(() => _isLoading = false);
                  _showToast(res['message'], isError: true);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editDepartment(Map<String, dynamic> dept) {
    final controller = TextEditingController(text: dept['name']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Department', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter department name',
            filled: true,
            fillColor: AppColors.offWhite,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.grey400)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final newName = controller.text;
                Navigator.pop(context);
                setState(() => _isLoading = true);
                final res = await ApiService.updateDepartment(dept['id'], newName);
                if (res['error'] == false) {
                  _showToast("Department updated!");
                  _fetchDepartments();
                } else {
                  setState(() => _isLoading = false);
                  _showToast(res['message'], isError: true);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteDepartment(Map<String, dynamic> dept) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Department', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete "${dept['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.grey400)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              final res = await ApiService.deleteDepartment(dept['id']);
              if (res['error'] == false) {
                _showToast("Department deleted!");
                _fetchDepartments();
              } else {
                setState(() => _isLoading = false);
                _showToast(res['message'], isError: true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Departments',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Company structure',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.grey400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _addDepartment,
                icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                label: const Text('Add Dept', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.grey100),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                : _departments.isEmpty
                  ? Center(child: Text('No departments found.', style: TextStyle(color: AppColors.grey400)))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: DataTable(
                          columnSpacing: 30,
                          headingRowColor: WidgetStateProperty.all(AppColors.offWhite),
                          columns: [
                            DataColumn(
                              label: Text('Sr. No', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.navy)),
                            ),
                            DataColumn(
                              label: Text('Department Name', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.navy)),
                            ),
                            DataColumn(
                              label: Text('Actions', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.navy)),
                            ),
                          ],
                          rows: List.generate(_departments.length, (index) {
                            final dept = _departments[index];
                            return DataRow(
                              cells: [
                                DataCell(Text('${index + 1}', style: GoogleFonts.inter(color: AppColors.navy))),
                                DataCell(Text(dept['name'] ?? 'N/A', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.navy))),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.info),
                                        onPressed: () => _editDepartment(dept),
                                        tooltip: 'Edit',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                                        onPressed: () => _deleteDepartment(dept),
                                        tooltip: 'Delete',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
