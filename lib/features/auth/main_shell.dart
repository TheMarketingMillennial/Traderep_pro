import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/services/app_state.dart';
import '../dashboard/dashboard_screen.dart';
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

  final List<Widget> _screens = const [
    DashboardScreen(),
    JobsScreen(),
    PhotosScreen(),
    ContentScreen(),
    ReviewsScreen(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _NavItem(icon: Icons.work_rounded, label: 'Jobs'),
    _NavItem(icon: Icons.camera_alt_rounded, label: 'Photos'),
    _NavItem(icon: Icons.auto_awesome_rounded, label: 'Content'),
    _NavItem(icon: Icons.star_rounded, label: 'Reviews'),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

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

                // Badge for content pending
                final showBadge = i == 3 && state.pendingPosts.isNotEmpty;

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
                              decoration: const BoxDecoration(
                                color: TRColors.gold,
                                shape: BoxShape.circle,
                              ),
                              child: Center(child: Text(
                                '${state.pendingPosts.length}',
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
