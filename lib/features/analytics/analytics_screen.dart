import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/services/app_state.dart';
import '../../shared/widgets/tr_widgets.dart';
import '../../shared/models/models.dart';
import '../pricing/trial_widgets.dart';
import '../pricing/pricing_models.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final analytics = state.analytics;
    final tier = state.subscription.tier;
    final canAdvanced = FeatureAccess.canAccess(tier, 'advanced_analytics');
    final canCrew = FeatureAccess.canAccess(tier, 'crew_performance');
    final canReputation = FeatureAccess.canAccess(tier, 'reputation_scoring');

    return Scaffold(
      backgroundColor: TRColors.navyDeep,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildKPIs(state)),
            SliverToBoxAdapter(child: _buildChart(analytics)),
            SliverToBoxAdapter(child: _buildReviewFunnel(state)),
            // Crew Performance — locked for Starter
            SliverToBoxAdapter(
              child: canCrew
                ? _buildTopPerformers(state)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: LockedFeatureGate(
                      featureKey: 'crew_performance',
                      child: _buildTopPerformers(state),
                    ),
                  ),
            ),
            // Google Activity — locked for Starter
            SliverToBoxAdapter(
              child: canAdvanced
                ? _buildGoogleActivity(state)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: LockedFeatureGate(
                      featureKey: 'advanced_analytics',
                      child: _buildGoogleActivity(state),
                    ),
                  ),
            ),
            // Reputation Score — Pro only
            SliverToBoxAdapter(
              child: canReputation
                ? _buildReputationScore()
                : Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: LockedFeatureGate(
                      featureKey: 'reputation_scoring',
                      child: _buildReputationScore(),
                    ),
                  ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildReputationScore() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TRColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TRColors.gold.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.shield_rounded, color: TRColors.gold, size: 20),
                SizedBox(width: 8),
                Text('Reputation Score', style: TextStyle(
                  color: TRColors.white, fontSize: 15, fontWeight: FontWeight.w700,
                )),
                Spacer(),
                Text('PRO', style: TextStyle(
                  color: TRColors.gold, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8,
                )),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: TRColors.gold, width: 3),
                    color: TRColors.goldDim,
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('94', style: TextStyle(
                        color: TRColors.gold, fontSize: 24, fontWeight: FontWeight.w900,
                      )),
                      Text('/100', style: TextStyle(
                        color: TRColors.grayMid, fontSize: 10,
                      )),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      _ScoreRow(label: 'Review Velocity', score: 0.92, color: TRColors.success),
                      const SizedBox(height: 6),
                      _ScoreRow(label: 'Photo Quality', score: 0.88, color: TRColors.info),
                      const SizedBox(height: 6),
                      _ScoreRow(label: 'Response Rate', score: 0.96, color: TRColors.gold),
                      const SizedBox(height: 6),
                      _ScoreRow(label: 'GBP Activity', score: 0.85, color: TRColors.statusLead),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          const Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Analytics', style: TextStyle(
                color: TRColors.white, fontSize: 24, fontWeight: FontWeight.w800,
              )),
              Text('All time performance overview', style: TextStyle(
                color: TRColors.grayLight, fontSize: 14,
              )),
            ],
          )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: TRColors.cardDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: TRColors.divider),
            ),
            child: const Row(
              children: [
                Icon(Icons.calendar_today_rounded, color: TRColors.gold, size: 14),
                SizedBox(width: 6),
                Text('Last 6 months', style: TextStyle(
                  color: TRColors.grayLight, fontSize: 12, fontWeight: FontWeight.w600,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPIs(AppState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
        children: [
          TRStatCard(
            label: 'Projects Completed',
            value: '${state.completedJobsCount}',
            icon: Icons.check_circle_rounded,
            accentColor: TRColors.success,
          ),
          TRStatCard(
            label: 'Reviews Sent',
            value: '${state.reviewsSentCount}',
            icon: Icons.star_rounded,
            accentColor: TRColors.gold,
          ),
          TRStatCard(
            label: 'Photos Uploaded',
            value: '${state.photosUploadedCount}',
            icon: Icons.photo_camera_rounded,
            accentColor: TRColors.info,
          ),
          TRStatCard(
            label: 'Google Posts',
            value: '${state.googlePostsCount}',
            icon: Icons.business_center_rounded,
            accentColor: TRColors.statusLead,
          ),
        ],
      ),
    );
  }

  Widget _buildChart(AnalyticsSummary analytics) {
    final data = analytics.monthlyData;
    if (data.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Center(child: Text('No data yet — complete jobs to see your chart',
            style: TextStyle(color: TRColors.grayMid, fontSize: 13))),
      );
    }
    final maxJobs = data.map((d) => d.jobs).reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TRColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TRColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text('Monthly Performance', style: TextStyle(
                  color: TRColors.white, fontSize: 15, fontWeight: FontWeight.w700,
                )),
                Spacer(),
                _LegendDot(color: TRColors.gold, label: 'Jobs'),
                SizedBox(width: 12),
                _LegendDot(color: TRColors.info, label: 'Reviews'),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 140,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: data.map((month) {
                  final jobHeight = maxJobs > 0 ? (month.jobs / maxJobs) * 110 : 0.0;
                  final reviewHeight = maxJobs > 0 ? (month.reviews / maxJobs) * 110 : 0.0;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 12,
                                height: jobHeight,
                                decoration: BoxDecoration(
                                  color: TRColors.gold,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Container(
                                width: 12,
                                height: reviewHeight,
                                decoration: BoxDecoration(
                                  color: TRColors.info,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(month.month, style: const TextStyle(
                            color: TRColors.grayMid, fontSize: 10,
                          )),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewFunnel(AppState state) {
    final sent = state.reviewsSentCount;
    // Only compute funnel ratios when we have real data;
    // otherwise everything is 0 so bars stay empty.
    final opened = sent > 0 ? (sent * 0.85).round() : 0;
    final clicked = sent > 0 ? (sent * 0.68).round() : 0;
    final reviewed = sent;
    final rate = sent > 0 ? reviewed / sent : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TRColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TRColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('Review Funnel', style: TextStyle(
                color: TRColors.white, fontSize: 15, fontWeight: FontWeight.w700,
              )),
              const Spacer(),
              Text(sent > 0 ? '${(rate * 100).round()}% response rate' : 'No requests yet', style: const TextStyle(
                color: TRColors.success, fontSize: 12, fontWeight: FontWeight.w600,
              )),
            ]),
            const SizedBox(height: 16),
            _FunnelRow(label: 'Requests Sent', count: sent, total: sent, color: TRColors.info),
            const SizedBox(height: 8),
            _FunnelRow(label: 'Opened', count: opened, total: sent, color: TRColors.statusLead),
            const SizedBox(height: 8),
            _FunnelRow(label: 'Clicked Link', count: clicked, total: sent, color: TRColors.warning),
            const SizedBox(height: 8),
            _FunnelRow(label: 'Left Review', count: reviewed, total: sent, color: TRColors.success),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPerformers(AppState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TRColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TRColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Top Crew Members', style: TextStyle(
              color: TRColors.white, fontSize: 15, fontWeight: FontWeight.w700,
            )),
            const SizedBox(height: 14),
            ...state.team.take(3).toList().asMap().entries.map((entry) {
              final rank = entry.key + 1;
              final user = entry.value;
              final photoCount = [34, 28, 19][entry.key];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(
                        color: rank == 1 ? TRColors.goldDim : TRColors.cardMid,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: rank == 1 ? TRColors.gold : TRColors.divider,
                        ),
                      ),
                      child: Center(child: Text('$rank', style: TextStyle(
                        color: rank == 1 ? TRColors.gold : TRColors.grayMid,
                        fontSize: 11, fontWeight: FontWeight.w800,
                      ))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(user.name, style: const TextStyle(
                      color: TRColors.white, fontSize: 14, fontWeight: FontWeight.w600,
                    ))),
                    Text('$photoCount photos', style: const TextStyle(
                      color: TRColors.grayLight, fontSize: 12,
                    )),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleActivity(AppState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TRColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TRColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.business_rounded, color: TRColors.info, size: 20),
                SizedBox(width: 8),
                Text('Google Business Activity', style: TextStyle(
                  color: TRColors.white, fontSize: 15, fontWeight: FontWeight.w700,
                )),
              ],
            ),
            const SizedBox(height: 14),
            _GoogleStat(label: 'Posts Published', value: '${state.googlePostsCount}', icon: Icons.post_add_rounded, color: TRColors.info),
            const SizedBox(height: 10),
            _GoogleStat(label: 'Photos Uploaded to GBP', value: '${state.photosUploadedCount}', icon: Icons.photo_rounded, color: TRColors.statusLead),
            const SizedBox(height: 10),
            _GoogleStat(label: 'Profile Views (est.)', value: '1,284', icon: Icons.visibility_rounded, color: TRColors.success),
            const SizedBox(height: 10),
            _GoogleStat(label: 'Avg Rating', value: '4.8 ★', icon: Icons.star_rounded, color: TRColors.gold),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: TRColors.grayLight, fontSize: 11)),
    ]);
  }
}

class _FunnelRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _FunnelRow({required this.label, required this.count, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? count / total : 0.0;
    return Row(
      children: [
        SizedBox(width: 100, child: Text(label, style: const TextStyle(color: TRColors.grayLight, fontSize: 12))),
        Expanded(child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: TRColors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        )),
        const SizedBox(width: 8),
        Text('$count', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _GoogleStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _GoogleStat({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 10),
      Expanded(child: Text(label, style: const TextStyle(color: TRColors.grayLight, fontSize: 13))),
      Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700)),
    ]);
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final double score;
  final Color color;

  const _ScoreRow({required this.label, required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: const TextStyle(color: TRColors.grayLight, fontSize: 11)),
        ),
        Expanded(child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: score,
            backgroundColor: TRColors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        )),
        const SizedBox(width: 6),
        Text('${(score * 100).round()}', style: TextStyle(
          color: color, fontSize: 11, fontWeight: FontWeight.w700,
        )),
      ],
    );
  }
}
