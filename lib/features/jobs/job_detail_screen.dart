import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/services/app_state.dart';
import '../../shared/widgets/tr_widgets.dart';
import '../../shared/models/models.dart';
import '../../shared/models/sms_models.dart';
import '../sms/sms_widgets.dart';

class JobDetailScreen extends StatelessWidget {
  final Job job;
  const JobDetailScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final currentJob = state.jobs.firstWhere((j) => j.id == job.id, orElse: () => job);

    return Scaffold(
      backgroundColor: TRColors.navyDeep,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, currentJob),
          SliverToBoxAdapter(child: _buildBody(context, currentJob, state)),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context, currentJob, state),
    );
  }

  Widget _buildAppBar(BuildContext context, Job job) {
    return SliverAppBar(
      backgroundColor: TRColors.navyDeep,
      expandedHeight: 120,
      floating: true,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: TRColors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(60, 0, 20, 16),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(job.customerName, style: const TextStyle(
              color: TRColors.white, fontSize: 16, fontWeight: FontWeight.w800,
            )),
            StatusBadge(status: job.status, compact: true),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert_rounded, color: TRColors.white),
          onPressed: () => _showActions(context, job),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, Job job, AppState state) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(job),
          const SizedBox(height: 16),
          _buildStatusTracker(job),
          const SizedBox(height: 16),
          _buildSmsStatusSection(context, job, state),
          const SizedBox(height: 16),
          _buildPhotoSection(context, job),
          const SizedBox(height: 16),
          _buildTemplateSection(context, job, state),
          const SizedBox(height: 16),
          _buildReviewSection(context, job, state),
          const SizedBox(height: 16),
          _buildNotesSection(job),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Job job) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TRColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TRColors.divider),
      ),
      child: Column(
        children: [
          _InfoRow(icon: Icons.work_rounded, label: 'Job Type', value: job.jobType),
          const Divider(color: TRColors.divider, height: 20),
          _InfoRow(icon: Icons.location_on_rounded, label: 'Address', value: job.address),
          const Divider(color: TRColors.divider, height: 20),
          _InfoRow(icon: Icons.phone_rounded, label: 'Phone', value: job.phone),
          const Divider(color: TRColors.divider, height: 20),
          _InfoRow(icon: Icons.email_rounded, label: 'Email', value: job.email),
          if (job.startDate != null) ...[
            const Divider(color: TRColors.divider, height: 20),
            _InfoRow(
              icon: Icons.calendar_today_rounded,
              label: 'Start Date',
              value: _formatDate(job.startDate!),
            ),
          ],
          if (job.completionDate != null) ...[
            const Divider(color: TRColors.divider, height: 20),
            _InfoRow(
              icon: Icons.check_circle_rounded,
              label: 'Completed',
              value: _formatDate(job.completionDate!),
              valueColor: TRColors.success,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusTracker(Job job) {
    final statuses = JobStatus.values;
    final currentIdx = statuses.indexOf(job.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TRColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TRColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Job Progress', style: TextStyle(
            color: TRColors.white, fontSize: 15, fontWeight: FontWeight.w700,
          )),
          const SizedBox(height: 16),
          Row(
            children: statuses.asMap().entries.map((entry) {
              final i = entry.key;
              final status = entry.value;
              final isCompleted = i <= currentIdx;
              final isCurrent = i == currentIdx;
              final color = JobStatusTheme.color(status.displayName);

              return Expanded(child: Row(
                children: [
                  Expanded(child: Column(
                    children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: isCompleted ? (isCurrent ? color : TRColors.success) : TRColors.cardMid,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCompleted ? (isCurrent ? color : TRColors.success) : TRColors.divider,
                            width: isCurrent ? 2 : 1,
                          ),
                        ),
                        child: isCompleted
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                          : null,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        status.displayName.split(' ').first,
                        style: TextStyle(
                          color: isCompleted ? TRColors.white : TRColors.grayMid,
                          fontSize: 9,
                          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )),
                  if (i < statuses.length - 1)
                    Container(
                      width: 16, height: 1.5,
                      color: i < currentIdx ? TRColors.success : TRColors.divider,
                    ),
                ],
              ));
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(BuildContext context, Job job) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TRColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TRColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Project Photos', style: TextStyle(
                color: TRColors.white, fontSize: 15, fontWeight: FontWeight.w700,
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
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_a_photo_rounded, color: TRColors.gold, size: 14),
                      SizedBox(width: 4),
                      Text('Add Photo', style: TextStyle(
                        color: TRColors.gold, fontSize: 12, fontWeight: FontWeight.w600,
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (job.photos.isEmpty)
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: TRColors.cardMid,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: TRColors.divider, style: BorderStyle.solid),
              ),
              child: const Center(child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_library_outlined, color: TRColors.grayMid, size: 28),
                  SizedBox(height: 6),
                  Text('No photos yet', style: TextStyle(color: TRColors.grayMid, fontSize: 13)),
                ],
              )),
            )
          else
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: job.photos.length + 1,
                itemBuilder: (_, i) {
                  if (i == job.photos.length) {
                    return Container(
                      width: 90, height: 90,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: TRColors.cardMid,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: TRColors.divider),
                      ),
                      child: const Icon(Icons.add_rounded, color: TRColors.grayMid, size: 28),
                    );
                  }
                  final photo = job.photos[i];
                  return Container(
                    width: 90, height: 90,
                    margin: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(photo.url, fit: BoxFit.cover),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTemplateSection(BuildContext context, Job job, AppState state) {
    final template = state.templates.firstWhere(
      (t) => t.id == job.templateId,
      orElse: () => state.templates.first,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TRColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TRColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${template.emoji} Photo Checklist', style: const TextStyle(
                color: TRColors.white, fontSize: 15, fontWeight: FontWeight.w700,
              )),
              const Spacer(),
              Text(template.name, style: const TextStyle(
                color: TRColors.grayLight, fontSize: 12,
              )),
            ],
          ),
          const SizedBox(height: 12),
          ...template.shots.map((shot) {
            // ignore: dead_code
            const isComplete = false; // placeholder — wire to uploaded photos set
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      // ignore: dead_code
                      color: isComplete ? TRColors.success.withValues(alpha: 0.2) : TRColors.cardMid,
                      shape: BoxShape.circle,
                      border: Border.all(
                        // ignore: dead_code
                        color: isComplete ? TRColors.success : TRColors.divider,
                      ),
                    ),
                    child: isComplete
                      // ignore: dead_code
                      ? const Icon(Icons.check_rounded, color: TRColors.success, size: 12)
                      : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shot.name, style: const TextStyle(
                        color: TRColors.white, fontSize: 13, fontWeight: FontWeight.w600,
                      )),
                      Text(shot.instruction, style: const TextStyle(
                        color: TRColors.grayMid, fontSize: 11,
                      )),
                    ],
                  )),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: _phaseColor(shot.phase).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      shot.phase.name.toUpperCase(),
                      style: TextStyle(
                        color: _phaseColor(shot.phase),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Status SMS Section ──────────────────────────────────────────────────────
  Widget _buildSmsStatusSection(BuildContext context, Job job, AppState state) {
    // Show for all statuses except lead and completed (review covers completed)
    if (job.status == JobStatus.lead || job.status == JobStatus.completed) {
      return const SizedBox.shrink();
    }

    final jobSmsLog = state.smsForJob(job.id);
    final companyName = state.company?.name ?? 'our team';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TRColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TRColors.info.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.sms_rounded, color: TRColors.info, size: 20),
            const SizedBox(width: 8),
            const Text('Send Status Update', style: TextStyle(
              color: TRColors.white, fontSize: 15, fontWeight: FontWeight.w700,
            )),
            const Spacer(),
            if (jobSmsLog.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: TRColors.info.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${jobSmsLog.length} sent', style: const TextStyle(
                  color: TRColors.info, fontSize: 10, fontWeight: FontWeight.w700,
                )),
              ),
          ]),
          const SizedBox(height: 6),
          Text(
            'Keep ${job.customerName} informed with a quick text update.',
            style: const TextStyle(color: TRColors.grayLight, fontSize: 13),
          ),
          const SizedBox(height: 14),
          GoldButton(
            label: 'Send Status SMS',
            icon: Icons.sms_rounded,
            outlined: true,
            compact: true,
            onTap: () => showSendSmsSheet(
              context,
              jobId: job.id,
              customerName: job.customerName,
              customerPhone: job.phone,
              jobType: job.jobType,
              companyName: companyName,
              templates: SmsTemplates.statusTemplates,
              title: 'Status Update',
            ),
          ),
          // Last SMS sent indicator
          if (jobSmsLog.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.check_circle_outline_rounded,
                  color: TRColors.success, size: 13),
              const SizedBox(width: 5),
              Text(
                'Last: "${jobSmsLog.first.templateKey.replaceAll('status_', '').replaceAll('_', ' ')}" — '
                '${_timeAgo(jobSmsLog.first.sentAt)}',
                style: const TextStyle(color: TRColors.grayMid, fontSize: 11),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  // ── Review Request Section ──────────────────────────────────────────────────
  Widget _buildReviewSection(BuildContext context, Job job, AppState state) {
    if (job.status != JobStatus.completed) return const SizedBox.shrink();

    final companyName = state.company?.name ?? 'our team';
    // Pull the review link from this company's Firestore document
    final reviewLink = state.company?.googleReviewLink;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TRColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: job.reviewSent
              ? TRColors.success.withValues(alpha: 0.3)
              : TRColors.gold.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.star_rounded,
                color: job.reviewSent ? TRColors.success : TRColors.gold,
                size: 20),
            const SizedBox(width: 8),
            Text(
              job.reviewSent ? 'Review Request Sent' : 'Request a Review',
              style: const TextStyle(
                  color: TRColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            job.reviewSent
                ? 'A review request was sent to ${job.customerName}. Check Reviews tab for status.'
                : 'Job is complete! Send ${job.customerName} a Google review request to grow your reputation.',
            style: const TextStyle(color: TRColors.grayLight, fontSize: 13),
          ),
          if (!job.reviewSent) ...[
            const SizedBox(height: 14),
            GoldButton(
              label: 'Send Review Request via SMS',
              icon: Icons.star_rounded,
              compact: true,
              onTap: () => showSendSmsSheet(
                context,
                jobId: job.id,
                customerName: job.customerName,
                customerPhone: job.phone,
                jobType: job.jobType,
                companyName: companyName,
                reviewLink: reviewLink,
                templates: SmsTemplates.reviewTemplates,
                title: 'Review Request',
              ),
            ),
          ],
          if (job.reviewSent) ...[
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.check_circle_rounded,
                  color: TRColors.success, size: 14),
              const SizedBox(width: 6),
              const Text('Review request sent via SMS',
                  style: TextStyle(color: TRColors.success, fontSize: 12)),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesSection(Job job) {
    return Container(
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
              Icon(Icons.notes_rounded, color: TRColors.grayLight, size: 18),
              SizedBox(width: 8),
              Text('Internal Notes', style: TextStyle(
                color: TRColors.white, fontSize: 15, fontWeight: FontWeight.w700,
              )),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            job.notes ?? 'No notes added yet.',
            style: const TextStyle(color: TRColors.grayLight, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, Job job, AppState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: const BoxDecoration(
        color: TRColors.cardDark,
        border: Border(top: BorderSide(color: TRColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(child: _nextStatusButton(context, job, state)),
          const SizedBox(width: 10),
          Container(
            height: 54,
            decoration: BoxDecoration(
              color: TRColors.cardMid,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: TRColors.divider),
            ),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.camera_alt_rounded, color: TRColors.gold, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nextStatusButton(BuildContext context, Job job, AppState state) {
    if (job.status == JobStatus.completed) {
      return GoldButton(label: 'Job Complete ✓', onTap: null);
    }

    final nextStatuses = {
      JobStatus.lead: JobStatus.scheduled,
      JobStatus.scheduled: JobStatus.inProgress,
      JobStatus.inProgress: JobStatus.awaitingApproval,
      JobStatus.awaitingApproval: JobStatus.completed,
    };

    final nextStatus = nextStatuses[job.status];
    if (nextStatus == null) return const SizedBox.shrink();

    final labels = {
      JobStatus.scheduled: '→ Mark Scheduled',
      JobStatus.inProgress: '→ Start Job',
      JobStatus.awaitingApproval: '→ Submit for Approval',
      JobStatus.completed: '→ Mark Complete',
    };

    return GoldButton(
      label: labels[nextStatus] ?? 'Next Step',
      onTap: () {
        state.updateJobStatus(job.id, nextStatus);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Job updated to: ${nextStatus.displayName}'),
          backgroundColor: TRColors.success,
        ));
      },
    );
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  Color _phaseColor(PhotoType type) {
    switch (type) {
      case PhotoType.before:   return TRColors.info;
      case PhotoType.progress: return TRColors.warning;
      case PhotoType.after:    return TRColors.success;
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _showActions(BuildContext context, Job job) {
    showModalBottomSheet(
      context: context,
      backgroundColor: TRColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(
              color: TRColors.divider, borderRadius: BorderRadius.circular(2),
            )),
            const SizedBox(height: 20),
            _ActionTile(icon: Icons.edit_rounded, label: 'Edit Job Details', onTap: () => Navigator.pop(context)),
            _ActionTile(icon: Icons.person_add_rounded, label: 'Assign Crew', onTap: () => Navigator.pop(context)),
            _ActionTile(icon: Icons.share_rounded, label: 'Share Job Link', onTap: () => Navigator.pop(context)),
            _ActionTile(icon: Icons.delete_outline_rounded, label: 'Archive Job', color: TRColors.error, onTap: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: TRColors.grayMid, size: 16),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: TRColors.grayMid, fontSize: 11)),
            Text(value, style: TextStyle(
              color: valueColor ?? TRColors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            )),
          ],
        )),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionTile({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? TRColors.white;
    return ListTile(
      leading: Icon(icon, color: c, size: 20),
      title: Text(label, style: TextStyle(color: c, fontSize: 15, fontWeight: FontWeight.w600)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }
}
