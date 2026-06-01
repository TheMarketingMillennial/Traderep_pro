import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/services/app_state.dart';
import '../../shared/models/models.dart';

class EditJobScreen extends StatefulWidget {
  final Job job;
  const EditJobScreen({super.key, required this.job});

  @override
  State<EditJobScreen> createState() => _EditJobScreenState();
}

class _EditJobScreenState extends State<EditJobScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final TextEditingController _customerNameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _jobTypeCtrl;
  late final TextEditingController _notesCtrl;

  DateTime? _startDate;

  @override
  void initState() {
    super.initState();
    final j = widget.job;
    _customerNameCtrl = TextEditingController(text: j.customerName);
    _addressCtrl      = TextEditingController(text: j.address);
    _phoneCtrl        = TextEditingController(text: j.phone);
    _emailCtrl        = TextEditingController(text: j.email);
    _jobTypeCtrl      = TextEditingController(text: j.jobType);
    _notesCtrl        = TextEditingController(text: j.notes ?? '');
    _startDate        = j.startDate;
  }

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _jobTypeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ─── Save ──────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final j = widget.job;
    final updated = Job(
      id:              j.id,
      companyId:       j.companyId,
      customerName:    _customerNameCtrl.text.trim(),
      address:         _addressCtrl.text.trim(),
      phone:           _phoneCtrl.text.trim(),
      email:           _emailCtrl.text.trim(),
      jobType:         _jobTypeCtrl.text.trim(),
      templateId:      j.templateId,
      status:          j.status,
      crewLeadId:      j.crewLeadId,
      crewMemberIds:   j.crewMemberIds,
      startDate:       _startDate,
      completionDate:  j.completionDate,
      notes:           _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      photos:          j.photos,
      reviewSent:      j.reviewSent,
      createdAt:       j.createdAt,
    );

    // ignore: use_build_context_synchronously
    context.read<AppState>().updateJob(updated);

    if (mounted) {
      Navigator.pop(context, updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job details updated'),
          backgroundColor: TRColors.gold,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ─── Date picker ───────────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary:   TRColors.gold,
            onPrimary: TRColors.navyDeep,
            surface:   TRColors.cardDark,
            onSurface: TRColors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TRColors.navyDeep,
      appBar: AppBar(
        backgroundColor: TRColors.navyDeep,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: TRColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Job Details',
          style: TextStyle(color: TRColors.white, fontWeight: FontWeight.w700, fontSize: 16),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _saving
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(color: TRColors.gold, strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: _save,
                    child: const Text(
                      'Save',
                      style: TextStyle(color: TRColors.gold, fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            _SectionHeader(label: 'Customer'),
            const SizedBox(height: 12),
            _Field(
              label: 'Customer Name',
              controller: _customerNameCtrl,
              icon: Icons.person_rounded,
              hint: 'Full name or company',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            _Field(
              label: 'Phone',
              controller: _phoneCtrl,
              icon: Icons.phone_rounded,
              hint: '(555) 000-0000',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            _Field(
              label: 'Email',
              controller: _emailCtrl,
              icon: Icons.email_rounded,
              hint: 'customer@email.com',
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null; // optional
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),

            const SizedBox(height: 24),
            _SectionHeader(label: 'Job Info'),
            const SizedBox(height: 12),

            _Field(
              label: 'Job Type',
              controller: _jobTypeCtrl,
              icon: Icons.construction_rounded,
              hint: 'e.g. Full Roof Replacement',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            _Field(
              label: 'Address',
              controller: _addressCtrl,
              icon: Icons.location_on_rounded,
              hint: '123 Main St, City, State',
              maxLines: 2,
            ),

            const SizedBox(height: 14),
            // ── Start Date picker ──
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: TRColors.navyMid,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TRColors.divider),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: TRColors.grayMid, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Start Date',
                            style: TextStyle(color: TRColors.grayMid, fontSize: 11, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 3),
                          Text(
                            _startDate != null ? _formatDate(_startDate!) : 'Tap to set a date',
                            style: TextStyle(
                              color: _startDate != null ? TRColors.white : TRColors.grayMid,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                      color: _startDate != null ? TRColors.gold : TRColors.grayMid, size: 20),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            _SectionHeader(label: 'Notes'),
            const SizedBox(height: 12),

            _Field(
              label: 'Internal Notes',
              controller: _notesCtrl,
              icon: Icons.notes_rounded,
              hint: 'Special instructions, access codes, crew reminders…',
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

// ─── Section header ───────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(label.toUpperCase(),
        style: const TextStyle(
          color: TRColors.gold, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
      const SizedBox(width: 10),
      const Expanded(child: Divider(color: TRColors.divider)),
    ]);
  }
}

// ─── Text field ───────────────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final TextInputType keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  const _Field({
    required this.label,
    required this.controller,
    required this.icon,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: TRColors.white, fontSize: 15, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: TRColors.grayMid, size: 18),
        labelStyle: const TextStyle(color: TRColors.grayMid, fontSize: 12),
        hintStyle: const TextStyle(color: TRColors.grayDark, fontSize: 14),
        filled: true,
        fillColor: TRColors.navyMid,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: TRColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: TRColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: TRColors.gold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: TRColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: TRColors.error, width: 1.5),
        ),
      ),
    );
  }
}
