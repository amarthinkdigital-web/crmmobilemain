import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  String _selectedClient = 'Tech Solutions Ltd.';
  String _selectedStatus = 'Pending';
  final _itemController = TextEditingController();
  final _amountController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _notesController = TextEditingController();

  final List<Map<String, dynamic>> _lineItems = [
    {'desc': 'Web Development — March', 'qty': 1, 'rate': 3500.0},
    {'desc': 'SEO Optimization', 'qty': 1, 'rate': 800.0},
  ];

  double get _subtotal => _lineItems.fold(0, (sum, item) => sum + item['qty'] * item['rate']);
  double get _tax => _subtotal * 0.18;
  double get _total => _subtotal + _tax;

  @override
  void dispose() {
    _itemController.dispose();
    _amountController.dispose();
    _dueDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Create Invoice',
                      style: GoogleFonts.inter(
                          fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.navy, letterSpacing: -0.5)),
                  Text('Generate a new invoice for a client',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.grey400)),
                ],
              ),
              Text('INV-2026-006',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.gold)),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Invoice Details',
            Column(
              children: [
                _formLabel('Client'),
                const SizedBox(height: 8),
                _dropdownField(
                  _selectedClient,
                  ['Tech Solutions Ltd.', 'Global Logistics Co.', 'Creative Minds Agency', 'Innovate Software'],
                  (v) => setState(() => _selectedClient = v!),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _dateField('Issue Date', 'Mar 09, 2026')),
                    const SizedBox(width: 12),
                    Expanded(child: _dateField('Due Date', 'Mar 23, 2026')),
                  ],
                ),
                const SizedBox(height: 14),
                _formLabel('Status'),
                const SizedBox(height: 8),
                _dropdownField(
                  _selectedStatus,
                  ['Pending', 'Paid', 'Overdue'],
                  (v) => setState(() => _selectedStatus = v!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSection(
            'Line Items',
            Column(
              children: [
                ..._lineItems.asMap().entries.map((e) => _buildLineItem(e.key, e.value)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => setState(() {
                    _lineItems.add({'desc': 'New Service', 'qty': 1, 'rate': 0.0});
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.grey200, style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_rounded, size: 18, color: AppColors.gold),
                          const SizedBox(width: 6),
                          Text('Add Line Item',
                              style: GoogleFonts.inter(
                                  fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildTotalsCard(),
          const SizedBox(height: 20),
          _buildSection(
            'Notes',
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Payment terms, bank details, or additional notes...',
                filled: true,
                fillColor: AppColors.offWhite,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.grey200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.grey200),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Save Draft'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navy,
                    side: const BorderSide(color: AppColors.navy),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.send_rounded, size: 18, color: AppColors.navy),
                  label: Text('Send Invoice',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.gold)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _formLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grey400)),
    );
  }

  Widget _dropdownField(String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.navy),
          items: items.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _dateField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grey400)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.offWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.grey200),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.grey400),
              const SizedBox(width: 8),
              Text(value, style: GoogleFonts.inter(fontSize: 13, color: AppColors.navy)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLineItem(int index, Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(item['desc'],
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navy)),
          ),
          const SizedBox(width: 8),
          Text('x${item['qty']}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.grey400)),
          const SizedBox(width: 8),
          Text(r'$' '${item['rate'].toStringAsFixed(0)}',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _lineItems.removeAt(index)),
            child: const Icon(Icons.close_rounded, size: 16, color: AppColors.error),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _totalRow('Subtotal', r'$' '${_subtotal.toStringAsFixed(2)}', false),
          const SizedBox(height: 8),
          _totalRow('GST (18%)', r'$' '${_tax.toStringAsFixed(2)}', false),
          const Divider(color: Colors.white24, height: 20),
          _totalRow('Total', r'$' '${_total.toStringAsFixed(2)}', true),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value, bool bold) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: bold ? 16 : 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                color: AppColors.white.withOpacity(bold ? 1.0 : 0.7))),
        Text(value,
            style: GoogleFonts.inter(
                fontSize: bold ? 18 : 13,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                color: bold ? AppColors.gold : AppColors.white.withOpacity(0.8))),
      ],
    );
  }
}
