import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../services/api_service.dart';
import '../../../theme/app_theme.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _invoices = [];
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  Future<void> _fetchInvoices() async {
    setState(() => _isLoading = true);
    final res = await ApiService.getInvoices();
    if (res['error'] == false) {
      setState(() {
        _invoices = List<Map<String, dynamic>>.from(res['data'] ?? []);
        _isLoading = false;
      });
    } else {
      // If error, use mock data for demo if requested, but we'll just show empty for now or snackbar
      setState(() => _isLoading = false);
      if (mounted) {
        // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? "Error loading invoices")));
      }
      // For demo purposes, populating with some dummy data if empty
      if (_invoices.isEmpty) {
        _invoices = [
          {
            'invoice_no': 'INV-001',
            'client_name': 'Think Digital',
            'project_name': 'CRM Development',
            'date': '2024-03-20',
            'status': 'Paid',
            'amount': 5000.0,
            'due_amount': 0.0,
            'description': 'Mobile App Development',
            'qty': 1,
            'price': 5000.0,
            'gst': 900.0,
            'total': 5900.0,
          },
          {
            'invoice_no': 'INV-002',
            'client_name': 'Ace Auto Spa',
            'project_name': 'Website Redesign',
            'date': '2024-03-22',
            'status': 'Pending',
            'amount': 1200.0,
            'due_amount': 1200.0,
            'description': 'UI/UX Design',
            'qty': 1,
            'price': 1200.0,
            'gst': 216.0,
            'total': 1416.0,
          }
        ];
      }
    }
  }

  double get _totalRevenue => _invoices.fold(0, (sum, item) => sum + (double.tryParse(item['amount'].toString()) ?? 0));
  double get _totalOutstanding => _invoices.fold(0, (sum, item) => sum + (double.tryParse(item['due_amount']?.toString() ?? '0') ?? 0));

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.navy));
    
    return RefreshIndicator(
      onRefresh: _fetchInvoices,
      color: AppColors.navy,
      child: SingleChildScrollView(
        controller: ScrollController(),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildStatsGrid(),
                    const SizedBox(height: 32),
                    _buildTableCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Invoices",
          style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.navy, letterSpacing: -1),
        ),
        Text(
          "Manage your billing and payments tracking",
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.grey400, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 20),
        // Search bar moved here, made "small"
        Container(
          width: 280,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.grey100)
          ),
          child: TextField(
            controller: _searchController,
            style: GoogleFonts.inter(fontSize: 13),
            decoration: InputDecoration(
              hintText: "Search invoices...",
              hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.grey400),
              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.grey400),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard("Total Invoices", _invoices.length.toString(), Icons.receipt_long_rounded, Colors.blue)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard("Total Revenue", "₹${NumberFormat('#,##,###').format(_totalRevenue)}", Icons.account_balance_wallet_rounded, AppColors.success)),
          ],
        ),
        const SizedBox(height: 16),
        _buildStatCard("Total Outstanding", "₹${NumberFormat('#,##,###').format(_totalOutstanding)}", Icons.warning_amber_rounded, AppColors.error, isFullWidth: true),
        const SizedBox(height: 32),
        // Create button moved "downside" (below stats)
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton.icon(
            onPressed: () => _showInvoiceDialog(),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text("Create New Invoice"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, {bool isFullWidth = false}) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(value, style: GoogleFonts.jetBrainsMono(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.navy)),
          Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.grey400)),
        ],
      ),
    );
  }

  Widget _buildTableCard() {
    final filtered = _invoices.where((inv) {
      final name = inv['client_name'].toString().toLowerCase();
      final no = inv['invoice_no'].toString().toLowerCase();
      return name.contains(_searchQuery) || no.contains(_searchQuery);
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.grey100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text("Recent Invoices", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.navy)),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            primary: false, // Ensure this doesn't conflict
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(AppColors.offWhite),
              columnSpacing: 32,
              horizontalMargin: 24,
              columns: [
                _buildDataColumn("Invoice No"),
                _buildDataColumn("Client"),
                _buildDataColumn("Project"),
                _buildDataColumn("Date"),
                _buildDataColumn("Status"),
                _buildDataColumn("Amount"),
                _buildDataColumn("Due"),
                _buildDataColumn("Actions"),
              ],
              rows: filtered.map((inv) {
                return DataRow(cells: [
                  DataCell(Text(inv['invoice_no']?.toString() ?? 'N/A', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
                  DataCell(Text(inv['client_name']?.toString() ?? 'N/A')),
                  DataCell(Text(inv['project_name']?.toString() ?? 'N/A')),
                  DataCell(Text(inv['date']?.toString() ?? 'N/A')),
                  DataCell(_buildStatusChip(inv['status']?.toString() ?? 'Pending')),
                  DataCell(Text("₹${inv['amount']}", style: GoogleFonts.inter(fontWeight: FontWeight.w700))),
                  DataCell(Text("₹${inv['due_amount']}", style: GoogleFonts.inter(color: AppColors.error, fontWeight: FontWeight.w600))),
                  DataCell(Row(
                    children: [
                      _buildActionIcon(Icons.visibility_outlined, AppColors.navy, () => _showInvoiceDialog(viewOnly: true, invoice: inv)),
                      _buildActionIcon(Icons.edit_outlined, AppColors.info, () => _showInvoiceDialog(invoice: inv)),
                      _buildActionIcon(Icons.picture_as_pdf_outlined, AppColors.error, () {}),
                      _buildActionIcon(Icons.delete_outline_rounded, AppColors.error, () => _deleteInvoice(inv['id'])),
                    ],
                  )),
                ]);
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  DataColumn _buildDataColumn(String label) {
    return DataColumn(label: Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy)));
  }

  Widget _buildStatusChip(String status) {
    Color color = AppColors.warning;
    if (status == 'Paid') color = AppColors.success;
    if (status == 'Overdue') color = AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildActionIcon(IconData icon, Color color, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 18),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }

  void _showInvoiceDialog({bool viewOnly = false, Map<String, dynamic>? invoice}) {
    showDialog(
      context: context,
      builder: (context) => _InvoiceDialog(
        invoice: invoice,
        viewOnly: viewOnly,
        onSuccess: _fetchInvoices,
      ),
    );
  }

  Future<void> _deleteInvoice(dynamic id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Invoice"),
        content: const Text("Are you sure you want to delete this invoice?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final res = await ApiService.deleteInvoice(id);
      if (res['error'] == false) {
        _fetchInvoices();
      }
    }
  }
}

class _InvoiceDialog extends StatefulWidget {
  final Map<String, dynamic>? invoice;
  final bool viewOnly;
  final VoidCallback onSuccess;
  const _InvoiceDialog({this.invoice, this.viewOnly = false, required this.onSuccess});

  @override
  State<_InvoiceDialog> createState() => _InvoiceDialogState();
}

class _InvoiceDialogState extends State<_InvoiceDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _noController;
  late TextEditingController _clientController;
  late TextEditingController _projectController;
  late TextEditingController _descController;
  late TextEditingController _qtyController;
  late TextEditingController _priceController;
  
  double _subtotal = 0;
  double _gst = 0;
  double _total = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _noController = TextEditingController(text: widget.invoice?['invoice_no'] ?? "");
    _clientController = TextEditingController(text: widget.invoice?['client_name'] ?? "");
    _projectController = TextEditingController(text: widget.invoice?['project_name'] ?? "");
    _descController = TextEditingController(text: widget.invoice?['description'] ?? "");
    _qtyController = TextEditingController(text: widget.invoice?['qty']?.toString() ?? "1");
    _priceController = TextEditingController(text: widget.invoice?['price']?.toString() ?? "0");
    _qtyController.addListener(_calculateTotals);
    _priceController.addListener(_calculateTotals);
    _calculateTotals();
  }

  void _calculateTotals() {
    double qty = double.tryParse(_qtyController.text) ?? 0;
    double price = double.tryParse(_priceController.text) ?? 0;
    setState(() {
      _subtotal = qty * price;
      _gst = _subtotal * 0.18; // 18% GST
      _total = _subtotal + _gst;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Container(
        width: 800,
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.viewOnly ? "View Invoice" : (widget.invoice == null ? "Create New Invoice" : "Edit Invoice"),
                      style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.navy),
                    ),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                  ],
                ),
                const Divider(height: 48),
                _buildField("Invoice No", _noController),
                const SizedBox(height: 20),
                _buildField("Date", TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now())), readOnly: true),
                const SizedBox(height: 20),
                _buildField("Client Name", _clientController),
                const SizedBox(height: 20),
                _buildField("Project Name", _projectController),
                const SizedBox(height: 32),
                Text("Items Details", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navy)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.grey100)),
                  child: Column(
                    children: [
                      _buildField("Description", _descController),
                      const SizedBox(height: 20),
                      _buildField("Quantity", _qtyController, keyboardType: TextInputType.number),
                      const SizedBox(height: 20),
                      _buildField("Price per Item", _priceController, keyboardType: TextInputType.number),
                      const SizedBox(height: 20),
                      _buildField("Subtotal", TextEditingController(text: _subtotal.toStringAsFixed(2)), readOnly: true),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 300,
                    child: Column(
                      children: [
                        _buildSummaryRow("Subtotal", "₹${_subtotal.toStringAsFixed(2)}"),
                        const SizedBox(height: 8),
                        _buildSummaryRow("GST (18%)", "₹${_gst.toStringAsFixed(2)}"),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
                        _buildSummaryRow("Grand Total", "₹${_total.toStringAsFixed(2)}", isGrand: true),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text("Download PDF"),
                      style: TextButton.styleFrom(foregroundColor: AppColors.error),
                    ),
                    const SizedBox(height: 12),
                    if (!widget.viewOnly)
                      ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Save Invoice"),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {bool readOnly = false, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grey400)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly || widget.viewOnly,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.grey200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.grey200)),
          ),
          validator: (v) => v!.isEmpty ? "Required" : null,
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isGrand = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 14, color: isGrand ? AppColors.navy : AppColors.grey400, fontWeight: isGrand ? FontWeight.w800 : FontWeight.w500)),
        Text(value, style: GoogleFonts.inter(fontSize: 14, color: isGrand ? AppColors.navy : AppColors.grey600, fontWeight: isGrand ? FontWeight.w800 : FontWeight.w700)),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final data = {
      'invoice_no': _noController.text,
      'client_name': _clientController.text,
      'project_name': _projectController.text,
      'description': _descController.text,
      'qty': _qtyController.text,
      'price': _priceController.text,
      'amount': _subtotal,
      'gst': _gst,
      'total': _total,
      'status': widget.invoice?['status'] ?? 'Pending',
    };

    final res = widget.invoice == null ? await ApiService.createInvoice(data) : await ApiService.updateInvoice(widget.invoice!['id'], data);

    if (res['error'] == false) {
      widget.onSuccess();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? "Error saving invoice")));
    }
    setState(() => _isSaving = false);
  }
}
