import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/services/app_state.dart';
import '../../features/pricing/pricing_screen.dart';
import '../../features/pricing/pricing_models.dart';
import '../dashboard/dashboard_screen.dart' show DashboardScreen;
import '../jobs/jobs_screen.dart';
import '../photos/photos_screen.dart';
import '../reviews/reviews_screen.dart';
import '../content/content_screen.dart';
import '../profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  List<Widget> get _screens => [
    DashboardScreen(onSwitchTab: _switchTab),
    const JobsScreen(),
    const PhotosScreen(),
    const ContentScreen(),
    const ReviewsScreen(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _NavItem(icon: Icons.work_rounded, label: 'Jobs'),
    _NavItem(icon: Icons.camera_alt_rounded, label: 'Photos'),
    _NavItem(icon: Icons.auto_awesome_rounded, label: 'Content'),
    _NavItem(icon: Icons.star_rounded, label: 'Reviews'),
  ];

  void _switchTab(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    // ── Trial gate ──────────────────────────────────────────────────────────
    // Block access when trial has expired and subscription is not active.
    // Users with status == 'none' (never signed up) are also gated so they
    // must pick a plan before using the app.
    final sub = state.subscription;
    final isBlocked =
        sub.status == SubscriptionStatus.none ||
        (sub.status == SubscriptionStatus.trial && sub.trialDaysRemaining <= 0) ||
        sub.status == SubscriptionStatus.cancelled;

    if (isBlocked) {
      return _TrialExpiredGate(subscription: sub);
    }

    return Scaffold(
      backgroundColor: TRColors.navyDeep,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(state),
    );
  }

  Widget _buildBottomNav(AppState state) {
    return Container(
      decoration: const BoxDecoration(
        color: TRColors.cardDark,
        border: Border(top: BorderSide(color: TRColors.divider, width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ..._navItems.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                final selected = _currentIndex == i;

                // Badge for content pending (index 3) or photos pending approval (index 2)
                final showBadge = (i == 3 && state.pendingPosts.isNotEmpty) ||
                    (i == 2 && state.canApprovePhotos && state.pendingSubmissions.isNotEmpty);
                final badgeCount = i == 3
                    ? state.pendingPosts.length
                    : state.pendingSubmissions.length;

                return GestureDetector(
                  onTap: () => setState(() => _currentIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? TRColors.goldDim : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.icon,
                              color: selected ? TRColors.gold : TRColors.grayMid,
                              size: 22,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.label,
                              style: TextStyle(
                                color: selected ? TRColors.gold : TRColors.grayMid,
                                fontSize: 10,
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        if (showBadge)
                          Positioned(
                            top: -3, right: -5,
                            child: Container(
                              width: 14, height: 14,
                              decoration: BoxDecoration(
                                color: i == 2 ? TRColors.warning : TRColors.gold,
                                shape: BoxShape.circle,
                              ),
                              child: Center(child: Text(
                                '$badgeCount',
                                style: const TextStyle(
                                  color: TRColors.navyDeep,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                ),
                              )),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),

              // More (Profile)
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(
                              color: TRColors.gold.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(child: Text(
                              context.read<AppState>().currentUser?.name.substring(0, 1) ?? 'U',
                              style: const TextStyle(color: TRColors.gold, fontSize: 10, fontWeight: FontWeight.w800),
                            )),
                          ),
                          // Trial indicator dot
                          if (state.isInTrial)
                            Positioned(
                              top: -2, right: -2,
                              child: Container(
                                width: 8, height: 8,
                                decoration: BoxDecoration(
                                  color: state.trialDaysRemaining <= 3 ? TRColors.error : TRColors.gold,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: TRColors.cardDark, width: 1),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      const Text('Profile', style: TextStyle(color: TRColors.grayMid, fontSize: 10)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

// ─── Trial Expired / No-Plan Gate ─────────────────────────────────────────────
//
// Shown when:
//   • Trial has expired (status == trial, daysRemaining == 0)
//   • Subscription is cancelled
//   • User never selected a plan (status == none)
//
// The user cannot navigate past this screen until they complete checkout
// through PricingScreen.
//
class _TrialExpiredGate extends StatelessWidget {
  final ActiveSubscription subscription;
  const _TrialExpiredGate({required this.subscription});

  bool get _isExpiredTrial =>
      subscription.status == SubscriptionStatus.trial &&
      subscription.trialDaysRemaining <= 0;

  bool get _isCancelled => subscription.status == SubscriptionStatus.cancelled;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TRColors.navyDeep,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 96, height: 96,
                decoration: BoxDecoration(
                  color: TRColors.gold.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: TRColors.gold.withValues(alpha: 0.4), width: 2),
                ),
                child: const Icon(Icons.lock_clock_rounded, color: TRColors.gold, size: 48),
              ),
              const SizedBox(height: 28),

              // Headline
              Text(
                _isCancelled
                    ? 'Subscription Cancelled'
                    : _isExpiredTrial
                        ? 'Your Free Trial Has Ended'
                        : 'Choose a Plan to Continue',
                style: const TextStyle(
                  color: TRColors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Subtext
              Text(
                _isCancelled
                    ? 'Your TradeRep subscription has been cancelled. Reactivate to keep growing your reputation.'
                    : _isExpiredTrial
                        ? 'Your 14-day trial has expired. Choose a plan to continue using TradeRep and keep your jobs and reputation data.'
                        : 'Start your free 14-day trial — no credit card required to begin.',
                style: const TextStyle(
                  color: TRColors.grayLight,
                  fontSize: 15,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // What they'll lose / keep callout
              if (_isExpiredTrial || _isCancelled)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: TRColors.cardDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: TRColors.divider),
                  ),
                  child: Column(
                    children: [
                      _GatePoint(
                        icon: Icons.check_circle_rounded,
                        color: TRColors.success,
                        text: 'All your jobs and photos are safe',
                      ),
                      const SizedBox(height: 8),
                      _GatePoint(
                        icon: Icons.check_circle_rounded,
                        color: TRColors.success,
                        text: 'Your review history is preserved',
                      ),
                      const SizedBox(height: 8),
                      _GatePoint(
                        icon: Icons.pause_circle_rounded,
                        color: TRColors.warning,
                        text: 'New job creation paused until reactivated',
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 32),

              // CTA button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TRColors.gold,
                    foregroundColor: TRColors.navyDeep,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.rocket_launch_rounded, size: 20),
                  label: Text(
                    _isExpiredTrial || _isCancelled
                        ? 'Reactivate — Choose a Plan'
                        : 'Start Free Trial',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PricingScreen(showBackButton: false),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 14),

              // Sign out link
              TextButton(
                onPressed: () => context.read<AppState>().logout(),
                child: const Text(
                  'Sign out',
                  style: TextStyle(color: TRColors.grayMid, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GatePoint extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _GatePoint({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: const TextStyle(
        color: TRColors.grayLight, fontSize: 13,
      ))),
    ]);
  }
}
