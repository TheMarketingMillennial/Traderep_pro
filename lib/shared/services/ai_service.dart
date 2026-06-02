// ai_service.dart — TradeRep Pro
//
// Thin HTTP client that calls the Railway /generate-caption endpoint.
// The Railway server holds the OPENAI_API_KEY — the Flutter app never
// touches the key directly.
//
// Usage:
//   final result = await AiService.generateCaption(
//     companyName: 'Smith Roofing',
//     trade: 'Roofing',
//     serviceArea: 'Austin, TX',
//     jobType: 'Roof Replacement',
//     jobDescription: 'Replaced 40-year-old shingles, new gutters added',
//     tone: CaptionTone.professional,
//   );
//   if (result != null) {
//     print(result.caption);
//     print(result.hashtags);
//   }

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';

// ── Tone options ──────────────────────────────────────────────────────────────
enum CaptionTone {
  professional,
  friendly,
  bold;

  String get label {
    switch (this) {
      case CaptionTone.professional: return 'Professional';
      case CaptionTone.friendly:     return 'Friendly';
      case CaptionTone.bold:         return 'Bold';
    }
  }

  String get description {
    switch (this) {
      case CaptionTone.professional: return 'Trustworthy & quality-focused';
      case CaptionTone.friendly:     return 'Warm & conversational';
      case CaptionTone.bold:         return 'Punchy & confident';
    }
  }
}

// ── Result model ──────────────────────────────────────────────────────────────
class CaptionResult {
  final String caption;
  final List<String> hashtags;
  const CaptionResult({required this.caption, required this.hashtags});
}

// ── Service ───────────────────────────────────────────────────────────────────
class AiService {
  AiService._();

  static String get _baseUrl => AppConfig.aiServerUrl;
  static const _timeout = Duration(seconds: 20);

  /// Generates a Google Business Profile post caption via the Railway server.
  /// Returns null if the server is unreachable or OpenAI is not configured.
  static Future<CaptionResult?> generateCaption({
    required String jobType,
    String companyName  = '',
    String trade        = '',
    String serviceArea  = '',
    String jobDescription = '',
    CaptionTone tone    = CaptionTone.professional,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('[AiService] Generating caption — job: $jobType, tone: ${tone.name}');
      }

      final res = await http
          .post(
            Uri.parse('$_baseUrl/generate-caption'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'companyName':    companyName,
              'trade':          trade,
              'serviceArea':    serviceArea,
              'jobType':        jobType,
              'jobDescription': jobDescription,
              'tone':           tone.name,
            }),
          )
          .timeout(_timeout);

      if (res.statusCode != 200) {
        if (kDebugMode) {
          debugPrint('[AiService] Server error ${res.statusCode}: ${res.body}');
        }
        return null;
      }

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final caption  = (json['caption']  as String?)?.trim() ?? '';
      final rawTags  = (json['hashtags'] as List<dynamic>?) ?? [];
      final hashtags = rawTags.map((t) => t.toString()).toList();

      if (caption.isEmpty) {
        if (kDebugMode) debugPrint('[AiService] Empty caption returned');
        return null;
      }

      if (kDebugMode) {
        debugPrint('[AiService] Caption received — ${caption.length} chars, ${hashtags.length} tags');
      }

      return CaptionResult(caption: caption, hashtags: hashtags);

    } catch (e) {
      if (kDebugMode) debugPrint('[AiService] generateCaption error: $e');
      return null;
    }
  }

  /// Generates a personalized SMS message via the Railway server.
  /// [type] matches the SmsTemplate key: 'review_request', 'scheduled',
  /// 'crew_on_way', 'in_progress', 'completed', 'thank_you'.
  /// Returns null if the server is unreachable or OpenAI is not configured.
  static Future<String?> generateSms({
    required String type,
    required String customerName,
    required String jobType,
    required String companyName,
    String reviewLink = '',
    String crewNote  = '',
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('[AiService] Generating SMS — type: $type, customer: $customerName');
      }

      final res = await http
          .post(
            Uri.parse('$_baseUrl/generate-sms'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'type':         type,
              'customerName': customerName,
              'jobType':      jobType,
              'companyName':  companyName,
              'reviewLink':   reviewLink,
              'crewNote':     crewNote,
            }),
          )
          .timeout(_timeout);

      if (res.statusCode != 200) {
        if (kDebugMode) debugPrint('[AiService] SMS server error ${res.statusCode}: ${res.body}');
        return null;
      }

      final json    = jsonDecode(res.body) as Map<String, dynamic>;
      final message = (json['message'] as String?)?.trim() ?? '';

      if (message.isEmpty) {
        if (kDebugMode) debugPrint('[AiService] Empty SMS returned');
        return null;
      }

      if (kDebugMode) debugPrint('[AiService] SMS received — ${message.length} chars');
      return message;

    } catch (e) {
      if (kDebugMode) debugPrint('[AiService] generateSms error: $e');
      return null;
    }
  }

  /// Quick health check — returns true if Railway server has OpenAI configured.
  static Future<bool> isAvailable() async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return false;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return json['openai'] == true;
    } catch (_) {
      return false;
    }
  }
}
