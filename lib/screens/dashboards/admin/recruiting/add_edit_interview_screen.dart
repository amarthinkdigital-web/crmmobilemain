import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// If using file_picker, import it here (requires file_picker in pubspec)
// import 'package:file_picker/file_picker.dart';
import '../../../../theme/app_theme.dart';
import '../../../../services/recruiting_api_service.dart';
import '../../../../models/interview_model.dart';

class AddEditInterviewScreen extends StatefulWidget {
  final Interview? interview;
  const AddEditInterviewScreen({super.key, this.interview});

  @override
  State<AddEditInterviewScreen> createState() => _AddEditInterviewScreenState();
}

class _AddEditInterviewScreenState extends State<AddEditInterviewScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  String _applyFor = 'Job';
  String _mode = 'online';
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeFromController = TextEditingController();
  final _timeToController = TextEditingController();
  final _linkController = TextEditingController();
  final _descController = TextEditingController();

  List<String> _selectedFiles = [];

  @override
  void initState() {
    super.initState();
    if (widget.interview != null) {
      final i = widget.interview!;
      _applyFor = i.applyFor.isNotEmpty ? i.applyFor : 'Job';
      _mode = i.interviewMode.isNotEmpty ? i.interviewMode : 'online';
      _nameController.text = i.name;
      _emailController.text = i.email;
      _phoneController.text = i.phone;
      _cityController.text = i.city;
      _dateController.text = i.interviewDate;
      _timeFromController.text = i.interviewTimeFrom;
      _timeToController.text = i.interviewTimeTo;
      _linkController.text = i.meetingLink ?? '';
      _descController.text = i.taskDescription ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _dateController.dispose();
    _timeFromController.dispose();
    _timeToController.dispose();
    _linkController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    // Requires file_picker package. Mocking for now as we don't have pubspec control.
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File picker requires file_picker plugin in pubspec.yaml')));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final data = {
      'apply_for': _applyFor,
      'name': _nameController.text,
      'email': _emailController.text,
      'phone': _phoneController.text,
      'city': _cityController.text,
      'interview_date': _dateController.text,
      'interview_mode': _mode,
      'meeting_link': _mode == 'online' ? _linkController.text : '',
      'interview_time_from': _timeFromController.text,
      'interview_time_to': _timeToController.text,
      'task_description': _descController.text,
      'send_confirmation_mail': 1, // Optional default
    };

    Map<String, dynamic> response;
    if (widget.interview == null) {
      response = await RecruitingApiService.createInterview(data, _selectedFiles);
    } else {
      response = await RecruitingApiService.updateInterview(widget.interview!.id, data, _selectedFiles);
    }

    setState(() => _isLoading = false);

    if (response['error'] == false) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved successfully!')));
        Navigator.pop(context);
      }
    } else {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'])));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: Text(widget.interview == null ? 'Add Interview' : 'Edit Interview'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.navy))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.grey100),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Candidate Info", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_nameController, "Full Name", Icons.person)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField(_emailController, "Email Address", Icons.email)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_phoneController, "Phone Number", Icons.phone)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField(_cityController, "City", Icons.location_city)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text("Interview Details", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _applyFor,
                              decoration: const InputDecoration(labelText: 'Apply For'),
                              items: const [
                                DropdownMenuItem(value: 'Job', child: Text('Job')),
                                DropdownMenuItem(value: 'Intern', child: Text('Intern')),
                              ],
                              onChanged: (v) => setState(() => _applyFor = v!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _mode,
                              decoration: const InputDecoration(labelText: 'Mode'),
                              items: const [
                                DropdownMenuItem(value: 'online', child: Text('Online')),
                                DropdownMenuItem(value: 'offline', child: Text('Offline')),
                              ],
                              onChanged: (v) => setState(() => _mode = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_mode == 'online') ...[
                        _buildTextField(_linkController, "Meeting Link (e.g., Google Meet)", Icons.link),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_dateController, "Date (YYYY-MM-DD)", Icons.calendar_today)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField(_timeFromController, "From Time (HH:MM)", Icons.access_time)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField(_timeToController, "To Time (HH:MM)", Icons.access_time)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text("Task / Notes", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descController,
                        maxLines: 4,
                        decoration: const InputDecoration(labelText: 'Task Description / Internal Notes'),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Attach Task Files'),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.navy,
                            foregroundColor: AppColors.white,
                          ),
                          child: const Text('Save Interview'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.grey400),
      ),
      validator: (value) => value!.isEmpty ? 'Required field' : null,
    );
  }
}
