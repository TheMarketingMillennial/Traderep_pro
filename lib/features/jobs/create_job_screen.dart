import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/services/app_state.dart';
import '../../shared/widgets/tr_widgets.dart';
import '../../shared/models/models.dart';

class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({super.key});

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _jobTypeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _selectedTemplate;
  DateTime? _startDate;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();

    return Scaffold(
      backgroundColor: TRColors.navyDeep,
      appBar: AppBar(
        backgroundColor: TRColors.navyDeep,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: TRColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Create New Job', style: TextStyle(
          color: TRColors.white, fontSize: 18, fontWeight: FontWeight.w700,
        )),
        actions: [
          TextButton(
            onPressed: () => _saveJob(context, state),
            child: const Text('Save', style: TextStyle(
              color: TRColors.gold, fontSize: 16, fontWeight: FontWeight.w700,
            )),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('Customer Information', [
              _TRFormField(controller: _nameCtrl, label: 'Customer Name *', icon: Icons.person_rounded, hint: 'First & Last Name'),
              const SizedBox(height: 14),
              _TRFormField(controller: _addressCtrl, label: 'Job Address *', icon: Icons.location_on_rounded, hint: '123 Main St, City, State'),
              const SizedBox(height: 14),
              _TRFormField(controller: _phoneCtrl, label: 'Phone Number', icon: Icons.phone_rounded, hint: '(555) 000-0000', keyboardType: TextInputType.phone),
              const SizedBox(height: 14),
              _TRFormField(controller: _emailCtrl, label: 'Email Address', icon: Icons.email_rounded, hint: 'customer@email.com', keyboardType: TextInputType.emailAddress),
            ]),
            const SizedBox(height: 24),
            _buildSection('Job Details', [
              _TRFormField(controller: _jobTypeCtrl, label: 'Job Type *', icon: Icons.work_rounded, hint: 'e.g. Full Roof Replacement'),
              const SizedBox(height: 14),
              _buildTemplatePicker(state),
              const SizedBox(height: 14),
              _buildDatePicker(context),
            ]),
            const SizedBox(height: 24),
            _buildSection('Notes', [
              TextField(
                controller: _notesCtrl,
                maxLines: 4,
                style: const TextStyle(color: TRColors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Internal notes about the job, special instructions...',
                  filled: true,
                  fillColor: TRColors.cardMid,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TRColors.divider)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TRColors.divider)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TRColors.gold, width: 1.5)),
                  hintStyle: const TextStyle(color: TRColors.grayMid),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ]),
            const SizedBox(height: 32),
            GoldButton(
              label: 'Create Job File',
              icon: Icons.add_circle_rounded,
              onTap: () => _saveJob(context, state),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(
          color: TRColors.gold, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8,
        )),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TRColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: TRColors.divider),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      ],
    );
  }

  Widget _buildTemplatePicker(AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Photo Template', style: TextStyle(
          color: TRColors.grayLight, fontSize: 13, fontWeight: FontWeight.w600,
        )),
        const SizedBox(height: 8),
        SizedBox(
          height: 56,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: state.templates.length,
            itemBuilder: (_, i) {
              final tmpl = state.templates[i];
              final isSelected = _selectedTemplate == tmpl.id;
              return GestureDetector(
                onTap: () => setState(() => _selectedTemplate = tmpl.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? TRColors.goldDim : TRColors.cardMid,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? TRColors.gold : TRColors.divider,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(tmpl.emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(tmpl.name, style: TextStyle(
                        color: isSelected ? TRColors.gold : TRColors.white,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      )),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 730)),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: TRColors.gold,
                onPrimary: TRColors.navyDeep,
                surface: TRColors.cardDark,
              ),
            ),
            child: child!,
          ),
        );
        if (date != null) setState(() => _startDate = date);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: TRColors.cardMid,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _startDate != null ? TRColors.gold : TRColors.divider,
            width: _startDate != null ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month_rounded,
              color: _startDate != null ? TRColors.gold : TRColors.grayMid, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(
              _startDate != null
                ? 'Start: ${_formatDate(_startDate!)}'
                : 'Select Start Date (optional)',
              style: TextStyle(
                color: _startDate != null ? TRColors.white : TRColors.grayMid,
                fontSize: 14,
              ),
            )),
            if (_startDate != null)
              GestureDetector(
                onTap: () => setState(() => _startDate = null),
                child: const Icon(Icons.close_rounded, color: TRColors.grayMid, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  void _saveJob(BuildContext context, AppState state) {
    if (_nameCtrl.text.isEmpty || _addressCtrl.text.isEmpty || _jobTypeCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in required fields'), backgroundColor: TRColors.error),
      );
      return;
    }

    final job = Job(
      id: 'job_${DateTime.now().millisecondsSinceEpoch}',
      companyId: 'co_001',
      customerName: _nameCtrl.text,
      address: _addressCtrl.text,
      phone: _phoneCtrl.text.isEmpty ? 'N/A' : _phoneCtrl.text,
      email: _emailCtrl.text.isEmpty ? 'N/A' : _emailCtrl.text,
      jobType: _jobTypeCtrl.text,
      templateId: _selectedTemplate ?? 'tmpl_roofing',
      status: JobStatus.lead,
      startDate: _startDate,
      notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
      createdAt: DateTime.now(),
    );

    state.addJob(job);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Job created successfully!'),
        backgroundColor: TRColors.success,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _TRFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String hint;
  final TextInputType? keyboardType;

  const _TRFormField({
    required this.controller, required this.label,
    required this.icon, required this.hint, this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(
          color: TRColors.grayLight, fontSize: 13, fontWeight: FontWeight.w600,
        )),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: TRColors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18),
            filled: true,
            fillColor: TRColors.cardMid,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: TRColors.divider)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: TRColors.divider)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: TRColors.gold, width: 1.5)),
          ),
        ),
      ],
    );
  }
}
