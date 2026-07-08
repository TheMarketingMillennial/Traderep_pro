// ─────────────────────────────────────────────────────────────────────────────
// PRIVACY POLICY SCREEN — TradeRep Pro
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
                    child: Text('Privacy Policy', style: TextStyle(
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
                  // Effective date
                  Text(
                    'Effective date: ${DateTime.now().year}',
                    style: const TextStyle(
                        color: TRColors.grayMid, fontSize: 12),
                  ),
                  const SizedBox(height: 20),

                  _PolicySection(
                    title: '1. Overview',
                    body:
                        'TradeRep Pro ("we", "us", "our") is a mobile and web application '
                        'designed to help trade businesses document jobs, request Google reviews, '
                        'and publish content to Google Business Profiles. We are committed to '
                        'protecting the privacy of our users and their customers. This policy '
                        'explains what data we collect, how we use it, and your rights.',
                  ),

                  _PolicySection(
                    title: '2. Information We Collect',
                    body:
                        'Account data: When you sign up, we collect your name, email address, '
                        'phone number, and company information.\n\n'
                        'Job data: Job details including customer names, phone numbers, addresses, '
                        'job type, and completion status.\n\n'
                        'Photos: Before and after photos uploaded by your crew for job documentation '
                        'and Google Business Profile content.\n\n'
                        'Google Business Profile: If you connect your GBP, we store your Google '
                        'location ID and access tokens to publish posts and retrieve your review link. '
                        'We do not store your Google account password.\n\n'
                        'SMS logs: Records of review request messages sent, including recipient '
                        'phone numbers and message delivery status.\n\n'
                        'Payment data: Subscription billing is handled by Stripe. We do not store '
                        'your credit card details on our servers.',
                  ),

                  _PolicySection(
                    title: '3. How We Use Your Data',
                    body:
                        '• To provide and operate the TradeRep Pro service\n'
                        '• To send review request SMS messages on your behalf\n'
                        '• To generate AI-assisted Google Business Profile posts\n'
                        '• To process subscription payments through Stripe\n'
                        '• To send account and service notifications\n'
                        '• To improve the product and troubleshoot issues\n\n'
                        'We do not sell your data or your customers\' data to third parties.',
                  ),

                  _PolicySection(
                    title: '4. Third-Party Services',
                    body:
                        'We use the following third-party services to operate TradeRep Pro:\n\n'
                        'Firebase (Google): User authentication and cloud database storage.\n\n'
                        'Twilio: SMS delivery for review request messages. Customer phone numbers '
                        'are transmitted to Twilio solely for message delivery.\n\n'
                        'Stripe: Subscription billing and payment processing.\n\n'
                        'OpenAI: AI-generated post captions. Job type and context data are '
                        'sent to generate content — no personally identifiable information is included.\n\n'
                        'Google APIs: Google Business Profile management for posting and retrieving '
                        'review links.\n\n'
                        'Each provider has its own privacy policy and data handling practices.',
                  ),

                  _PolicySection(
                    title: '5. Data Storage and Security',
                    body:
                        'Your data is stored securely in Google Firebase, which is encrypted at '
                        'rest and in transit using industry-standard TLS encryption. Access is '
                        'restricted to authenticated users of your company account.\n\n'
                        'We employ security rules to ensure that company data is accessible only '
                        'to team members with the appropriate role.',
                  ),

                  _PolicySection(
                    title: '6. Customer Data',
                    body:
                        'When your crew submits a job, customer information (name, phone, address) '
                        'is stored to enable review requests and job tracking. This data is owned '
                        'by your business and is not shared with other TradeRep Pro accounts or '
                        'third parties beyond what is required to send SMS messages via Twilio.',
                  ),

                  _PolicySection(
                    title: '7. Data Retention',
                    body:
                        'Your account data is retained for as long as your subscription is active. '
                        'If you cancel your account, you may request deletion of your data by '
                        'emailing us at $_supportEmail. We will process deletion requests within '
                        '30 days.',
                  ),

                  _PolicySection(
                    title: '8. Your Rights',
                    body:
                        'You have the right to:\n'
                        '• Access the data we hold about you and your company\n'
                        '• Correct inaccurate data\n'
                        '• Request deletion of your data\n'
                        '• Export your data\n'
                        '• Disconnect third-party integrations (GBP, Stripe) at any time\n\n'
                        'To exercise any of these rights, contact us at $_supportEmail.',
                  ),

                  _PolicySection(
                    title: '9. Children\'s Privacy',
                    body:
                        'TradeRep Pro is intended for business use by adults. We do not knowingly '
                        'collect data from individuals under 18 years of age.',
                  ),

                  _PolicySection(
                    title: '10. Changes to This Policy',
                    body:
                        'We may update this Privacy Policy periodically. When we do, we will '
                        'update the effective date at the top of this page. Continued use of '
                        'TradeRep Pro after changes constitutes acceptance of the updated policy.',
                  ),

                  _PolicySection(
                    title: '11. Contact Us',
                    body: 'If you have any questions about this Privacy Policy or how we '
                        'handle your data, please contact us at:',
                    trailing: GestureDetector(
                      onTap: () => launchUrl(
                        Uri.parse(
                            'mailto:$_supportEmail?subject=Privacy%20Policy%20Question'),
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
                  ),

                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'TradeRep Pro — PROOF. VISIBILITY. GROWTH.',
                      style: TextStyle(
                          color: TRColors.grayMid,
                          fontSize: 11,
                          letterSpacing: 0.8),
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

// ─── Policy Section Widget ────────────────────────────────────────────────────
class _PolicySection extends StatelessWidget {
  final String title;
  final String body;
  final Widget? trailing;

  const _PolicySection({
    required this.title,
    required this.body,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TRColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TRColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(
            color: TRColors.gold,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          )),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(
            color: TRColors.grayLight,
            fontSize: 13,
            height: 1.6,
          )),
          if (trailing != null) ...[
            const SizedBox(height: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}
