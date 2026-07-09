// pricing_screen.dart — TradeRep Pro
// Single plan: $75/month, 3 seats included, $14.99/month per extra seat.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/services/app_state.dart';
import '../../shared/services/stripe_service.dart';
import 'pricing_models.dart';

class PricingScreen extends StatefulWidget {
  final bool showBackButton;
  const PricingScreen({super.key, this.showBackButton = true});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _handleSubscribe(AppState state) async {
    setState(() { _loading = true; _error = null; });
    try {
      final user = state.currentUser;
      if (user == null) {
        setState(() => _error = 'Please sign in before subscribing.');
        return;
      }
      final result = await StripeService.startTrialSubscription(
        email: user.email,
        name: user.name,
      );
      if (!mounted) return;
      if (result.success) {
        state.startTrial(
          stripeCustomerId: result.customerId,
          stripeSubscriptionId: result.subscriptionId,
        );
        Navigator.pop(context);
      } else {
        setState(() => _error = result.error ?? 'Subscription failed. Please try again.');
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not start checkout. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final sub = state.subscription;

    return Scaffold(
      backgroundColor: TRColors.navyDeep,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildPlanCard(state, sub)),
            SliverToBoxAdapter(child: _buildFeatureList()),
            SliverToBoxAdapter(child: _buildSeatInfo()),
            SliverToBoxAdapter(child: _buildFAQ()),
            SliverToBoxAdapter(child: _buildCTA(state, sub)),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          if (widget.showBackButton)
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: TRColors.cardDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: TRColors.divider),
                ),
                child: const Icon(Icons.arrow_back_rounded, color: TRColors.white, size: 18),
              ),
            ),
          if (widget.showBackButton) const SizedBox(width: 12),
          const Expanded(
            child: Text('Simple Pricing', style: TextStyle(
              color: TRColors.white, fontSize: 22, fontWeight: FontWeight.w800,
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(AppState state, ActiveSubscription sub) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [TRColors.gold.withValues(alpha: 0.15), TRColors.cardDark],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: TRColors.gold.withValues(alpha: 0.4), width: 1.5),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan name + badge
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: TRColors.gold,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('ONE PLAN', style: TextStyle(
                  color: TRColors.navyDeep, fontSize: 10, fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                )),
              ),
              const Spacer(),
              if (sub.isInTrial)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: TRColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: TRColors.success.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '${sub.trialDaysRemaining} days left in trial',
                    style: const TextStyle(color: TRColors.success, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
            ]),

            const SizedBox(height: 16),
            const Text('TradeRep Pro', style: TextStyle(
              color: TRColors.white, fontSize: 26, fontWeight: FontWeight.w900,
            )),
            const SizedBox(height: 8),

            // Price
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Text('\$75', style: TextStyle(
                color: TRColors.gold, fontSize: 52, fontWeight: FontWeight.w900, height: 1,
              )),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('/month', style: TextStyle(
                  color: TRColors.grayMid, fontSize: 16, fontWeight: FontWeight.w500,
                )),
              ),
            ]),

            const SizedBox(height: 4),
            const Text(
              'Includes 3 team members. No setup fee. No contracts.',
              style: TextStyle(color: TRColors.grayLight, fontSize: 13),
            ),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: TRColors.navyMid,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                const Icon(Icons.person_add_rounded, color: TRColors.gold, size: 18),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Additional team members: \$14.99/month each',
                    style: TextStyle(color: TRColors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureList() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Everything included', style: TextStyle(
            color: TRColors.white, fontSize: 17, fontWeight: FontWeight.w800,
          )),
          const SizedBox(height: 14),
          ...TRPlan.features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  color: TRColors.success.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: TRColors.success, size: 14),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(f, style: const TextStyle(
                color: TRColors.grayLight, fontSize: 14,
              ))),
            ]),
          )),
        ],
      ),
    );
  }

  Widget _buildSeatInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: TRColors.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: TRColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.group_rounded, color: TRColors.gold, size: 18),
              SizedBox(width: 8),
              Text('Team seats', style: TextStyle(
                color: TRColors.white, fontSize: 15, fontWeight: FontWeight.w700,
              )),
            ]),
            const SizedBox(height: 12),
            _seatRow('Base plan', '3 seats included', '\$75/mo'),
            const Divider(color: TRColors.divider, height: 20),
            _seatRow('4th team member', '+1 seat', '+\$14.99/mo'),
            const SizedBox(height: 4),
            _seatRow('5th team member', '+1 seat', '+\$14.99/mo'),
            const SizedBox(height: 4),
            _seatRow('Each additional', '+1 seat', '+\$14.99/mo'),
            const SizedBox(height: 12),
            const Text(
              'Seats are added automatically when you invite new team members. '
              'You\'ll see the cost before confirming.',
              style: TextStyle(color: TRColors.grayMid, fontSize: 12, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _seatRow(String label, String seats, String price) {
    return Row(children: [
      Expanded(child: Text(label, style: const TextStyle(color: TRColors.grayLight, fontSize: 13))),
      Text(seats, style: const TextStyle(color: TRColors.grayMid, fontSize: 12)),
      const SizedBox(width: 16),
      Text(price, style: const TextStyle(
        color: TRColors.white, fontSize: 13, fontWeight: FontWeight.w700,
      )),
    ]);
  }

  Widget _buildFAQ() {
    final faqs = [
      ('Is there a free trial?', 'Yes — 14 days free, no credit card required.'),
      ('Can I cancel anytime?', 'Yes. No contracts, no cancellation fees. Cancel from your account settings.'),
      ('What happens when I exceed 3 team members?', 'You\'ll be prompted to add a seat at \$14.99/month before the invitation is sent.'),
      ('Are there any setup fees?', 'None. Start using TradeRep Pro immediately after signing up.'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Common questions', style: TextStyle(
            color: TRColors.white, fontSize: 17, fontWeight: FontWeight.w800,
          )),
          const SizedBox(height: 14),
          ...faqs.map((faq) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TRColors.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TRColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(faq.$1, style: const TextStyle(
                    color: TRColors.white, fontSize: 14, fontWeight: FontWeight.w700,
                  )),
                  const SizedBox(height: 6),
                  Text(faq.$2, style: const TextStyle(
                    color: TRColors.grayLight, fontSize: 13, height: 1.5,
                  )),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildCTA(AppState state, ActiveSubscription sub) {
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: TRColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: TRColors.error.withValues(alpha: 0.3)),
          ),
          child: Text(_error!, style: const TextStyle(color: TRColors.error, fontSize: 13)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(children: [
        if (sub.isInTrial) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: TRColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: TRColors.success.withValues(alpha: 0.3)),
            ),
            child: Column(children: [
              const Icon(Icons.check_circle_rounded, color: TRColors.success, size: 28),
              const SizedBox(height: 8),
              Text(
                'Your free trial is active — ${sub.trialDaysRemaining} days remaining',
                style: const TextStyle(color: TRColors.success, fontSize: 14, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                'You\'ll be prompted to subscribe before your trial ends.',
                style: TextStyle(color: TRColors.grayLight, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ]),
          ),
        ] else if (sub.isActive) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: TRColors.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: TRColors.gold.withValues(alpha: 0.3)),
            ),
            child: Column(children: [
              const Icon(Icons.verified_rounded, color: TRColors.gold, size: 28),
              const SizedBox(height: 8),
              Text(
                'Active — \$${sub.currentMonthlyTotal.toStringAsFixed(2)}/month',
                style: const TextStyle(color: TRColors.gold, fontSize: 15, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                '${sub.purchasedSeats} seat${sub.purchasedSeats == 1 ? '' : 's'}',
                style: const TextStyle(color: TRColors.grayLight, fontSize: 12),
              ),
            ]),
          ),
        ] else ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : () => _handleSubscribe(state),
              style: ElevatedButton.styleFrom(
                backgroundColor: TRColors.gold,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _loading
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(TRColors.navyDeep)))
                  : const Text('Start 14-Day Free Trial', style: TextStyle(
                      color: TRColors.navyDeep, fontSize: 16, fontWeight: FontWeight.w900,
                    )),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'No credit card required. Cancel anytime.',
            style: TextStyle(color: TRColors.grayMid, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ]),
    );
  }
}

// ─── Seat Upgrade Dialog ──────────────────────────────────────────────────────
// Shown when admin tries to invite beyond included seat count.
class SeatUpgradeDialog extends StatefulWidget {
  final SeatPurchaseRequest request;
  final VoidCallback onConfirm;
  const SeatUpgradeDialog({super.key, required this.request, required this.onConfirm});

  @override
  State<SeatUpgradeDialog> createState() => _SeatUpgradeDialogState();
}

class _SeatUpgradeDialogState extends State<SeatUpgradeDialog> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: TRColors.navyMid,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: TRColors.gold.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_add_rounded, color: TRColors.gold, size: 28),
            ),
            const SizedBox(height: 16),
            const Text("You've reached your included team members",
              style: TextStyle(color: TRColors.white, fontSize: 16, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.request.confirmationMessage,
              style: const TextStyle(color: TRColors.grayLight, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'New total: \$${TRPlan.totalMonthly(widget.request.extraSeatsNeeded).toStringAsFixed(2)}/month',
              style: const TextStyle(color: TRColors.gold, fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
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
                onPressed: _loading ? null : () async {
                  setState(() => _loading = true);
                  widget.onConfirm();
                  if (mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: TRColors.gold,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _loading
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(TRColors.navyDeep)))
                    : const Text('Add Seat', style: TextStyle(
                        color: TRColors.navyDeep, fontWeight: FontWeight.w800)),
              )),
            ]),
          ],
        ),
      ),
    );
  }
}
