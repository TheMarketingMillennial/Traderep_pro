// ─────────────────────────────────────────────────────────────────────────────
// SMS WIDGETS — TradeRep Pro
// SendSmsSheet, SmsHistoryScreen, SmsLogTile
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/sms_models.dart';
import '../../shared/services/app_state.dart';
import '../../shared/services/sms_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SEND SMS BOTTOM SHEET
// Shows phone validation, template picker, message preview, and send button.
// Caller passes the list of templates to display (review or status templates).
// ─────────────────────────────────────────────────────────────────────────────
class SendSmsSheet extends StatefulWidget {
  final String jobId;
  final String customerName;
  final String customerPhone;
  final String jobType;
  final String companyName;
  final String? reviewLink;       // company-specific Google review URL
  final List<SmsTemplate> templates;
  final String title;

  const SendSmsSheet({
    super.key,
    required this.jobId,
    required this.customerName,
    required this.customerPhone,
    required this.jobType,
    required this.companyName,
    this.reviewLink,
    required this.templates,
    required this.title,
  });

  @override
  State<SendSmsSheet> createState() => _SendSmsSheetState();
}

class _SendSmsSheetState extends State<SendSmsSheet> {
  late final TextEditingController _phoneCtrl;
  late SmsTemplate _selectedTemplate;
  String? _phoneError;
  bool _sending = false;
  // Server mode — resolved once on open; refreshed before send
  bool _serverMockMode = true;   // true until health check says otherwise
  bool _healthChecked = false;

  // Crew-editable variable values: key → current value
  final Map<String, String> _variableValues = {};
  // Controllers for each variable's freeform text field
  final Map<String, TextEditingController> _varControllers = {};

  @override
  void initState() {
    super.initState();
    _phoneCtrl = TextEditingController(text: widget.customerPhone);
    _selectedTemplate = widget.templates.first;
    _initVariableControllers();
    // Check server mode immediately so the badge is accurate before send
    _checkServerMode();
  }

  Future<void> _checkServerMode() async {
    final status = await SmsService.instance.checkHealth();
    if (mounted) {
      setState(() {
        _serverMockMode = status.mockMode;
        _healthChecked = true;
      });
    }
  }

  void _initVariableControllers() {
    // Dispose old controllers
    for (final c in _varControllers.values) {
      c.dispose();
    }
    _varControllers.clear();
    _variableValues.clear();
    // Create a controller + default empty value for each variable
    for (final v in _selectedTemplate.variables) {
      _variableValues[v.key] = '';
      final ctrl = TextEditingController();
      ctrl.addListener(() {
        setState(() => _variableValues[v.key] = ctrl.text);
      });
      _varControllers[v.key] = ctrl;
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    for (final c in _varControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // Resolves {{placeholders}} with crew-entered values
  String _resolveBody(String raw) {
    var result = raw;
    for (final entry in _variableValues.entries) {
      final value = entry.value.trim().isEmpty ? entry.key : entry.value.trim();
      result = result.replaceAll(entry.key, value);
    }
    return result;
  }

  String get _messagePreview => _resolveBody(
    _selectedTemplate.buildBody(
      customerName: widget.customerName,
      jobType: widget.jobType,
      companyName: widget.companyName,
      reviewLink: widget.reviewLink,
    ),
  );

  // Returns true if all required variables have a value
  bool get _variablesFilled =>
    _selectedTemplate.variables.every((v) => _variableValues[v.key]?.isNotEmpty == true);

  void _validatePhone(String value) {
    setState(() {
      _phoneError = PhoneValidator.validate(value);
    });
  }

  Future<void> _send() async {
    _validatePhone(_phoneCtrl.text);
    if (_phoneError != null) {
      // Phone number is invalid — the red error text shows under the field,
      // but also show a snackbar so it's impossible to miss.
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please enter a valid phone number: $_phoneError'),
        backgroundColor: TRColors.error,
        duration: const Duration(seconds: 4),
      ));
      return;
    }

    // Block send if crew hasn't filled required variable fields
    if (!_variablesFilled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please fill in all required fields before sending.'),
        backgroundColor: TRColors.warning,
        duration: Duration(seconds: 3),
      ));
      return;
    }

    setState(() => _sending = true);

    final state = context.read<AppState>();
    SmsResult result;

    // Build a resolved template that substitutes crew variables into the body
    final resolvedTemplate = _selectedTemplate.variables.isEmpty
        ? _selectedTemplate
        : SmsTemplate(
            key: _selectedTemplate.key,
            label: _selectedTemplate.label,
            description: _selectedTemplate.description,
            type: _selectedTemplate.type,
            buildBody: ({required customerName, required jobType,
                required companyName, reviewLink}) =>
              _resolveBody(_selectedTemplate.buildBody(
                customerName: customerName,
                jobType: jobType,
                companyName: companyName,
                reviewLink: reviewLink,
              )),
          );

    if (_selectedTemplate.type == SmsType.reviewRequest) {
      result = await state.sendReviewSms(
        jobId: widget.jobId,
        customerName: widget.customerName,
        toPhone: _phoneCtrl.text,
        jobType: widget.jobType,
        companyName: widget.companyName,
        reviewLink: widget.reviewLink,
      );
    } else {
      result = await state.sendStatusSms(
        jobId: widget.jobId,
        customerName: widget.customerName,
        toPhone: _phoneCtrl.text,
        jobType: widget.jobType,
        companyName: widget.companyName,
        template: resolvedTemplate,
      );
    }

    if (!mounted) return;
    setState(() => _sending = false);

    if (result.success) {
      // Show success snackbar then dismiss the sheet
      final msg = result.message;
      final isMock = msg?.isMock ?? true;
      // Pop first — success snackbar shows on the screen below
      Navigator.pop(context, result);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(
            isMock
              ? 'SMS simulated ✓ (mock mode — no real message sent)'
              : 'SMS sent to ${PhoneValidator.toDisplay(_phoneCtrl.text)}',
          )),
        ]),
        backgroundColor: TRColors.success,
        duration: const Duration(seconds: 4),
      ));
    } else {
      // KEEP the sheet open so user can correct the phone number or retry.
      // Show the error inside the sheet context (still mounted).
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.error_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(
            result.error ?? 'Failed to send SMS. Check the phone number and try again.',
            style: const TextStyle(fontSize: 13),
          )),
        ]),
        backgroundColor: TRColors.error,
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white70,
          onPressed: () {},
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: TRColors.cardDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20, 16, 20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Handle ──────────────────────────────────────────────────────
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: TRColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            )),
            const SizedBox(height: 16),

            // ── Header ──────────────────────────────────────────────────────
            Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: TRColors.goldDim,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.sms_rounded, color: TRColors.gold, size: 20),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.title, style: const TextStyle(
                  color: TRColors.white, fontSize: 16, fontWeight: FontWeight.w800,
                )),
                Text('To: ${widget.customerName}', style: const TextStyle(
                  color: TRColors.grayMid, fontSize: 12,
                )),
              ]),
              const Spacer(),
              // Live / Mock badge — reflects actual server Twilio config
              _healthChecked
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _serverMockMode
                        ? TRColors.warning.withValues(alpha: 0.15)
                        : TRColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _serverMockMode
                          ? TRColors.warning.withValues(alpha: 0.5)
                          : TRColors.success.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      _serverMockMode ? 'MOCK' : 'LIVE',
                      style: TextStyle(
                        color: _serverMockMode ? TRColors.warning : TRColors.success,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : const SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation(TRColors.grayMid),
                    ),
                  ),
            ]),
            const SizedBox(height: 20),

            // ── Missing Review Link Warning ────────────────────────────────
            if (widget.templates.any((t) => t.type == SmsType.reviewRequest) &&
                (widget.reviewLink == null || widget.reviewLink!.isEmpty)) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: TRColors.warning.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: TRColors.warning.withValues(alpha: 0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(Icons.warning_amber_rounded,
                          color: TRColors.warning, size: 16),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'No Google review link connected. '  
                        'Connect your Google Business Profile in Settings → '  
                        'Profile to include your review link in this message.',
                        style: TextStyle(
                          color: TRColors.warning,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Phone Field ──────────────────────────────────────────────────
            const Text('Customer Phone', style: TextStyle(
              color: TRColors.grayLight, fontSize: 12, fontWeight: FontWeight.w600,
            )),
            const SizedBox(height: 6),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: TRColors.white, fontSize: 15),
              onChanged: _validatePhone,
              decoration: InputDecoration(
                hintText: '(720) 555-1234',
                hintStyle: TextStyle(color: TRColors.grayMid.withValues(alpha: 0.6)),
                prefixIcon: const Icon(Icons.phone_rounded, color: TRColors.grayMid, size: 18),
                errorText: _phoneError,
                errorStyle: const TextStyle(color: TRColors.error, fontSize: 11),
                filled: true,
                fillColor: TRColors.cardMid,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: TRColors.gold, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: TRColors.error),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),

            // ── Template Picker ──────────────────────────────────────────────
            if (widget.templates.length > 1) ...[
              const Text('Message Template', style: TextStyle(
                color: TRColors.grayLight, fontSize: 12, fontWeight: FontWeight.w600,
              )),
              const SizedBox(height: 8),
              ...widget.templates.map((t) => _TemplateTile(
                template: t,
                selected: _selectedTemplate.key == t.key,
                onTap: () => setState(() {
                  _selectedTemplate = t;
                  _initVariableControllers();
                }),
              )),
              const SizedBox(height: 16),
            ],

            // ── Crew Variable Fields ─────────────────────────────────────────
            if (_selectedTemplate.variables.isNotEmpty) ...[
              ..._selectedTemplate.variables.map((variable) =>
                _VariableField(
                  variable: variable,
                  currentValue: _variableValues[variable.key] ?? '',
                  controller: _varControllers[variable.key]!,
                  onQuickSelect: (val) {
                    setState(() {
                      _variableValues[variable.key] = val;
                      _varControllers[variable.key]!.text = val;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Message Preview ──────────────────────────────────────────────
            const Text('Message Preview', style: TextStyle(
              color: TRColors.grayLight, fontSize: 12, fontWeight: FontWeight.w600,
            )),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: TRColors.cardMid,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TRColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.phone_iphone_rounded, color: TRColors.grayMid, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'To: ${PhoneValidator.toDisplay(_phoneCtrl.text)}',
                      style: const TextStyle(color: TRColors.grayMid, fontSize: 11),
                    ),
                    const Spacer(),
                    Text(
                      '${_messagePreview.length} chars',
                      style: const TextStyle(color: TRColors.grayMid, fontSize: 11),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    _messagePreview,
                    style: const TextStyle(
                      color: TRColors.white, fontSize: 13, height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Send Button ──────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_sending || !_variablesFilled) ? null : _send,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TRColors.gold,
                  disabledBackgroundColor: TRColors.gold.withValues(alpha: 0.5),
                  foregroundColor: TRColors.navyDeep,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _sending
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(TRColors.navyDeep),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Send SMS', style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800,
                        )),
                      ],
                    ),
              ),
            ),

            // Only show a notice when mock mode is active so operators
            // know to configure Twilio on Railway. No notice when live.
            if (_serverMockMode) ...[
              const SizedBox(height: 12),
              Center(child: Text(
                'Mock mode — Twilio not configured on server',
                style: TextStyle(
                  color: TRColors.warning.withValues(alpha: 0.8),
                  fontSize: 11,
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Template Tile ────────────────────────────────────────────────────────────
class _TemplateTile extends StatelessWidget {
  final SmsTemplate template;
  final bool selected;
  final VoidCallback onTap;

  const _TemplateTile({
    required this.template,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? TRColors.goldDim : TRColors.cardMid,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? TRColors.gold : TRColors.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Icon(
            Icons.sms_outlined,
            color: selected ? TRColors.gold : TRColors.grayMid,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(template.label, style: TextStyle(
                color: selected ? TRColors.gold : TRColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              )),
              Text(template.description, style: const TextStyle(
                color: TRColors.grayMid, fontSize: 11,
              )),
            ],
          )),
          if (selected)
            const Icon(Icons.check_circle_rounded, color: TRColors.gold, size: 18),
        ]),
      ),
    );
  }
}

// ─── Variable Field ───────────────────────────────────────────────────────────
// Rendered for each SmsTemplateVariable on the selected template.
// Shows quick-select chips on top, freeform text field below.
class _VariableField extends StatelessWidget {
  final SmsTemplateVariable variable;
  final String currentValue;
  final TextEditingController controller;
  final ValueChanged<String> onQuickSelect;

  const _VariableField({
    required this.variable,
    required this.currentValue,
    required this.controller,
    required this.onQuickSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(variable.label, style: const TextStyle(
            color: TRColors.grayLight, fontSize: 12, fontWeight: FontWeight.w600,
          )),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: TRColors.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('Required', style: TextStyle(
              color: TRColors.gold, fontSize: 9, fontWeight: FontWeight.w700,
            )),
          ),
        ]),
        const SizedBox(height: 8),

        // Quick-select chips
        if (variable.quickOptions.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: variable.quickOptions.map((opt) {
              final selected = currentValue == opt;
              return GestureDetector(
                onTap: () => onQuickSelect(opt),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected ? TRColors.gold.withValues(alpha: 0.2) : TRColors.cardMid,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? TRColors.gold : TRColors.divider,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(opt, style: TextStyle(
                    color: selected ? TRColors.gold : TRColors.grayLight,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  )),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          const Row(children: [
            Expanded(child: Divider(color: TRColors.divider)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('or type your own', style: TextStyle(
                color: TRColors.grayMid, fontSize: 11,
              )),
            ),
            Expanded(child: Divider(color: TRColors.divider)),
          ]),
          const SizedBox(height: 10),
        ],

        // Freeform text input
        TextField(
          controller: controller,
          style: const TextStyle(color: TRColors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: variable.hint,
            hintStyle: TextStyle(color: TRColors.grayMid.withValues(alpha: 0.6)),
            prefixIcon: const Icon(Icons.edit_rounded, color: TRColors.grayMid, size: 16),
            filled: true,
            fillColor: TRColors.cardMid,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: TRColors.gold, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'This will replace "${variable.key}" in the message',
          style: const TextStyle(color: TRColors.grayMid, fontSize: 11),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SMS HISTORY SCREEN
// Full-page log of all SMS messages sent this session.
// ─────────────────────────────────────────────────────────────────────────────
class SmsHistoryScreen extends StatelessWidget {
  const SmsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final log = context.watch<AppState>().smsLog;

    return Scaffold(
      backgroundColor: TRColors.navyDeep,
      appBar: AppBar(
        backgroundColor: TRColors.navyDeep,
        foregroundColor: TRColors.white,
        title: const Text('SMS History', style: TextStyle(
          color: TRColors.white, fontWeight: FontWeight.w700, fontSize: 18,
        )),
        centerTitle: false,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: TRColors.divider),
        ),
      ),
      body: log.isEmpty
        ? _buildEmpty()
        : _buildList(log),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sms_outlined, color: TRColors.grayMid, size: 48),
          SizedBox(height: 16),
          Text('No messages sent yet', style: TextStyle(
            color: TRColors.white, fontSize: 16, fontWeight: FontWeight.w600,
          )),
          SizedBox(height: 8),
          Text('SMS history will appear here after\nyou send your first message.',
            style: TextStyle(color: TRColors.grayMid, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<SmsMessage> log) {
    // Group by date
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: log.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) return _buildSummaryCard(log);
        return _SmsLogTile(message: log[i - 1]);
      },
    );
  }

  Widget _buildSummaryCard(List<SmsMessage> log) {
    final reviews   = log.where((m) => m.type == SmsType.reviewRequest).length;
    final mocked    = log.where((m) => m.isMock).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TRColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TRColors.divider),
      ),
      child: Row(children: [
        _SummaryCell(value: '${log.length}', label: 'Total Sent', color: TRColors.info),
        _SummaryCell(value: '${log.where((m) => m.status.isSuccess).length}', label: 'Delivered', color: TRColors.success),
        _SummaryCell(value: '$reviews', label: 'Review Req', color: TRColors.gold),
        _SummaryCell(
          value: mocked == log.length ? 'Mock' : 'Live',
          label: 'Mode',
          color: mocked == log.length ? TRColors.warning : TRColors.success,
        ),
      ]),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _SummaryCell({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Column(children: [
      Text(value, style: TextStyle(
        color: color, fontSize: 20, fontWeight: FontWeight.w800,
      )),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(
        color: TRColors.grayMid, fontSize: 10,
      ), textAlign: TextAlign.center),
    ]));
  }
}

// ─── SMS Log Tile ─────────────────────────────────────────────────────────────
class _SmsLogTile extends StatelessWidget {
  final SmsMessage message;
  const _SmsLogTile({required this.message});

  @override
  Widget build(BuildContext context) {
    final isReview = message.type == SmsType.reviewRequest;
    final failed   = message.status.isFailed;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TRColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: failed ? TRColors.error.withValues(alpha: 0.4) : TRColors.divider,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          // Type icon
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: isReview
                ? TRColors.gold.withValues(alpha: 0.15)
                : TRColors.info.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isReview ? Icons.star_rounded : Icons.sms_rounded,
              color: isReview ? TRColors.gold : TRColors.info,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(message.customerName, style: const TextStyle(
              color: TRColors.white, fontSize: 13, fontWeight: FontWeight.w700,
            )),
            Text(
              message.type.displayName,
              style: const TextStyle(color: TRColors.grayMid, fontSize: 11),
            ),
          ])),
          // Status badge
          _StatusBadge(status: message.status),
        ]),
        const SizedBox(height: 10),
        // Phone + mock indicator
        Row(children: [
          const Icon(Icons.phone_rounded, color: TRColors.grayMid, size: 13),
          const SizedBox(width: 4),
          Text(
            PhoneValidator.toDisplay(message.toPhone),
            style: const TextStyle(color: TRColors.grayMid, fontSize: 12),
          ),
          const Spacer(),
          if (message.isMock)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: TRColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: TRColors.warning.withValues(alpha: 0.4)),
              ),
              child: const Text('MOCK', style: TextStyle(
                color: TRColors.warning, fontSize: 9, fontWeight: FontWeight.w700,
              )),
            ),
          const SizedBox(width: 8),
          Text(_timeAgo(message.sentAt), style: const TextStyle(
            color: TRColors.grayMid, fontSize: 11,
          )),
        ]),
        // Message body (collapsible)
        const SizedBox(height: 8),
        Text(
          message.body,
          style: const TextStyle(color: TRColors.grayLight, fontSize: 12, height: 1.4),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        // Error message if failed
        if (message.errorMessage != null) ...[
          const SizedBox(height: 6),
          Text(
            'Error: ${message.errorMessage}',
            style: const TextStyle(color: TRColors.error, fontSize: 11),
          ),
        ],
      ]),
    );
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final SmsStatus status;
  const _StatusBadge({required this.status});

  Color get _color {
    if (status.isSuccess) return TRColors.success;
    if (status.isFailed)  return TRColors.error;
    return TRColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Text(status.displayName, style: TextStyle(
        color: _color, fontSize: 10, fontWeight: FontWeight.w700,
      )),
    );
  }
}

// ─── Helper: Show SendSmsSheet ────────────────────────────────────────────────
Future<SmsResult?> showSendSmsSheet(
  BuildContext context, {
  required String jobId,
  required String customerName,
  required String customerPhone,
  required String jobType,
  required String companyName,
  String? reviewLink,             // company-specific Google review URL
  required List<SmsTemplate> templates,
  required String title,
}) {
  return showModalBottomSheet<SmsResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => SendSmsSheet(
      jobId: jobId,
      customerName: customerName,
      customerPhone: customerPhone,
      jobType: jobType,
      companyName: companyName,
      reviewLink: reviewLink,
      templates: templates,
      title: title,
    ),
  );
}
