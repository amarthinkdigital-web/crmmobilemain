import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../services/api_service.dart';

class EmployeeProfileScreen extends StatefulWidget {
  const EmployeeProfileScreen({super.key});

  @override
  State<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen> {
  String selectedDepartment = "All Departments";
  String selectedStatus = "All";
  String selectedLocation = "All";

  final searchController = TextEditingController();

  // Form Controllers
  final nameController = TextEditingController();
  final idController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final roleController = TextEditingController();
  final locationController = TextEditingController();
  String formDept = "Software Engineering";

  List<Map<String, dynamic>> employees = [];

  final List<String> departments = [
    "All Departments",
    "Software Engineering",
    "Design",
    "Marketing",
    "HR",
    "Security",
  ];

  final List<String> formDepartments = [
    "Software Engineering",
    "Design",
    "Marketing",
    "HR",
    "Security",
  ];

  final List<String> statusList = [
    "All",
    "Active",
    "Terminate",
    "Resigned",
    "On Hold",
  ];
  final List<String> locations = [
    "All",
    "Pune",
    "Mumbai",
    "Bangalore",
    "Delhi",
  ];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      setState(() {});
    });
    _fetchEmployees();
  }

  @override
  void dispose() {
    searchController.dispose();
    nameController.dispose();
    idController.dispose();
    emailController.dispose();
    phoneController.dispose();
    roleController.dispose();
    locationController.dispose();
    super.dispose();
  }

  Future<void> _fetchEmployees() async {
    setState(() => isLoading = true);
    final res = await ApiService.getEmployeeProfiles();
    if (!mounted) return;

    if (res['error'] == false) {
      setState(() {
        employees = List<Map<String, dynamic>>.from(res['data'] ?? []);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Failed to load employee data'),
        ),
      );
    }
  }

  List<Map<String, dynamic>> get filteredEmployees {
    return employees.where((e) {
      final fname = e['first_name']?.toString().toLowerCase() ?? '';
      final lname = e['last_name']?.toString().toLowerCase() ?? '';
      final nameStr =
          e['name']?.toString().toLowerCase() ?? '$fname $lname'.trim();
      final emailStr = e['email']?.toString().toLowerCase() ?? '';
      final idStr =
          e['employee_id']?.toString().toLowerCase() ??
          e['id']?.toString().toLowerCase() ??
          '';
      final roleStr =
          e['role']?.toString().toLowerCase() ??
          e['designation']?.toString().toLowerCase() ??
          '';
      final search = searchController.text.toLowerCase();

      bool matchSearch =
          nameStr.contains(search) ||
          emailStr.contains(search) ||
          idStr.contains(search) ||
          roleStr.contains(search);

      String deptName = 'Unknown';
      if (e['department'] is Map) {
        deptName = e['department']['name']?.toString() ?? 'Unknown';
      } else if (e['department_name'] != null) {
        deptName = e['department_name'].toString();
      } else if (e['dept'] != null) {
        deptName = e['dept'].toString();
      }
      bool matchDept =
          selectedDepartment == "All Departments" ||
          deptName == selectedDepartment;

      String statusStr = e['status']?.toString() ?? 'Active';
      bool matchStatus =
          selectedStatus == "All" ||
          statusStr.toLowerCase() == selectedStatus.toLowerCase();

      String locStr =
          e['location']?.toString() ?? e['state']?.toString() ?? 'N/A';
      bool matchLoc =
          selectedLocation == "All" ||
          locStr.toLowerCase() == selectedLocation.toLowerCase();

      return matchSearch && matchDept && matchStatus && matchLoc;
    }).toList();
  }

  void _addEmployee() {
    if (nameController.text.isEmpty || idController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill required fields (Name & ID)"),
        ),
      );
      return;
    }
    setState(() {
      employees.insert(0, {
        "id": idController.text,
        "name": nameController.text,
        "email": emailController.text,
        "phone": phoneController.text,
        "location": locationController.text,
        "status": "Active",
        "dept": formDept,
        "role": roleController.text,
      });
      _clearForm();
    });
    Navigator.pop(context); // Close modal
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Employee profile created successfully!")),
    );
  }

  void _clearForm() {
    nameController.clear();
    idController.clear();
    emailController.clear();
    phoneController.clear();
    roleController.clear();
    locationController.clear();
  }

  void _showAddEmployeeSheet() {
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
                        "Create Employee",
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Fill in the employee details",
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
                "Employee ID*",
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
                      "Designation / Role",
                      roleController,
                      Icons.work_outline_rounded,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInputField(
                      "Location",
                      locationController,
                      Icons.location_on_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
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
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.offWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.grey100),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: formDept,
                            isExpanded: true,
                            isDense: true,
                            padding: const EdgeInsets.symmetric(vertical: 12),
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
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _addEmployee,
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
                  "Employee Profiles",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddEmployeeSheet,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text("Add Employee"),
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
                  : filteredEmployees.isEmpty
                  ? Center(
                      child: Text(
                        "No employees found.",
                        style: GoogleFonts.inter(
                          color: AppColors.grey400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: filteredEmployees.length,
                      itemBuilder: (context, index) {
                        final employee = filteredEmployees[index];
                        return _buildEmployeeCard(employee);
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
                hintText: "Search name, ID, role or email...",
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
                    "Loc",
                    selectedLocation,
                    locations,
                    (v) => setState(() => selectedLocation = v!),
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
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.grey100),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          padding: const EdgeInsets.symmetric(vertical: 10),
          style: GoogleFonts.inter(
            color: AppColors.navy,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          items: items
              .map((i) => DropdownMenuItem(value: i, child: Text(i)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> employee) {
    final String firstName = employee['first_name']?.toString() ?? '';
    final String lastName = employee['last_name']?.toString() ?? '';
    final String nameStr = firstName.isNotEmpty
        ? '$firstName $lastName'.trim()
        : (employee['name']?.toString() ?? 'Unknown');

    String deptName = 'Unknown Dept';
    if (employee['department'] is Map) {
      deptName = employee['department']['name']?.toString() ?? 'Unknown Dept';
    } else if (employee['department_name'] != null) {
      deptName = employee['department_name'].toString();
    } else if (employee['dept'] != null) {
      deptName = employee['dept'].toString();
    }

    final String emailStr = employee['email']?.toString() ?? 'N/A';
    final String phoneStr =
        employee['phone']?.toString() ??
        employee['phone_number']?.toString() ??
        'N/A';
    final String locationStr =
        employee['location']?.toString() ??
        employee['state']?.toString() ??
        'N/A';
    final String roleStr =
        employee['role']?.toString() ??
        employee['designation']?.toString() ??
        'Employee';
    final String statusStr = employee['status']?.toString() ?? 'Active';

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
                    color: AppColors.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      nameStr.isNotEmpty
                          ? nameStr.substring(0, 1).toUpperCase()
                          : 'E',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.goldDark,
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
                        "$roleStr • $deptName",
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
                _buildInfoRow(Icons.location_on_outlined, locationStr),
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
            // child: Row(
            //   mainAxisAlignment: MainAxisAlignment.end,
            //   children: [
            //     _buildActionButton(Icons.visibility_outlined, "View", () {}),
            //     const SizedBox(width: 10),
            //     _buildActionButton(Icons.edit_outlined, "Edit", () {}),
            //     const SizedBox(width: 10),
            //     _buildActionButton(
            //       Icons.delete_outline_rounded,
            //       "Delete",
            //       () {},
            //       color: AppColors.error,
            //     ),
            //   ],
            // ),
          ),
        ],
      ),
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
