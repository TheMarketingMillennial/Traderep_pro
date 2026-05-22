import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/services/app_state.dart';
import '../../shared/widgets/tr_widgets.dart';
import '../../shared/models/models.dart';
import '../../shared/models/sms_models.dart';
import '../sms/sms_widgets.dart';

class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final reviews = state.reviews;

    final total = reviews.length;
    final completed = reviews.where((r) => r.reviewed).length;
    final opened = reviews.where((r) => r.opened).length;

    return Scaffold(
      backgroundColor: TRColors.navyDeep,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildStats(total, completed, opened, state.analytics.avgRating)),
            SliverToBoxAdapter(child: _buildPolicy()),
            SliverToBoxAdapter(child: _buildList(context, state, reviews)),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final smsCount = context.watch<AppState>().smsLog.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reviews', style: TextStyle(
                color: TRColors.white, fontSize: 24, fontWeight: FontWeight.w800,
              )),
              SizedBox(height: 4),
              Text('Track review requests and Google star ratings', style: TextStyle(
                color: TRColors.grayLight, fontSize: 14,
              )),
            ],
          )),
          // SMS History button
          GestureDetector(
            onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SmsHistoryScreen())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: TRColors.cardDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: TRColors.divider),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.sms_rounded, color: TRColors.info, size: 15),
                const SizedBox(width: 5),
                Text(
                  smsCount > 0 ? 'SMS Log ($smsCount)' : 'SMS Log',
                  style: const TextStyle(
                    color: TRColors.info, fontSize: 12, fontWeight: FontWeight.w600,
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(int total, int completed, int opened, double avg) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Expanded(child: _ReviewStat(value: '$total', label: 'Requests Sent', color: TRColors.info)),
          const SizedBox(width: 10),
          Expanded(child: _ReviewStat(value: '$completed', label: 'Reviews Left', color: TRColors.success)),
          const SizedBox(width: 10),
          Expanded(child: _ReviewStat(value: '${avg.toStringAsFixed(1)}★', label: 'Avg Rating', color: TRColors.gold)),
        ],
      ),
    );
  }

  Widget _buildPolicy() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TRColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TRColors.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, color: TRColors.success, size: 20),
          const SizedBox(width: 10),
          const Expanded(child: Text(
            'TradeRep follows Google\'s review policies. We never filter or gate reviews — all customers receive equal treatment.',
            style: TextStyle(color: TRColors.grayLight, fontSize: 12, height: 1.4),
          )),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, AppState state, List<ReviewRequest> reviews) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Review History'),
          const SizedBox(height: 12),
          ...reviews.map((review) => _ReviewTile(review: review)),
          const SizedBox(height: 20),
          _buildCompletedJobs(context, state),
        ],
      ),
    );
  }

  Widget _buildCompletedJobs(BuildContext context, AppState state) {
    final completed = state.completedJobs.where((j) => !j.reviewSent).toList();
    if (completed.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Text('Pending Review Requests', style: TextStyle(
            color: TRColors.white, fontSize: 17, fontWeight: FontWeight.w700,
          )),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: TRColors.gold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('${completed.length}', style: const TextStyle(
              color: TRColors.gold, fontSize: 11, fontWeight: FontWeight.w700,
            )),
          ),
        ]),
        const SizedBox(height: 10),
        const Text('These jobs are complete but haven\'t received review requests yet.',
          style: TextStyle(color: TRColors.grayMid, fontSize: 13)),
        const SizedBox(height: 12),
        ...completed.map((job) => _PendingReviewTile(job: job, state: state)),
      ],
    );
  }
}

// ─── Pending Review Tile ──────────────────────────────────────────────────────
class _PendingReviewTile extends StatelessWidget {
  final Job job;
  final AppState state;
  const _PendingReviewTile({required this.job, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TRColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TRColors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.star_outline_rounded, color: TRColors.gold, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(job.customerName, style: const TextStyle(
              color: TRColors.white, fontSize: 14, fontWeight: FontWeight.w600,
            )),
            Text(job.jobType, style: const TextStyle(
              color: TRColors.grayMid, fontSize: 12,
            )),
          ],
        )),
        GestureDetector(
          onTap: () => showSendSmsSheet(
            context,
            jobId: job.id,
            customerName: job.customerName,
            customerPhone: job.phone,
            jobType: job.jobType,
            companyName: state.company?.name ?? 'our team',
            templates: SmsTemplates.reviewTemplates,
            title: 'Review Request',
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: TRColors.gold,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.sms_rounded, color: TRColors.navyDeep, size: 13),
              SizedBox(width: 5),
              Text('Send SMS', style: TextStyle(
                color: TRColors.navyDeep, fontSize: 12, fontWeight: FontWeight.w700,
              )),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _ReviewStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _ReviewStat({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: TRColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TRColors.divider),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(
            color: color, fontSize: 22, fontWeight: FontWeight.w800,
          )),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(
            color: TRColors.grayMid, fontSize: 11, fontWeight: FontWeight.w500,
          ), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final ReviewRequest review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TRColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TRColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(review.customerName, style: const TextStyle(
                color: TRColors.white, fontSize: 14, fontWeight: FontWeight.w700,
              )),
              Row(
                children: [
                  if (review.reviewed && review.starRating != null)
                    Row(children: List.generate(5, (i) => Icon(
                      Icons.star_rounded,
                      color: i < review.starRating! ? TRColors.gold : TRColors.divider,
                      size: 16,
                    ))),
                  if (!review.reviewed)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: review.opened ? TRColors.info.withValues(alpha: 0.2) : TRColors.cardMid,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: review.opened ? TRColors.info : TRColors.divider),
                      ),
                      child: Text(
                        review.opened ? 'Opened' : 'Delivered',
                        style: TextStyle(
                          color: review.opened ? TRColors.info : TRColors.grayMid,
                          fontSize: 10, fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                review.method == 'sms' ? Icons.sms_rounded : Icons.email_rounded,
                color: TRColors.grayMid, size: 13,
              ),
              const SizedBox(width: 4),
              Text(review.sentTo, style: const TextStyle(color: TRColors.grayMid, fontSize: 12)),
              const Spacer(),
              Text(_timeAgo(review.sentAt), style: const TextStyle(color: TRColors.grayMid, fontSize: 11)),
            ],
          ),
          if (review.reviewed) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: TRColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: TRColors.success.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, color: TRColors.success, size: 12),
                  SizedBox(width: 5),
                  Text('Google review submitted', style: TextStyle(
                    color: TRColors.success, fontSize: 11, fontWeight: FontWeight.w600,
                  )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }
}
