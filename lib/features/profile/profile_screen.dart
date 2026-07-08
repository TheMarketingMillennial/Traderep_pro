import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/services/app_state.dart';
import '../../shared/services/gbp_auth_service.dart';
import '../../shared/widgets/tr_widgets.dart';
import '../../shared/models/models.dart';
import '../pricing/trial_widgets.dart';
import '../pricing/pricing_screen.dart';
import 'help_support_screen.dart';
import 'privacy_policy_screen.dart';

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

  void _showGbpOAuthSheet(BuildContext context, AppState state) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: state,
        child: _GbpOAuthSheet(state: state),
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
            subtitle: state.googleConnected
                ? (company.gbpLocationId != null && company.gbpLocationId!.isNotEmpty
                    ? 'Connected — tap to reconnect'
                    : 'Connected — tap to manage')
                : 'Not connected — tap to connect with Google',
            statusColor: state.googleConnected ? TRColors.success : TRColors.error,
            onTap: () => _showGbpOAuthSheet(context, state),
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
    final isAdmin = state.currentUser?.role == UserRole.admin ||
        state.currentUser?.role == UserRole.officeManager;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(children: [
            const Text('TEAM MEMBERS', style: TextStyle(
              color: TRColors.grayMid, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8,
            )),
            const Spacer(),
            if (isAdmin)
              GestureDetector(
                onTap: () => _showInviteSheet(context, state),
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

          // Active team members
          if (state.team.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: TRColors.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TRColors.divider),
              ),
              child: const Row(children: [
                Icon(Icons.group_outlined, color: TRColors.grayMid, size: 16),
                SizedBox(width: 8),
                Expanded(child: Text('No team members yet. Invite your crew to get started.',
                  style: TextStyle(color: TRColors.grayMid, fontSize: 13))),
              ]),
            )
          else
            ...state.team.map((member) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: TRColors.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TRColors.divider),
              ),
              child: Row(children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: TRColors.navyMid,
                    shape: BoxShape.circle,
                    border: Border.all(color: TRColors.divider),
                  ),
                  child: Center(child: Text(
                    member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: TRColors.gold, fontSize: 16, fontWeight: FontWeight.w700),
                  )),
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
                Column(children: [
                  RoleBadge(role: member.role),
                  const SizedBox(height: 3),
                  Container(
                    width: 7, height: 7,
                    decoration: const BoxDecoration(color: TRColors.success, shape: BoxShape.circle),
                  ),
                ]),
              ]),
            )),

          // Pending invites
          if (isAdmin && state.pendingInvites.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('PENDING INVITES', style: TextStyle(
              color: TRColors.grayMid, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8,
            )),
            const SizedBox(height: 8),
            ...state.pendingInvites.map((invite) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: TRColors.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TRColors.warning.withValues(alpha: 0.4)),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: TRColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.phone_outlined, color: TRColors.warning, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(invite.name, style: const TextStyle(
                      color: TRColors.white, fontSize: 14, fontWeight: FontWeight.w600,
                    )),
                    Text(invite.phone, style: const TextStyle(color: TRColors.grayMid, fontSize: 11)),
                  ],
                )),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    RoleBadge(role: invite.role),
                    const SizedBox(height: 4),
                    const Text('Pending', style: TextStyle(
                      color: TRColors.warning, fontSize: 10, fontWeight: FontWeight.w600,
                    )),
                  ],
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => state.cancelInvite(invite.id),
                  child: const Icon(Icons.close_rounded, color: TRColors.grayMid, size: 18),
                ),
              ]),
            )),
          ],
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
            icon: Icons.help_outline_rounded,
            title: 'Help & Support',
            subtitle: 'FAQs and contact support',
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const HelpSupportScreen(),
            )),
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'How TradeRep Pro handles your data',
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const PrivacyPolicyScreen(),
            )),
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

void _showInviteSheet(BuildContext context, AppState state) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(
      value: state,
      child: const _InviteTeamSheet(),
    ),
  );
}

// Keep old name as an alias so nothing else breaks
// ignore: unused_element
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
// INVITE TEAM MEMBER SHEET
// ─────────────────────────────────────────────────────────────────────────────

// App Store / Play Store links — swap for real URLs before publishing


class _InviteTeamSheet extends StatefulWidget {
  const _InviteTeamSheet();

  @override
  State<_InviteTeamSheet> createState() => _InviteTeamSheetState();
}

class _InviteTeamSheetState extends State<_InviteTeamSheet> {
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  UserRole _role   = UserRole.crewMember;
  bool _loading    = false;
  String? _error;

  // After a successful invite, show the confirmation view
  String? _sentInviteId;
  String? _sentPhone;
  String? _sentName;
  String? _sentCompanyName;
  String? _sentInviterName;

  static const _roles = [
    UserRole.crewMember,
    UserRole.crewLead,
    UserRole.salesRep,
    UserRole.officeManager,
  ];

  static const _roleDescriptions = {
    UserRole.crewMember:    'Submit photos and view assigned jobs.',
    UserRole.crewLead:      'Manage crew, submit and review photos.',
    UserRole.salesRep:      'Create jobs, send reviews, manage content.',
    UserRole.officeManager: 'Approve photos, manage team, full access.',
  };

  InputDecoration _fieldDecoration(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: TRColors.grayDark),
    prefixIcon: Icon(icon, color: TRColors.grayMid, size: 18),
    filled: true,
    fillColor: TRColors.navyMid,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border:        OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: TRColors.divider)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: TRColors.divider)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: TRColors.gold, width: 1.5)),
    errorBorder:   OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: TRColors.error, width: 1.5)),
  );

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveInvite() async {
    final name  = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      setState(() => _error = 'Please fill in name and phone number.');
      return;
    }
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length < 10) {
      setState(() => _error = 'Please enter a valid phone number.');
      return;
    }

    setState(() { _loading = true; _error = null; });
    final appState = context.read<AppState>();
    final id = await appState.sendTeamInvite(phone: phone, name: name, role: _role);
    if (!mounted) return;

    if (id == null) {
      setState(() { _loading = false; _error = 'Failed to save invite. Please try again.'; });
    } else {
      setState(() {
        _loading = false;
        _sentInviteId = id;
        _sentPhone = phone;
        _sentName = name;
        _sentCompanyName = appState.company?.name ?? 'your company';
        _sentInviterName = appState.currentUser?.name ?? 'Your admin';
      });
    }
  }

  /// Opens native SMS app pre-filled with the invite message.
  Future<void> _sendSMS() async {
    final name    = _sentName ?? '';
    final company = _sentCompanyName ?? 'the team';
    final body = Uri.encodeComponent(
      'Hey $name! $_sentInviterName has added you to $company on TradeRep Pro — '
      'the app we use to document jobs, collect reviews, and post to Google. '
      'Search "TradeRep Pro" in the App Store or Google Play, sign up with this phone number, '
      'and you\'ll automatically join the team. 👷',
    );
    final smsUri = Uri.parse('sms:${_sentPhone ?? ''}?body=$body');
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: TRColors.navyDeep,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20,
          20 + MediaQuery.of(context).viewInsets.bottom),
      child: _sentInviteId != null
          ? _buildSuccessView(context)
          : _buildFormView(),
    );
  }

  // ── Form view ───────────────────────────────────────────────────────────────
  Widget _buildFormView() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(child: Container(
            width: 36, height: 4,
            decoration: BoxDecoration(color: TRColors.divider, borderRadius: BorderRadius.circular(2)),
          )),
          const SizedBox(height: 16),

          // Title
          const Row(children: [
            Icon(Icons.person_add_rounded, color: TRColors.gold, size: 22),
            SizedBox(width: 10),
            Text('Invite Team Member', style: TextStyle(
              color: TRColors.white, fontSize: 18, fontWeight: FontWeight.w800,
            )),
          ]),
          const SizedBox(height: 4),
          const Text(
            'Enter their details and you\'ll get a ready-to-send text message with the app download link.',
            style: TextStyle(color: TRColors.grayLight, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),

          // Name field
          const Text('Full Name', style: TextStyle(
            color: TRColors.grayLight, fontSize: 12, fontWeight: FontWeight.w600,
          )),
          const SizedBox(height: 6),
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: TRColors.white),
            textCapitalization: TextCapitalization.words,
            decoration: _fieldDecoration('e.g. Jake Rivera', Icons.person_outline_rounded),
          ),
          const SizedBox(height: 14),

          // Phone field
          const Text('Cell Phone Number', style: TextStyle(
            color: TRColors.grayLight, fontSize: 12, fontWeight: FontWeight.w600,
          )),
          const SizedBox(height: 6),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: TRColors.white),
            decoration: _fieldDecoration('(555) 000-0000', Icons.phone_rounded),
          ),
          const SizedBox(height: 4),
          const Text(
            'They\'ll sign up with this number — it links them to your company.',
            style: TextStyle(color: TRColors.grayMid, fontSize: 11),
          ),
          const SizedBox(height: 14),

          // Role picker
          const Text('Role', style: TextStyle(
            color: TRColors.grayLight, fontSize: 12, fontWeight: FontWeight.w600,
          )),
          const SizedBox(height: 8),
          ..._roles.map((role) {
            final selected = _role == role;
            return GestureDetector(
              onTap: () => setState(() => _role = role),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? TRColors.goldDim : TRColors.cardDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? TRColors.gold : TRColors.divider,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(children: [
                  Icon(_roleIcon(role),
                    color: selected ? TRColors.gold : TRColors.grayMid, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_roleLabel(role), style: TextStyle(
                        color: selected ? TRColors.gold : TRColors.white,
                        fontSize: 13, fontWeight: FontWeight.w600,
                      )),
                      Text(_roleDescriptions[role] ?? '', style: const TextStyle(
                        color: TRColors.grayMid, fontSize: 11, height: 1.3,
                      )),
                    ],
                  )),
                  if (selected)
                    const Icon(Icons.check_circle_rounded, color: TRColors.gold, size: 18),
                ]),
              ),
            );
          }),

          // Error
          if (_error != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: TRColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: TRColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline_rounded, color: TRColors.error, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: const TextStyle(color: TRColors.error, fontSize: 12))),
              ]),
            ),
          ],

          const SizedBox(height: 20),
          GoldButton(
            label: _loading ? 'Saving...' : 'Continue',
            icon: Icons.arrow_forward_rounded,
            onTap: _loading ? null : _saveInvite,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Center(child: Text('Cancel',
              style: TextStyle(color: TRColors.grayLight, fontSize: 14))),
          ),
        ],
      ),
    );
  }

  // ── Success / Send view ───────────────────────────────────────────────────
  Widget _buildSuccessView(BuildContext ctx) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(child: Container(
            width: 36, height: 4,
            decoration: BoxDecoration(color: TRColors.divider, borderRadius: BorderRadius.circular(2)),
          )),
          const SizedBox(height: 20),

          // Checkmark
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: TRColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: TRColors.success.withValues(alpha: 0.4), width: 2),
            ),
            child: const Icon(Icons.check_rounded, color: TRColors.success, size: 28),
          ),
          const SizedBox(height: 12),
          Text('Invite Ready for ${_sentName ?? 'them'}!', style: const TextStyle(
            color: TRColors.white, fontSize: 18, fontWeight: FontWeight.w800,
          )),
          const SizedBox(height: 4),
          Text('Send them the app download link via text.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: TRColors.grayLight, fontSize: 13)),
          const SizedBox(height: 20),

          // ── Primary: Send via SMS ──────────────────────────────────────
          GestureDetector(
            onTap: _sendSMS,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [TRColors.gold, TRColors.gold.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: TRColors.navyDeep.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.sms_rounded, color: TRColors.navyDeep, size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Send Text Message', style: TextStyle(
                      color: TRColors.navyDeep, fontSize: 15, fontWeight: FontWeight.w800,
                    )),
                    SizedBox(height: 2),
                    Text('Opens your Messages app — pre-filled and ready to send',
                      style: TextStyle(color: TRColors.navyDeep, fontSize: 11)),
                  ],
                )),
                const Icon(Icons.arrow_forward_ios_rounded, color: TRColors.navyDeep, size: 14),
              ]),
            ),
          ),

          const SizedBox(height: 16),

          // ── How it works ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: TRColors.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: TRColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.info_outline_rounded, color: TRColors.info, size: 15),
                  SizedBox(width: 6),
                  Text('How joining works', style: TextStyle(
                    color: TRColors.white, fontSize: 12, fontWeight: FontWeight.w700,
                  )),
                ]),
                const SizedBox(height: 10),
                _StepRow(number: '1', text: '${_sentName ?? 'They'} search "TradeRep Pro" in the App Store or Google Play'),
                _StepRow(number: '2', text: 'They create an account using ${_sentPhone ?? 'this phone number'}'),
                const _StepRow(number: '3', text: 'They automatically join your company — no code needed'),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: GoldButton(
              label: 'Invite Another',
              icon: Icons.person_add_rounded,
              onTap: () => setState(() {
                _sentInviteId = null;
                _sentPhone = null;
                _sentName = null;
                _sentInviterName = null;
                _nameCtrl.clear();
                _phoneCtrl.clear();
                _role = UserRole.crewMember;
              }),
            )),
            const SizedBox(width: 10),
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: TRColors.divider),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Done', style: TextStyle(color: TRColors.grayLight, fontSize: 14)),
            )),
          ]),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  IconData _roleIcon(UserRole r) {
    switch (r) {
      case UserRole.crewMember:    return Icons.construction_rounded;
      case UserRole.crewLead:      return Icons.engineering_rounded;
      case UserRole.salesRep:      return Icons.badge_rounded;
      case UserRole.officeManager: return Icons.manage_accounts_rounded;
      default:                     return Icons.person_rounded;
    }
  }

  String _roleLabel(UserRole r) {
    switch (r) {
      case UserRole.crewMember:    return 'Crew Member';
      case UserRole.crewLead:      return 'Crew Lead';
      case UserRole.salesRep:      return 'Sales Rep';
      case UserRole.officeManager: return 'Office Manager';
      default:                     return r.name;
    }
  }
}

class _StepRow extends StatelessWidget {
  final String number;
  final String text;
  const _StepRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
              color: TRColors.gold.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(number, style: const TextStyle(
              color: TRColors.gold, fontSize: 10, fontWeight: FontWeight.w800,
            ))),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(
            color: TRColors.grayLight, fontSize: 12, height: 1.4,
          ))),
        ],
      ),
    );
  }
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

// ─── GBP OAuth Sheet (Profile) ───────────────────────────────────────────────
// Replaces the old Location ID edit sheet with a one-tap Google Sign-In flow.
// No text fields, no technical IDs — user just taps "Sign in with Google".

class _GbpOAuthSheet extends StatefulWidget {
  final AppState state;
  const _GbpOAuthSheet({required this.state});

  @override
  State<_GbpOAuthSheet> createState() => _GbpOAuthSheetState();
}

enum _ProfileGbpPhase { idle, waiting, connected, error }

class _GbpOAuthSheetState extends State<_GbpOAuthSheet> {
  _ProfileGbpPhase _phase = _ProfileGbpPhase.idle;
  String? _locationName;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    if (widget.state.googleConnected) {
      _phase        = _ProfileGbpPhase.connected;
      _locationName = widget.state.company?.gbpLocationId;
    }
  }

  Future<void> _startOAuth() async {
    final companyId = widget.state.company?.id;
    if (companyId == null || companyId.isEmpty) {
      setState(() {
        _phase    = _ProfileGbpPhase.error;
        _errorMsg = 'Company not loaded. Please sign out and back in.';
      });
      return;
    }

    setState(() => _phase = _ProfileGbpPhase.waiting);

    await GbpAuthService.instance.startOAuthFlow(
      companyId: companyId,
      onBrowserOpened: () {
        if (mounted) setState(() => _phase = _ProfileGbpPhase.waiting);
      },
      onConnected: (result) {
        if (!mounted) return;
        widget.state.connectGoogleViaOAuth(result);
        setState(() {
          _phase        = _ProfileGbpPhase.connected;
          _locationName = result.locationName ?? result.locationId;
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      },
      onError: (err) {
        if (!mounted) return;
        setState(() {
          _phase    = _ProfileGbpPhase.error;
          _errorMsg = err;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: TRColors.navyMid,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: TRColors.goldDark, width: 1.5)),
      ),
      padding: EdgeInsets.fromLTRB(
        20, 16, 20,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: TRColors.grayMid.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          )),
          const SizedBox(height: 20),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _phase == _ProfileGbpPhase.connected
              ? Container(
                  key: const ValueKey('check'),
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: TRColors.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      color: TRColors.success, size: 32),
                )
              : Container(
                  key: const ValueKey('gbp'),
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: TRColors.gold.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.business_rounded,
                      color: TRColors.gold, size: 28),
                ),
          ),
          const SizedBox(height: 14),

          Text(
            _phase == _ProfileGbpPhase.connected
              ? 'Google Business Connected'
              : 'Connect Google Business Profile',
            style: TextStyle(
              color: _phase == _ProfileGbpPhase.connected
                  ? TRColors.success : TRColors.white,
              fontSize: 17, fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _phase == _ProfileGbpPhase.connected
              ? (_locationName != null
                  ? 'Profile "$_locationName" is linked.'
                  : 'Your Google Business Profile is linked.')
              : 'One tap — no technical steps required.',
            style: const TextStyle(color: TRColors.grayMid, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          if (_phase == _ProfileGbpPhase.waiting)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: TRColors.gold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TRColors.gold.withValues(alpha: 0.25)),
              ),
              child: Row(children: const [
                SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(
                      color: TRColors.gold, strokeWidth: 2.5)),
                SizedBox(width: 12),
                Expanded(child: Text(
                  'Waiting for Google approval…\nComplete sign-in in your browser, then return here.',
                  style: TextStyle(color: TRColors.gold, fontSize: 12, height: 1.4),
                )),
              ]),
            ),

          if (_phase == _ProfileGbpPhase.error && _errorMsg != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TRColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TRColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline_rounded,
                    color: TRColors.error, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_errorMsg!,
                    style: const TextStyle(color: TRColors.error, fontSize: 12))),
              ]),
            ),

          if (_phase == _ProfileGbpPhase.connected) ...[
            // ── Connected actions ──────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.sync_rounded, size: 18),
                label: const Text('Reconnect with Different Account'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: TRColors.gold,
                  side: const BorderSide(
                      color: TRColors.gold, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
                onPressed: () {
                  // Reset to idle so the connect flow starts fresh
                  setState(() {
                    _phase = _ProfileGbpPhase.idle;
                    _locationName = null;
                  });
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                icon: const Icon(Icons.link_off_rounded,
                    size: 18, color: TRColors.error),
                label: const Text('Disconnect Google Business Profile',
                    style: TextStyle(color: TRColors.error)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                        color: TRColors.error.withValues(alpha: 0.4)),
                  ),
                ),
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: TRColors.cardDark,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      title: const Text('Disconnect GBP?',
                          style: TextStyle(
                              color: TRColors.white,
                              fontWeight: FontWeight.w700)),
                      content: const Text(
                        'This will remove the connection to your Google '
                        'Business Profile. Review links will no longer be '
                        'included in SMS messages until you reconnect.',
                        style: TextStyle(
                            color: TRColors.grayLight, fontSize: 13,
                            height: 1.5),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel',
                              style: TextStyle(
                                  color: TRColors.grayLight)),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            widget.state.disconnectGbp();
                            Navigator.pop(context); // close sheet
                          },
                          child: const Text('Disconnect',
                              style: TextStyle(
                                  color: TRColors.error,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Center(child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done',
                  style: TextStyle(color: TRColors.grayMid, fontSize: 13)),
            )),
          ] else ...[
            GoldButton(
              label: _phase == _ProfileGbpPhase.waiting
                  ? 'Waiting for browser…'
                  : _phase == _ProfileGbpPhase.error
                      ? 'Try Again'
                      : 'Sign in with Google',
              icon: _phase == _ProfileGbpPhase.waiting
                  ? Icons.hourglass_empty_rounded
                  : Icons.login_rounded,
              onTap: _phase == _ProfileGbpPhase.waiting ? null : _startOAuth,
            ),
            const SizedBox(height: 8),
            Center(child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: TRColors.grayMid, fontSize: 13)),
            )),
          ],
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? statusColor;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.statusColor,
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
            const Icon(Icons.chevron_right_rounded, color: TRColors.grayMid, size: 18),
          ],
        ),
      ),
    );
  }
}
