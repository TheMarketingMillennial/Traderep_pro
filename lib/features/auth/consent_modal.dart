// consent_modal.dart — TradeRep Pro
// Terms of Service + Privacy Policy consent modal shown before account creation.
// Must be accepted before Firebase Auth account is created.

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// ─── Version constants ────────────────────────────────────────────────────────
const kTermsVersion   = 'July 10, 2026';
const kPrivacyVersion = 'July 10, 2026';

// Exact marketing opt-in language recorded in Firestore for compliance.
const kMarketingConsentLanguage =
    'I would like to receive product updates, promotions, and marketing '
    'communications from TradeRep Pro.';

// ─── Result returned when the user accepts ────────────────────────────────────
class ConsentResult {
  final bool termsAccepted;
  final bool privacyAccepted;
  final bool marketingOptIn;
  final DateTime acceptedAt;

  const ConsentResult({
    required this.termsAccepted,
    required this.privacyAccepted,
    required this.marketingOptIn,
    required this.acceptedAt,
  });
}

// ─── Public entry point ───────────────────────────────────────────────────────

/// Shows the consent modal as a full-screen dialog.
/// Returns [ConsentResult] when the user accepts, or null if they cancel.
Future<ConsentResult?> showConsentModal(BuildContext context) {
  return showDialog<ConsentResult>(
    context: context,
    barrierDismissible: false, // must tap Cancel explicitly
    builder: (_) => const _ConsentModal(),
  );
}

// ─── Modal widget ─────────────────────────────────────────────────────────────

class _ConsentModal extends StatefulWidget {
  const _ConsentModal();

  @override
  State<_ConsentModal> createState() => _ConsentModalState();
}

class _ConsentModalState extends State<_ConsentModal>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  bool _termsChecked     = false;
  bool _privacyChecked   = false;
  bool _marketingChecked = false; // optional, unchecked by default

  bool get _canAccept => _termsChecked && _privacyChecked;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _accept() {
    if (!_canAccept) return;
    Navigator.of(context).pop(ConsentResult(
      termsAccepted:   true,
      privacyAccepted: true,
      marketingOptIn:  _marketingChecked,
      acceptedAt:      DateTime.now().toUtc(),
    ));
  }

  void _cancel() => Navigator.of(context).pop(null);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: TRColors.navyDark,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          _buildTabs(),
          Flexible(child: _buildTabContent()),
          _buildCheckboxSection(),
          _buildButtons(),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: TRColors.divider)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: TRColors.goldDim,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.gavel_rounded, color: TRColors.gold, size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Review & Accept', style: TextStyle(
                  color: TRColors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                )),
                SizedBox(height: 2),
                Text('Required before creating your account', style: TextStyle(
                  color: TRColors.grayMid,
                  fontSize: 11,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab bar ────────────────────────────────────────────────────────────────

  Widget _buildTabs() {
    return Container(
      color: TRColors.navyMid,
      child: TabBar(
        controller: _tabCtrl,
        indicatorColor: TRColors.gold,
        indicatorWeight: 2.5,
        labelColor: TRColors.gold,
        unselectedLabelColor: TRColors.grayLight,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontSize: 13),
        tabs: const [
          Tab(text: 'Terms of Service'),
          Tab(text: 'Privacy Policy'),
        ],
      ),
    );
  }

  // ── Tab content ────────────────────────────────────────────────────────────

  Widget _buildTabContent() {
    return SizedBox(
      height: 260,
      child: TabBarView(
        controller: _tabCtrl,
        children: [
          _LegalScrollView(text: _kTermsText, label: 'Effective Date: $kTermsVersion'),
          _LegalScrollView(text: _kPrivacyText, label: 'Effective Date: $kPrivacyVersion'),
        ],
      ),
    );
  }

  // ── Checkboxes ─────────────────────────────────────────────────────────────

  Widget _buildCheckboxSection() {
    return Container(
      decoration: const BoxDecoration(
        color: TRColors.cardDark,
        border: Border.symmetric(
          horizontal: BorderSide(color: TRColors.divider),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Required: Terms
          _ConsentCheckbox(
            value: _termsChecked,
            required: true,
            label: 'I have read and agree to the Terms of Service.',
            onChanged: (v) => setState(() => _termsChecked = v ?? false),
          ),
          const SizedBox(height: 6),
          // Required: Privacy
          _ConsentCheckbox(
            value: _privacyChecked,
            required: true,
            label: 'I have read and acknowledge the Privacy Policy.',
            onChanged: (v) => setState(() => _privacyChecked = v ?? false),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: TRColors.divider, height: 1),
          ),
          // Optional: Marketing
          _ConsentCheckbox(
            value: _marketingChecked,
            required: false,
            label: kMarketingConsentLanguage,
            onChanged: (v) => setState(() => _marketingChecked = v ?? false),
          ),
        ],
      ),
    );
  }

  // ── Buttons ────────────────────────────────────────────────────────────────

  Widget _buildButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _cancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: TRColors.grayLight,
                side: const BorderSide(color: TRColors.divider),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _canAccept ? _accept : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: TRColors.gold,
                disabledBackgroundColor: TRColors.gold.withValues(alpha: 0.35),
                foregroundColor: TRColors.navyDeep,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: const Text(
                'Accept & Create Account',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Scrollable legal text section ───────────────────────────────────────────

class _LegalScrollView extends StatelessWidget {
  final String text;
  final String label;
  const _LegalScrollView({required this.text, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Text(label, style: const TextStyle(
            color: TRColors.grayMid, fontSize: 10, fontStyle: FontStyle.italic,
          )),
        ),
        Expanded(
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                text,
                style: const TextStyle(
                  color: TRColors.grayLight,
                  fontSize: 12,
                  height: 1.6,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Checkbox row ──────────────────────────────────────────────────────────────

class _ConsentCheckbox extends StatelessWidget {
  final bool value;
  final bool required;
  final String label;
  final ValueChanged<bool?> onChanged;

  const _ConsentCheckbox({
    required this.value,
    required this.required,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: TRColors.gold,
                checkColor: TRColors.navyDeep,
                side: BorderSide(
                  color: required && !value ? TRColors.grayMid : TRColors.divider,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: TRColors.grayLight,
                      fontSize: 12,
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(text: label),
                      if (!required)
                        const TextSpan(
                          text: '  (optional)',
                          style: TextStyle(color: TRColors.grayMid, fontSize: 11),
                        ),
                      if (required)
                        const TextSpan(
                          text: ' *',
                          style: TextStyle(color: TRColors.error, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Legal text ───────────────────────────────────────────────────────────────

const _kTermsText = '''
TRADE REP PRO — TERMS OF SERVICE
Effective Date: July 10, 2026
Developer: The Marketing Millennial LIMITED
Support: support@app.tradereppro.com | Website: https://tradereppro.com

1. PARTIES AND AGREEMENT
These Terms of Service ("Agreement") constitute a legally binding contract between The Marketing Millennial LIMITED, doing business as Trade Rep Pro ("Company," "we," "us," or "our"), and the business entity or authorized representative accepting this Agreement ("Customer," "you," or "your"). This Agreement governs your access to and use of the Trade Rep Pro software-as-a-service platform and all associated features, APIs, and services (collectively, the "Platform").

2. DEFINITIONS
"Account" means the Customer's registered access credentials and associated data on the Platform. "AI-Generated Content" means any text, copy, or other output produced by artificial intelligence tools integrated into the Platform, including content generated through OpenAI. "Authorized User" means any individual invited by the Customer to access the Platform under the Customer's Account. "Billing Period" means the monthly subscription cycle beginning on the date the Customer's paid subscription commences. "Customer Content" means all data, photos, text, and other materials uploaded or submitted by the Customer or its Authorized Users to the Platform. "Google Business Profile" means the Customer's Google Business Profile account connected to the Platform via OAuth. "Platform" means the Trade Rep Pro SaaS application, including all features, APIs, integrations, and services provided by the Company. "Subscription" means the Customer's paid or trial access to the Platform under the pricing terms in Section 6. "Sub-Processor" means any third-party service provider that processes data on behalf of the Company in connection with the Platform.

3. ACCEPTANCE AND ELECTRONIC ASSENT
By clicking "I Agree," creating an Account, or accessing the Platform, you agree to be bound by this Agreement and the Privacy Policy, which is incorporated by reference. This electronic acceptance constitutes a valid, binding signature under the Electronic Signatures in Global and National Commerce Act (15 U.S.C. §§ 7001–7006) and the Minnesota Uniform Electronic Transactions Act (Minn. Stat. §§ 325L.01–.19). If you do not agree, you must not access or use the Platform. If you are accepting on behalf of a business entity, you represent that you have authority to bind that entity to this Agreement.

4. ELIGIBILITY AND BUSINESS-USE REPRESENTATION
The Platform is designed exclusively for business use. By creating an Account, you represent and warrant that: you are a legal business entity or an authorized representative of one; you are not accessing the Platform for personal, household, or consumer purposes; and you have the legal authority to enter into this Agreement on behalf of the business you represent. The Platform is not directed to, and may not be used by, individuals acting in a personal consumer capacity. The Company does not knowingly collect personal information from children under 13 in compliance with the Children's Online Privacy Protection Act (15 U.S.C. §§ 6501–6506; 16 C.F.R. Part 312).

5. ACCOUNT REGISTRATION AND SECURITY
5.1 Registration. You must provide accurate, complete, and current information when creating an Account. 5.2 Authorized Users. You may invite Authorized Users to your Account subject to the seat limits in Section 6. You are solely responsible for all actions taken by Authorized Users under your Account. 5.3 Credentials. You are responsible for maintaining the confidentiality of your login credentials. 5.4 Unauthorized Access. You must not access or attempt to access any Account, system, or data that you are not authorized to access.

6. SUBSCRIPTION TERMS AND PRICING
6.1 Plan. The Platform is offered at \$75.00 per month, which includes up to three (3) Authorized User seats. 6.2 Additional Seats. Each additional seat costs \$14.99 per month. 6.3 Free Trial. New Customers receive a 14-day free trial. No payment method is required to begin the trial. 6.4 Auto-Renewal. Your Subscription automatically renews each month until cancelled. 6.5 No Setup Fee.

7. MINNESOTA AUTO-RENEWAL DISCLOSURES
Monthly subscription price: \$75.00/month (up to 3 seats); \$14.99/month per additional seat. Billing cycle: monthly, automatically renewing. Cancellation method: self-service through your Account settings at tradereppro.com. No refunds after billing; cancellation takes effect at the end of the current Billing Period. At least three (3) days before your free trial converts to a paid Subscription, we will send an email notifying you of the upcoming charge and how to cancel.

8. PAYMENT, FAILED PAYMENTS, AND GRACE PERIOD
All payments are processed by Stripe. All fees are non-refundable. If a payment fails, we will notify you by email and automatically retry the charge up to three (3) times over a seven (7) day grace period.

9. CANCELLATION POLICY
You may cancel your Subscription at any time through your Account settings at tradereppro.com. Cancellation takes effect at the end of the current Billing Period. No prorated refunds are issued.

10. ACCEPTABLE USE POLICY
You may use the Platform solely for lawful business purposes. You must not use the Platform for any illegal purpose, send spam or unsolicited SMS in violation of the CAN-SPAM Act or TCPA, reverse engineer any portion of the Platform, or use AI-generated content to deceive or defraud any person.

11. GOOGLE BUSINESS PROFILE OAUTH INTEGRATION
By connecting your Google Business Profile, you authorize the Company to access it via OAuth 2.0. OAuth tokens are stored securely in Firebase and used solely for actions you initiate. You may revoke access at any time through your Account settings or through myaccount.google.com.

12. AI-GENERATED CONTENT
All AI-Generated Content is provided as a draft suggestion only. You must review and approve all AI-Generated Content before publishing or transmitting it. THE COMPANY MAKES NO WARRANTY REGARDING THE ACCURACY, COMPLETENESS, LEGALITY, OR FITNESS FOR ANY PURPOSE OF AI-GENERATED CONTENT.

13. CUSTOMER CONTENT AND INTELLECTUAL PROPERTY
You retain all ownership rights in your Customer Content. You grant the Company a limited license to use your Customer Content solely to operate and provide the Platform. The Company retains all rights in the Platform, including its software, design, trademarks, and proprietary technology.

14. DMCA SAFE HARBOR AND COPYRIGHT POLICY
DMCA notices may be sent to: legal@themarketingmillennial.com | 6367 River Mill Dr., Monticello, MN 55362.

15. THIRD-PARTY SERVICES AND SUB-PROCESSORS
The Platform integrates with Stripe, Google Firebase, Twilio, OpenAI, and Google. The Company is not liable for any outage, failure, or data loss caused by any third-party service provider. An up-to-date list of Sub-Processors is maintained at https://tradereppro.com/sub-processors.

16. WARRANTY DISCLAIMER
THE PLATFORM IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTY OF ANY KIND. THE COMPANY EXPRESSLY DISCLAIMS ALL WARRANTIES, WHETHER EXPRESS, IMPLIED, STATUTORY, OR OTHERWISE.

17. LIMITATION OF LIABILITY
THE COMPANY'S TOTAL CUMULATIVE LIABILITY FOR ALL CLAIMS WILL NOT EXCEED THE TOTAL FEES YOU ACTUALLY PAID TO THE COMPANY IN THE TWELVE (12) MONTHS IMMEDIATELY PRECEDING THE EVENT GIVING RISE TO THE CLAIM.

18. INDEMNIFICATION
You will defend, indemnify, and hold harmless the Company from and against any third-party claim arising out of your violation of this Agreement, your Customer Content, or AI-Generated Content you approved and published.

19. ACCOUNT SUSPENSION AND TERMINATION
The Company may immediately suspend or terminate your Account for illegal activity, fraud, security threats, or material breach of this Agreement.

20. DATA RETENTION AND DELETION
Following cancellation, your Customer Content remains accessible for thirty (30) days for export. After that, it is permanently deleted. Residual backup copies are purged within ninety (90) days.

21. MODIFICATIONS TO THIS AGREEMENT
The Company may modify this Agreement. For material changes, at least fourteen (14) days' email notice will be provided before changes take effect.

22. GOVERNING LAW
This Agreement is governed by the laws of the State of Minnesota. Disputes are subject to binding arbitration administered by the AAA in Minneapolis, Minnesota.

23. CLASS ACTION WAIVER
ALL CLAIMS MUST BE BROUGHT IN YOUR INDIVIDUAL CAPACITY. THE ARBITRATOR MAY NOT PRESIDE OVER ANY CLASS OR REPRESENTATIVE PROCEEDING.

Last Updated: July 10, 2026
Trade Rep Pro is a product of The Marketing Millennial LIMITED.
6367 River Mill Dr., Monticello, MN 55362
''';

const _kPrivacyText = '''
TRADE REP PRO — PRIVACY POLICY
Effective Date: July 10, 2026
Developer: The Marketing Millennial LIMITED
Privacy Contact: support@app.tradereppro.com | Website: https://tradereppro.com

1. IDENTITY OF DATA CONTROLLER
The Marketing Millennial LIMITED, doing business as Trade Rep Pro ("Company," "we," "us," or "our"), is the data controller responsible for the personal and business information collected through the Trade Rep Pro platform ("Platform").

2. SCOPE AND APPLICABILITY
This Privacy Policy applies to all data collected through the Platform, including data submitted by business account holders ("Customers") and their authorized employees ("Authorized Users"), data collected through our website at tradereppro.com, and data collected through our marketing communications.

3. DATA WE COLLECT
Business and Account Data: Company name, business address, industry, and account registration information. Employee and User Data: Names, email addresses, job titles, and login credentials of Authorized Users. Customer Data: Information about your customers that you enter into the Platform. Job and Project Data: Job descriptions, project details, status information, and associated records. Photos and Media: Images and files uploaded to the Platform. Google Business Profile Data: Profile metrics, review statistics, post performance data, and other information retrieved from your connected Google Business Profile via OAuth. AI-Generated Content: Content generated by AI tools within the Platform. Subscription and Billing Data: Subscription plan, billing history, and payment method information (payment card details are processed and stored by Stripe; we do not store full card numbers). Usage and Analytics Data: Platform usage patterns, feature interactions, login history, session data, and team activity logs. Communications Data: Records of SMS messages sent through the Platform. Marketing Preferences: Your opt-in or opt-out status for email and SMS marketing communications.

4. HOW WE COLLECT DATA
We collect data directly from you when you register an Account or enter information into the Platform; automatically through your use of the Platform; from third-party services you connect, such as your Google Business Profile via OAuth; and from Stripe in connection with subscription and billing events.

5. PURPOSES OF PROCESSING
Contract Performance: To create and manage your Account, provide Platform features, process payments, and deliver the services you have subscribed to. Platform Operations: To maintain, secure, and improve the Platform. Communications: To send transactional messages and, where you have opted in, marketing communications. Legal Compliance: To comply with applicable law, respond to legal process, and enforce our Terms of Service. Legitimate Interests: To analyze usage patterns, measure customer success, develop new features, and generate aggregated industry insights.

6. THIRD-PARTY SUB-PROCESSORS
Payment Processing: Stripe, Inc. Cloud Storage and Database: Google Firebase (Cloud Firestore and Firebase Storage). Authentication: Google Firebase Authentication. SMS Delivery: Twilio, Inc. AI Content Generation: OpenAI, L.L.C. Business Profile Management: Google LLC (Google Business Profile API). We do not sell your personal data. An up-to-date list of Sub-Processors is maintained at https://tradereppro.com/sub-processors.

7. GOOGLE BUSINESS PROFILE OAUTH DATA
We request only the OAuth scopes necessary to perform the features you use. OAuth tokens are stored securely in Firebase and used solely for actions you initiate. You may revoke access at any time through your Account settings or through myaccount.google.com.

8. AI CONTENT PROCESSING
When you use AI-powered features, your inputs are transmitted to OpenAI for processing to generate draft content. We do not use your Customer Content to train AI models without your express consent. You are solely responsible for content you choose to publish or transmit.

9. INTERNAL ANALYTICS AND AGGREGATED DATA
We collect operational metrics to measure Platform performance, customer success, and feature usage. We do not sell personally identifiable customer data. Aggregated and anonymized data may be used to improve the Platform and create industry insights.

10. MARKETING COMMUNICATIONS — EMAIL
If you opt in to email marketing, we will send you product updates, promotions, and other marketing communications from Trade Rep Pro. Every marketing email will include a clear identification that the message is from Trade Rep Pro, our physical mailing address, a functioning one-click unsubscribe mechanism, and prompt processing of unsubscribe requests within ten (10) business days. Our email marketing practices comply with the CAN-SPAM Act (15 U.S.C. §§ 7701–7713). You may unsubscribe at any time by contacting support@app.tradereppro.com.

11. MARKETING COMMUNICATIONS — SMS (TCPA / A2P 10DLC)
We will not send you SMS marketing messages unless you provide separate, express written consent. You may opt out of SMS marketing at any time by replying STOP.

12. DATA SECURITY
We implement commercially reasonable administrative, technical, and physical safeguards to protect your data against unauthorized access, alteration, disclosure, or destruction.

13. DATA RETENTION
We retain your Account and Customer Content for as long as your Account is active or as needed to provide the Platform. Following cancellation, your data is retained for thirty (30) days for export, then permanently deleted from active systems. Residual backup copies are purged within ninety (90) days.

14. YOUR RIGHTS
Depending on your location, you may have rights to access, correct, delete, or port your personal data, and to object to or restrict certain processing. To exercise these rights, contact us at support@app.tradereppro.com. We will respond within thirty (30) days.

15. MINNESOTA CONSUMER DATA PRIVACY ACT (MCDPA)
We process personal data in accordance with the Minnesota Consumer Data Privacy Act (2025 Minn. Laws, effective July 31, 2025). Minnesota residents have the right to access, correct, delete, and obtain a copy of their personal data. To submit a verified consumer request, contact support@app.tradereppro.com.

16. CHILDREN'S PRIVACY
The Platform is designed exclusively for business use and is not directed to children under 13. We do not knowingly collect personal information from children in compliance with the Children's Online Privacy Protection Act (15 U.S.C. §§ 6501–6506).

17. CONTACT US
Privacy Contact: support@app.tradereppro.com
Mailing Address: The Marketing Millennial LIMITED, 6367 River Mill Dr., Monticello, MN 55362

18. CHANGES TO THIS PRIVACY POLICY
We may update this Privacy Policy from time to time. For material changes, we will send email notice to your Account email address at least fourteen (14) days before the changes take effect.

Last Updated: July 10, 2026
Trade Rep Pro is a product of The Marketing Millennial LIMITED.
''';
