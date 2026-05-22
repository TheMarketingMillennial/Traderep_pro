import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/services/app_state.dart';
import '../../shared/widgets/tr_widgets.dart';
import '../../shared/models/models.dart';
import '../pricing/trial_widgets.dart';
import '../pricing/pricing_models.dart';
import 'google_post_sheets.dart';

class ContentScreen extends StatefulWidget {
  const ContentScreen({super.key});

  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final hasContentAccess = FeatureAccess.canAccess(state.subscription.tier, 'content_approval');

    return Scaffold(
      backgroundColor: TRColors.navyDeep,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, state),
            if (!hasContentAccess)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: UpgradePrompt(
                  featureKey: 'content_approval',
                  title: 'Content Approval Dashboard',
                  description: 'Upgrade to Growth to auto-generate posts from your job photos.',
                  icon: Icons.auto_awesome_rounded,
                ),
              ),
            _buildTabs(),
            Expanded(
              child: hasContentAccess
                ? TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPendingTab(context, state),
                      _buildApprovedTab(context, state),
                      _buildPublishedTab(context, state),
                    ],
                  )
                : const _ContentLockedView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Content', style: TextStyle(
                  color: TRColors.white, fontSize: 24, fontWeight: FontWeight.w800,
                )),
                Text(
                  '${state.pendingPosts.length} posts awaiting your approval',
                  style: const TextStyle(color: TRColors.grayLight, fontSize: 13),
                ),
              ],
            ),
          ),
          if (state.googleConnected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: TRColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: TRColors.success.withValues(alpha: 0.4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.business_rounded, color: TRColors.success, size: 14),
                  SizedBox(width: 4),
                  Text('GBP Connected', style: TextStyle(
                    color: TRColors.success, fontSize: 11, fontWeight: FontWeight.w600,
                  )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = ['Pending', 'Approved', 'Published'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final selected = _tabController.index == entry.key;
          return Expanded(child: GestureDetector(
            onTap: () {
              _tabController.animateTo(entry.key);
              setState(() {});
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: selected ? TRColors.gold : TRColors.cardDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: selected ? TRColors.gold : TRColors.divider),
              ),
              child: Text(tabs[entry.key],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? TRColors.navyDeep : TRColors.grayLight,
                  fontSize: 13, fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                )),
            ),
          ));
        }).toList(),
      ),
    );
  }

  Widget _buildPendingTab(BuildContext context, AppState state) {
    final pending = state.posts.where((p) => p.status == ContentStatus.pending).toList();
    if (pending.isEmpty) {
      return const TREmptyState(
        icon: Icons.auto_awesome_outlined,
        title: 'No Pending Posts',
        subtitle: 'AI-generated content from completed jobs will appear here for your review.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: pending.length,
      itemBuilder: (_, i) => _ContentCard(post: pending[i], isEditable: true),
    );
  }

  Widget _buildApprovedTab(BuildContext context, AppState state) {
    final approved = state.posts.where((p) => p.status == ContentStatus.approved).toList();
    if (approved.isEmpty) {
      return const TREmptyState(
        icon: Icons.check_circle_outline_rounded,
        title: 'No Approved Posts',
        subtitle: 'Posts you approve will appear here, ready to be published to Google.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: approved.length,
      itemBuilder: (_, i) => _ContentCard(post: approved[i], isEditable: false, showPublish: true),
    );
  }

  Widget _buildPublishedTab(BuildContext context, AppState state) {
    final published = state.posts.where((p) => p.status == ContentStatus.published).toList();
    if (published.isEmpty) {
      return const TREmptyState(
        icon: Icons.public_rounded,
        title: 'No Published Posts',
        subtitle: 'Published posts will be tracked here with engagement metrics.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: published.length,
      itemBuilder: (_, i) => _ContentCard(post: published[i], isEditable: false),
    );
  }
}

class _ContentCard extends StatefulWidget {
  final ContentPost post;
  final bool isEditable;
  final bool showPublish;

  const _ContentCard({required this.post, this.isEditable = false, this.showPublish = false});

  @override
  State<_ContentCard> createState() => _ContentCardState();
}

class _ContentCardState extends State<_ContentCard> {
  bool _expanded = false;
  late TextEditingController _captionCtrl;

  @override
  void initState() {
    super.initState();
    _captionCtrl = TextEditingController(text: widget.post.suggestedCaption);
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: TRColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(children: [
              const Icon(Icons.auto_awesome_rounded, color: TRColors.gold, size: 16),
              const SizedBox(width: 6),
              const Expanded(child: Text('AI-Generated Post', style: TextStyle(
                color: TRColors.gold, fontSize: 12, fontWeight: FontWeight.w600,
              ))),
              _statusBadge(widget.post.status),
            ]),
          ),

          // Before/After Photos
          ClipRRect(
            borderRadius: BorderRadius.zero,
            child: SizedBox(
              height: 160,
              child: Row(
                children: [
                  Expanded(child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(widget.post.beforePhotoUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: TRColors.cardMid,
                          child: const Icon(Icons.photo_rounded, color: TRColors.grayMid, size: 40),
                        )),
                      Positioned(top: 8, left: 8, child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54, borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('BEFORE', style: TextStyle(
                          color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5,
                        )),
                      )),
                    ],
                  )),
                  const SizedBox(width: 2),
                  Expanded(child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(widget.post.afterPhotoUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: TRColors.cardMid,
                          child: const Icon(Icons.photo_rounded, color: TRColors.grayMid, size: 40),
                        )),
                      Positioned(top: 8, left: 8, child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: TRColors.gold.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('AFTER', style: TextStyle(
                          color: TRColors.navyDeep, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5,
                        )),
                      )),
                    ],
                  )),
                ],
              ),
            ),
          ),

          // Caption
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CAPTION', style: TextStyle(
                  color: TRColors.grayMid, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8,
                )),
                const SizedBox(height: 6),
                widget.isEditable
                  ? TextField(
                      controller: _captionCtrl,
                      maxLines: 3,
                      style: const TextStyle(color: TRColors.white, fontSize: 13, height: 1.5),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: TRColors.cardMid,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: TRColors.divider)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: TRColors.divider)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: TRColors.gold, width: 1.5)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    )
                  : Text(widget.post.suggestedCaption, style: const TextStyle(
                      color: TRColors.white, fontSize: 13, height: 1.5,
                    ), maxLines: _expanded ? null : 3,
                    overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis),

                const SizedBox(height: 10),
                // Hashtags
                Wrap(
                  spacing: 6, runSpacing: 4,
                  children: widget.post.suggestedHashtags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: TRColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: TRColors.info.withValues(alpha: 0.3)),
                    ),
                    child: Text(tag, style: const TextStyle(
                      color: TRColors.info, fontSize: 11, fontWeight: FontWeight.w500,
                    )),
                  )).toList(),
                ),

                if (widget.isEditable) ...[
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: GestureDetector(
                      onTap: () {
                        state.updatePostStatus(widget.post.id, ContentStatus.rejected);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Post rejected'), backgroundColor: TRColors.error,
                        ));
                      },
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: TRColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: TRColors.error.withValues(alpha: 0.4)),
                        ),
                        child: const Center(child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.close_rounded, color: TRColors.error, size: 16),
                            SizedBox(width: 4),
                            Text('Reject', style: TextStyle(color: TRColors.error, fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        )),
                      ),
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: GestureDetector(
                      onTap: () {
                        state.updatePostStatus(widget.post.id, ContentStatus.approved);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Post approved! Ready to publish.'), backgroundColor: TRColors.success,
                        ));
                      },
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: TRColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: TRColors.success.withValues(alpha: 0.4)),
                        ),
                        child: const Center(child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_rounded, color: TRColors.success, size: 16),
                            SizedBox(width: 4),
                            Text('Approve', style: TextStyle(color: TRColors.success, fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        )),
                      ),
                    )),
                  ]),
                ],

                if (widget.showPublish) ...[
                  const SizedBox(height: 14),
                  GoldButton(
                    label: 'Publish to Google Business Profile',
                    icon: Icons.business_rounded,
                    compact: true,
                    onTap: () => showPublishSheet(context, post: widget.post),
                  ),
                  const SizedBox(height: 8),
                  GoldButton(
                    label: 'Schedule for Later',
                    icon: Icons.schedule_rounded,
                    outlined: true,
                    compact: true,
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Scheduling feature coming soon'), backgroundColor: TRColors.navyMid),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color get _borderColor {
    switch (widget.post.status) {
      case ContentStatus.pending: return TRColors.warning.withValues(alpha: 0.4);
      case ContentStatus.approved: return TRColors.success.withValues(alpha: 0.3);
      case ContentStatus.rejected: return TRColors.error.withValues(alpha: 0.3);
      case ContentStatus.published: return TRColors.info.withValues(alpha: 0.3);
      default: return TRColors.divider;
    }
  }

  Widget _statusBadge(ContentStatus status) {
    final configs = {
      ContentStatus.pending: (TRColors.warning, 'PENDING REVIEW'),
      ContentStatus.approved: (TRColors.success, 'APPROVED'),
      ContentStatus.rejected: (TRColors.error, 'REJECTED'),
      ContentStatus.published: (TRColors.info, 'PUBLISHED'),
      ContentStatus.scheduled: (TRColors.statusLead, 'SCHEDULED'),
    };
    final cfg = configs[status] ?? (TRColors.grayMid, 'UNKNOWN');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cfg.$1.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(cfg.$2, style: TextStyle(
        color: cfg.$1, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.4,
      )),
    );
  }
}

// Locked view shown to Starter plan users in Content tab
class _ContentLockedView extends StatelessWidget {
  const _ContentLockedView();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        children: [
          // Preview card (dimmed)
          Opacity(
            opacity: 0.3,
            child: Container(
              decoration: BoxDecoration(
                color: TRColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: TRColors.warning.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                    child: Row(children: [
                      const Icon(Icons.auto_awesome_rounded, color: TRColors.gold, size: 16),
                      const SizedBox(width: 6),
                      const Expanded(child: Text('AI-Generated Post', style: TextStyle(
                        color: TRColors.gold, fontSize: 12, fontWeight: FontWeight.w600,
                      ))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: TRColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text('PENDING REVIEW', style: TextStyle(
                          color: TRColors.warning, fontSize: 9, fontWeight: FontWeight.w800,
                        )),
                      ),
                    ]),
                  ),
                  Container(
                    height: 120,
                    color: TRColors.cardMid,
                    child: const Center(child: Icon(Icons.photo_rounded, color: TRColors.grayMid, size: 48)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 10, decoration: BoxDecoration(
                          color: TRColors.grayMid, borderRadius: BorderRadius.circular(4),
                        )),
                        const SizedBox(height: 6),
                        Container(height: 10, width: 200, decoration: BoxDecoration(
                          color: TRColors.grayMid, borderRadius: BorderRadius.circular(4),
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Feature highlights
          _ContentFeatureCard(
            icon: Icons.auto_awesome_rounded,
            title: 'AI Post Generation',
            desc: 'Every completed job automatically becomes a Google-ready before/after post.',
          ),
          const SizedBox(height: 10),
          _ContentFeatureCard(
            icon: Icons.edit_note_rounded,
            title: 'Caption Editing',
            desc: 'Review, edit, and approve AI captions before they go live on your Google profile.',
          ),
          const SizedBox(height: 10),
          _ContentFeatureCard(
            icon: Icons.schedule_rounded,
            title: 'Scheduling',
            desc: 'Schedule posts for optimal times. Stay active on Google without extra work.',
          ),
          const SizedBox(height: 10),
          _ContentFeatureCard(
            icon: Icons.share_rounded,
            title: 'Social-Ready Images',
            desc: 'Export branded before/after cards for Instagram, Facebook, and more.',
          ),
        ],
      ),
    );
  }
}

class _ContentFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  const _ContentFeatureCard({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TRColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TRColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: TRColors.goldDim,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: TRColors.gold, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(
                  color: TRColors.white, fontSize: 13, fontWeight: FontWeight.w700,
                )),
                const SizedBox(height: 3),
                Text(desc, style: const TextStyle(
                  color: TRColors.grayLight, fontSize: 12, height: 1.4,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
