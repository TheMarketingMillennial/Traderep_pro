// ─────────────────────────────────────────────────────────────────────────────
// gbp_service.dart — TradeRep Pro
//
// Flutter-side HTTP client that talks to the /gbp/* routes on the Railway
// backend (server.js). All GBP OAuth credentials (client_id, client_secret,
// access_token, refresh_token) stay on the server — Flutter never sees them.
//
// ─── How it works ────────────────────────────────────────────────────────────
//
//  1. Admin taps "Connect with Google" → GbpAuthService opens OAuth consent in
//     browser → Railway /gbp/callback stores tokens + locationId in Firestore.
//
//  2. When admin taps "Publish to Google Business Profile" in PublishSheet,
//     Flutter calls GbpService.instance.publishPost(...).
//
//  3. GbpService POSTs to /publish-google-post on the Railway server,
//     passing companyId + post content.
//
//  4. Railway reads the stored access_token from Firestore (auto-refreshing
//     via refresh_token if expired), then calls the GBP Posts API.
//
//  5. On success, AppState marks the ContentPost as ContentStatus.published
//     in Firestore and returns the GBP post name (resource ID) to the caller.
//
// ─── Configuration ────────────────────────────────────────────────────────────
//   --dart-define=GBP_SERVER_URL=https://traderep-server-production.up.railway.app
//   Defaults to the production Railway URL (app_config.dart).
//   No localhost fallback — all environments use the live Railway backend.
//
// ─── Degradation ─────────────────────────────────────────────────────────────
//   If the server is unreachable, returns GbpResult.failure with
//   error_code='SERVER_UNREACHABLE' — caller shows manual fallback UI.
//   If GBP OAuth is not yet configured, returns GBP_NOT_CONFIGURED.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';

class GbpService {
  GbpService._();
  static final GbpService instance = GbpService._();

  static String get _baseUrl => AppConfig.gbpServerUrl;
  static const Duration _timeout = Duration(seconds: 20);

  // ── Publish Post ─────────────────────────────────────────────────────────

  /// Publishes a post to Google Business Profile via the Railway server.
  ///
  /// [locationId]  — GBP location resource name, e.g. 'accounts/123/locations/456'.
  ///                 Stored as Company.gbpLocationId in Firestore.
  ///
  /// [summary]     — Full post text (caption + hashtags, already combined).
  ///                 GBP max ~1500 characters.
  ///
  /// [photoUrl]    — URL of the after photo. GBP fetches this URL server-side
  ///                 to attach as the post's media. Must be publicly accessible.
  ///
  /// [callToActionType]  — GBP CTA type: 'CALL', 'LEARN_MORE', 'SIGN_UP', etc.
  ///                       Defaults to 'CALL' when company phone is provided.
  ///
  /// [callToActionUrl]   — URL or tel: link for the CTA button.
  Future<GbpResult> publishPost({
    required String locationId,
    required String summary,
    required String photoUrl,
    String callToActionType = 'CALL',
    String callToActionUrl = '',
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/gbp/publish'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'location_id':          locationId,
          'summary':              summary,
          'photo_url':            photoUrl,
          'call_to_action_type':  callToActionType,
          'call_to_action_url':   callToActionUrl,
        }),
      ).timeout(_timeout);

      final data = json.decode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 && data['success'] == true) {
        final post = data['post'] as Map<String, dynamic>? ?? {};
        final isMock = post['is_mock'] as bool? ?? false;
        final postName = post['name'] as String? ?? '';
        if (kDebugMode) {
          debugPrint('[GbpService] ✅ Post published | name: $postName | mock: $isMock');
        }
        return GbpResult.success(
          postName: postName,
          isMock: isMock,
        );
      }

      // Server returned a structured error
      final errorCode = data['error_code'] as String? ?? 'UNKNOWN';
      final error     = data['error']      as String? ?? 'Unknown server error';
      if (kDebugMode) debugPrint('[GbpService] ❌ $errorCode: $error');
      return GbpResult.failure(error: error, errorCode: errorCode);

    } on Exception catch (e) {
      if (kDebugMode) debugPrint('[GbpService] Server unreachable: $e');
      return GbpResult.failure(
        error: 'GBP server unreachable. Check your internet connection.',
        errorCode: 'SERVER_UNREACHABLE',
      );
    }
  }

  // ── Config Check ─────────────────────────────────────────────────────────

  /// Checks whether the Railway server has GBP credentials configured.
  /// Used by the settings UI to show a helpful status indicator.
  Future<GbpServerConfig> checkConfig() async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/gbp/config'))
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        return GbpServerConfig(
          online:         true,
          mockMode:       data['mock_mode']      as bool? ?? true,
          gbpConfigured:  data['gbp_configured'] as bool? ?? false,
          clientIdHint:   data['client_id_hint'] as String? ?? '',
        );
      }
    } catch (_) {}
    return const GbpServerConfig(
      online:        false,
      mockMode:      true,
      gbpConfigured: false,
      clientIdHint:  '',
    );
  }
}

// ─── Result types ──────────────────────────────────────────────────────────

class GbpResult {
  final bool success;
  /// GBP localPost resource name on success, e.g. 'accounts/123/locations/456/localPosts/789'
  final String? postName;
  final bool isMock;
  final String? error;
  /// Machine-readable code: GBP_NOT_CONFIGURED | GBP_AUTH_FAILED |
  /// GBP_API_ERROR | SERVER_UNREACHABLE | UNKNOWN
  final String? errorCode;

  const GbpResult._({
    required this.success,
    this.postName,
    this.isMock = false,
    this.error,
    this.errorCode,
  });

  factory GbpResult.success({required String postName, bool isMock = false}) =>
      GbpResult._(success: true, postName: postName, isMock: isMock);

  factory GbpResult.failure({required String error, String errorCode = 'UNKNOWN'}) =>
      GbpResult._(success: false, error: error, errorCode: errorCode);

  /// True when credentials aren't set on the server yet —
  /// UI should offer the manual Phase 1 fallback.
  bool get isNotConfigured => errorCode == 'GBP_NOT_CONFIGURED';
  bool get isAuthFailed    => errorCode == 'GBP_AUTH_FAILED';
  bool get isUnreachable   => errorCode == 'SERVER_UNREACHABLE';
}

class GbpServerConfig {
  final bool online;
  final bool mockMode;
  final bool gbpConfigured;
  final String clientIdHint;

  const GbpServerConfig({
    required this.online,
    required this.mockMode,
    required this.gbpConfigured,
    required this.clientIdHint,
  });
}
