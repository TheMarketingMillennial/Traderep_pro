// photo_approval_screen.dart — TradeRep Pro
// Approval queue for admins, office managers, and marketing (salesRep).
// Shows pending submissions first; approved/rejected are in a history list.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';
import '../../shared/services/app_state.dart';
import '../content/google_post_sheets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// APPROVAL SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class PhotoApprovalScreen extends StatefulWidget {
  const PhotoApprovalScreen({super.key});

  @override
  State<PhotoApprovalScreen> createState() => _PhotoApprovalScreenState();
}

class _PhotoApprovalScreenState extends State<PhotoApprovalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final pending = state.pendingSubmissions;
    final reviewed = state.photoSubmissions
        .where((s) => s.status != PhotoSubmissionStatus.pending)
        .toList();

    return Scaffold(
      backgroundColor: TRColors.navyDeep,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  // Back to main app
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: TRColors.cardDark,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: TRColors.divider),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: TRColors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('Photo Approvals', style: TextStyle(
                    color: TRColors.white, fontSize: 22, fontWeight: FontWeight.w800,
                  ))),
                  if (pending.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: TRColors.warning.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: TRColors.warning.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '${pending.length} pending',
                        style: const TextStyle(
                          color: TRColors.warning, fontSize: 11, fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Tab bar ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  _ApprovalTab(
                    label: 'Pending',
                    count: pending.length,
                    selected: _tabs.index == 0,
                    countColor: TRColors.warning,
                    onTap: () { _tabs.animateTo(0); setState(() {}); },
                  ),
                  const SizedBox(width: 8),
                  _ApprovalTab(
                    label: 'Reviewed',
                    count: reviewed.length,
                    selected: _tabs.index == 1,
                    countColor: TRColors.success,
                    onTap: () { _tabs.animateTo(1); setState(() {}); },
                  ),
                ],
              ),
            ),

            // ── Body ─────────────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _PendingList(submissions: pending),
                  _ReviewedList(submissions: reviewed),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PENDING LIST
// ─────────────────────────────────────────────────────────────────────────────

class _PendingList extends StatelessWidget {
  final List<PhotoSubmission> submissions;
  const _PendingList({required this.submissions});

  @override
  Widget build(BuildContext context) {
    if (submissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: TRColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline_rounded, color: TRColors.success, size: 36),
            ),
            const SizedBox(height: 16),
            const Text('All caught up!', style: TextStyle(
              color: TRColors.white, fontSize: 18, fontWeight: FontWeight.w700,
            )),
            const SizedBox(height: 6),
            const Text('No photos waiting for review.', style: TextStyle(
              color: TRColors.grayMid, fontSize: 14,
            )),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: submissions.length,
      itemBuilder: (_, i) => _SubmissionCard(submission: submissions[i], showActions: true),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REVIEWED LIST
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewedList extends StatelessWidget {
  final List<PhotoSubmission> submissions;
  const _ReviewedList({required this.submissions});

  @override
  Widget build(BuildContext context) {
    if (submissions.isEmpty) {
      return const Center(
        child: Text('No reviewed submissions yet.', style: TextStyle(color: TRColors.grayMid)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: submissions.length,
      itemBuilder: (_, i) => _SubmissionCard(submission: submissions[i], showActions: false),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUBMISSION CARD
// ─────────────────────────────────────────────────────────────────────────────

class _SubmissionCard extends StatelessWidget {
  final PhotoSubmission submission;
  final bool showActions;
  const _SubmissionCard({required this.submission, required this.showActions});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(submission.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: TRColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Status chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(submission.status.shortName.toUpperCase(),
                        style: TextStyle(
                          color: statusColor, fontSize: 9, fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Photo type chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: TRColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _primaryType(submission.photos),
                        style: const TextStyle(color: TRColors.info, fontSize: 9, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${submission.photos.length} photo${submission.photos.length == 1 ? '' : 's'}',
                      style: const TextStyle(color: TRColors.grayMid, fontSize: 12),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Job name
                Text(submission.jobName, style: const TextStyle(
                  color: TRColors.white, fontSize: 15, fontWeight: FontWeight.w700,
                )),
                const SizedBox(height: 4),

                // Submitted by + time
                Row(children: [
                  const Icon(Icons.person_outline_rounded, color: TRColors.grayMid, size: 14),
                  const SizedBox(width: 4),
                  Text(submission.submittedByName, style: const TextStyle(color: TRColors.grayMid, fontSize: 12)),
                  const SizedBox(width: 10),
                  const Icon(Icons.access_time_rounded, color: TRColors.grayMid, size: 14),
                  const SizedBox(width: 4),
                  Text(_formatTime(submission.submittedAt), style: const TextStyle(color: TRColors.grayMid, fontSize: 12)),
                ]),

                // Crew note
                if (submission.crewNote != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: TRColors.navyMid,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.notes_rounded, color: TRColors.grayMid, size: 14),
                        const SizedBox(width: 6),
                        Expanded(child: Text(submission.crewNote!,
                          style: const TextStyle(color: TRColors.grayLight, fontSize: 12, height: 1.4),
                        )),
                      ],
                    ),
                  ),
                ],

                // Reviewer note
                if (submission.reviewerNote != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.rate_review_rounded, color: statusColor, size: 14),
                        const SizedBox(width: 6),
                        Expanded(child: Text(submission.reviewerNote!,
                          style: TextStyle(color: statusColor, fontSize: 12, height: 1.4),
                        )),
                        if (submission.reviewedByName != null) ...[
                          const SizedBox(width: 4),
                          Text('— ${submission.reviewedByName}',
                            style: TextStyle(color: statusColor.withValues(alpha: 0.7), fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Photo strip ──────────────────────────────────────────────────
          if (submission.photos.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 0, 4),
              child: Text(
                '${submission.photos.length} photo${submission.photos.length == 1 ? '' : 's'} — tap to view full size',
                style: const TextStyle(color: TRColors.grayMid, fontSize: 11),
              ),
            ),
            SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                itemCount: submission.photos.length,
                itemBuilder: (_, i) {
                  final photo = submission.photos[i];
                  return GestureDetector(
                    onTap: () => _openPhotoViewer(context, submission.photos, i),
                    child: Container(
                      width: 110,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: TRColors.navyMid,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: TRColors.divider),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (photo.networkUrl != null)
                              Image.network(
                                photo.networkUrl!,
                                fit: BoxFit.cover,
                                loadingBuilder: (_, child, progress) {
                                  if (progress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: progress.expectedTotalBytes != null
                                          ? progress.cumulativeBytesLoaded /
                                              progress.expectedTotalBytes!
                                          : null,
                                      strokeWidth: 2,
                                      color: TRColors.gold,
                                    ),
                                  );
                                },
                                errorBuilder: (_, err, ___) => Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.broken_image_rounded,
                                        color: TRColors.error, size: 28),
                                    const SizedBox(height: 4),
                                    const Text('Failed to\nload',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: TRColors.error, fontSize: 9)),
                                  ],
                                ),
                              )
                            else
                              _PhotoPlaceholder(type: photo.type),
                            // Type label badge
                            Positioned(
                              bottom: 4, left: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  photo.type.name.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            // Tap indicator
                            Positioned(
                              top: 4, right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(Icons.zoom_in_rounded,
                                    color: Colors.white, size: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          // ── Action buttons (pending only) ────────────────────────────────
          if (showActions)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                children: [
                  Expanded(child: _ActionButton(
                    label: 'Reject',
                    icon: Icons.close_rounded,
                    color: TRColors.error,
                    onTap: () => _showReviewSheet(context, submission, approve: false),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _ActionButton(
                    label: 'Approve',
                    icon: Icons.check_rounded,
                    color: TRColors.success,
                    filled: true,
                    onTap: () => _showReviewSheet(context, submission, approve: true),
                  )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _openPhotoViewer(BuildContext context, List<SubmittedPhoto> photos, int startIndex) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _PhotoViewerScreen(photos: photos, initialIndex: startIndex),
    ));
  }

  void _showReviewSheet(BuildContext context, PhotoSubmission submission, {required bool approve}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReviewNoteSheet(
        submission: submission,
        approve: approve,
      ),
    );
  }

  Color _statusColor(PhotoSubmissionStatus s) {
    switch (s) {
      case PhotoSubmissionStatus.pending:  return TRColors.warning;
      case PhotoSubmissionStatus.approved: return TRColors.success;
      case PhotoSubmissionStatus.rejected: return TRColors.error;
    }
  }

  String _primaryType(List<SubmittedPhoto> photos) {
    if (photos.isEmpty) return 'PHOTOS';
    final t = photos.first.type;
    switch (t) {
      case PhotoType.before:   return 'BEFORE';
      case PhotoType.progress: return 'PROGRESS';
      case PhotoType.after:    return 'AFTER';
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REVIEW NOTE SHEET (Approve / Reject with optional note)
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewNoteSheet extends StatefulWidget {
  final PhotoSubmission submission;
  final bool approve;
  const _ReviewNoteSheet({required this.submission, required this.approve});

  @override
  State<_ReviewNoteSheet> createState() => _ReviewNoteSheetState();
}

class _ReviewNoteSheetState extends State<_ReviewNoteSheet> {
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() => _saving = true);
    final state = context.read<AppState>();

    if (widget.approve) {
      await state.approveSubmission(
        widget.submission.id,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );
    } else {
      await state.rejectSubmission(
        widget.submission.id,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            Icon(
              widget.approve ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: widget.approve ? TRColors.success : TRColors.error,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(widget.approve ? 'Photos approved!' : 'Photos rejected.'),
          ]),
          backgroundColor: TRColors.cardDark,
        ),
      );
      // After approval, offer to create a Google post draft from these photos
      if (widget.approve && mounted) {
        showCreatePostSheet(context, widget.submission);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.approve ? TRColors.success : TRColors.error;
    final label = widget.approve ? 'Approve' : 'Reject';
    final icon  = widget.approve ? Icons.check_circle_rounded : Icons.cancel_rounded;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: TRColors.navyMid,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: TRColors.divider, borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Text('$label Submission', style: const TextStyle(
                color: TRColors.white, fontSize: 17, fontWeight: FontWeight.w800,
              )),
            ]),
            const SizedBox(height: 4),
            Text(
              widget.submission.jobName,
              style: const TextStyle(color: TRColors.grayMid, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Optional note
            TextField(
              controller: _noteCtrl,
              maxLines: 3,
              autofocus: false,
              style: const TextStyle(color: TRColors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: widget.approve
                    ? 'Optional feedback for the crew (e.g. "Great shots! Use the after photo for social.")…'
                    : 'Tell the crew what to fix (required for best results)…',
                hintStyle: const TextStyle(color: TRColors.grayMid, fontSize: 13),
                filled: true,
                fillColor: TRColors.cardDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: TRColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: TRColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: color),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: TRColors.divider),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Cancel', style: TextStyle(color: TRColors.grayLight)),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: _saving ? null : _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                      )
                    : Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              )),
            ]),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FULL-SCREEN PHOTO VIEWER (tap a thumbnail)
// ─────────────────────────────────────────────────────────────────────────────

class _PhotoViewerScreen extends StatefulWidget {
  final List<SubmittedPhoto> photos;
  final int initialIndex;
  const _PhotoViewerScreen({required this.photos, required this.initialIndex});

  @override
  State<_PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<_PhotoViewerScreen> {
  late PageController _page;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _page = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Photo ${_current + 1} of ${widget.photos.length}',
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _page,
        itemCount: widget.photos.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (_, i) {
          final photo = widget.photos[i];
          return InteractiveViewer(
            child: Center(
              child: photo.networkUrl != null
                  ? Image.network(
                      photo.networkUrl!,
                      fit: BoxFit.contain,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded /
                                        progress.expectedTotalBytes!
                                    : null,
                                color: TRColors.gold,
                              ),
                              const SizedBox(height: 12),
                              const Text('Loading photo…',
                                  style: TextStyle(color: Colors.white54, fontSize: 13)),
                            ],
                          ),
                        );
                      },
                      errorBuilder: (_, err, ___) => Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.broken_image_rounded,
                              color: Colors.white38, size: 72),
                          const SizedBox(height: 12),
                          const Text('Could not load photo',
                              style: TextStyle(color: Colors.white54, fontSize: 14)),
                          const SizedBox(height: 4),
                          const Text('Check Firebase Storage permissions',
                              style: TextStyle(color: Colors.white30, fontSize: 11)),
                        ],
                      ),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_not_supported_rounded,
                            color: Colors.white38, size: 72),
                        SizedBox(height: 12),
                        Text('No photo URL available',
                            style: TextStyle(color: Colors.white54, fontSize: 14)),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SMALL COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────

class _ApprovalTab extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color countColor;
  final VoidCallback onTap;
  const _ApprovalTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.countColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? TRColors.gold : TRColors.cardDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? TRColors.gold : TRColors.divider),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: TextStyle(
                color: selected ? TRColors.navyDeep : TRColors.grayLight,
                fontSize: 13, fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              )),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: selected ? TRColors.navyDeep.withValues(alpha: 0.2) : countColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('$count', style: TextStyle(
                    color: selected ? TRColors.navyDeep : countColor,
                    fontSize: 11, fontWeight: FontWeight.w800,
                  )),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
  final VoidCallback onTap;
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.filled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: filled ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: filled ? 0 : 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: filled ? Colors.white : color, size: 16),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
              color: filled ? Colors.white : color,
              fontSize: 13, fontWeight: FontWeight.w700,
            )),
          ],
        ),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  final PhotoType type;
  const _PhotoPlaceholder({required this.type});

  @override
  Widget build(BuildContext context) {
    final icon = type == PhotoType.before
        ? Icons.history_rounded
        : type == PhotoType.progress
            ? Icons.trending_up_rounded
            : Icons.check_circle_outline_rounded;
    return Container(
      color: TRColors.navyMid,
      child: Center(child: Icon(icon, color: TRColors.grayMid, size: 28)),
    );
  }
}
