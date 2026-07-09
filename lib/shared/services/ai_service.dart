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

// ── Brand voice / tone options ────────────────────────────────────────────────
// 9 options matching the admin brand voice selector in ProfileScreen.
// The server /generate-caption endpoint reads the 'tone' field as these names.
enum CaptionTone {
  professional,
  friendly,
  familyOwned,
  luxury,
  educational,
  straightforward,
  premium,
  bold,
  localCommunity;

  String get label {
    switch (this) {
      case CaptionTone.professional:    return 'Professional';
      case CaptionTone.friendly:        return 'Friendly';
      case CaptionTone.familyOwned:     return 'Family-Owned';
      case CaptionTone.luxury:          return 'Luxury';
      case CaptionTone.educational:     return 'Educational';
      case CaptionTone.straightforward: return 'Straightforward';
      case CaptionTone.premium:         return 'Premium';
      case CaptionTone.bold:            return 'Bold';
      case CaptionTone.localCommunity:  return 'Local Community';
    }
  }

  String get description {
    switch (this) {
      case CaptionTone.professional:    return 'Trustworthy & quality-focused';
      case CaptionTone.friendly:        return 'Warm & conversational';
      case CaptionTone.familyOwned:     return 'Personal & community-rooted';
      case CaptionTone.luxury:          return 'Premium & sophisticated';
      case CaptionTone.educational:     return 'Informative & helpful';
      case CaptionTone.straightforward: return 'Direct & no-nonsense';
      case CaptionTone.premium:         return 'High-quality & exclusive';
      case CaptionTone.bold:            return 'Punchy & confident';
      case CaptionTone.localCommunity:  return 'Neighborly & place-based';
    }
  }

  /// The key sent to the server — matches Firestore brand_voice field values.
  String get serverKey {
    switch (this) {
      case CaptionTone.professional:    return 'professional';
      case CaptionTone.friendly:        return 'friendly';
      case CaptionTone.familyOwned:     return 'family_owned';
      case CaptionTone.luxury:          return 'luxury';
      case CaptionTone.educational:     return 'educational';
      case CaptionTone.straightforward: return 'straightforward';
      case CaptionTone.premium:         return 'premium';
      case CaptionTone.bold:            return 'bold';
      case CaptionTone.localCommunity:  return 'local_community';
    }
  }

  /// Construct from a Firestore brand_voice string.
  static CaptionTone fromBrandVoice(String? voice) {
    switch (voice) {
      case 'professional':    return CaptionTone.professional;
      case 'friendly':        return CaptionTone.friendly;
      case 'family_owned':    return CaptionTone.familyOwned;
      case 'luxury':          return CaptionTone.luxury;
      case 'educational':     return CaptionTone.educational;
      case 'straightforward': return CaptionTone.straightforward;
      case 'premium':         return CaptionTone.premium;
      case 'bold':            return CaptionTone.bold;
      case 'local_community': return CaptionTone.localCommunity;
      default:                return CaptionTone.professional;
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
  ///
  /// New parameters for enhanced generation:
  /// - [brandVoice]: Admin's selected writing style key (e.g. 'friendly').
  ///   Overrides [tone] when provided.
  /// - [customerHighlight]: One-sentence highlight submitted by crew.
  /// - [customerCity]: City from the job address for geographic relevance.
  /// - [season]: Current season string (e.g. 'summer', 'winter').
  /// - [previousPostSummaries]: List of {opening, closing, hashtags} maps from
  ///   the last 50–100 published posts for anti-repetition.
  ///
  /// Returns null if the server is unreachable or OpenAI is not configured.
  static Future<CaptionResult?> generateCaption({
    required String jobType,
    String companyName        = '',
    String trade              = '',
    String serviceArea        = '',
    String jobDescription     = '',
    CaptionTone tone          = CaptionTone.professional,
    String? brandVoice,
    String? customerHighlight,
    String? customerCity,
    String? season,
    List<Map<String, dynamic>> previousPostSummaries = const [],
  }) async {
    try {
      // Resolve effective tone: brand voice takes precedence over explicit tone.
      final effectiveTone = brandVoice != null
          ? CaptionTone.fromBrandVoice(brandVoice)
          : tone;

      if (kDebugMode) {
        debugPrint('[AiService] Generating caption — job: $jobType, voice: ${effectiveTone.serverKey}');
      }

      final res = await http
          .post(
            Uri.parse('$_baseUrl/generate-caption'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'companyName':           companyName,
              'trade':                 trade,
              'serviceArea':           serviceArea,
              'jobType':               jobType,
              'jobDescription':        jobDescription,
              'tone':                  effectiveTone.serverKey,
              if (customerHighlight != null && customerHighlight.isNotEmpty)
                'customerHighlight':   customerHighlight,
              if (customerCity != null && customerCity.isNotEmpty)
                'customerCity':        customerCity,
              if (season != null && season.isNotEmpty)
                'season':              season,
              if (previousPostSummaries.isNotEmpty)
                'previousPosts':       previousPostSummaries,
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

  /// Returns the current meteorological season string for the Northern Hemisphere.
  static String get currentSeason {
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5)  return 'spring';
    if (month >= 6 && month <= 8)  return 'summer';
    if (month >= 9 && month <= 11) return 'fall';
    return 'winter';
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
