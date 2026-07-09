import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/services/app_state.dart';
import 'pricing_models.dart';
import 'pricing_screen.dart';

// ─── Trial Countdown Banner ───────────────────────────────────────────────────
// Placed at the top of the dashboard when in trial mode
class TrialBanner extends StatelessWidget {
  const TrialBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.isInTrial) return const SizedBox.shrink();

    final days = state.trialDaysRemaining;
    final isUrgent = days <= 3;
    final color = isUrgent ? TRColors.error : TRColors.gold;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => const PricingScreen(),
      )),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            // Countdown circle
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$days', style: TextStyle(
                    color: color, fontSize: 16, fontWeight: FontWeight.w900, height: 1,
                  )),
                  Text('days', style: TextStyle(
                    color: color, fontSize: 7, fontWeight: FontWeight.w600,
                  )),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isUrgent ? 'Trial ending soon!' : 'Free Trial Active',
                    style: TextStyle(
                      color: color, fontSize: 13, fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    isUrgent
                      ? 'Subscribe now to keep your reputation running.'
                      : 'You have $days days left. Subscribe to continue.',
                    style: const TextStyle(color: TRColors.grayLight, fontSize: 11),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isUrgent ? 'Subscribe' : 'Subscribe',
                style: TextStyle(
                  color: isUrgent ? TRColors.white : TRColors.navyDeep,
                  fontSize: 12, fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Trial Progress Bar ───────────────────────────────────────────────────────
class TrialProgressBar extends StatelessWidget {
  const TrialProgressBar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.isInTrial) return const SizedBox.shrink();

    final progress = state.subscription.trialProgress;
    final days = state.trialDaysRemaining;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TRColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TRColors.divider),
      ),
      child: Column(children: [
        Row(children: [
          const Icon(Icons.timer_rounded, color: TRColors.grayLight, size: 14),
          const SizedBox(width: 6),
          const Expanded(child: Text('Trial Progress', style: TextStyle(
            color: TRColors.grayLight, fontSize: 12, fontWeight: FontWeight.w600,
          ))),
          Text('$days days remaining', style: const TextStyle(
            color: TRColors.gold, fontSize: 12, fontWeight: FontWeight.w700,
          )),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: TRColors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(
              days <= 3 ? TRColors.error : TRColors.gold,
            ),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 6),
        const Row(children: [
          Text('Day 1', style: TextStyle(color: TRColors.grayMid, fontSize: 10)),
          Spacer(),
          Text('Day 14', style: TextStyle(color: TRColors.grayMid, fontSize: 10)),
        ]),
      ]),
    );
  }
}

// ─── Plan Badge (shown on dashboard header) ───────────────────────────────────
// Shows subscription status — Trial or Active — without tier references.
class PlanBadge extends StatelessWidget {
  const PlanBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final sub = state.subscription;
    final isTrialing = state.isInTrial;
    final color = isTrialing ? TRColors.gold : TRColors.success;
    final label = isTrialing ? 'TradeRep Pro · Trial' : 'TradeRep Pro';

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => const PricingScreen(),
      )),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspace_premium_rounded, color: color, size: 13),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w700,
              ),
            ),
            // Seat info for active subscriptions
            if (sub.isActive) ...[
              const SizedBox(width: 6),
              Container(
                width: 1, height: 10,
                color: color.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 6),
              Text(
                '${sub.purchasedSeats} seats',
                style: TextStyle(
                  color: color.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Subscription Status Card ─────────────────────────────────────────────────
class SubscriptionCard extends StatelessWidget {
  const SubscriptionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final sub = state.subscription;
    // Single plan: always TRColors.gold accent
    const color = TRColors.gold;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => const PricingScreen(),
      )),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0x1FF7BE1A), // gold @ ~12%
              TRColors.cardDark,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.workspace_premium_rounded, color: color, size: 22),
              const SizedBox(width: 8),
              const Text('TradeRep Pro', style: TextStyle(
                color: TRColors.white, fontSize: 16, fontWeight: FontWeight.w800,
              )),
              const Spacer(),
              _SubStatusBadge(status: sub.status),
            ]),
            const SizedBox(height: 8),

            // Seat summary
            _SeatSummaryRow(sub: sub),
            const SizedBox(height: 8),

            if (sub.isInTrial) ...[
              Text('Trial ends in ${sub.trialDaysRemaining} days', style: const TextStyle(
                color: TRColors.grayLight, fontSize: 13,
              )),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: sub.trialProgress,
                  backgroundColor: TRColors.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    sub.trialDaysRemaining <= 3 ? TRColors.error : color,
                  ),
                  minHeight: 5,
                ),
              ),
            ] else ...[
              Text(
                sub.nextBillingDate != null
                  ? 'Next billing: ${_formatDate(sub.nextBillingDate!)} · \$${sub.currentMonthlyTotal.toStringAsFixed(2)}/mo'
                  : '\$${sub.currentMonthlyTotal.toStringAsFixed(2)}/month',
                style: const TextStyle(color: TRColors.grayLight, fontSize: 13),
              ),
            ],
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PricingScreen())),
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Center(child: Text('Manage Plan', style: TextStyle(
                    color: color, fontSize: 13, fontWeight: FontWeight.w700,
                  ))),
                ),
              )),
              const SizedBox(width: 8),
              Expanded(child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BillingScreen())),
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: TRColors.cardMid,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: TRColors.divider),
                  ),
                  child: const Center(child: Text('Billing', style: TextStyle(
                    color: TRColors.grayLight, fontSize: 13, fontWeight: FontWeight.w600,
                  ))),
                ),
              )),
            ]),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[date.month-1]} ${date.day}, ${date.year}';
  }
}

// ─── Seat Summary Row ─────────────────────────────────────────────────────────
class _SeatSummaryRow extends StatelessWidget {
  final ActiveSubscription sub;
  const _SeatSummaryRow({required this.sub});

  @override
  Widget build(BuildContext context) {
    final total = sub.purchasedSeats;
    final extra = sub.extraSeats;
    return Row(children: [
      const Icon(Icons.people_rounded, color: TRColors.grayMid, size: 14),
      const SizedBox(width: 6),
      Text(
        '$total seat${total == 1 ? '' : 's'} '
        '(${TRPlan.includedSeats} included'
        '${extra > 0 ? ' + $extra extra' : ''})',
        style: const TextStyle(color: TRColors.grayLight, fontSize: 12),
      ),
    ]);
  }
}

class _SubStatusBadge extends StatelessWidget {
  final SubscriptionStatus status;
  const _SubStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final configs = {
      SubscriptionStatus.trial:     (TRColors.gold,    'TRIAL'),
      SubscriptionStatus.active:    (TRColors.success,  'ACTIVE'),
      SubscriptionStatus.pastDue:   (TRColors.error,    'PAST DUE'),
      SubscriptionStatus.cancelled: (TRColors.grayMid,  'CANCELLED'),
      SubscriptionStatus.none:      (TRColors.grayMid,  'INACTIVE'),
    };
    final cfg = configs[status] ?? (TRColors.grayMid, 'UNKNOWN');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cfg.$1.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cfg.$1.withValues(alpha: 0.35)),
      ),
      child: Text(cfg.$2, style: TextStyle(
        color: cfg.$1, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5,
      )),
    );
  }
}

// ─── Billing Screen ───────────────────────────────────────────────────────────
class BillingScreen extends StatelessWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final sub = state.subscription;

    return Scaffold(
      backgroundColor: TRColors.navyDeep,
      appBar: AppBar(
        backgroundColor: TRColors.navyDeep,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: TRColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Billing & Subscription', style: TextStyle(
          color: TRColors.white, fontSize: 18, fontWeight: FontWeight.w700,
        )),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current plan card
            const SubscriptionCard(),
            const SizedBox(height: 20),

            // Metrics row
            const Text('SUBSCRIPTION METRICS', style: TextStyle(
              color: TRColors.grayMid, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8,
            )),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _MetricCard(
                label: 'MRR',
                value: '\$${sub.currentMonthlyTotal.toStringAsFixed(2)}',
                icon: Icons.attach_money_rounded,
                color: TRColors.success,
              )),
              const SizedBox(width: 10),
              Expanded(child: _MetricCard(
                label: 'Seats',
                value: '${sub.purchasedSeats}',
                icon: Icons.people_rounded,
                color: TRColors.gold,
              )),
              const SizedBox(width: 10),
              Expanded(child: _MetricCard(
                label: 'Status',
                value: sub.status.displayName,
                icon: Icons.circle,
                color: sub.isInTrial ? TRColors.gold : TRColors.success,
              )),
            ]),
            const SizedBox(height: 20),

            // Stripe info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TRColors.cardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: TRColors.info.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.credit_card_rounded, color: TRColors.info, size: 20),
                    SizedBox(width: 8),
                    Text('Stripe Billing', style: TextStyle(
                      color: TRColors.white, fontSize: 15, fontWeight: FontWeight.w700,
                    )),
                  ]),
                  const SizedBox(height: 8),
                  const Text(
                    'TradeRep Pro uses Stripe for secure subscription billing. Your payment information is encrypted and never stored on our servers.',
                    style: TextStyle(color: TRColors.grayLight, fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  ...[
                    ('Recurring billing', 'Automatic monthly charges via Stripe'),
                    ('Trial management', '14-day free trial with grace period'),
                    ('Seat management', 'Automatically adjusts when you invite team'),
                    ('Failed payment handling', 'Retry logic + email notifications'),
                    ('Billing history', 'Full invoice records via Stripe Portal'),
                  ].map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      const Icon(Icons.check_circle_rounded, color: TRColors.success, size: 14),
                      const SizedBox(width: 8),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.$1, style: const TextStyle(color: TRColors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          Text(item.$2, style: const TextStyle(color: TRColors.grayMid, fontSize: 11)),
                        ],
                      )),
                    ]),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Seat pricing note
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: TRColors.goldDim,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TRColors.gold.withValues(alpha: 0.25)),
              ),
              child: Row(children: [
                const Icon(Icons.people_alt_rounded, color: TRColors.gold, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Seat Pricing', style: TextStyle(
                      color: TRColors.gold, fontSize: 13, fontWeight: FontWeight.w700,
                    )),
                    Text(
                      '\$${TRPlan.monthlyPrice.toStringAsFixed(0)}/mo includes ${TRPlan.includedSeats} seats · '
                      '\$${TRPlan.extraSeatPrice.toStringAsFixed(2)}/mo per additional seat',
                      style: const TextStyle(color: TRColors.grayLight, fontSize: 12),
                    ),
                  ],
                )),
              ]),
            ),
            const SizedBox(height: 16),

            // Billing history
            const Text('BILLING HISTORY', style: TextStyle(
              color: TRColors.grayMid, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8,
            )),
            const SizedBox(height: 10),
            if (sub.billingHistory.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: TRColors.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TRColors.divider),
                ),
                child: const Center(child: Text(
                  'No billing history yet. Your first invoice will appear here.',
                  style: TextStyle(color: TRColors.grayMid, fontSize: 13),
                  textAlign: TextAlign.center,
                )),
              )
            else
              ...sub.billingHistory.map((record) => _BillingRow(record: record)),

            const SizedBox(height: 20),

            // Manage subscription actions
            const Text('MANAGE SUBSCRIPTION', style: TextStyle(
              color: TRColors.grayMid, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8,
            )),
            const SizedBox(height: 10),
            _BillingAction(
              icon: Icons.people_alt_rounded,
              label: 'Add Team Seats',
              subtitle: '\$${TRPlan.extraSeatPrice.toStringAsFixed(2)}/month per additional member',
              color: TRColors.success,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PricingScreen())),
            ),
            _BillingAction(
              icon: Icons.receipt_long_rounded,
              label: 'Download Invoices',
              subtitle: 'Access full billing history via Stripe',
              color: TRColors.grayLight,
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Redirecting to Stripe billing portal...'), backgroundColor: TRColors.info),
              ),
            ),
            _BillingAction(
              icon: Icons.cancel_outlined,
              label: 'Cancel Subscription',
              subtitle: 'Access ends at period end',
              color: TRColors.error,
              onTap: () => _showCancelDialog(context),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: TRColors.cardDark,
      title: const Text('Cancel Subscription?', style: TextStyle(color: TRColors.white, fontWeight: FontWeight.w700)),
      content: const Text(
        'Your access continues until the end of the current billing period. You can resubscribe at any time — your data is always preserved.',
        style: TextStyle(color: TRColors.grayLight, fontSize: 14, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Keep Subscription', style: TextStyle(color: TRColors.gold, fontWeight: FontWeight.w700)),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Subscription cancellation submitted.'), backgroundColor: TRColors.error),
            );
          },
          child: const Text('Cancel Anyway', style: TextStyle(color: TRColors.error)),
        ),
      ],
    ));
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: TRColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TRColors.divider),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(color: TRColors.grayMid, fontSize: 10)),
      ]),
    );
  }
}

class _BillingRow extends StatelessWidget {
  final BillingRecord record;
  const _BillingRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final dateStr = '${months[record.date.month-1]} ${record.date.day}, ${record.date.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TRColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TRColors.divider),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: TRColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.receipt_rounded, color: TRColors.success, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(record.description, style: const TextStyle(color: TRColors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            Text(dateStr, style: const TextStyle(color: TRColors.grayMid, fontSize: 11)),
          ],
        )),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('\$${record.amount.toStringAsFixed(2)}', style: const TextStyle(
            color: TRColors.white, fontSize: 14, fontWeight: FontWeight.w700,
          )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: TRColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(record.status.toUpperCase(), style: const TextStyle(
              color: TRColors.success, fontSize: 9, fontWeight: FontWeight.w700,
            )),
          ),
        ]),
      ]),
    );
  }
}

class _BillingAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _BillingAction({required this.icon, required this.label, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: TRColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: TRColors.divider),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700)),
              Text(subtitle, style: const TextStyle(color: TRColors.grayMid, fontSize: 12)),
            ],
          )),
          const Icon(Icons.chevron_right_rounded, color: TRColors.grayMid, size: 18),
        ]),
      ),
    );
  }
}
