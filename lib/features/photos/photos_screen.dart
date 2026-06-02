// photos_screen.dart — TradeRep Pro
// Role-based photo hub:
//   All roles  → "Submit" tab (capture guide + submit sheet)
//   All roles  → "Gallery" tab (submitted photos by job)
//   Approvers  → "Review Queue" tab with pending count badge
//   (admin / officeManager / salesRep can approve)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/services/app_state.dart';
import '../../shared/widgets/tr_widgets.dart';
import '../../shared/models/models.dart';
import 'photo_submission_widgets.dart';
import 'photo_approval_screen.dart';

class PhotosScreen extends StatefulWidget {
  const PhotosScreen({super.key});

  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen>
    with SingleTickerProviderStateMixin {
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
    final canApprove = state.canApprovePhotos;
    final pendingCount = state.pendingSubmissions.length;

    return Scaffold(
      backgroundColor: TRColors.navyDeep,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, state),
            _buildTabBar(canApprove, pendingCount),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSubmitTab(context, state),
                  _buildGalleryTab(context, state),
                  // Tab 3 differs by role
                  canApprove
                      ? const PhotoApprovalScreen()
                      : _buildMySubmissionsTab(context, state),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, AppState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          const Expanded(child: Text('Photos', style: TextStyle(
            color: TRColors.white, fontSize: 24, fontWeight: FontWeight.w800,
          ))),
          // Submit button — available to ALL roles
          GestureDetector(
            onTap: () => showSubmitPhotosSheet(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: TRColors.gold,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.upload_rounded, color: TRColors.navyDeep, size: 18),
                  SizedBox(width: 6),
                  Text('Submit', style: TextStyle(
                    color: TRColors.navyDeep, fontSize: 13, fontWeight: FontWeight.w700,
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tab Bar ─────────────────────────────────────────────────────────────────

  Widget _buildTabBar(bool canApprove, int pendingCount) {
    final labels = ['Submit', 'Gallery', canApprove ? 'Review Queue' : 'My Submissions'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: labels.asMap().entries.map((entry) {
          final i = entry.key;
          final label = entry.value;
          final selected = _tabController.index == i;
          // Show badge on Review Queue tab when there are pending items
          final showBadge = i == 2 && canApprove && pendingCount > 0;

          return Expanded(child: GestureDetector(
            onTap: () {
              _tabController.animateTo(i);
              setState(() {});
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: i < 2 ? 6.0 : 0.0),
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: selected ? TRColors.gold : TRColors.cardDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: selected ? TRColors.gold : TRColors.divider),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Text(label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? TRColors.navyDeep : TRColors.grayLight,
                      fontSize: 11, fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (showBadge)
                    Positioned(
                      top: -8, right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: TRColors.warning,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('$pendingCount', style: const TextStyle(
                          color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800,
                        )),
                      ),
                    ),
                ],
              ),
            ),
          ));
        }).toList(),
      ),
    );
  }

  // ─── TAB 1: Submit (Capture Guide) ───────────────────────────────────────────

  Widget _buildSubmitTab(BuildContext context, AppState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Quick submit card
          GestureDetector(
            onTap: () => showSubmitPhotosSheet(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [TRColors.gold, TRColors.gold.withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.upload_rounded, color: TRColors.navyDeep, size: 28),
                  SizedBox(width: 14),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Submit Photos for Review', style: TextStyle(
                        color: TRColors.navyDeep, fontSize: 16, fontWeight: FontWeight.w800,
                      )),
                      SizedBox(height: 3),
                      Text('Pick a job, select type, add photos + note', style: TextStyle(
                        color: TRColors.navyDeep, fontSize: 12,
                      )),
                    ],
                  )),
                  Icon(Icons.arrow_forward_ios_rounded, color: TRColors.navyDeep, size: 16),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Active jobs — tap to open submit sheet pre-loaded
          const Text('Active Jobs', style: TextStyle(
            color: TRColors.grayLight, fontSize: 13, fontWeight: FontWeight.w600,
          )),
          const SizedBox(height: 8),
          if (state.activeJobs.isEmpty)
            const _EmptyJobsHint()
          else
            ...state.activeJobs.take(5).map((job) => _JobQuickTile(
              job: job,
              onTap: () => showSubmitPhotosSheet(context, preselectedJob: job),
            )),

          const SizedBox(height: 20),

          // AI framing guide
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [TRColors.cardDark, TRColors.navyMid],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: TRColors.gold.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.auto_awesome_rounded, color: TRColors.gold, size: 20),
                  SizedBox(width: 8),
                  Text('AI Photo Framing Guide', style: TextStyle(
                    color: TRColors.gold, fontSize: 15, fontWeight: FontWeight.w700,
                  )),
                ]),
                const SizedBox(height: 10),
                const Text(
                  'Follow these framing tips to ensure your photos score high for marketing use.',
                  style: TextStyle(color: TRColors.grayLight, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 14),
                ..._framingTips.map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: (tip['color'] as Color).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(tip['icon'] as IconData, color: tip['color'] as Color, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tip['title'] as String, style: const TextStyle(
                          color: TRColors.white, fontSize: 13, fontWeight: FontWeight.w600,
                        )),
                        Text(tip['desc'] as String, style: const TextStyle(
                          color: TRColors.grayMid, fontSize: 12,
                        )),
                      ],
                    )),
                  ]),
                )),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Photo templates — trade-aware split
          _buildTemplateSection(state),
        ],
      ),
    );
  }

  // ─── Template Section (trade-aware) ──────────────────────────────────────────

  Widget _buildTemplateSection(AppState state) {
    final trade = state.companyTrade;
    final allTemplates = state.templatesForCompanyTrade;

    if (trade.isEmpty) {
      // Company not loaded yet — show all without split
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Photo Templates', style: TextStyle(
            color: TRColors.white, fontSize: 17, fontWeight: FontWeight.w700,
          )),
          const SizedBox(height: 12),
          ...allTemplates.map((t) => _TemplateTile(template: t)),
        ],
      );
    }

    final tradeEmoji = TradeCategory.values
        .firstWhere((c) => c.displayName == trade,
            orElse: () => TradeCategory.homeServices)
        .emoji;

    final matched = allTemplates
        .where((t) => t.tradeCategory.toLowerCase() == trade.toLowerCase())
        .toList();
    final others = allTemplates
        .where((t) => t.tradeCategory.toLowerCase() != trade.toLowerCase())
        .toList();

    return _TradeTemplateSection(
      trade: trade,
      tradeEmoji: tradeEmoji,
      matchedTemplates: matched,
      otherTemplates: others,
    );
  }

  // ─── TAB 2: Gallery ──────────────────────────────────────────────────────────

  Widget _buildGalleryTab(BuildContext context, AppState state) {
    final approved = state.photoSubmissions
        .where((s) => s.status == PhotoSubmissionStatus.approved)
        .toList();

    if (approved.isEmpty) {
      return const Center(
        child: TREmptyState(
          icon: Icons.photo_library_outlined,
          title: 'Photo Gallery',
          subtitle: 'Approved photos will appear here, organized by job.',
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: approved.length,
      itemBuilder: (_, i) {
        final sub = approved[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: TRColors.cardDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: TRColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: TRColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('APPROVED', style: TextStyle(
                          color: TRColors.success, fontSize: 9, fontWeight: FontWeight.w800,
                        )),
                      ),
                      const Spacer(),
                      Text('${sub.photos.length} photo${sub.photos.length == 1 ? '' : 's'}',
                        style: const TextStyle(color: TRColors.grayMid, fontSize: 12)),
                    ]),
                    const SizedBox(height: 8),
                    Text(sub.jobName, style: const TextStyle(
                      color: TRColors.white, fontSize: 15, fontWeight: FontWeight.w700,
                    )),
                    const SizedBox(height: 4),
                    Text('by ${sub.submittedByName}', style: const TextStyle(
                      color: TRColors.grayMid, fontSize: 12,
                    )),
                  ],
                ),
              ),
              // Photo strip
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  itemCount: sub.photos.length,
                  itemBuilder: (_, j) {
                    final photo = sub.photos[j];
                    return Container(
                      width: 88,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: TRColors.navyMid,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: photo.displayUrl != null
                            ? Image.network(photo.displayUrl!, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.photo_rounded, color: TRColors.grayMid))
                            : const Icon(Icons.photo_rounded, color: TRColors.grayMid),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── TAB 3 (crew only): My Submissions ──────────────────────────────────────

  Widget _buildMySubmissionsTab(BuildContext context, AppState state) {
    final userId = state.currentUser?.id;
    final mine = state.photoSubmissions
        .where((s) => s.submittedById == userId)
        .toList();

    if (mine.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TREmptyState(
              icon: Icons.cloud_upload_outlined,
              title: 'No Submissions Yet',
              subtitle: 'Tap Submit to send photos to your manager for review.',
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => showSubmitPhotosSheet(context),
              icon: const Icon(Icons.upload_rounded, size: 18),
              label: const Text('Submit Photos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: TRColors.gold,
                foregroundColor: TRColors.navyDeep,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: mine.length,
      itemBuilder: (_, i) {
        final sub = mine[i];
        final statusColor = _statusColor(sub.status);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: TRColors.cardDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_statusIcon(sub.status), color: statusColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sub.jobName, style: const TextStyle(
                  color: TRColors.white, fontSize: 14, fontWeight: FontWeight.w600,
                )),
                const SizedBox(height: 3),
                Row(children: [
                  Text(sub.status.displayName, style: TextStyle(
                    color: statusColor, fontSize: 12, fontWeight: FontWeight.w600,
                  )),
                  Text('  ·  ${sub.photos.length} photo${sub.photos.length == 1 ? '' : 's'}',
                    style: const TextStyle(color: TRColors.grayMid, fontSize: 12)),
                ]),
                if (sub.reviewerNote != null) ...[
                  const SizedBox(height: 4),
                  Text(sub.reviewerNote!, style: const TextStyle(
                    color: TRColors.grayMid, fontSize: 12, fontStyle: FontStyle.italic,
                  ), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ],
            )),
          ]),
        );
      },
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  Color _statusColor(PhotoSubmissionStatus s) {
    switch (s) {
      case PhotoSubmissionStatus.pending:  return TRColors.warning;
      case PhotoSubmissionStatus.approved: return TRColors.success;
      case PhotoSubmissionStatus.rejected: return TRColors.error;
    }
  }

  IconData _statusIcon(PhotoSubmissionStatus s) {
    switch (s) {
      case PhotoSubmissionStatus.pending:  return Icons.hourglass_top_rounded;
      case PhotoSubmissionStatus.approved: return Icons.check_circle_rounded;
      case PhotoSubmissionStatus.rejected: return Icons.cancel_rounded;
    }
  }

  static final _framingTips = [
    {'title': 'Doorway Shot', 'desc': 'Stand in doorway for a full-room capture', 'icon': Icons.door_front_door_rounded, 'color': TRColors.info},
    {'title': 'Wide Angle', 'desc': 'Step back to show the complete scope of work', 'icon': Icons.open_in_full_rounded, 'color': TRColors.statusLead},
    {'title': 'Detail Close-Up', 'desc': 'Move close to highlight craftsmanship', 'icon': Icons.center_focus_strong_rounded, 'color': TRColors.warning},
    {'title': 'Landscape Mode', 'desc': 'Rotate for vanities, counters, and panels', 'icon': Icons.screen_rotation_rounded, 'color': TRColors.success},
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// SMALL REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _JobQuickTile extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;
  const _JobQuickTile({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: TRColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: TRColors.divider),
        ),
        child: Row(children: [
          const Icon(Icons.work_rounded, color: TRColors.grayMid, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(job.customerName, style: const TextStyle(
                color: TRColors.white, fontSize: 14, fontWeight: FontWeight.w600,
              )),
              Text('${job.jobType} · ${job.status.displayName}', style: const TextStyle(
                color: TRColors.grayMid, fontSize: 12,
              )),
            ],
          )),
          const Icon(Icons.camera_alt_rounded, color: TRColors.gold, size: 18),
        ]),
      ),
    );
  }
}

class _TemplateTile extends StatefulWidget {
  final ProjectTemplate template;
  final bool highlight;
  const _TemplateTile({required this.template, this.highlight = false});

  @override
  State<_TemplateTile> createState() => _TemplateTileState();
}

class _TemplateTileState extends State<_TemplateTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.template;
    final borderColor = widget.highlight
        ? TRColors.gold.withValues(alpha: 0.5)
        : TRColors.divider;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: TRColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: widget.highlight ? 1.5 : 1),
      ),
      child: Column(
        children: [
          // Header row — always visible
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Text(t.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.name, style: const TextStyle(
                      color: TRColors.white, fontSize: 14, fontWeight: FontWeight.w700,
                    )),
                    Text('${t.shots.length} required shots', style: const TextStyle(
                      color: TRColors.grayMid, fontSize: 12,
                    )),
                  ],
                )),
                AnimatedRotation(
                  turns: _expanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.chevron_right_rounded, color: TRColors.grayMid, size: 20),
                ),
              ]),
            ),
          ),

          // Expanded shot list
          if (_expanded) ...[
            const Divider(color: TRColors.divider, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Shot Checklist', style: TextStyle(
                    color: TRColors.grayLight, fontSize: 11,
                    fontWeight: FontWeight.w600, letterSpacing: 0.5,
                  )),
                  const SizedBox(height: 8),
                  ...t.shots.map((shot) => _ShotRow(shot: shot)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ShotRow extends StatelessWidget {
  final TemplateShot shot;
  const _ShotRow({required this.shot});

  static const _phaseColors = {
    PhotoType.before:   TRColors.warning,
    PhotoType.progress: TRColors.info,
    PhotoType.after:    TRColors.success,
  };
  static const _phaseLabels = {
    PhotoType.before:   'Before',
    PhotoType.progress: 'Progress',
    PhotoType.after:    'After',
  };

  @override
  Widget build(BuildContext context) {
    final color = _phaseColors[shot.phase] ?? TRColors.grayMid;
    final label = _phaseLabels[shot.phase] ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(label, style: TextStyle(
              color: color, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.4,
            )),
          ),
          const SizedBox(width: 8),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(shot.name, style: const TextStyle(
                color: TRColors.white, fontSize: 13, fontWeight: FontWeight.w600,
              )),
              const SizedBox(height: 1),
              Text(shot.instruction, style: const TextStyle(
                color: TRColors.grayMid, fontSize: 11, height: 1.4,
              )),
            ],
          )),
        ],
      ),
    );
  }
}

class _EmptyJobsHint extends StatelessWidget {
  const _EmptyJobsHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TRColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TRColors.divider),
      ),
      child: const Row(children: [
        Icon(Icons.info_outline_rounded, color: TRColors.grayMid, size: 16),
        SizedBox(width: 8),
        Expanded(child: Text('No active jobs. Mark a job as In Progress to link photos.',
          style: TextStyle(color: TRColors.grayMid, fontSize: 13))),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TRADE-AWARE TEMPLATE SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _TradeTemplateSection extends StatefulWidget {
  final String trade;
  final String tradeEmoji;
  final List<ProjectTemplate> matchedTemplates;
  final List<ProjectTemplate> otherTemplates;

  const _TradeTemplateSection({
    required this.trade,
    required this.tradeEmoji,
    required this.matchedTemplates,
    required this.otherTemplates,
  });

  @override
  State<_TradeTemplateSection> createState() => _TradeTemplateSectionState();
}

class _TradeTemplateSectionState extends State<_TradeTemplateSection> {
  bool _showOthers = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Your Trade header ──────────────────────────────────────────────
        Row(children: [
          Text(widget.tradeEmoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${widget.trade} Templates',
              style: const TextStyle(
                color: TRColors.white, fontSize: 17, fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: TRColors.goldDim,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('YOUR TRADE', style: const TextStyle(
              color: TRColors.gold, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.6,
            )),
          ),
        ]),
        const SizedBox(height: 4),
        const Text(
          'These templates are pre-configured for your trade.',
          style: TextStyle(color: TRColors.grayMid, fontSize: 12),
        ),
        const SizedBox(height: 12),

        // Matched templates
        if (widget.matchedTemplates.isEmpty)
          _NoTradeTemplatesHint(trade: widget.trade)
        else
          ...widget.matchedTemplates.map((t) => _TemplateTile(template: t, highlight: true)),

        // ── Other templates (collapsible) ──────────────────────────────────
        if (widget.otherTemplates.isNotEmpty) ...[
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => setState(() => _showOthers = !_showOthers),
            child: Row(children: [
              const Expanded(child: Divider(color: TRColors.divider, thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(children: [
                  Text(
                    _showOthers ? 'Hide other templates' : 'Browse other trade templates',
                    style: const TextStyle(color: TRColors.grayMid, fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _showOthers ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: TRColors.grayMid, size: 16,
                  ),
                ]),
              ),
              const Expanded(child: Divider(color: TRColors.divider, thickness: 1)),
            ]),
          ),
          if (_showOthers) ...[
            const SizedBox(height: 12),
            ...widget.otherTemplates.map((t) => _TemplateTile(template: t, highlight: false)),
          ],
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

class _NoTradeTemplatesHint extends StatelessWidget {
  final String trade;
  const _NoTradeTemplatesHint({required this.trade});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TRColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TRColors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.auto_awesome_rounded, color: TRColors.gold, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(
          'Custom templates for $trade will appear here once configured by your admin.',
          style: const TextStyle(color: TRColors.grayLight, fontSize: 13),
        )),
      ]),
    );
  }
}

// Re-export PhotoScoreBar used by the old AI Analysis tab
// (kept for use elsewhere in the app)
class PhotoScoreBar extends StatelessWidget {
  final String label;
  final double score;
  final Color color;
  const PhotoScoreBar({
    super.key,
    required this.label,
    required this.score,
    this.color = TRColors.gold,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(child: Text(label, style: const TextStyle(color: TRColors.grayLight, fontSize: 12))),
          Text('${(score * 100).toInt()}%', style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w700,
          )),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score,
            backgroundColor: TRColors.cardMid,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
