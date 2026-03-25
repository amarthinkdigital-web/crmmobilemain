import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class WhatsappSettingsScreen extends StatefulWidget {
  const WhatsappSettingsScreen({super.key});

  @override
  State<WhatsappSettingsScreen> createState() => _WhatsappSettingsScreenState();
}

class _WhatsappSettingsScreenState extends State<WhatsappSettingsScreen> {
  bool _isConnected = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildConnectionStatus(),
          const SizedBox(height: 24),
          _buildCategoryHeader('API Configuration'),
          const SizedBox(height: 12),
          _buildApiConfigCard(),
          const SizedBox(height: 24),
          _buildCategoryHeader('Automated Templates'),
          const SizedBox(height: 12),
          _buildTemplateList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WhatsApp API',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Manage automated messaging and notifications',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.grey400),
            ),
          ],
        ),
        const Icon(Icons.message_rounded, color: Color(0xFF25D366), size: 28),
      ],
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isConnected ? const Color(0xFF25D366).withOpacity(0.1) : AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _isConnected ? const Color(0xFF25D366).withOpacity(0.2) : AppColors.error.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            _isConnected ? Icons.check_circle_rounded : Icons.error_rounded,
            color: _isConnected ? const Color(0xFF25D366) : AppColors.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isConnected ? 'API Instance Connected' : 'Connection Lost',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _isConnected ? const Color(0xFF075E54) : AppColors.error,
                  ),
                ),
                Text(
                  _isConnected ? 'Instance ID: WH-9842-XP3' : 'Unable to reach WhatsApp Gateway',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: _isConnected ? const Color(0xFF075E54).withOpacity(0.7) : AppColors.error.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          if (!_isConnected)
            ElevatedButton(
              onPressed: () => setState(() => _isConnected = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Reconnect'),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.gold,
      ),
    );
  }

  Widget _buildApiConfigCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Column(
        children: [
          _buildReadOnlyField('API Token', '•••••••••••••••••••••••••••••'),
          const SizedBox(height: 16),
          _buildReadOnlyField('Webhook URL', 'https://api.thinkdigital.com/wa-hooks'),
          const SizedBox(height: 16),
          _buildToggleItem('Enable Auto-Responder', true),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grey400)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.offWhite,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value,
            style: GoogleFonts.jetBrainsMono(fontSize: 12, color: AppColors.navy),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleItem(String label, bool value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navy)),
        Switch(value: value, onChanged: (v) {}, activeColor: AppColors.gold),
      ],
    );
  }

  Widget _buildTemplateList() {
    final templates = [
      {'name': 'Welcome Message', 'type': 'Onboarding'},
      {'name': 'Invoice Reminder', 'type': 'Billing'},
      {'name': 'Work Log Alert', 'type': 'Operations'},
    ];

    return Column(
      children: templates.map((t) => _buildTemplateTile(t)).toList(),
    );
  }

  Widget _buildTemplateTile(Map<String, String> t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, color: AppColors.grey400, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t['name']!, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy)),
                Text(t['type']!, style: GoogleFonts.inter(fontSize: 11, color: AppColors.grey400)),
              ],
            ),
          ),
          const Icon(Icons.edit_note_rounded, color: AppColors.gold, size: 20),
        ],
      ),
    );
  }
}
