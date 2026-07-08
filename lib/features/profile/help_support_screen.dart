// ─────────────────────────────────────────────────────────────────────────────
// HELP & SUPPORT SCREEN — TradeRep Pro
// FAQ accordion + contact support button
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _supportEmail = 'support@app.tradereppro.com';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TRColors.navyDeep,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
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
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text('Help & Support', style: TextStyle(
                      color: TRColors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    )),
                  ),
                ],
              ),
            ),

            // ── Content ─────────────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                children: [
                  // Contact card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: TRColors.goldDim,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: TRColors.gold.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            color: TRColors.gold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.headset_mic_rounded,
                              color: TRColors.gold, size: 22),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Need direct help?', style: TextStyle(
                                color: TRColors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              )),
                              SizedBox(height: 2),
                              Text('We reply within one business day.',
                                  style: TextStyle(
                                      color: TRColors.grayLight, fontSize: 12)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => launchUrl(
                            Uri.parse(
                                'mailto:$_supportEmail?subject=TradeRep%20Pro%20Support'),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: TRColors.gold,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('Email Us', style: TextStyle(
                              color: TRColors.navyDeep,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            )),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  const Text('FREQUENTLY ASKED QUESTIONS', style: TextStyle(
                    color: TRColors.grayMid,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  )),
                  const SizedBox(height: 12),

                  // FAQ items
                  ..._faqs.map((faq) => _FaqTile(
                    question: faq['q']!,
                    answer: faq['a']!,
                  )),

                  const SizedBox(height: 28),

                  // Bottom contact nudge
                  Center(
                    child: Column(
                      children: [
                        const Text("Didn't find your answer?",
                            style: TextStyle(
                                color: TRColors.grayLight, fontSize: 13)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => launchUrl(
                            Uri.parse(
                                'mailto:$_supportEmail?subject=TradeRep%20Pro%20Support'),
                          ),
                          child: const Text(
                            _supportEmail,
                            style: TextStyle(
                              color: TRColors.gold,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: TRColors.gold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── FAQ data ─────────────────────────────────────────────────────────────────
const _faqs = [
  {
    'q': 'How do I create a new job?',
    'a': 'Tap the + button on the Jobs screen. Fill in the customer name, phone '
        'number, job type, and service address, then tap Save. The job will appear '
        'in your active jobs list immediately.',
  },
  {
    'q': 'How do I submit photos for a job?',
    'a': 'Open any job and tap "Submit Photos". Select your before/after photos '
        'from your camera or gallery. Once submitted, they will go into the '
        'approval queue for your admin or office manager to review.',
  },
  {
    'q': 'How do photos get approved?',
    'a': 'Admins and office managers see a "Photo Approvals" section. They can '
        'approve or reject each submission. Approved photos are used to generate '
        'Google Business Profile posts.',
  },
  {
    'q': 'How do I send a Google review request?',
    'a': 'Go to the Reviews tab. Any completed job will appear as a pending review '
        'request. Tap "Send SMS" to open the message sheet — customise if needed '
        'and tap Send. The customer receives a text with a direct link to your '
        'Google review page.',
  },
  {
    'q': 'Why does the review SMS not include my Google review link?',
    'a': 'You need to connect your Google Business Profile first. Go to Settings '
        '→ Profile → Google Business Profile and tap "Sign in with Google". Once '
        'connected, your review link is automatically included in every request.',
  },
  {
    'q': 'How do I connect my Google Business Profile?',
    'a': 'Go to Settings → Profile → Google Business Profile and tap "Sign in '
        'with Google". A browser window will open — sign in with the Google '
        'account that manages your GBP listing and grant access. Return to the '
        'app and your profile will be linked automatically.',
  },
  {
    'q': 'How do I disconnect or reconnect my Google Business Profile?',
    'a': 'Go to Settings → Profile → Google Business Profile. If already '
        'connected, you will see a "Disconnect" option. Disconnecting removes '
        'the link so you can reconnect with a different Google account.',
  },
  {
    'q': 'How do I invite a team member?',
    'a': 'Go to Settings → Profile → Team Members and tap "+ Invite". Enter '
        'their name, phone number, and role. They will receive an SMS with '
        'instructions to download the app and join your team.',
  },
  {
    'q': 'What roles are available for team members?',
    'a': 'Crew Member — submit photos and view assigned jobs.\n'
        'Crew Lead — manage crew, submit and review photos.\n'
        'Sales Rep — create jobs, send reviews, manage content.\n'
        'Office Manager — approve photos, manage team, full access.\n'
        'Admin — full access including billing and settings.',
  },
  {
    'q': 'How does the Google post content get generated?',
    'a': 'After photos are approved, your admin can tap "Generate Post" from the '
        'Content tab. TradeRep Pro uses AI to write a professional caption based '
        'on the job type and photos, which is then ready to publish directly to '
        'your Google Business Profile.',
  },
  {
    'q': 'What plan do I need for SMS review requests?',
    'a': 'Review request SMS is available on the Growth and Pro plans. Starter '
        'plan users can upgrade at any time from Settings → Profile → Manage '
        'Subscription.',
  },
  {
    'q': 'How do I cancel or change my subscription?',
    'a': 'Go to Settings → Profile → Manage Subscription. You can upgrade, '
        'downgrade, or cancel at any time. Changes take effect at the start of '
        'your next billing cycle.',
  },
  {
    'q': 'Is my data secure?',
    'a': 'Yes. All data is stored in Google Firebase with industry-standard '
        'encryption. Twilio handles SMS delivery — your customers\' phone numbers '
        'are never shared with third parties. See our Privacy Policy for full '
        'details.',
  },
];

// ─── FAQ Accordion Tile ───────────────────────────────────────────────────────
class _FaqTile extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _ctrl;
  late Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _rotation = Tween<double>(begin: 0, end: 0.5).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: TRColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _expanded
                ? TRColors.gold.withValues(alpha: 0.4)
                : TRColors.divider,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.question, style: TextStyle(
                      color: _expanded ? TRColors.gold : TRColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    )),
                  ),
                  const SizedBox(width: 8),
                  RotationTransition(
                    turns: _rotation,
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: _expanded ? TRColors.gold : TRColors.grayMid,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            // Answer
            if (_expanded) ...[
              Divider(
                  color: TRColors.gold.withValues(alpha: 0.2), height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Text(widget.answer, style: const TextStyle(
                  color: TRColors.grayLight,
                  fontSize: 13,
                  height: 1.55,
                )),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
