// ─────────────────────────────────────────────────────────────────────────────
// SMS SERVICE — TradeRep Pro
//
// Flutter-side HTTP client that calls the Railway backend.
// All Twilio credentials stay on the server — Flutter never sees them.
// Endpoints: POST /sms/send, GET /sms/log, GET /health
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/sms_models.dart';
import '../../core/config/app_config.dart';

class SmsService {
  SmsService._();
  static final SmsService instance = SmsService._();

  // ── Server URL ──────────────────────────────────────────────────────────────
  // Reads from --dart-define=SMS_SERVER_URL (set in scripts/build_with_secrets.sh).
  // Defaults to the production Railway URL. See app_config.dart for details.
  static String get _baseUrl => AppConfig.smsServerUrl;

  // Timeout for individual SMS send requests
  static const Duration _timeout = Duration(seconds: 15);

  // ── Health Check ─────────────────────────────────────────────────────────
  Future<SmsServerStatus> checkHealth() async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        return SmsServerStatus(
          online: true,
          mockMode: data['mock_mode'] as bool? ?? true,
          twilioConfigured: data['twilio_configured'] as bool? ?? false,
          messagesSent: data['messages_sent'] as int? ?? 0,
        );
      }
    } catch (_) {}
    return const SmsServerStatus(online: false, mockMode: true,
        twilioConfigured: false, messagesSent: 0);
  }

  // ── Send SMS ────────────────────────────────────────────────────────────────
  Future<SmsResult> send({
    required String toPhone,
    required String body,
    required String jobId,
    required String templateKey,
    required String customerName,
    required SmsType type,
  }) async {
    // Client-side phone validation before hitting the server
    final validationError = PhoneValidator.validate(toPhone);
    if (validationError != null) {
      return SmsResult.failure(
        error: validationError,
        toPhone: toPhone,
        templateKey: templateKey,
      );
    }

    final e164 = PhoneValidator.toE164(toPhone);

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/sms/send'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'to_phone':      e164,
          'body':          body,
          'job_id':        jobId,
          'template_key':  templateKey,
          'customer_name': customerName,
          'type':          type.name,
        }),
      ).timeout(_timeout);

      final data = json.decode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 && data['success'] == true) {
        final msgData = data['message'] as Map<String, dynamic>;
        final message = _parseMessage(msgData);
        return SmsResult.success(message: message);
      } else {
        final error = data['error'] as String? ?? 'Unknown server error';
        if (kDebugMode) debugPrint('SMS send failed: $error');
        return SmsResult.failure(
          error: error,
          toPhone: toPhone,
          templateKey: templateKey,
        );
      }
    } on Exception catch (e) {
      // Server unreachable — fall through to local mock fallback
      if (kDebugMode) debugPrint('SMS server unreachable: $e — using local mock');
      return _localMockSend(
        toPhone: e164,
        body: body,
        jobId: jobId,
        templateKey: templateKey,
        customerName: customerName,
        type: type,
      );
    }
  }

  // ── Fetch Server Log ────────────────────────────────────────────────────────
  Future<List<SmsMessage>> fetchLog() async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/sms/log'))
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final messages = (data['messages'] as List<dynamic>? ?? [])
            .map((m) => _parseMessage(m as Map<String, dynamic>))
            .toList();
        return messages;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('fetchLog error: $e');
    }
    return [];
  }

  // ── Local Mock Fallback ─────────────────────────────────────────────────────
  // Used when Railway server is unreachable (e.g. no internet, local dev).
  // Produces a realistic SmsMessage so the UI still works fully.
  SmsResult _localMockSend({
    required String toPhone,
    required String body,
    required String jobId,
    required String templateKey,
    required String customerName,
    required SmsType type,
  }) {
    final id = 'LOCAL_${DateTime.now().millisecondsSinceEpoch}';
    final message = SmsMessage(
      id: id,
      sid: 'LOCAL_MOCK_$id',
      jobId: jobId,
      companyId: 'co_001',
      customerName: customerName,
      toPhone: toPhone,
      body: body,
      type: type,
      status: SmsStatus.delivered,
      templateKey: templateKey,
      isMock: true,
      sentAt: DateTime.now(),
    );
    if (kDebugMode) {
      debugPrint('[LOCAL MOCK] SMS to $toPhone | $templateKey | $body');
    }
    return SmsResult.success(message: message);
  }

  // ── Parser ──────────────────────────────────────────────────────────────────
  SmsMessage _parseMessage(Map<String, dynamic> d) {
    return SmsMessage(
      id:           d['id'] as String? ?? '',
      sid:          d['sid'] as String?,
      jobId:        d['job_id'] as String? ?? '',
      companyId:    d['company_id'] as String? ?? 'co_001',
      customerName: d['customer_name'] as String? ?? '',
      toPhone:      d['to'] as String? ?? d['to_phone'] as String? ?? '',
      fromPhone:    d['from'] as String? ?? d['from_phone'] as String? ?? '',
      body:         d['body'] as String? ?? '',
      type:         _parseType(d['type'] as String?),
      status:       SmsStatus.fromTwilio(d['status'] as String? ?? 'sent'),
      templateKey:  d['template_key'] as String? ?? '',
      isMock:       d['is_mock'] as bool? ?? true,
      errorMessage: d['error'] as String?,
      sentAt:       _parseDate(d['sent_at']),
    );
  }

  SmsType _parseType(String? raw) {
    if (raw == 'reviewRequest' || raw == 'review_request') {
      return SmsType.reviewRequest;
    }
    return SmsType.statusUpdate;
  }

  DateTime _parseDate(dynamic raw) {
    if (raw == null) return DateTime.now();
    try { return DateTime.parse(raw as String); } catch (_) { return DateTime.now(); }
  }
}

// ─── Server Status ────────────────────────────────────────────────────────────
class SmsServerStatus {
  final bool online;
  final bool mockMode;
  final bool twilioConfigured;
  final int messagesSent;
  const SmsServerStatus({
    required this.online,
    required this.mockMode,
    required this.twilioConfigured,
    required this.messagesSent,
  });
}

// ─── Result Type ──────────────────────────────────────────────────────────────
class SmsResult {
  final bool success;
  final SmsMessage? message;
  final String? error;

  const SmsResult._({required this.success, this.message, this.error});

  factory SmsResult.success({required SmsMessage message}) =>
      SmsResult._(success: true, message: message);

  factory SmsResult.failure({
    required String error,
    String toPhone = '',
    String templateKey = '',
  }) => SmsResult._(success: false, error: error);
}
