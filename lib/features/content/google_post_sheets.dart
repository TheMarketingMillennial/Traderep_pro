// google_post_sheets.dart — TradeRep Pro
// Two bottom sheets that form the Phase 1 Google Business Profile posting flow:
//
//  1. CreatePostSheet — shown immediately after admin approves a photo
//     submission. Lets the admin pick which photos to use as before/after,
//     edit the auto-generated caption, and tap "Create Draft" to write the
//     ContentPost to Firestore.
//
//  2. PublishSheet — shown from the Content tab "Publish" button on any
//     approved post. Shows before/after preview, editable caption + hashtags,
//     Copy Caption, Share Image (share_plus), and Open Google Business App
//     (url_launcher deep-link).
//
// Phase 2 (deferred): GBP OAuth token stored in Railway, /publish_google_post
// endpoint, gbpLocationId per company — no changes needed to these sheets.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';
import '../../shared/services/app_state.dart';
import '../../shared/services/ai_service.dart';
import '../../shared/widgets/tr_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SHOW HELPERS — called from other screens
// ─────────────────────────────────────────────────────────────────────────────

/// Show CreatePostSheet after approving a photo submission.
/// Rebuilds caption from submission context; user edits, then taps "Create Draft".
void showCreatePostSheet(BuildContext context, PhotoSubmission submission) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<AppState>(),
      child: CreatePostSheet(submission: submission),
    ),
  );
}

/// Show PublishSheet for an already-created ContentPost (from Content tab).
void showPublishSheet(BuildContext context, {required ContentPost post}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<AppState>(),
      child: PublishSheet(post: post),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CREATE POST SHEET
// ─────────────────────────────────────────────────────────────────────────────

class CreatePostSheet extends StatefulWidget {
  final PhotoSubmission submission;
  const CreatePostSheet({super.key, required this.submission});

  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  late TextEditingController _captionCtrl;
  late TextEditingController _hashtagCtrl;

  // Selected photo indices for before / after slots
  int? _beforeIdx;
  int? _afterIdx;

  bool _saving        = false;
  bool _generatingAi  = false;

  @override
  void initState() {
    super.initState();
    final photos = widget.submission.photos;

    // Auto-select best before/after based on PhotoType
    for (var i = 0; i < photos.length; i++) {
      if (_beforeIdx == null && photos[i].type == PhotoType.before) {
        _beforeIdx = i;
      }
      if (_afterIdx == null && photos[i].type == PhotoType.after) {
        _afterIdx = i;
      }
    }
    // Fallbacks
    if (photos.isNotEmpty) {
      _beforeIdx ??= 0;
      _afterIdx ??= photos.length - 1;
      // If both resolved to same index (e.g. single photo), keep it — it will
      // be used for both slots, which is fine for a progress-only submission.
    }

    // Build auto-caption from company + job context
    final state = context.read<AppState>();
    final company = state.company;
    final tradeName = company?.tradeCategory ?? 'Trade';
    final area = company?.serviceArea ?? '';
    final bizName = company?.name ?? '';
    final jobName = widget.submission.jobName;

    _captionCtrl = TextEditingController(
      text: '🛠️ $jobName complete${area.isNotEmpty ? " in $area" : ""}!\n\n'
          'Our crew delivered a clean, professional result for another happy '
          'customer. Every job gets our full attention — start to finish. 👍\n\n'
          '${bizName.isNotEmpty ? "✨ $bizName — " : ""}'
          'Trusted $tradeName Experts'
          '${area.isNotEmpty ? " serving $area" : ""}.\n\n'
          'Call or message us for a free estimate!',
    );
    _hashtagCtrl = TextEditingController(
      text: '#${'#$tradeName'.replaceAll('# ', '#').replaceAll(' ', '')} '
          '#BeforeAndAfter '
          '#${'$tradeName Contractor'.replaceAll(' ', '')} '
          '#HomeImprovement '
          '#QualityWork '
          '#ContractorLife',
    );
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    _hashtagCtrl.dispose();
    super.dispose();
  }

  /// Builds tone chip buttons: Professional | Friendly | Bold
  List<Widget> _buildToneChips() {
    return CaptionTone.values.map((tone) {
      return Padding(
        padding: const EdgeInsets.only(left: 6),
        child: GestureDetector(
          onTap: () => _regenerateWithAi(tone),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: TRColors.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: TRColors.gold.withValues(alpha: 0.4)),
            ),
            child: Text(tone.label,
              style: const TextStyle(
                color: TRColors.gold, fontSize: 11, fontWeight: FontWeight.w600,
              )),
          ),
        ),
      );
    }).toList();
  }

  /// Calls Railway /generate-caption and updates caption + hashtag fields.
  Future<void> _regenerateWithAi(CaptionTone tone) async {
    if (_generatingAi) return;
    setState(() => _generatingAi = true);

    final state   = context.read<AppState>();
    final company = state.company;

    final result = await AiService.generateCaption(
      jobType:        widget.submission.jobName,
      companyName:    company?.name ?? '',
      trade:          company?.tradeCategory ?? '',
      serviceArea:    company?.serviceArea ?? '',
      jobDescription: widget.submission.crewNote ?? '',
      tone:           tone,
    );

    if (!mounted) return;
    setState(() => _generatingAi = false);

    if (result != null) {
      _captionCtrl.text  = result.caption;
      _hashtagCtrl.text  = result.hashtags.join(' ');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('AI unavailable — check Railway server has OPENAI_API_KEY set'),
        backgroundColor: TRColors.warning,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _createDraft() async {
    if (_saving) return;
    setState(() => _saving = true);

    final state = context.read<AppState>();
    final photos = widget.submission.photos;

    // Build a temporary submission with the user's chosen before/after photos
    // re-ordered so createPostFromSubmission picks them correctly.
    final beforePhoto = _beforeIdx != null ? photos[_beforeIdx!] : photos.first;
    final afterPhoto = _afterIdx != null ? photos[_afterIdx!] : photos.last;

    // Override the auto-generated caption with whatever the admin typed
    final editedCaption = _captionCtrl.text.trim();
    final editedHashtags = _hashtagCtrl.text
        .trim()
        .split(RegExp(r'\s+'))
        .where((t) => t.startsWith('#'))
        .toList();

    try {
      // Create post via AppState (writes to Firestore, optimistic update)
      final post = await state.createPostFromSubmission(widget.submission);

      if (post != null && mounted) {
        // Update caption/hashtags if admin edited them
        if (editedCaption != post.suggestedCaption ||
            editedHashtags.join(' ') != post.suggestedHashtags.join(' ')) {
          // We need to update the local list with the edited values.
          // The simplest approach: build a corrected post and replace it.
          final corrected = ContentPost(
            id: post.id,
            jobId: post.jobId,
            beforePhotoUrl: beforePhoto.networkUrl ?? post.beforePhotoUrl,
            afterPhotoUrl: afterPhoto.networkUrl ?? post.afterPhotoUrl,
            suggestedCaption: editedCaption.isNotEmpty
                ? editedCaption
                : post.suggestedCaption,
            suggestedHashtags:
                editedHashtags.isNotEmpty ? editedHashtags : post.suggestedHashtags,
            projectSummary: post.projectSummary,
            status: post.status,
            createdAt: post.createdAt,
            sourceSubmissionId: post.sourceSubmissionId,
            companyId: post.companyId,
          );
          state.replacePost(corrected);
        }

        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_rounded,
                  color: TRColors.success, size: 18),
              SizedBox(width: 10),
              Text('Draft created! Ready to publish from Content tab.'),
            ]),
            backgroundColor: TRColors.cardDark,
            action: SnackBarAction(
              label: 'Go to Content',
              textColor: TRColors.gold,
              onPressed: () {
                // Navigation is handled by the main shell tab index
              },
            ),
          ),
        );
      } else if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create draft. Please try again.'),
            backgroundColor: TRColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: TRColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.submission.photos;
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: TRColors.navyMid,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: TRColors.goldDark, width: 1.5),
          ),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.92,
          minChildSize: 0.5,
          maxChildSize: 0.97,
          expand: false,
          builder: (_, controller) => Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: TRColors.grayMid.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: TRColors.goldDark.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.post_add_rounded,
                          color: TRColors.gold, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Create Google Post Draft',
                              style: TextStyle(
                                  color: TRColors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                          Text(
                            widget.submission.jobName,
                            style: const TextStyle(
                                color: TRColors.gold,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded,
                          color: TRColors.grayMid, size: 20),
                    ),
                  ],
                ),
              ),
              const Divider(color: TRColors.navyLight, height: 1),
              // Scrollable body
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    // ── Photo selector ──────────────────────────────────────
                    _SectionLabel(label: 'Before Photo', icon: Icons.photo_outlined),
                    const SizedBox(height: 8),
                    _PhotoChipRow(
                      photos: photos,
                      selectedIdx: _beforeIdx,
                      onSelect: (i) => setState(() => _beforeIdx = i),
                    ),
                    const SizedBox(height: 16),
                    _SectionLabel(label: 'After Photo', icon: Icons.photo_rounded),
                    const SizedBox(height: 8),
                    _PhotoChipRow(
                      photos: photos,
                      selectedIdx: _afterIdx,
                      onSelect: (i) => setState(() => _afterIdx = i),
                    ),
                    const SizedBox(height: 20),
                    // ── Before/After Preview ────────────────────────────────
                    if (_beforeIdx != null && _afterIdx != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _PhotoPreviewTile(
                              label: 'BEFORE',
                              url: photos[_beforeIdx!].displayUrl,
                              borderColor: TRColors.error.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _PhotoPreviewTile(
                              label: 'AFTER',
                              url: photos[_afterIdx!].displayUrl,
                              borderColor:
                                  TRColors.success.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                    // ── AI Regenerate row ───────────────────────────────────
                    Row(children: [
                      const Icon(Icons.auto_awesome_rounded, color: TRColors.gold, size: 14),
                      const SizedBox(width: 6),
                      const Text('Regenerate with AI',
                        style: TextStyle(color: TRColors.gold, fontSize: 12, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      if (_generatingAi)
                        const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: TRColors.gold),
                        )
                      else ..._buildToneChips(),
                    ]),
                    const SizedBox(height: 12),
                    // ── Caption editor ──────────────────────────────────────
                    _SectionLabel(
                        label: 'Caption (AI-generated — edit freely)',
                        icon: Icons.edit_note_rounded),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: TRColors.navyDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: TRColors.navyLight.withValues(alpha: 0.6)),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        controller: _captionCtrl,
                        maxLines: 7,
                        style: const TextStyle(
                            color: TRColors.white,
                            fontSize: 14,
                            height: 1.5),
                        decoration: const InputDecoration.collapsed(
                          hintText: 'Write your post caption…',
                          hintStyle:
                              TextStyle(color: TRColors.grayMid, fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // ── Hashtag editor ──────────────────────────────────────
                    _SectionLabel(
                        label: 'Hashtags', icon: Icons.tag_rounded),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: TRColors.navyDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: TRColors.navyLight.withValues(alpha: 0.6)),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        controller: _hashtagCtrl,
                        maxLines: 2,
                        style: const TextStyle(
                            color: TRColors.gold, fontSize: 13, height: 1.5),
                        decoration: const InputDecoration.collapsed(
                          hintText: '#Roofing #BeforeAndAfter …',
                          hintStyle:
                              TextStyle(color: TRColors.grayMid, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // ── Create Draft button ─────────────────────────────────
                    GoldButton(
                      label: _saving ? 'Creating Draft…' : 'Create Draft Post',
                      icon: Icons.add_circle_outline_rounded,
                      onTap: _saving ? null : _createDraft,
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Skip for now',
                          style:
                              TextStyle(color: TRColors.grayMid, fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PUBLISH SHEET
// ─────────────────────────────────────────────────────────────────────────────

class PublishSheet extends StatefulWidget {
  final ContentPost post;
  const PublishSheet({super.key, required this.post});

  @override
  State<PublishSheet> createState() => _PublishSheetState();
}

class _PublishSheetState extends State<PublishSheet> {
  late TextEditingController _captionCtrl;

  // Manual-mode state
  bool _copied  = false;
  bool _sharing = false;

  // Auto-publish state (Phase 2 — gbpLocationId configured)
  bool _publishing = false;
  String? _publishError;
  bool _publishedSuccessfully = false;

  static const _gbpUrl = 'https://business.google.com/create-post';

  @override
  void initState() {
    super.initState();
    _captionCtrl = TextEditingController(
      text: '${widget.post.suggestedCaption}\n\n'
            '${widget.post.suggestedHashtags.join(' ')}',
    );
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  // ── Manual-mode helpers ───────────────────────────────────────────────────

  Future<void> _copyCaption() async {
    await Clipboard.setData(ClipboardData(text: _captionCtrl.text));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  Future<void> _shareImage() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final shareText =
          'Check out this project!\n\n'
          'After: ${widget.post.afterPhotoUrl}\n'
          'Before: ${widget.post.beforePhotoUrl}\n\n'
          '${_captionCtrl.text}';
      await Share.share(shareText, subject: 'TradeRep Pro — Project Showcase');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Share failed: $e'),
          backgroundColor: TRColors.error,
        ));
      }
    }
    if (mounted) setState(() => _sharing = false);
  }

  Future<void> _openGbp() async {
    final uri = Uri.parse(_gbpUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not open Google Business. Visit business.google.com'),
          backgroundColor: TRColors.warning,
        ));
      }
    }
  }

  Future<void> _markPublished() async {
    context.read<AppState>().updatePostStatus(widget.post.id, ContentStatus.published);
    if (mounted) Navigator.of(context).pop();
  }

  // ── Phase 2: auto-publish via Railway ────────────────────────────────────

  Future<void> _publishNow() async {
    if (_publishing) return;
    setState(() {
      _publishing    = true;
      _publishError  = null;
    });

    // Sync any caption edits the admin made back into the post before sending
    final editedPost = ContentPost(
      id:                widget.post.id,
      jobId:             widget.post.jobId,
      beforePhotoUrl:    widget.post.beforePhotoUrl,
      afterPhotoUrl:     widget.post.afterPhotoUrl,
      suggestedCaption:  _captionCtrl.text.trim(),
      suggestedHashtags: const [],       // already embedded in caption text
      projectSummary:    widget.post.projectSummary,
      status:            widget.post.status,
      scheduledFor:      widget.post.scheduledFor,
      createdAt:         widget.post.createdAt,
      sourceSubmissionId: widget.post.sourceSubmissionId,
      companyId:         widget.post.companyId,
    );

    final result = await context.read<AppState>().publishToGbp(editedPost);

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _publishing = false;
        _publishedSuccessfully = true;
      });
      // Brief success pause then close
      await Future.delayed(const Duration(seconds: 1, milliseconds: 500));
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_rounded,
                color: TRColors.success, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(
              result.isMock
                  ? 'Post published (mock mode). Set MOCK_MODE=false to go live.'
                  : '🎉 Post is now live on Google Business Profile!',
            )),
          ]),
          backgroundColor: TRColors.cardDark,
          duration: const Duration(seconds: 4),
        ));
      }
    } else {
      setState(() {
        _publishing   = false;
        _publishError = result.error;
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state        = context.watch<AppState>();
    final locationId   = state.company?.gbpLocationId;
    final isAutoMode   = locationId != null && locationId.isNotEmpty;

    final headerSubtitle = isAutoMode
        ? 'Auto-publish via Google Business API'
        : 'Copy caption → Share image → Post to GBP';

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: TRColors.navyMid,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: TRColors.goldDark, width: 1.5)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.92,
          minChildSize: 0.5,
          maxChildSize: 0.97,
          expand: false,
          builder: (_, controller) => Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: TRColors.grayMid.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: TRColors.goldDark.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.business_rounded,
                          color: TRColors.gold, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Publish to Google Business',
                              style: TextStyle(
                                  color: TRColors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                          Text(headerSubtitle,
                              style: const TextStyle(
                                  color: TRColors.grayMid, fontSize: 12)),
                        ],
                      ),
                    ),
                    // Mode badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isAutoMode
                            ? const Color(0xFF4285F4).withValues(alpha: 0.15)
                            : TRColors.navyLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isAutoMode ? 'AUTO' : 'MANUAL',
                        style: TextStyle(
                          color: isAutoMode
                              ? const Color(0xFF4285F4)
                              : TRColors.grayMid,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded,
                          color: TRColors.grayMid, size: 20),
                    ),
                  ],
                ),
              ),
              const Divider(color: TRColors.navyLight, height: 1),
              // Scrollable body
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    // ── Before/After preview ──────────────────────────────
                    _SectionLabel(
                        label: 'Photo Preview',
                        icon: Icons.photo_library_rounded),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: _PhotoPreviewTile(
                        label: 'BEFORE',
                        url: widget.post.beforePhotoUrl.isNotEmpty
                            ? widget.post.beforePhotoUrl : null,
                        borderColor: TRColors.error.withValues(alpha: 0.6),
                        height: 160,
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: _PhotoPreviewTile(
                        label: 'AFTER',
                        url: widget.post.afterPhotoUrl.isNotEmpty
                            ? widget.post.afterPhotoUrl : null,
                        borderColor: TRColors.success.withValues(alpha: 0.6),
                        height: 160,
                      )),
                    ]),
                    const SizedBox(height: 20),
                    // ── Caption editor ────────────────────────────────────
                    _SectionLabel(
                        label: 'Caption + Hashtags (edit if needed)',
                        icon: Icons.edit_note_rounded),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: TRColors.navyDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: TRColors.navyLight.withValues(alpha: 0.6)),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        controller: _captionCtrl,
                        maxLines: 8,
                        style: const TextStyle(
                            color: TRColors.white,
                            fontSize: 14, height: 1.5),
                        decoration: const InputDecoration.collapsed(
                          hintText: 'Caption…',
                          hintStyle: TextStyle(
                              color: TRColors.grayMid, fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ═══════════════════════════════════════════════════════
                    // AUTO MODE (Phase 2) — gbpLocationId is set
                    // ═══════════════════════════════════════════════════════
                    if (isAutoMode) ...[
                      // Location info chip
                      _GbpLocationChip(locationId: locationId),
                      const SizedBox(height: 20),
                      // Error banner
                      if (_publishError != null) ...[
                        _ErrorBanner(
                          error: _publishError!,
                          onDismiss: () => setState(() => _publishError = null),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Publish Now button
                      GoldButton(
                        label: _publishedSuccessfully
                            ? '✅ Published!'
                            : _publishing
                                ? 'Publishing…'
                                : 'Publish Now to Google Business',
                        icon: _publishedSuccessfully
                            ? Icons.check_circle_rounded
                            : Icons.send_rounded,
                        onTap: (_publishing || _publishedSuccessfully)
                            ? null
                            : _publishNow,
                      ),
                      const SizedBox(height: 12),
                      // Fallback option
                      const Divider(color: TRColors.navyLight),
                      const SizedBox(height: 12),
                      const Center(
                        child: Text(
                          'Or publish manually:',
                          style: TextStyle(
                              color: TRColors.grayMid, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildManualActions(),
                    ]

                    // ═══════════════════════════════════════════════════════
                    // MANUAL MODE (Phase 1) — no gbpLocationId yet
                    // ═══════════════════════════════════════════════════════
                    else ...[
                      _StepGuide(),
                      const SizedBox(height: 20),
                      _buildManualActions(),
                      const SizedBox(height: 24),
                      const Divider(color: TRColors.navyLight),
                      const SizedBox(height: 16),
                      GoldButton(
                        label: 'Mark as Published',
                        icon: Icons.check_circle_outline_rounded,
                        onTap: _markPublished,
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          "Tap after you've posted to GBP to mark this complete.",
                          style: TextStyle(
                              color: TRColors.grayMid.withValues(alpha: 0.7),
                              fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // Setup prompt
                      const SizedBox(height: 20),
                      _SetupGbpBanner(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManualActions() => Column(children: [
    _ActionButton(
      icon: _copied ? Icons.check_circle_rounded : Icons.copy_rounded,
      label: _copied ? 'Copied!' : 'Copy Caption',
      subtitle: 'Paste directly into your GBP post',
      color: _copied ? TRColors.success : TRColors.gold,
      onTap: _copyCaption,
    ),
    const SizedBox(height: 10),
    _ActionButton(
      icon: Icons.share_rounded,
      label: _sharing ? 'Opening share…' : 'Share After Photo',
      subtitle: 'Save image to camera roll or share to GBP',
      color: TRColors.grayLight,
      onTap: _sharing ? null : _shareImage,
    ),
    const SizedBox(height: 10),
    _ActionButton(
      icon: Icons.open_in_new_rounded,
      label: 'Open Google Business Profile',
      subtitle: 'Launches GBP app or website to create your post',
      color: const Color(0xFF4285F4),
      onTap: _openGbp,
    ),
  ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP GUIDE WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _StepGuide extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF4285F4).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF4285F4).withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: Color(0xFF4285F4), size: 16),
              SizedBox(width: 8),
              Text('How to post to Google Business',
                  style: TextStyle(
                      color: Color(0xFF4285F4),
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          ...[
            ('1', 'Tap "Copy Caption" to copy your post text'),
            ('2', 'Tap "Share After Photo" to save the image'),
            ('3', 'Tap "Open Google Business Profile"'),
            ('4', 'Create a new post → paste caption → attach photo'),
            ('5', 'Tap "Mark as Published" when done'),
          ].map((step) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4285F4),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(step.$1,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(step.$2,
                          style: const TextStyle(
                              color: TRColors.grayLight,
                              fontSize: 13,
                              height: 1.4)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED SUB-WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: TRColors.gold, size: 16),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                color: TRColors.grayLight,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4)),
      ],
    );
  }
}

/// Horizontal chip row for selecting which submitted photo goes in a slot.
class _PhotoChipRow extends StatelessWidget {
  final List<SubmittedPhoto> photos;
  final int? selectedIdx;
  final ValueChanged<int> onSelect;

  const _PhotoChipRow({
    required this.photos,
    required this.selectedIdx,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return const Text('No photos',
          style: TextStyle(color: TRColors.grayMid, fontSize: 13));
    }
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final photo = photos[i];
          final selected = selectedIdx == i;
          final url = photo.displayUrl;
          return GestureDetector(
            onTap: () => onSelect(i),
            child: Stack(
              children: [
                Container(
                  width: 64,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? TRColors.gold
                          : TRColors.navyLight.withValues(alpha: 0.5),
                      width: selected ? 2 : 1,
                    ),
                    image: url != null
                        ? DecorationImage(
                            image: NetworkImage(url),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: TRColors.navyDark,
                  ),
                  child: url == null
                      ? const Icon(Icons.image_not_supported_outlined,
                          color: TRColors.grayMid, size: 22)
                      : null,
                ),
                if (selected)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: TRColors.gold,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: TRColors.navyDark, size: 12),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: TRColors.navyDark.withValues(alpha: 0.75),
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(9)),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      photo.type.name.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: TRColors.grayMid,
                          fontSize: 8,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Square photo preview tile with a BEFORE/AFTER label badge.
class _PhotoPreviewTile extends StatelessWidget {
  final String label;
  final String? url;
  final Color borderColor;
  final double height;

  const _PhotoPreviewTile({
    required this.label,
    required this.url,
    required this.borderColor,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
        color: TRColors.navyDark,
        image: url != null && url!.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(url!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: url == null || url!.isEmpty
          ? Center(
              child: Icon(Icons.image_not_supported_outlined,
                  color: TRColors.grayMid.withValues(alpha: 0.4), size: 28))
          : Stack(
              children: [
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: TRColors.navyDark.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: Text(label,
                        style: TextStyle(
                            color: borderColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Tappable action button for the PublishSheet.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: TRColors.navyDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            color: color,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            color: TRColors.grayMid, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: color.withValues(alpha: 0.5), size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PHASE 2 SUB-WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

/// Shows the GBP location resource ID that will be posted to.
class _GbpLocationChip extends StatelessWidget {
  final String locationId;
  const _GbpLocationChip({required this.locationId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF4285F4).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF4285F4).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_rounded,
              color: Color(0xFF4285F4), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GBP Location Connected',
                  style: TextStyle(
                      color: Color(0xFF4285F4),
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  locationId,
                  style: const TextStyle(
                      color: TRColors.grayMid,
                      fontSize: 11,
                      fontFamily: 'monospace'),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Red error banner shown when Railway publish call fails.
class _ErrorBanner extends StatelessWidget {
  final String error;
  final VoidCallback onDismiss;
  const _ErrorBanner({required this.error, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TRColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TRColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: TRColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                  color: TRColors.error, fontSize: 13, height: 1.4),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close_rounded,
                color: TRColors.error, size: 16),
          ),
        ],
      ),
    );
  }
}

/// Shown in manual mode to nudge admin toward setting up Phase 2.
class _SetupGbpBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TRColors.goldDark.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TRColors.goldDark.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.bolt_rounded, color: TRColors.gold, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enable one-tap publishing',
                  style: TextStyle(
                      color: TRColors.gold,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4),
                Text(
                  'Set your GBP Location ID in Profile → Google Business Profile '
                  'to publish directly from this screen — no copy/paste needed.',
                  style: TextStyle(
                      color: TRColors.grayMid,
                      fontSize: 12,
                      height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
