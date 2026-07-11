import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/services/app_state.dart';
import '../../shared/services/gbp_auth_service.dart';
import '../../shared/widgets/tr_widgets.dart';
import '../../shared/models/models.dart';
import '../pricing/trial_widgets.dart';
import '../photos/photo_approval_screen.dart';
import '../profile/profile_screen.dart';
import '../jobs/job_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  final void Function(int)? onSwitchTab;
  const DashboardScreen({super.key, this.onSwitchTab});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.currentUser;
    final company = state.company;
    return Scaffold(
      backgroundColor: TRColors.navyDeep,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context, user, company, state)),
            SliverToBoxAdapter(child: TrialBanner()),
            SliverToBoxAdapter(child: _buildGoogleBanner(context, state)),
            SliverToBoxAdapter(child: _buildStats(state)),
            SliverToBoxAdapter(child: _buildPendingContent(context, state)),
            SliverToBoxAdapter(child: _buildPendingPhotos(context, state)),
            SliverToBoxAdapter(child: _buildRecentJobs(context, state)),
            SliverToBoxAdapter(child: _buildTeamActivity(context, state)),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TRUser? user, Company? company, AppState state) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$greeting,', style: const TextStyle(
                  color: TRColors.grayLight, fontSize: 14,
                )),
                Text(user?.name.split(' ').first ?? 'there', style: const TextStyle(
                  color: TRColors.white, fontSize: 22, fontWeight: FontWeight.w800,
                )),
                Row(children: [
                  Container(
                    width: 6, height: 6,
                    decoration: const BoxDecoration(color: TRColors.success, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Text(company?.name ?? '', style: const TextStyle(
                    color: TRColors.grayLight, fontSize: 12,
                  )),
                ]),
              ],
            ),
          ),
          Row(
            children: [
              // Plan badge in header
              const PlanBadge(),
              const SizedBox(width: 8),
              // Pending badge
              Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      if (state.pendingSubmissions.isNotEmpty || state.pendingPosts.isNotEmpty) {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const PhotoApprovalScreen(),
                        ));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('No pending notifications'),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ));
                      }
                    },
                    icon: const Icon(Icons.notifications_outlined, color: TRColors.white, size: 24),
                  ),
                  if (state.pendingPosts.isNotEmpty)
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        width: 16, height: 16,
                        decoration: const BoxDecoration(color: TRColors.gold, shape: BoxShape.circle),
                        child: Center(
                          child: Text('${state.pendingPosts.length}', style: const TextStyle(
                            color: TRColors.navyDeep, fontSize: 9, fontWeight: FontWeight.w800,
                          )),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
                )),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: TRColors.gold.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: TRColors.gold.withValues(alpha: 0.4)),
                  ),
                  child: Center(child: Text(
                    user?.name.substring(0, 1) ?? 'U',
                    style: const TextStyle(color: TRColors.gold, fontSize: 16, fontWeight: FontWeight.w800),
                  )),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  void _showGbpConnectSheet(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: TRColors.cardDark,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _GbpConnectSheet(state: state),
    );
  }

  Widget _buildGoogleBanner(BuildContext context, AppState state) {
    if (state.googleConnected) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TRColors.goldDim,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TRColors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.business_rounded, color: TRColors.gold, size: 20),
          const SizedBox(width: 10),
          const Expanded(child: Text(
            'Connect Google Business Profile to start posting',
            style: TextStyle(color: TRColors.gold, fontSize: 13, fontWeight: FontWeight.w600),
          )),
          TextButton(
            onPressed: () => _showGbpConnectSheet(context, state),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              backgroundColor: TRColors.gold,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Setup', style: TextStyle(color: TRColors.navyDeep, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(AppState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Your Activity'),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              TRStatCard(
                label: 'Jobs Completed',
                value: '${state.completedJobsCount}',
                icon: Icons.check_circle_rounded,
                accentColor: TRColors.success,
                onTap: () => onSwitchTab?.call(1),
              ),
              TRStatCard(
                label: 'Reviews Sent',
                value: '${state.reviewsSentCount}',
                icon: Icons.star_rounded,
                accentColor: TRColors.gold,
                onTap: () => onSwitchTab?.call(1),
              ),
              TRStatCard(
                label: 'Photos Uploaded',
                value: '${state.photosUploadedCount}',
                icon: Icons.photo_library_rounded,
                accentColor: TRColors.info,
                onTap: () => onSwitchTab?.call(2),
              ),
              TRStatCard(
                label: 'Google Posts',
                value: '${state.googlePostsCount}',
                icon: Icons.business_rounded,
                accentColor: TRColors.statusLead,
                onTap: () => onSwitchTab?.call(3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingContent(BuildContext context, AppState state) {
    final pending = state.pendingPosts;
    if (pending.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SectionHeader(title: 'Content Pending Review'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: TRColors.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${pending.length} waiting', style: const TextStyle(
                  color: TRColors.warning, fontSize: 11, fontWeight: FontWeight.w600,
                )),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...pending.map((post) => _ContentPreviewCard(post: post)),
        ],
      ),
    );
  }

  Widget _buildPendingPhotos(BuildContext context, AppState state) {
    if (!state.canApprovePhotos) return const SizedBox.shrink();
    final pending = state.pendingSubmissions;
    if (pending.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SectionHeader(title: 'Photos Pending Approval'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: TRColors.info.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${pending.length} waiting', style: const TextStyle(
                  color: TRColors.info, fontSize: 11, fontWeight: FontWeight.w600,
                )),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...pending.take(2).map((sub) => _PhotoSubmissionPreviewCard(submission: sub)),
          if (pending.length > 2)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+${pending.length - 2} more — open Photos tab to review',
                style: const TextStyle(color: TRColors.grayMid, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentJobs(BuildContext context, AppState state) {
    final jobs = state.jobs.take(3).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Active Jobs',
            action: 'View All',
            onAction: () => onSwitchTab?.call(1),
          ),
          const SizedBox(height: 12),
          ...jobs.map((job) => JobCard(
            job: job,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTeamActivity(BuildContext context, AppState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Team Activity',
            action: 'Manage',
            onAction: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const ProfileScreen(),
            )),
          ),
          const SizedBox(height: 12),
          ...state.team.take(4).map((member) => _TeamMemberTile(user: member)),
        ],
      ),
    );
  }
}

class _ContentPreviewCard extends StatelessWidget {
  final ContentPost post;
  const _ContentPreviewCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TRColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TRColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: TRColors.gold, size: 16),
              const SizedBox(width: 6),
              const Expanded(child: Text('AI-Generated Content Ready', style: TextStyle(
                color: TRColors.gold, fontSize: 13, fontWeight: FontWeight.w600,
              ))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: TRColors.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('PENDING', style: TextStyle(
                  color: TRColors.warning, fontSize: 10, fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                )),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Before/After preview
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 90,
              child: Row(
                children: [
                  Expanded(child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(post.beforePhotoUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: TRColors.cardMid,
                          child: const Icon(Icons.photo_rounded, color: TRColors.grayMid)),
                      ),
                      Positioned(bottom: 4, left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('BEFORE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  )),
                  const SizedBox(width: 2),
                  Expanded(child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(post.afterPhotoUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: TRColors.cardMid,
                          child: const Icon(Icons.photo_rounded, color: TRColors.grayMid)),
                      ),
                      Positioned(bottom: 4, left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: TRColors.gold.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('AFTER', style: TextStyle(color: TRColors.navyDeep, fontSize: 9, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            post.suggestedCaption,
            style: const TextStyle(color: TRColors.grayLight, fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: GestureDetector(
                onTap: () {
                  state.updatePostStatus(post.id, ContentStatus.rejected);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Post rejected'), backgroundColor: TRColors.error),
                  );
                },
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: TRColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: TRColors.error.withValues(alpha: 0.3)),
                  ),
                  child: const Center(child: Text('Reject', style: TextStyle(
                    color: TRColors.error, fontSize: 13, fontWeight: FontWeight.w600,
                  ))),
                ),
              )),
              const SizedBox(width: 8),
              Expanded(child: GestureDetector(
                onTap: () {
                  state.updatePostStatus(post.id, ContentStatus.approved);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Post approved for publishing!'), backgroundColor: TRColors.success),
                  );
                },
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: TRColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: TRColors.success.withValues(alpha: 0.4)),
                  ),
                  child: const Center(child: Text('Approve', style: TextStyle(
                    color: TRColors.success, fontSize: 13, fontWeight: FontWeight.w600,
                  ))),
                ),
              )),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhotoSubmissionPreviewCard extends StatelessWidget {
  final PhotoSubmission submission;
  const _PhotoSubmissionPreviewCard({required this.submission});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PhotoApprovalScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: TRColors.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: TRColors.info.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: TRColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.photo_library_rounded, color: TRColors.info, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(submission.jobName, style: const TextStyle(
                color: TRColors.white, fontSize: 14, fontWeight: FontWeight.w600,
              )),
              const SizedBox(height: 3),
              Text(
                '${submission.photos.length} photo${submission.photos.length == 1 ? '' : 's'} · by ${submission.submittedByName}',
                style: const TextStyle(color: TRColors.grayMid, fontSize: 12),
              ),
            ],
          )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: TRColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('REVIEW', style: TextStyle(
              color: TRColors.warning, fontSize: 10, fontWeight: FontWeight.w800,
            )),
          ),
        ]),
      ),
    );
  }
}

class _TeamMemberTile extends StatelessWidget {
  final TRUser user;
  const _TeamMemberTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  color: TRColors.navyLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: TRColors.divider),
                ),
                child: Center(child: Text(
                  user.name.substring(0, 1),
                  style: const TextStyle(color: TRColors.gold, fontSize: 15, fontWeight: FontWeight.w700),
                )),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name, style: const TextStyle(
                    color: TRColors.white, fontSize: 14, fontWeight: FontWeight.w600,
                  )),
                  RoleBadge(role: user.role),
                ],
              )),
              Row(children: [
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(color: TRColors.success, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: TRColors.grayMid.withValues(alpha: 0.5), size: 12),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}


// ─── GBP OAuth Connect Sheet ──────────────────────────────────────────────────
// One-tap Google Sign-In. No Location ID hunting required.
// Flow: tap button → browser opens Google consent → Railway callback stores
// tokens → this sheet polls /gbp/status and updates UI when done.
class _GbpConnectSheet extends StatefulWidget {
  final AppState state;
  const _GbpConnectSheet({required this.state});

  @override
  State<_GbpConnectSheet> createState() => _GbpConnectSheetState();
}

enum _GbpSheetState { idle, waiting, connected, error }

class _GbpConnectSheetState extends State<_GbpConnectSheet> {
  _GbpSheetState _phase = _GbpSheetState.idle;
  String? _locationName;
  String? _errorMsg;

  Future<void> _startOAuth() async {
    final companyId = widget.state.company?.id;
    if (companyId == null || companyId.isEmpty) {
      setState(() {
        _phase    = _GbpSheetState.error;
        _errorMsg = 'Company not loaded. Please sign out and back in.';
      });
      return;
    }

    setState(() => _phase = _GbpSheetState.waiting);

    await GbpAuthService.instance.startOAuthFlow(
      companyId: companyId,
      onBrowserOpened: () {
        // Browser opened — keep showing the waiting spinner
        if (mounted) setState(() => _phase = _GbpSheetState.waiting);
      },
      onConnected: (result) {
        if (!mounted) return;
        // Tell AppState — updates googleConnected + gbpLocationId in memory + Firestore
        widget.state.connectGoogleViaOAuth(result);
        setState(() {
          _phase        = _GbpSheetState.connected;
          _locationName = result.locationName ?? result.locationId;
        });
        // Auto-dismiss after success
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      },
      onError: (err) {
        if (!mounted) return;
        setState(() {
          _phase    = _GbpSheetState.error;
          _errorMsg = err;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 36,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: TRColors.divider, borderRadius: BorderRadius.circular(2)),
          )),
          const SizedBox(height: 24),

          // Icon
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _phase == _GbpSheetState.connected
              ? Container(
                  key: const ValueKey('check'),
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: TRColors.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: TRColors.success.withValues(alpha: 0.4)),
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: TRColors.success, size: 36),
                )
              : Container(
                  key: const ValueKey('gbp'),
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: TRColors.gold.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                    border: Border.all(color: TRColors.gold.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.business_rounded, color: TRColors.gold, size: 32),
                ),
          ),
          const SizedBox(height: 16),

          // Title + subtitle
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _phase == _GbpSheetState.connected
              ? Column(key: const ValueKey('done'), children: [
                  const Text('Connected!', style: TextStyle(
                    color: TRColors.success, fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(
                    _locationName != null
                      ? 'Your profile "$_locationName" is now linked.'
                      : 'Google Business Profile linked.',
                    style: const TextStyle(color: TRColors.grayLight, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ])
              : Column(key: const ValueKey('title'), children: [
                  const Text('Connect Google Business Profile', style: TextStyle(
                    color: TRColors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  const Text(
                    'Sign in with Google to link your Business Profile.\nNo technical steps — just one tap.',
                    style: TextStyle(color: TRColors.grayLight, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ]),
          ),
          const SizedBox(height: 24),

          // What gets connected info card (idle only)
          if (_phase == _GbpSheetState.idle) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: TRColors.cardMid,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TRColors.divider),
              ),
              child: Column(
                children: [
                  _OAuthPermRow(Icons.photo_camera_rounded,   'Upload project photos to your listing'),
                  const Divider(color: TRColors.divider, height: 16),
                  _OAuthPermRow(Icons.post_add_rounded,       'Publish approved posts to Google'),
                  const Divider(color: TRColors.divider, height: 16),
                  _OAuthPermRow(Icons.star_rounded,           'Access your Google review link'),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Waiting state
          if (_phase == _GbpSheetState.waiting) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TRColors.cardMid,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TRColors.gold.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                    color: TRColors.gold, strokeWidth: 2.5,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Waiting for Google approval…', style: TextStyle(
                      color: TRColors.gold, fontSize: 13, fontWeight: FontWeight.w700)),
                    SizedBox(height: 3),
                    Text('Complete sign-in in your browser, then return here.',
                      style: TextStyle(color: TRColors.grayMid, fontSize: 12)),
                  ],
                )),
              ]),
            ),
            const SizedBox(height: 20),
          ],

          // Error state
          if (_phase == _GbpSheetState.error && _errorMsg != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: TRColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TRColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline_rounded, color: TRColors.error, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(_errorMsg!, style: const TextStyle(
                  color: TRColors.error, fontSize: 13))),
              ]),
            ),
            const SizedBox(height: 20),
          ],

          // Primary action button
          if (_phase != _GbpSheetState.connected) SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: TRColors.gold,
                foregroundColor: TRColors.navyDeep,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: _phase == _GbpSheetState.waiting ? null : _startOAuth,
              icon: _phase == _GbpSheetState.waiting
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(color: TRColors.navyDeep, strokeWidth: 2.5),
                  )
                : const Icon(Icons.login_rounded, size: 20),
              label: Text(
                _phase == _GbpSheetState.error
                  ? 'Try Again'
                  : _phase == _GbpSheetState.waiting
                    ? 'Waiting for browser…'
                    : 'Sign in with Google',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (_phase != _GbpSheetState.connected)
            Center(child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: TRColors.grayMid, fontSize: 14)),
            )),
        ],
      ),
    );
  }
}

class _OAuthPermRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _OAuthPermRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: TRColors.gold, size: 16),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: const TextStyle(color: TRColors.grayLight, fontSize: 13))),
      const Icon(Icons.check_rounded, color: TRColors.success, size: 16),
    ]);
  }
}
