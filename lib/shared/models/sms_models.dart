// ─────────────────────────────────────────────────────────────────────────────
// SMS MODELS — TradeRep Pro
// Twilio-ready data layer. All types structured to map 1:1 with Twilio API.
// ─────────────────────────────────────────────────────────────────────────────

// ─── Message Status ───────────────────────────────────────────────────────────
enum SmsStatus {
  queued,
  sending,
  sent,
  delivered,
  failed,
  undelivered;

  String get displayName {
    switch (this) {
      case SmsStatus.queued:       return 'Queued';
      case SmsStatus.sending:      return 'Sending';
      case SmsStatus.sent:         return 'Sent';
      case SmsStatus.delivered:    return 'Delivered';
      case SmsStatus.failed:       return 'Failed';
      case SmsStatus.undelivered:  return 'Undelivered';
    }
  }

  // Maps directly from Twilio message.status field values
  static SmsStatus fromTwilio(String twilioStatus) {
    switch (twilioStatus.toLowerCase()) {
      case 'queued':      return SmsStatus.queued;
      case 'sending':     return SmsStatus.sending;
      case 'sent':        return SmsStatus.sent;
      case 'delivered':   return SmsStatus.delivered;
      case 'failed':      return SmsStatus.failed;
      case 'undelivered': return SmsStatus.undelivered;
      default:            return SmsStatus.sent;
    }
  }

  bool get isSuccess => this == SmsStatus.sent || this == SmsStatus.delivered;
  bool get isFailed  => this == SmsStatus.failed || this == SmsStatus.undelivered;
  bool get isPending => this == SmsStatus.queued || this == SmsStatus.sending;
}

// ─── SMS Message Type ─────────────────────────────────────────────────────────
enum SmsType {
  reviewRequest,
  statusUpdate;

  String get displayName {
    switch (this) {
      case SmsType.reviewRequest: return 'Review Request';
      case SmsType.statusUpdate:  return 'Status Update';
    }
  }
}

// ─── SMS Message Record ───────────────────────────────────────────────────────
// Stored locally (and optionally in Firestore sms_log collection).
// sid field maps to Twilio MessageSid — populated when live, mock value when simulated.
class SmsMessage {
  final String id;           // local UUID
  final String? sid;         // Twilio MessageSid (e.g. 'SM...')
  final String jobId;
  final String companyId;
  final String customerName;
  final String toPhone;      // E.164 format stored, display format shown in UI
  final String fromPhone;    // Twilio number — empty in mock mode
  final String body;         // actual message text sent
  final SmsType type;
  final SmsStatus status;
  final String templateKey;  // which template was used
  final bool isMock;         // true = simulated, false = real Twilio send
  final String? errorMessage;
  final DateTime sentAt;

  const SmsMessage({
    required this.id,
    this.sid,
    required this.jobId,
    required this.companyId,
    required this.customerName,
    required this.toPhone,
    this.fromPhone = '',
    required this.body,
    required this.type,
    required this.status,
    required this.templateKey,
    this.isMock = true,
    this.errorMessage,
    required this.sentAt,
  });

  SmsMessage copyWith({SmsStatus? status, String? sid, String? errorMessage}) {
    return SmsMessage(
      id: id,
      sid: sid ?? this.sid,
      jobId: jobId,
      companyId: companyId,
      customerName: customerName,
      toPhone: toPhone,
      fromPhone: fromPhone,
      body: body,
      type: type,
      status: status ?? this.status,
      templateKey: templateKey,
      isMock: isMock,
      errorMessage: errorMessage ?? this.errorMessage,
      sentAt: sentAt,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'sid': sid,
    'job_id': jobId,
    'company_id': companyId,
    'customer_name': customerName,
    'to_phone': toPhone,
    'from_phone': fromPhone,
    'body': body,
    'type': type.name,
    'status': status.name,
    'template_key': templateKey,
    'is_mock': isMock,
    'error_message': errorMessage,
    'sent_at': sentAt.toIso8601String(),
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// SMS TEMPLATES
// All message bodies are defined here. Edit text here to change what gets sent.
// Fixed variables: {customerName}, {jobType}, {companyName}, {reviewLink}
// Crew-editable variables: declared in SmsTemplateVariable list, shown as
// inline fields in the SendSmsSheet before sending.
// ─────────────────────────────────────────────────────────────────────────────

// ─── Crew-editable variable definition ───────────────────────────────────────
class SmsTemplateVariable {
  final String key;           // placeholder in body, e.g. '{{eta}}'
  final String label;         // shown above the field, e.g. 'Arrival Time'
  final String hint;          // input hint, e.g. '20 minutes'
  final List<String> quickOptions; // tap-to-fill chips; empty = freeform only

  const SmsTemplateVariable({
    required this.key,
    required this.label,
    required this.hint,
    this.quickOptions = const [],
  });
}

class SmsTemplate {
  final String key;
  final String label;
  final String description;
  final SmsType type;
  final List<SmsTemplateVariable> variables; // crew-editable placeholders
  final String Function({
    required String customerName,
    required String jobType,
    required String companyName,
    String? reviewLink,
  }) buildBody;

  const SmsTemplate({
    required this.key,
    required this.label,
    required this.description,
    required this.type,
    this.variables = const [],
    required this.buildBody,
  });
}

// ─── Template Registry ────────────────────────────────────────────────────────
class SmsTemplates {
  SmsTemplates._();

  // ── Review Request ──────────────────────────────────────────────────────────
  static final reviewRequest = SmsTemplate(
    key: 'review_request',
    label: 'Google Review Request',
    description: 'Asks customer to leave a Google review after job completion',
    type: SmsType.reviewRequest,
    buildBody: ({required customerName, required jobType, required companyName, reviewLink}) =>
      (reviewLink != null && reviewLink.isNotEmpty)
        ? 'Hey $customerName! $companyName here — we just finished your $jobType and '
          'wanted to say thank you for trusting us with the work. 🙏\n\n'
          'Would you mind leaving us a quick Google review? It takes less than 60 seconds '
          'and makes a huge difference for our small business:\n'
          '$reviewLink\n\n'
          'Thanks so much — we really appreciate it!'
        : 'Hey $customerName! $companyName here — we just finished your $jobType and '
          'wanted to say thank you for trusting us. 🙏\n\n'
          'Could you take 60 seconds to leave us a Google review? Reviews help our '
          'small business more than you know. Just search "$companyName" on Google '
          'and tap "Write a review" — we\'d really appreciate it!\n\n'
          'Thanks again for choosing us!',
  );

  // ── Status Updates ──────────────────────────────────────────────────────────
  static final scheduled = SmsTemplate(
    key: 'status_scheduled',
    label: 'Job Scheduled',
    description: 'Lets the customer know when we\'re coming',
    type: SmsType.statusUpdate,
    buildBody: ({required customerName, required jobType, required companyName, reviewLink}) =>
      'Hey $customerName! This is $companyName — we\'ve got your $jobType on the schedule. '
      'We\'ll send you a heads up before we head your way. '
      'Any questions in the meantime, just reply here.',
  );

  static final crewOnWay = SmsTemplate(
    key: 'status_crew_on_way',
    label: 'Crew On the Way',
    description: 'Heads up text when crew is leaving for the job',
    type: SmsType.statusUpdate,
    variables: [
      SmsTemplateVariable(
        key: '{{eta}}',
        label: 'Arrival Time',
        hint: 'e.g. 20 minutes',
        quickOptions: ['10 minutes', '15 minutes', '20 minutes', '30 minutes', '45 minutes', '1 hour'],
      ),
    ],
    buildBody: ({required customerName, required jobType, required companyName, reviewLink}) =>
      'Hey $customerName — $companyName here. Our crew just left and we\'re heading your way now. '
      'Should be there in about {{eta}}. See you soon! 🚛',
  );

  static final inProgress = SmsTemplate(
    key: 'status_in_progress',
    label: 'Work Started',
    description: 'Quick text once the crew gets started on site',
    type: SmsType.statusUpdate,
    buildBody: ({required customerName, required jobType, required companyName, reviewLink}) =>
      'Hey $customerName! $companyName here — we\'re on site and the crew just got started on your $jobType. '
      'We\'ll keep you posted as things move along.',
  );

  static final completed = SmsTemplate(
    key: 'status_completed',
    label: 'Job Wrapped Up',
    description: 'Notifies customer the work is done and crew has cleaned up',
    type: SmsType.statusUpdate,
    buildBody: ({required customerName, required jobType, required companyName, reviewLink}) =>
      'Hey $customerName — $companyName here. Your $jobType is all wrapped up! ✅ '
      'The crew has cleaned up and cleared out. '
      'Take a look when you get a chance and let us know if you have any questions.',
  );

  static final thankYou = SmsTemplate(
    key: 'status_thank_you',
    label: 'Thank You',
    description: 'Personal thank you after the job is complete',
    type: SmsType.statusUpdate,
    buildBody: ({required customerName, required jobType, required companyName, reviewLink}) =>
      'Hey $customerName — just wanted to personally say thank you for choosing $companyName. '
      'Your $jobType was a great project and we really appreciate your business. '
      'We\'re always here if you need anything down the road. 🏠',
  );

  // ── All templates by type ───────────────────────────────────────────────────
  static List<SmsTemplate> get reviewTemplates => [reviewRequest];

  static List<SmsTemplate> get statusTemplates => [
    scheduled,
    crewOnWay,
    inProgress,
    completed,
    thankYou,
  ];

  static SmsTemplate? byKey(String key) {
    final all = [...reviewTemplates, ...statusTemplates];
    try {
      return all.firstWhere((t) => t.key == key);
    } catch (_) {
      return null;
    }
  }
}

// ─── Phone Validation ─────────────────────────────────────────────────────────
class PhoneValidator {
  PhoneValidator._();

  // Strips all non-digit characters from a phone number string
  static String digitsOnly(String phone) =>
      phone.replaceAll(RegExp(r'[^\d]'), '');

  // Returns true if the phone number has exactly 10 digits (US)
  static bool isValid(String phone) {
    final digits = digitsOnly(phone);
    return digits.length == 10 || (digits.length == 11 && digits.startsWith('1'));
  }

  // Converts any US format to E.164: +1XXXXXXXXXX
  // Handles: (720) 555-1234 / 720-555-1234 / 7205551234 / 17205551234
  static String toE164(String phone) {
    final digits = digitsOnly(phone);
    if (digits.length == 10) return '+1$digits';
    if (digits.length == 11 && digits.startsWith('1')) return '+$digits';
    return '+1$digits'; // best effort
  }

  // Formats E.164 for display: +17205551234 → (720) 555-1234
  static String toDisplay(String phone) {
    final digits = digitsOnly(phone);
    final d = digits.length == 11 ? digits.substring(1) : digits;
    if (d.length == 10) {
      return '(${d.substring(0,3)}) ${d.substring(3,6)}-${d.substring(6)}';
    }
    return phone;
  }

  // Validation error string for UI (null = valid)
  static String? validate(String phone) {
    if (phone.trim().isEmpty) return 'Phone number is required';
    if (!isValid(phone)) return 'Enter a valid 10-digit US phone number';
    return null;
  }
}
