import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/services/app_state.dart';
import '../../shared/services/ai_service.dart';
import '../../shared/widgets/tr_widgets.dart';
import '../../shared/models/models.dart';

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
    // Single plan — content approval always accessible


    return Scaffold(
      backgroundColor: TRColors.navyDeep,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, state),

            _buildTabs(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPendingTab(context, state),
                  _buildApprovedTab(context, state),
                  _buildPublishedTab(context, state),
                ],
              ),
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
  // ignore: prefer_final_fields — may add expand toggle in future
  bool _expanded = false;
  bool _regenerating = false;
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

  Future<void> _handleRegenerate(BuildContext context, AppState state) async {
    setState(() => _regenerating = true);
    final messenger = ScaffoldMessenger.of(context); // capture before async gap
    final company = state.company;
    final posts   = await state.getRecentGbpPosts();
    final summaries = posts.map((p) => {
      'opening':  p['opening_line'] ?? '',
      'closing':  p['closing_line'] ?? '',
      'hashtags': (p['hashtags'] as List<dynamic>?)?.join(' ') ?? '',
    }).toList();
    final result = await AiService.generateCaption(
      jobType:               widget.post.projectSummary,
      companyName:           company?.name ?? '',
      trade:                 company?.tradeCategory ?? '',
      serviceArea:           company?.serviceArea ?? '',
      brandVoice:            company?.brandVoice,
      season:                AiService.currentSeason,
      previousPostSummaries: summaries,
    );
    if (!mounted) return;
    setState(() => _regenerating = false);
    if (result != null) {
      _captionCtrl.text = result.caption;
      state.replacePost(ContentPost(
        id: widget.post.id, jobId: widget.post.jobId,
        beforePhotoUrl: widget.post.beforePhotoUrl, afterPhotoUrl: widget.post.afterPhotoUrl,
        suggestedCaption: result.caption, suggestedHashtags: result.hashtags,
        projectSummary: widget.post.projectSummary, status: widget.post.status,
        scheduledFor: widget.post.scheduledFor, createdAt: widget.post.createdAt,
        sourceSubmissionId: widget.post.sourceSubmissionId, companyId: widget.post.companyId,
      ));
    } else {
      messenger.showSnackBar(const SnackBar(
        content: Text('AI unavailable. Check Railway server.'),
        backgroundColor: TRColors.warning,
      ));
    }
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
                  const SizedBox(height: 10),
                  // Regenerate button
                  GestureDetector(
                    onTap: _regenerating ? null : () => _handleRegenerate(context, state),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: TRColors.gold.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: TRColors.gold.withValues(alpha: 0.4)),
                      ),
                      child: Center(child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_regenerating)
                            const SizedBox(width: 14, height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: TRColors.gold))
                          else
                            const Icon(Icons.refresh_rounded, color: TRColors.gold, size: 15),
                          const SizedBox(width: 6),
                          Text(_regenerating ? 'Regenerating…' : 'Regenerate Caption',
                            style: const TextStyle(color: TRColors.gold, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      )),
                    ),
                  ),
                  const SizedBox(height: 10),
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


