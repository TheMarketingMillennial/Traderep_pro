import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/services/app_state.dart';
import '../../shared/widgets/tr_widgets.dart';
import 'pricing_models.dart';

class PricingScreen extends StatefulWidget {
  final bool showBackButton;
  const PricingScreen({super.key, this.showBackButton = true});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 1; // default highlight: Growth (index 1)
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final plans = PricingPlan.all;

    return Scaffold(
      backgroundColor: TRColors.navyDeep,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHero(context, state)),
            SliverToBoxAdapter(child: _buildSocialProof()),
            SliverToBoxAdapter(child: _buildPlanSelector(plans)),
            SliverToBoxAdapter(child: _buildSelectedPlanDetail(plans, state)),
            SliverToBoxAdapter(child: _buildAllPlansComparison(plans, state)),
            SliverToBoxAdapter(child: _buildMessaging()),
            SliverToBoxAdapter(child: _buildFAQ()),
            SliverToBoxAdapter(child: _buildFooterCTA(state)),
            const SliverToBoxAdapter(child: SizedBox(height: 60)),
          ],
        ),
      ),
    );
  }

  // ─── HERO ─────────────────────────────────────────────────────────────────
  Widget _buildHero(BuildContext context, AppState state) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [TRColors.navyMid, TRColors.navyDeep],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            children: [
              // Top bar
              Row(children: [
                if (widget.showBackButton)
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: TRColors.cardMid,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: TRColors.divider),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: TRColors.white, size: 20),
                    ),
                  ),
                const Spacer(),
                const TRLogo(size: 36),
                const Spacer(),
                if (widget.showBackButton) const SizedBox(width: 40),
              ]),
              const SizedBox(height: 28),

              // Trial badge
              if (state.isInTrial)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: TRColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: TRColors.gold.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_rounded, color: TRColors.gold, size: 15),
                      const SizedBox(width: 6),
                      Text(
                        '${state.trialDaysRemaining} days left in free trial',
                        style: const TextStyle(color: TRColors.gold, fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),
              const Text(
                'Choose Your Plan',
                style: TextStyle(
                  color: TRColors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Turn completed jobs into online credibility.\nEvery plan includes a 14-day free trial.',
                style: TextStyle(color: TRColors.grayLight, fontSize: 15, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Trust badges
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _TrustBadge(icon: Icons.lock_outline_rounded, label: 'Secure Billing'),
                  const SizedBox(width: 20),
                  _TrustBadge(icon: Icons.cancel_outlined, label: 'Cancel Anytime'),
                  const SizedBox(width: 20),
                  _TrustBadge(icon: Icons.card_giftcard_rounded, label: '14-Day Free Trial'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── SOCIAL PROOF ─────────────────────────────────────────────────────────
  Widget _buildSocialProof() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TRColors.goldDim,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TRColors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.format_quote_rounded, color: TRColors.gold, size: 24),
        const SizedBox(width: 10),
        const Expanded(child: Text(
          '"One completed project can pay for TradeRep for an entire year."',
          style: TextStyle(color: TRColors.gold, fontSize: 13, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic),
        )),
      ]),
    );
  }

  // ─── PLAN SELECTOR TABS ───────────────────────────────────────────────────
  Widget _buildPlanSelector(List<PricingPlan> plans) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SELECT PLAN', style: TextStyle(
            color: TRColors.grayMid, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0,
          )),
          const SizedBox(height: 12),
          Row(
            children: plans.asMap().entries.map((entry) {
              final i = entry.key;
              final plan = entry.value;
              final selected = _selectedIndex == i;
              return Expanded(child: GestureDetector(
                onTap: () => setState(() => _selectedIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: EdgeInsets.only(right: i < plans.length - 1 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                  decoration: BoxDecoration(
                    color: selected ? plan.accentColor.withValues(alpha: 0.15) : TRColors.cardDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? plan.accentColor : TRColors.divider,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Column(children: [
                    if (plan.isMostPopular)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: TRColors.gold,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('POPULAR', style: TextStyle(
                          color: TRColors.navyDeep, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.5,
                        )),
                      )
                    else
                      const SizedBox(height: 18),
                    Text(plan.name, style: TextStyle(
                      color: selected ? plan.accentColor : TRColors.white,
                      fontSize: 14, fontWeight: FontWeight.w800,
                    )),
                    const SizedBox(height: 2),
                    RichText(text: TextSpan(children: [
                      TextSpan(text: '\$${plan.monthlyPrice}', style: TextStyle(
                        color: selected ? plan.accentColor : TRColors.white,
                        fontSize: 18, fontWeight: FontWeight.w900,
                      )),
                      const TextSpan(text: '/mo', style: TextStyle(
                        color: TRColors.grayMid, fontSize: 11,
                      )),
                    ])),
                  ]),
                ),
              ));
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── SELECTED PLAN DETAIL CARD ────────────────────────────────────────────
  Widget _buildSelectedPlanDetail(List<PricingPlan> plans, AppState state) {
    final plan = plans[_selectedIndex];
    final isCurrentPlan = state.currentTier == plan.tier;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(plan.tier),
        margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              plan.accentColor.withValues(alpha: 0.12),
              TRColors.cardDark,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: plan.accentColor.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(plan.name, style: const TextStyle(
                      color: TRColors.white, fontSize: 22, fontWeight: FontWeight.w900,
                    )),
                    if (plan.isMostPopular) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: TRColors.gold,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('MOST POPULAR', style: TextStyle(
                          color: TRColors.navyDeep, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5,
                        )),
                      ),
                    ],
                  ]),
                  Text(plan.bestFor, style: const TextStyle(color: TRColors.grayLight, fontSize: 13)),
                ]),
                const Spacer(),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  RichText(text: TextSpan(children: [
                    TextSpan(text: '\$${plan.monthlyPrice}', style: TextStyle(
                      color: plan.accentColor, fontSize: 32, fontWeight: FontWeight.w900,
                    )),
                  ])),
                  const Text('per month', style: TextStyle(color: TRColors.grayMid, fontSize: 12)),
                ]),
              ]),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Text(plan.tagline, style: const TextStyle(
                color: TRColors.grayLight, fontSize: 13, height: 1.5,
              )),
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Divider(color: TRColors.divider),
            ),

            // Features list
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                children: plan.features.map((f) => _FeatureRow(feature: f, accentColor: plan.accentColor)).toList(),
              ),
            ),

            // CTA
            Padding(
              padding: const EdgeInsets.all(20),
              child: isCurrentPlan
                ? Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: plan.accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: plan.accentColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.check_circle_rounded, color: plan.accentColor, size: 18),
                      const SizedBox(width: 8),
                      Text('Your Current Plan', style: TextStyle(
                        color: plan.accentColor, fontSize: 15, fontWeight: FontWeight.w700,
                      )),
                    ]),
                  )
                : _PlanCTAButton(plan: plan, onTap: () => _handlePlanAction(context, plan, state)),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Center(child: Text(
                '14-day free trial • No credit card required • Cancel anytime',
                style: const TextStyle(color: TRColors.grayMid, fontSize: 11),
                textAlign: TextAlign.center,
              )),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ALL PLANS COMPARISON TABLE ───────────────────────────────────────────
  Widget _buildAllPlansComparison(List<PricingPlan> plans, AppState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Compare All Plans', style: TextStyle(
            color: TRColors.white, fontSize: 20, fontWeight: FontWeight.w800,
          )),
          const SizedBox(height: 4),
          const Text('See exactly what\'s included in each tier.',
            style: TextStyle(color: TRColors.grayLight, fontSize: 13)),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: TRColors.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: TRColors.divider),
            ),
            child: Column(children: [
              // Header row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: const BoxDecoration(
                  color: TRColors.cardMid,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: Row(children: [
                  const Expanded(flex: 3, child: Text('Feature', style: TextStyle(
                    color: TRColors.grayLight, fontSize: 12, fontWeight: FontWeight.w600,
                  ))),
                  ...plans.map((p) => Expanded(child: Column(children: [
                    Text(p.name, style: TextStyle(
                      color: p.isMostPopular ? TRColors.gold : TRColors.white,
                      fontSize: 12, fontWeight: FontWeight.w700,
                    )),
                    Text('\$${p.monthlyPrice}', style: TextStyle(
                      color: p.accentColor, fontSize: 11,
                    )),
                  ]))),
                ]),
              ),
              // Feature rows
              ..._comparisonRows.asMap().entries.map((entry) {
                final i = entry.key;
                final row = entry.value;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: i < _comparisonRows.length - 1
                          ? const BorderSide(color: TRColors.divider)
                          : BorderSide.none,
                    ),
                  ),
                  child: Row(children: [
                    Expanded(flex: 3, child: Text(row['label'] as String, style: const TextStyle(
                      color: TRColors.grayLight, fontSize: 12,
                    ))),
                    ...plans.map((p) {
                      final tiers = row['tiers'] as List<PlanTier>;
                      final hasIt = tiers.contains(p.tier);
                      return Expanded(child: Center(child: hasIt
                        ? Icon(Icons.check_circle_rounded,
                            color: p.isMostPopular ? TRColors.gold : TRColors.success, size: 18)
                        : const Icon(Icons.remove_rounded, color: TRColors.divider, size: 18),
                      ));
                    }),
                  ]),
                );
              }),
            ]),
          ),
        ],
      ),
    );
  }

  static const List<Map<String, dynamic>> _comparisonRows = [
    {'label': 'Job creation', 'tiers': [PlanTier.starter, PlanTier.growth, PlanTier.pro]},
    {'label': 'Before/after photos', 'tiers': [PlanTier.starter, PlanTier.growth, PlanTier.pro]},
    {'label': 'Google review requests', 'tiers': [PlanTier.starter, PlanTier.growth, PlanTier.pro]},
    {'label': 'Basic Google posting', 'tiers': [PlanTier.starter, PlanTier.growth, PlanTier.pro]},
    {'label': 'AI photo selection', 'tiers': [PlanTier.growth, PlanTier.pro]},
    {'label': 'Content approval dashboard', 'tiers': [PlanTier.growth, PlanTier.pro]},
    {'label': 'Review automation', 'tiers': [PlanTier.growth, PlanTier.pro]},
    {'label': 'Social-ready image exports', 'tiers': [PlanTier.growth, PlanTier.pro]},
    {'label': 'Enhanced analytics', 'tiers': [PlanTier.growth, PlanTier.pro]},
    {'label': 'Multiple locations', 'tiers': [PlanTier.pro]},
    {'label': 'Crew performance tracking', 'tiers': [PlanTier.pro]},
    {'label': 'Reputation scoring', 'tiers': [PlanTier.pro]},
    {'label': 'AI recommendations', 'tiers': [PlanTier.pro]},
    {'label': 'Priority support', 'tiers': [PlanTier.pro]},
  ];

  // ─── MESSAGING STRIP ──────────────────────────────────────────────────────
  Widget _buildMessaging() {
    const messages = [
      (Icons.construction_rounded, 'Stay active on Google without extra work.'),
      (Icons.photo_camera_rounded, 'Every completed project becomes proof of quality.'),
      (Icons.star_rounded, 'Turn completed jobs into online credibility.'),
      (Icons.trending_up_rounded, 'Contractors using TradeRep average 4.8★ on Google.'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Why Contractors Choose TradeRep', style: TextStyle(
            color: TRColors.white, fontSize: 20, fontWeight: FontWeight.w800,
          )),
          const SizedBox(height: 16),
          ...messages.map((msg) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TRColors.cardDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: TRColors.divider),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: TRColors.goldDim,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(msg.$1, color: TRColors.gold, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(msg.$2, style: const TextStyle(
                color: TRColors.white, fontSize: 14, fontWeight: FontWeight.w600, height: 1.4,
              ))),
            ]),
          )),
        ],
      ),
    );
  }

  // ─── FAQ ──────────────────────────────────────────────────────────────────
  Widget _buildFAQ() {
    const faqs = [
      ('Do I need a credit card to start?', 'No. Start your 14-day free trial with no credit card required. You\'ll be prompted to add billing info before the trial ends.'),
      ('What happens after my trial ends?', 'Your subscription automatically begins on the plan you selected. You\'ll receive an email reminder 3 days before the trial ends.'),
      ('Can I change plans?', 'Yes. Upgrade or downgrade at any time. Upgrades take effect immediately. Downgrades apply at the next billing cycle.'),
      ('Is there a contract?', 'No contracts. TradeRep is month-to-month. Cancel anytime with no cancellation fees.'),
      ('How does the Google Business Profile integration work?', 'You authorize TradeRep via Google OAuth 2.0. We never store your Google password. All posts require your approval before publishing.'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Frequently Asked Questions', style: TextStyle(
            color: TRColors.white, fontSize: 20, fontWeight: FontWeight.w800,
          )),
          const SizedBox(height: 16),
          ...faqs.map((faq) => _FAQTile(question: faq.$1, answer: faq.$2)),
        ],
      ),
    );
  }

  // ─── FOOTER CTA ───────────────────────────────────────────────────────────
  Widget _buildFooterCTA(AppState state) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [TRColors.navyMid, TRColors.navyLight],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TRColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        const TRLogo(size: 52, showTagline: true),
        const SizedBox(height: 24),
        GoldButton(
          label: 'Start 14-Day Free Trial',
          icon: Icons.rocket_launch_rounded,
          onTap: () => _handlePlanAction(context, PricingPlan.growth, state),
        ),
        const SizedBox(height: 12),
        const Text(
          'No credit card • Cancel anytime • Instant setup',
          style: TextStyle(color: TRColors.grayMid, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }

  // ─── HANDLERS ─────────────────────────────────────────────────────────────
  void _handlePlanAction(BuildContext context, PricingPlan plan, AppState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: TRColors.cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CheckoutSheet(plan: plan, state: state),
    );
  }
}

// ─── Feature Row ──────────────────────────────────────────────────────────────
class _FeatureRow extends StatelessWidget {
  final PlanFeature feature;
  final Color accentColor;

  const _FeatureRow({required this.feature, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          feature.included
            ? Icon(Icons.check_circle_rounded, color: accentColor, size: 18)
            : Container(
                width: 18, height: 18,
                decoration: BoxDecoration(
                  color: TRColors.cardMid,
                  shape: BoxShape.circle,
                  border: Border.all(color: TRColors.divider),
                ),
                child: const Icon(Icons.lock_rounded, color: TRColors.grayMid, size: 10),
              ),
          const SizedBox(width: 10),
          Expanded(child: Text(feature.label, style: TextStyle(
            color: feature.included ? TRColors.white : TRColors.grayMid,
            fontSize: 14,
            decoration: feature.included ? null : null,
          ))),
          if (!feature.included && feature.lockedLabel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: TRColors.cardMid,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: TRColors.divider),
              ),
              child: Text(feature.lockedLabel!, style: const TextStyle(
                color: TRColors.grayMid, fontSize: 9, fontWeight: FontWeight.w700,
              )),
            ),
        ],
      ),
    );
  }
}

// ─── Plan CTA Button ─────────────────────────────────────────────────────────
class _PlanCTAButton extends StatelessWidget {
  final PricingPlan plan;
  final VoidCallback onTap;

  const _PlanCTAButton({required this.plan, required this.onTap});

  String get _label {
    if (plan.tier == PlanTier.growth) return 'Start 14-Day Free Trial';
    if (plan.tier == PlanTier.pro)    return 'Get Started — Pro';
    return 'Get Started';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: plan.isMostPopular ? TRColors.gold : plan.accentColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: plan.isMostPopular ? null : Border.all(color: plan.accentColor),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(
            Icons.rocket_launch_rounded,
            color: plan.isMostPopular ? TRColors.navyDeep : plan.accentColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(_label, style: TextStyle(
            color: plan.isMostPopular ? TRColors.navyDeep : plan.accentColor,
            fontSize: 15, fontWeight: FontWeight.w800,
          )),
        ]),
      ),
    );
  }
}

// ─── Trust Badge ─────────────────────────────────────────────────────────────
class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, color: TRColors.gold, size: 18),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: TRColors.grayLight, fontSize: 10, fontWeight: FontWeight.w600)),
    ]);
  }
}

// ─── FAQ Tile ─────────────────────────────────────────────────────────────────
class _FAQTile extends StatefulWidget {
  final String question;
  final String answer;
  const _FAQTile({required this.question, required this.answer});

  @override
  State<_FAQTile> createState() => _FAQTileState();
}

class _FAQTileState extends State<_FAQTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _open = !_open),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TRColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _open ? TRColors.gold.withValues(alpha: 0.4) : TRColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(widget.question, style: const TextStyle(
                color: TRColors.white, fontSize: 14, fontWeight: FontWeight.w600,
              ))),
              AnimatedRotation(
                turns: _open ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.keyboard_arrow_down_rounded, color: TRColors.gold, size: 22),
              ),
            ]),
            if (_open) ...[
              const SizedBox(height: 10),
              Text(widget.answer, style: const TextStyle(
                color: TRColors.grayLight, fontSize: 13, height: 1.6,
              )),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Checkout Sheet ───────────────────────────────────────────────────────────
class _CheckoutSheet extends StatefulWidget {
  final PricingPlan plan;
  final AppState state;
  const _CheckoutSheet({required this.plan, required this.state});

  @override
  State<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<_CheckoutSheet> {
  int _step = 0; // 0=confirm, 1=payment, 2=success
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: _step == 2 ? _buildSuccess() : _step == 1 ? _buildPayment() : _buildConfirm(),
      ),
    );
  }

  Widget _buildConfirm() {
    final plan = widget.plan;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(child: Container(width: 40, height: 4,
          decoration: BoxDecoration(color: TRColors.divider, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Start ${plan.name} Plan', style: const TextStyle(
              color: TRColors.white, fontSize: 20, fontWeight: FontWeight.w800,
            )),
            Text('14-day free trial, then \$${plan.monthlyPrice}/month',
              style: const TextStyle(color: TRColors.grayLight, fontSize: 13)),
          ]),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: plan.accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.rocket_launch_rounded, color: plan.accentColor, size: 24),
          ),
        ]),
        const SizedBox(height: 20),
        _OrderLine(label: 'Plan', value: '${plan.name} — Monthly'),
        _OrderLine(label: 'Trial period', value: '14 days FREE'),
        _OrderLine(label: 'First charge', value: '\$${plan.monthlyPrice}.00', bold: true),
        _OrderLine(label: 'Billing', value: 'Monthly — Cancel anytime'),
        const SizedBox(height: 20),
        // Stripe badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: TRColors.cardMid,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: TRColors.divider),
          ),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.lock_rounded, color: TRColors.success, size: 14),
            SizedBox(width: 6),
            Text('Secured & processed by Stripe', style: TextStyle(
              color: TRColors.grayLight, fontSize: 12,
            )),
            SizedBox(width: 8),
            Text('stripe', style: TextStyle(
              color: TRColors.info, fontSize: 14, fontWeight: FontWeight.w800,
            )),
          ]),
        ),
        const SizedBox(height: 20),
        GoldButton(
          label: 'Continue to Payment',
          icon: Icons.credit_card_rounded,
          onTap: () => setState(() => _step = 1),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: TRColors.grayMid)),
        ),
      ],
    );
  }

  Widget _buildPayment() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: Container(width: 40, height: 4,
          decoration: BoxDecoration(color: TRColors.divider, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        const Text('Payment Details', style: TextStyle(
          color: TRColors.white, fontSize: 20, fontWeight: FontWeight.w800,
        )),
        const SizedBox(height: 4),
        const Text('Powered by Stripe — Your card is never stored by TradeRep.',
          style: TextStyle(color: TRColors.grayMid, fontSize: 12)),
        const SizedBox(height: 20),
        _PaymentField(label: 'Card Number', hint: '1234 5678 9012 3456', icon: Icons.credit_card_rounded),
        const SizedBox(height: 12),
        Row(children: const [
          Expanded(child: _PaymentField(label: 'Expiry', hint: 'MM / YY', icon: Icons.date_range_rounded)),
          SizedBox(width: 12),
          Expanded(child: _PaymentField(label: 'CVC', hint: '•••', icon: Icons.security_rounded)),
        ]),
        const SizedBox(height: 12),
        _PaymentField(label: 'Name on Card', hint: 'John Smith', icon: Icons.person_rounded),
        const SizedBox(height: 20),
        _loading
          ? const SizedBox(height: 54, child: Center(child: CircularProgressIndicator(color: TRColors.gold)))
          : GoldButton(
              label: 'Start Free Trial',
              icon: Icons.rocket_launch_rounded,
              onTap: _processPayment,
            ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => setState(() => _step = 0),
          child: const Text('← Back', style: TextStyle(color: TRColors.grayMid)),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: TRColors.success.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: TRColors.success.withValues(alpha: 0.4), width: 2),
          ),
          child: const Icon(Icons.check_rounded, color: TRColors.success, size: 44),
        ),
        const SizedBox(height: 20),
        Text('You\'re on ${widget.plan.name}!', style: const TextStyle(
          color: TRColors.white, fontSize: 22, fontWeight: FontWeight.w800,
        )),
        const SizedBox(height: 8),
        Text(
          'Your 14-day free trial has started. No charge until ${_trialEndDate()}.',
          style: const TextStyle(color: TRColors.grayLight, fontSize: 14, height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        GoldButton(
          label: 'Start Using TradeRep',
          icon: Icons.arrow_forward_rounded,
          onTap: () => Navigator.pop(context),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _processPayment() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 2));
    widget.state.startTrial(widget.plan.tier);
    setState(() { _loading = false; _step = 2; });
  }

  String _trialEndDate() {
    final end = DateTime.now().add(const Duration(days: 14));
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[end.month-1]} ${end.day}, ${end.year}';
  }
}

class _OrderLine extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _OrderLine({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Text(label, style: const TextStyle(color: TRColors.grayLight, fontSize: 13)),
        const Spacer(),
        Text(value, style: TextStyle(
          color: bold ? TRColors.white : TRColors.grayLight,
          fontSize: 13,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        )),
      ]),
    );
  }
}

class _PaymentField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;

  const _PaymentField({required this.label, required this.hint, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(
          color: TRColors.grayLight, fontSize: 12, fontWeight: FontWeight.w600,
        )),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: TRColors.cardMid,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: TRColors.divider),
          ),
          child: Row(children: [
            Icon(icon, color: TRColors.grayMid, size: 16),
            const SizedBox(width: 10),
            Text(hint, style: const TextStyle(color: TRColors.grayMid, fontSize: 14)),
          ]),
        ),
      ],
    );
  }
}
