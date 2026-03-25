import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../services/api_service.dart';

class ManagerPage extends StatefulWidget {
  const ManagerPage({super.key});

  @override
  State<ManagerPage> createState() => _ManagerPageState();
}

class _ManagerPageState extends State<ManagerPage> {
  String selectedDepartment = "All Departments";
  String selectedStatus = "All";
  String selectedState = "All";

  final searchController = TextEditingController();

  // Form Controllers
  final nameController = TextEditingController();
  final idController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final stateController = TextEditingController();
  String formDept = "Project";

  List<Map<String, dynamic>> managers = [];

  final List<String> departments = [
    "All Departments",
    "Graphic",
    "HR",
    "Marketing",
    "Project",
  ];

  final List<String> formDepartments = [
    "Graphic",
    "HR",
    "Marketing",
    "Project",
  ];

  final List<String> statusList = [
    "All",
    "Active",
    "Terminate",
    "Resigned",
    "On Hold",
  ];
  final List<String> states = [
    "All",
    "Maharashtra",
    "Gujarat",
    "Delhi",
    "Karnataka",
  ];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      setState(() {});
    });
    _fetchManagers();
  }

  @override
  void dispose() {
    searchController.dispose();
    nameController.dispose();
    idController.dispose();
    emailController.dispose();
    phoneController.dispose();
    stateController.dispose();
    super.dispose();
  }

  Future<void> _fetchManagers() async {
    setState(() => isLoading = true);
    final res = await ApiService.getManagerProfiles();
    if (!mounted) return;

    if (res['error'] == false) {
      setState(() {
        managers = List<Map<String, dynamic>>.from(res['data'] ?? []);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Failed to load data')),
      );
    }
  }

  List<Map<String, dynamic>> get filteredManagers {
    return managers.where((m) {
      final fname = m['first_name']?.toString().toLowerCase() ?? '';
      final lname = m['last_name']?.toString().toLowerCase() ?? '';
      final nameStr =
          m['name']?.toString().toLowerCase() ?? '$fname $lname'.trim();
      final emailStr = m['email']?.toString().toLowerCase() ?? '';
      final idStr =
          m['employee_id']?.toString().toLowerCase() ??
          m['id']?.toString().toLowerCase() ??
          '';
      final search = searchController.text.toLowerCase();

      bool matchSearch =
          nameStr.contains(search) ||
          emailStr.contains(search) ||
          idStr.contains(search);

      String deptName = 'Unknown';
      if (m['department'] is Map) {
        deptName = m['department']['name']?.toString() ?? 'Unknown';
      } else if (m['department_name'] != null) {
        deptName = m['department_name'].toString();
      } else if (m['dept'] != null) {
        deptName = m['dept'].toString();
      }
      bool matchDept =
          selectedDepartment == "All Departments" ||
          deptName == selectedDepartment;

      String statusStr = m['status']?.toString() ?? 'Active';
      bool matchStatus =
          selectedStatus == "All" ||
          statusStr.toLowerCase() == selectedStatus.toLowerCase();

      String stateStr = m['state']?.toString() ?? 'N/A';
      bool matchState =
          selectedState == "All" ||
          stateStr.toLowerCase() == selectedState.toLowerCase();

      return matchSearch && matchDept && matchStatus && matchState;
    }).toList();
  }

  void _addManager() {
    if (nameController.text.isEmpty || idController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill required fields (Name & ID)"),
        ),
      );
      return;
    }
    setState(() {
      managers.insert(0, {
        "id": idController.text,
        "name": nameController.text,
        "email": emailController.text,
        "phone": phoneController.text,
        "state": stateController.text,
        "status": "Active",
        "dept": formDept,
      });
      _clearForm();
    });
    Navigator.pop(context); // Close the modal
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Manager profile created successfully!")),
    );
  }

  void _clearForm() {
    nameController.clear();
    idController.clear();
    emailController.clear();
    phoneController.clear();
    stateController.clear();
  }

  void _showAddManagerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 30,
        ),
        child: SingleChildScrollView(
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
                        "Create Manager",
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Fill in the details below",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.grey400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.offWhite,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              _buildInputField(
                "Manager ID*",
                idController,
                Icons.badge_outlined,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                "Full Name*",
                nameController,
                Icons.person_outline_rounded,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      "Email Address",
                      emailController,
                      Icons.email_outlined,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInputField(
                      "Phone Number",
                      phoneController,
                      Icons.phone_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      "State",
                      stateController,
                      Icons.location_on_outlined,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Department",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.grey600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        StatefulBuilder(
                          builder: (context, setModalState) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.offWhite,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.grey100),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: formDept,
                                  isExpanded: true,
                                  style: GoogleFonts.inter(
                                    color: AppColors.navy,
                                    fontSize: 14,
                                  ),
                                  items: formDepartments.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (v) =>
                                      setModalState(() => formDept = v!),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _addManager,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    "Create Profile",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.grey600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: AppColors.grey400),
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Manager Profiles",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddManagerSheet,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text("Add Manager"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildFilters(),
            const SizedBox(height: 20),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredManagers.isEmpty
                  ? Center(
                      child: Text(
                        "No managers found.",
                        style: GoogleFonts.inter(
                          color: AppColors.grey400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: filteredManagers.length,
                      itemBuilder: (context, index) {
                        final manager = filteredManagers[index];
                        return _buildManagerCard(manager);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.grey100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search name, ID or email...",
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.grey400,
                ),
                filled: true,
                isDense: true,
                fillColor: AppColors.offWhite,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    "Dept",
                    selectedDepartment,
                    departments,
                    (v) => setState(() => selectedDepartment = v!),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    "Status",
                    selectedStatus,
                    statusList,
                    (v) => setState(() => selectedStatus = v!),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    "State",
                    selectedState,
                    states,
                    (v) => setState(() => selectedState = v!),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.grey100),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          style: GoogleFonts.inter(
            color: AppColors.navy,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          items: items
              .map((i) => DropdownMenuItem(value: i, child: Text(i)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildManagerCard(Map<String, dynamic> manager) {
    final String firstName = manager['first_name']?.toString() ?? '';
    final String lastName = manager['last_name']?.toString() ?? '';
    final String nameStr = firstName.isNotEmpty
        ? '$firstName $lastName'.trim()
        : (manager['name']?.toString() ?? 'Unknown');
    final String idStr =
        manager['employee_id']?.toString() ??
        manager['id']?.toString() ??
        'N/A';

    String deptName = 'Unknown Dept';
    if (manager['department'] is Map) {
      deptName = manager['department']['name']?.toString() ?? 'Unknown Dept';
    } else if (manager['department_name'] != null) {
      deptName = manager['department_name'].toString();
    } else if (manager['dept'] != null) {
      deptName = manager['dept'].toString();
    }

    final String emailStr = manager['email']?.toString() ?? 'N/A';
    final String phoneStr =
        manager['phone']?.toString() ??
        manager['phone_number']?.toString() ??
        'N/A';
    final String stateStr = manager['state']?.toString() ?? 'N/A';
    final String statusStr = manager['status']?.toString() ?? 'Active';

    final statusColor = _getStatusColor(statusStr);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.navy.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      nameStr.isNotEmpty
                          ? nameStr.substring(0, 1).toUpperCase()
                          : 'M',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            nameStr,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              statusStr,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "$idStr • $deptName",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.grey600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(Icons.email_outlined, emailStr),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.phone_outlined, phoneStr),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.location_on_outlined, stateStr),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.offWhite.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildActionButton(Icons.visibility_outlined, "View", () => _showManagerDetails(manager)),
                const SizedBox(width: 10),
                // _buildActionButton(Icons.edit_outlined, "Edit", () {}),
                // const SizedBox(width: 10),
                // _buildActionButton(
                //   Icons.delete_outline_rounded,
                //   "Delete",
                //   () {},
                //   color: AppColors.error,
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showManagerDetails(Map<String, dynamic> manager) {
    final String firstName = manager['first_name']?.toString() ?? '';
    final String lastName = manager['last_name']?.toString() ?? '';
    final String nameStr = firstName.isNotEmpty ? '$firstName $lastName'.trim() : (manager['name']?.toString() ?? 'Unknown');
    final String idStr = manager['employee_id']?.toString() ?? manager['id']?.toString() ?? 'N/A';
    
    String deptName = 'Unknown Dept';
    if (manager['department'] is Map) {
      deptName = manager['department']['name']?.toString() ?? 'Unknown Dept';
    } else if (manager['department_name'] != null) {
      deptName = manager['department_name'].toString();
    } else if (manager['dept'] != null) {
      deptName = manager['dept'].toString();
    }

    final String statusStr = manager['status']?.toString() ?? 'Active';
    
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Manager Details', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.navy)),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: AppColors.grey400),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.navy.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          nameStr.isNotEmpty ? nameStr[0].toUpperCase() : 'M',
                          style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.navy),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(nameStr, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.navy)),
                  ),
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(statusStr).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusStr,
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: _getStatusColor(statusStr)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(Icons.badge_outlined, 'Employee ID', idStr),
                          const Divider(height: 24, thickness: 1, color: AppColors.offWhite),
                          _buildDetailRow(Icons.work_outline_rounded, 'Department', deptName),
                          const Divider(height: 24, thickness: 1, color: AppColors.offWhite),
                          ...manager.entries.where((e) {
                            final kStr = e.key.toLowerCase();
                            // Exclude already handled or irrelevant fields
                            if (['id', 'employee_id', 'name', 'first_name', 'last_name', 'status', 'created_at', 'updated_at', 'deleted_at', 'department', 'department_name', 'dept', 'user_type', 'role'].contains(kStr)) return false;
                            if (e.value == null || e.value.toString().trim().isEmpty || e.value.toString() == 'null') return false;
                            if (e.value is Map || e.value is List) return false;
                            return true;
                          }).map((e) {
                            String formatLabel(String key) {
                              return key.replaceAll('_', ' ').split(' ').map((word) {
                                if (word.isEmpty) return '';
                                return word[0].toUpperCase() + word.substring(1).toLowerCase();
                              }).join(' ');
                            }
                            String formatValue(dynamic val) {
                              String vStr = val.toString();
                              // Basic date formatting if it looks like an ISO date
                              if (vStr.contains('T') && vStr.length >= 19 && DateTime.tryParse(vStr) != null) {
                                return vStr.split('T').first;
                              }
                              return vStr;
                            }
                            return Column(
                              children: [
                                _buildDetailRow(Icons.info_outline_rounded, formatLabel(e.key), formatValue(e.value)),
                                const Divider(height: 24, thickness: 1, color: AppColors.offWhite),
                              ],
                            );
                          }),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.offWhite,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.navy),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.grey400)),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy)),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.grey400),
        const SizedBox(width: 10),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.grey600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.grey200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: color ?? AppColors.navy),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color ?? AppColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return AppColors.success;
      case 'On Hold':
        return AppColors.warning;
      case 'Terminate':
      case 'Resigned':
        return AppColors.error;
      default:
        return AppColors.grey600;
    }
  }
}
