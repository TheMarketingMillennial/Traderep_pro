import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/services/app_state.dart';
import '../../shared/widgets/tr_widgets.dart';
import '../../shared/models/models.dart';
import '../pricing/trial_widgets.dart';
import '../pricing/pricing_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.currentUser;
    final company = state.company;

    if (user == null || company == null) {
      return const Scaffold(
        backgroundColor: TRColors.navyDeep,
        body: Center(child: CircularProgressIndicator(color: TRColors.gold)),
      );
    }

    return Scaffold(
      backgroundColor: TRColors.navyDeep,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context, user, company, state)),
            SliverToBoxAdapter(child: _buildSubscriptionSection(context, state)),
            SliverToBoxAdapter(child: _buildCompanySection(context, company, state)),
            SliverToBoxAdapter(child: _buildTeamSection(context, state)),
            SliverToBoxAdapter(child: _buildSettingsSection(context, state)),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TRUser user, Company company, AppState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [TRColors.navyMid, TRColors.navyDeep],
        ),
      ),
      child: Column(
        children: [
          // Logo / Avatar area
          Row(
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: TRColors.goldDim,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: TRColors.gold.withValues(alpha: 0.4), width: 1.5),
                ),
                child: Center(child: Text(
                  company.name.substring(0, 1),
                  style: const TextStyle(color: TRColors.gold, fontSize: 28, fontWeight: FontWeight.w800),
                )),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(company.name, style: const TextStyle(
                    color: TRColors.white, fontSize: 18, fontWeight: FontWeight.w800,
                  )),
                  Text(company.tradeCategory, style: const TextStyle(
                    color: TRColors.gold, fontSize: 13, fontWeight: FontWeight.w600,
                  )),
                  Text(company.serviceArea, style: const TextStyle(
                    color: TRColors.grayLight, fontSize: 12,
                  )),
                ],
              )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: state.googleConnected
                    ? TRColors.success.withValues(alpha: 0.15)
                    : TRColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: state.googleConnected
                      ? TRColors.success.withValues(alpha: 0.4)
                      : TRColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.business_rounded,
                      color: state.googleConnected ? TRColors.success : TRColors.error, size: 18),
                    Text(state.googleConnected ? 'GBP' : 'GBP', style: TextStyle(
                      color: state.googleConnected ? TRColors.success : TRColors.error,
                      fontSize: 9, fontWeight: FontWeight.w700,
                    )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Current user row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: TRColors.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: TRColors.divider),
            ),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: TRColors.gold.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: TRColors.gold.withValues(alpha: 0.4)),
                  ),
                  child: Center(child: Text(user.name.substring(0, 1), style: const TextStyle(
                    color: TRColors.gold, fontSize: 16, fontWeight: FontWeight.w800,
                  ))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: const TextStyle(
                      color: TRColors.white, fontSize: 14, fontWeight: FontWeight.w700,
                    )),
                    Text(user.email, style: const TextStyle(color: TRColors.grayMid, fontSize: 12)),
                  ],
                )),
                RoleBadge(role: user.role),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionSection(BuildContext context, AppState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SUBSCRIPTION', style: TextStyle(
            color: TRColors.grayMid, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8,
          )),
          const SizedBox(height: 10),
          const SubscriptionCard(),
        ],
      ),
    );
  }

  void _showGbpLocationSheet(
      BuildContext context, AppState state, Company company) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: state,
        child: _GbpLocationSheet(current: company.gbpLocationId),
      ),
    );
  }

  Widget _buildCompanySection(BuildContext context, Company company, AppState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('COMPANY SETTINGS', style: TextStyle(
            color: TRColors.grayMid, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8,
          )),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.edit_rounded,
            title: 'Edit Company Profile',
            subtitle: 'Update name, logo, contact info',
            onTap: () => _showEditCompanySheet(context, company, state),
          ),
          _SettingsTile(
            icon: Icons.business_rounded,
            title: 'Google Business Profile',
            subtitle: state.googleConnected ? 'Connected — Tap to manage' : 'Not connected — Tap to connect',
            statusColor: state.googleConnected ? TRColors.success : TRColors.error,
            onTap: () {
              if (!state.googleConnected) state.connectGoogle();
            },
          ),
          _SettingsTile(
            icon: Icons.location_on_rounded,
            title: 'GBP Location ID',
            subtitle: (company.gbpLocationId != null && company.gbpLocationId!.isNotEmpty)
                ? company.gbpLocationId!
                : 'Not set — tap to enable one-tap publishing',
            statusColor: (company.gbpLocationId != null && company.gbpLocationId!.isNotEmpty)
                ? TRColors.success
                : TRColors.warning,
            onTap: () => _showGbpLocationSheet(context, state, company),
          ),
          _SettingsTile(
            icon: Icons.photo_library_rounded,
            title: 'Photo Templates',
            subtitle: '${state.templates.length} templates configured',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Photo template editor coming soon'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            )),
          ),
          _SettingsTile(
            icon: Icons.notifications_rounded,
            title: 'Review Request Settings',
            subtitle: 'SMS / Email timing and templates',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Review request settings coming soon'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            )),
          ),
          _SettingsTile(
            icon: Icons.credit_card_rounded,
            title: 'Manage Subscription',
            subtitle: 'Billing, plan upgrades, invoices',
            statusColor: TRColors.gold,
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const PricingScreen(),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSection(BuildContext context, AppState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('TEAM MEMBERS', style: TextStyle(
              color: TRColors.grayMid, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8,
            )),
            const Spacer(),
            GestureDetector(
              onTap: () => _showInviteDialog(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: TRColors.goldDim,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('+ Invite', style: TextStyle(
                  color: TRColors.gold, fontSize: 12, fontWeight: FontWeight.w700,
                )),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          ...state.team.map((member) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: TRColors.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: TRColors.divider),
            ),
            child: Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: TRColors.navyMid,
                    shape: BoxShape.circle,
                    border: Border.all(color: TRColors.divider),
                  ),
                  child: Center(child: Text(member.name.substring(0, 1), style: const TextStyle(
                    color: TRColors.gold, fontSize: 16, fontWeight: FontWeight.w700,
                  ))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.name, style: const TextStyle(
                      color: TRColors.white, fontSize: 14, fontWeight: FontWeight.w600,
                    )),
                    Text(member.email, style: const TextStyle(color: TRColors.grayMid, fontSize: 11)),
                  ],
                )),
                Column(
                  children: [
                    RoleBadge(role: member.role),
                    const SizedBox(height: 3),
                    Container(
                      width: 7, height: 7,
                      decoration: const BoxDecoration(color: TRColors.success, shape: BoxShape.circle),
                    ),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, AppState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('APP SETTINGS', style: TextStyle(
            color: TRColors.grayMid, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8,
          )),
          _SettingsTile(
            icon: Icons.rocket_launch_rounded,
            title: 'View All Plans',
            subtitle: 'Compare Starter, Growth, and Pro',
            statusColor: TRColors.info,
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const PricingScreen(),
            )),
          ),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.dark_mode_rounded,
            title: 'Dark / Light Mode',
            subtitle: state.themeMode == ThemeMode.dark ? 'Dark mode active' : 'Light mode active',
            trailing: Switch(
              value: state.themeMode == ThemeMode.dark,
              onChanged: (_) => state.toggleTheme(),
              activeThumbColor: TRColors.gold,
              activeTrackColor: TRColors.goldDim,
              inactiveThumbColor: TRColors.grayMid,
            ),
            onTap: () => state.toggleTheme(),
          ),
          _SettingsTile(
            icon: Icons.help_outline_rounded,
            title: 'Help & Support',
            subtitle: 'FAQs, contact support',
            onTap: () => launchUrl(Uri.parse('mailto:support@traderep.app?subject=TradeRep%20Support')),
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'How TradeRep handles your data',
            onTap: () => launchUrl(Uri.parse('https://traderep.app/privacy'), mode: LaunchMode.externalApplication),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              showDialog(context: context, builder: (_) => AlertDialog(
                backgroundColor: TRColors.cardDark,
                title: const Text('Sign Out', style: TextStyle(color: TRColors.white)),
                content: const Text('Are you sure you want to sign out?', style: TextStyle(color: TRColors.grayLight)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: TRColors.grayLight))),
                  TextButton(onPressed: () async {
                    Navigator.pop(context);
                    await state.logout();
                  }, child: const Text('Sign Out', style: TextStyle(color: TRColors.error))),
                ],
              ));
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TRColors.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TRColors.error.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.logout_rounded, color: TRColors.error, size: 20),
                  SizedBox(width: 12),
                  Text('Sign Out', style: TextStyle(
                    color: TRColors.error, fontSize: 15, fontWeight: FontWeight.w600,
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(child: Column(
            children: [
              const TRLogo(size: 32),
              const SizedBox(height: 8),
              const Text('TradeRep Pro v1.0.0', style: TextStyle(color: TRColors.grayMid, fontSize: 12)),
              const Text('PROOF. VISIBILITY. GROWTH.', style: TextStyle(
                color: TRColors.grayMid, fontSize: 10, letterSpacing: 1.2,
              )),
            ],
          )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS — Edit Company, Invite
// ─────────────────────────────────────────────────────────────────────────────

void _showEditCompanySheet(BuildContext context, Company company, AppState state) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(
      value: state,
      child: _EditCompanySheet(company: company),
    ),
  );
}

void _showInviteDialog(BuildContext context) {
  final ctrl = TextEditingController();
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: TRColors.cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Invite Team Member',
          style: TextStyle(color: TRColors.white, fontWeight: FontWeight.w700)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Enter their email and we\'ll send an invite link.',
              style: TextStyle(color: TRColors.grayLight, fontSize: 13)),
          const SizedBox(height: 16),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            style: const TextStyle(color: TRColors.white),
            decoration: InputDecoration(
              hintText: 'crew@example.com',
              hintStyle: const TextStyle(color: TRColors.grayDark),
              prefixIcon: const Icon(Icons.email_rounded, color: TRColors.grayMid, size: 18),
              filled: true,
              fillColor: TRColors.navyMid,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: TRColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: TRColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: TRColors.gold, width: 1.5),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel', style: TextStyle(color: TRColors.grayLight)),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            final email = ctrl.text.trim();
            if (email.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Invite sent to $email'),
                backgroundColor: TRColors.success,
                behavior: SnackBarBehavior.floating,
              ));
            }
          },
          child: const Text('Send Invite',
              style: TextStyle(color: TRColors.gold, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// EDIT COMPANY SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _EditCompanySheet extends StatefulWidget {
  final Company company;
  const _EditCompanySheet({required this.company});

  @override
  State<_EditCompanySheet> createState() => _EditCompanySheetState();
}

class _EditCompanySheetState extends State<_EditCompanySheet> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _serviceAreaCtrl;
  late final TextEditingController _websiteCtrl;

  @override
  void initState() {
    super.initState();
    final c = widget.company;
    _nameCtrl        = TextEditingController(text: c.name);
    _phoneCtrl       = TextEditingController(text: c.phone);
    _serviceAreaCtrl = TextEditingController(text: c.serviceArea);
    _websiteCtrl     = TextEditingController(text: c.website ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _serviceAreaCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    // ignore: use_build_context_synchronously
    context.read<AppState>().updateCompany(
      name:        _nameCtrl.text.trim(),
      phone:       _phoneCtrl.text.trim(),
      serviceArea: _serviceAreaCtrl.text.trim(),
      website:     _websiteCtrl.text.trim().isEmpty ? null : _websiteCtrl.text.trim(),
    );
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Company profile updated'),
        backgroundColor: TRColors.gold,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: TRColors.cardDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              // Handle
              Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: TRColors.divider, borderRadius: BorderRadius.circular(2)),
              )),
              const SizedBox(height: 16),
              Row(children: [
                const Text('Edit Company Profile', style: TextStyle(
                  color: TRColors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                const Spacer(),
                _saving
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: TRColors.gold, strokeWidth: 2))
                    : TextButton(
                        onPressed: _save,
                        child: const Text('Save',
                            style: TextStyle(color: TRColors.gold, fontWeight: FontWeight.w700))),
              ]),
              const SizedBox(height: 20),
              _SheetField(label: 'Company Name', ctrl: _nameCtrl,
                  icon: Icons.business_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
              const SizedBox(height: 14),
              _SheetField(label: 'Phone', ctrl: _phoneCtrl,
                  icon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 14),
              _SheetField(label: 'Service Area', ctrl: _serviceAreaCtrl,
                  icon: Icons.location_on_rounded,
                  hint: 'e.g. Denver, CO (50-mile radius)'),
              const SizedBox(height: 14),
              _SheetField(label: 'Website', ctrl: _websiteCtrl,
                  icon: Icons.language_rounded,
                  hint: 'yourcompany.com',
                  keyboardType: TextInputType.url),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Reusable field for sheets ────────────────────────────────────────────────
class _SheetField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final IconData icon;
  final String? hint;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _SheetField({
    required this.label,
    required this.ctrl,
    required this.icon,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: TRColors.divider)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: TRColors.divider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: TRColors.gold, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: TRColors.error)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: TRColors.error, width: 1.5)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GBP LOCATION ID EDIT SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _GbpLocationSheet extends StatefulWidget {
  final String? current;
  const _GbpLocationSheet({this.current});

  @override
  State<_GbpLocationSheet> createState() => _GbpLocationSheetState();
}

class _GbpLocationSheetState extends State<_GbpLocationSheet> {
  late TextEditingController _ctrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.current ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = _ctrl.text.trim();
    // Basic format check: must start with 'accounts/' if non-empty
    if (value.isNotEmpty && !value.startsWith('accounts/')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Format must be: accounts/123456789/locations/987654321'),
        backgroundColor: TRColors.error,
      ));
      return;
    }
    setState(() => _saving = true);
    await context.read<AppState>().updateGbpLocationId(
          value.isEmpty ? null : value,
        );
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded,
              color: TRColors.success, size: 18),
          const SizedBox(width: 10),
          Text(value.isEmpty
              ? 'GBP Location ID cleared.'
              : 'GBP Location ID saved!'),
        ]),
        backgroundColor: TRColors.cardDark,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: TRColors.navyMid,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border:
              Border(top: BorderSide(color: TRColors.goldDark, width: 1.5)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: TRColors.grayMid.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Header
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4285F4).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.location_on_rounded,
                    color: Color(0xFF4285F4), size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('GBP Location ID',
                        style: TextStyle(
                            color: TRColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    Text('Enables one-tap publishing to Google Business',
                        style: TextStyle(
                            color: TRColors.grayMid, fontSize: 12)),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 20),
            // How-to card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF4285F4).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF4285F4).withValues(alpha: 0.2)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('How to find your Location ID:',
                      style: TextStyle(
                          color: Color(0xFF4285F4),
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  SizedBox(height: 8),
                  Text(
                    '1. Go to Google Cloud Console → APIs & Services\n'
                    '2. Enable "My Business Business Information API"\n'
                    '3. Call: GET https://mybusinessbusinessinformation.googleapis.com/v1/accounts\n'
                    '4. Then: GET .../accounts/{id}/locations\n'
                    '5. Copy the "name" field, e.g. accounts/123/locations/456\n\n'
                    'Or check your GBP dashboard URL — the numbers after /locations/ is your location ID.',
                    style: TextStyle(
                        color: TRColors.grayMid,
                        fontSize: 12,
                        height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Input
            Container(
              decoration: BoxDecoration(
                color: TRColors.navyDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: TRColors.navyLight.withValues(alpha: 0.6)),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 4),
              child: TextField(
                controller: _ctrl,
                style: const TextStyle(
                    color: TRColors.white,
                    fontSize: 14,
                    fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'accounts/123456789/locations/987654321',
                  hintStyle:
                      TextStyle(color: TRColors.grayMid, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Save button
            GoldButton(
              label: _saving ? 'Saving…' : 'Save Location ID',
              icon: Icons.save_rounded,
              onTap: _saving ? null : _save,
            ),
            const SizedBox(height: 8),
            // Clear link
            if (widget.current != null && widget.current!.isNotEmpty)
              Center(
                child: TextButton(
                  onPressed: () {
                    _ctrl.clear();
                    _save();
                  },
                  child: const Text('Clear Location ID',
                      style: TextStyle(
                          color: TRColors.error, fontSize: 13)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? statusColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.statusColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: TRColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: TRColors.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (statusColor ?? TRColors.grayLight).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: statusColor ?? TRColors.grayLight, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(
                  color: TRColors.white, fontSize: 14, fontWeight: FontWeight.w600,
                )),
                Text(subtitle, style: TextStyle(
                  color: statusColor ?? TRColors.grayMid, fontSize: 12,
                )),
              ],
            )),
            trailing ?? const Icon(Icons.chevron_right_rounded, color: TRColors.grayMid, size: 18),
          ],
        ),
      ),
    );
  }
}
