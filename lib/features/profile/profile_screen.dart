import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    final user = state.currentUser!;
    final company = state.company!;

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
            onTap: () {},
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
            icon: Icons.photo_library_rounded,
            title: 'Photo Templates',
            subtitle: '${state.templates.length} templates configured',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.notifications_rounded,
            title: 'Review Request Settings',
            subtitle: 'SMS / Email timing and templates',
            onTap: () {},
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
              onTap: () {},
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
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'How TradeRep handles your data',
            onTap: () {},
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
                  TextButton(onPressed: () {
                    Navigator.pop(context);
                    state.logout();
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
