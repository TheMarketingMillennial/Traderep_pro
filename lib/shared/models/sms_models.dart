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
    description: 'Sends customer a link to leave a Google review',
    type: SmsType.reviewRequest,
    buildBody: ({required customerName, required jobType, required companyName, reviewLink}) =>
      (reviewLink != null && reviewLink.isNotEmpty)
        ? 'Hi $customerName! Your $jobType with $companyName is complete. '
          'We\'d love your feedback — could you spare 2 minutes to leave us a Google review? '
          '$reviewLink Thank you! 🌟'
        : 'Hi $customerName! Your $jobType with $companyName is complete. '
          'Thank you so much for choosing us! 🌟',
  );

  // ── Status Updates ──────────────────────────────────────────────────────────
  static final scheduled = SmsTemplate(
    key: 'status_scheduled',
    label: 'Project Scheduled',
    description: 'Notifies customer their project has been scheduled',
    type: SmsType.statusUpdate,
    buildBody: ({required customerName, required jobType, required companyName, reviewLink}) =>
      'Hi $customerName! Great news — your $jobType with $companyName has been scheduled. '
      'We\'ll be in touch with the exact date and time. Questions? Reply to this message.',
  );

  static final crewOnWay = SmsTemplate(
    key: 'status_crew_on_way',
    label: 'Crew On the Way',
    description: 'Lets customer know the crew is heading to the job site',
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
      'Hi $customerName! Your $companyName crew is on their way to your property now. '
      'Expected arrival in {{eta}}. Thank you for choosing us! 🚛',
  );

  static final inProgress = SmsTemplate(
    key: 'status_in_progress',
    label: 'Project In Progress',
    description: 'Confirms work has started on the customer\'s project',
    type: SmsType.statusUpdate,
    buildBody: ({required customerName, required jobType, required companyName, reviewLink}) =>
      'Hi $customerName! Work has officially started on your $jobType. '
      'Our $companyName crew is on-site and making great progress. We\'ll keep you updated!',
  );

  static final completed = SmsTemplate(
    key: 'status_completed',
    label: 'Project Completed',
    description: 'Confirms the project is done',
    type: SmsType.statusUpdate,
    buildBody: ({required customerName, required jobType, required companyName, reviewLink}) =>
      'Hi $customerName! Your $jobType is complete! ✅ '
      'The $companyName crew has finished and cleaned up. '
      'Please take a look and let us know if you have any questions.',
  );

  static final thankYou = SmsTemplate(
    key: 'status_thank_you',
    label: 'Thank You',
    description: 'Sends a thank you message after project completion',
    type: SmsType.statusUpdate,
    buildBody: ({required customerName, required jobType, required companyName, reviewLink}) =>
      'Hi $customerName! Thank you for choosing $companyName for your $jobType. '
      'It was a pleasure working with you. We\'re always here if you need us again! 🏠',
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
