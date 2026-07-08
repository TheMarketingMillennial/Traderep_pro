// ─────────────────────────────────────────────────────────────────────────────
// gbp_auth_service.dart — TradeRep Pro
//
// Handles the Google OAuth2 flow for connecting Google Business Profile.
//
// FLOW:
//  1. Call getAuthUrl(companyId) → Railway returns a Google OAuth URL
//  2. Open that URL in the external browser (url_launcher)
//  3. User approves → Google redirects to Railway /gbp/callback
//  4. Railway stores tokens + locationId in Firestore, shows success page
//  5. App polls /gbp/status to detect when Firestore is updated
//  6. On detection → calls AppState.connectGoogle() to update UI
//
// The Flutter app never sees OAuth tokens — they live entirely on the server.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/app_config.dart';

class GbpAuthResult {
  final bool success;
  final String? locationId;
  final String? locationName;
  final String? error;

  const GbpAuthResult._({
    required this.success,
    this.locationId,
    this.locationName,
    this.error,
  });

  factory GbpAuthResult.connected({String? locationId, String? locationName}) =>
      GbpAuthResult._(success: true, locationId: locationId, locationName: locationName);

  factory GbpAuthResult.failed(String error) =>
      GbpAuthResult._(success: false, error: error);
}

class GbpAuthService {
  GbpAuthService._();
  static final GbpAuthService instance = GbpAuthService._();

  static String get _baseUrl => AppConfig.gbpServerUrl;
  static const Duration _httpTimeout = Duration(seconds: 15);

  // ── Check if server has OAuth configured ────────────────────────────────────

  /// Returns true if Railway has GOOGLE_CLIENT_ID + GOOGLE_CLIENT_SECRET set.
  Future<bool> isOAuthConfigured() async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(_httpTimeout);
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        return data['gbp_oauth'] as bool? ?? false;
      }
    } catch (_) {}
    return false;
  }

  // ── Step 1: Get OAuth URL from Railway ──────────────────────────────────────

  /// Fetches the Google OAuth consent URL from the Railway server.
  Future<String?> getAuthUrl(String companyId) async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/gbp/auth-url?companyId=${Uri.encodeComponent(companyId)}'))
          .timeout(_httpTimeout);

      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        return data['authUrl'] as String?;
      }
      if (kDebugMode) {
        debugPrint('[GbpAuth] auth-url error ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[GbpAuth] getAuthUrl failed: $e');
    }
    return null;
  }

  // ── Step 2: Open OAuth URL in browser ──────────────────────────────────────

  /// Opens the Google OAuth consent screen in the external browser.
  /// Returns true if the URL was successfully launched.
  Future<bool> openAuthBrowser(String authUrl) async {
    final uri = Uri.parse(authUrl);
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (kDebugMode) debugPrint('[GbpAuth] openAuthBrowser failed: $e');
      return false;
    }
  }

  // ── Step 3: Poll /gbp/status until connected (or timeout) ──────────────────

  /// Polls the Railway /gbp/status endpoint until the company shows as connected.
  ///
  /// [companyId] — Firestore company document ID
  /// [onConnected] — called immediately when connected status detected
  /// [timeoutSeconds] — give up after this many seconds (default 300 = 5 min)
  /// [intervalSeconds] — polling interval (default 3s)
  ///
  /// Returns [GbpAuthResult] with connection info or error.
  Future<GbpAuthResult> pollForConnection({
    required String companyId,
    void Function(GbpAuthResult)? onConnected,
    int timeoutSeconds = 300,
    int intervalSeconds = 3,
  }) async {
    final deadline = DateTime.now().add(Duration(seconds: timeoutSeconds));

    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(Duration(seconds: intervalSeconds));

      try {
        final res = await http
            .get(Uri.parse('$_baseUrl/gbp/status?companyId=${Uri.encodeComponent(companyId)}'))
            .timeout(_httpTimeout);

        if (res.statusCode == 200) {
          final data = json.decode(res.body) as Map<String, dynamic>;
          final connected = data['connected'] as bool? ?? false;

          if (connected) {
            final result = GbpAuthResult.connected(
              locationId:   data['location_id']   as String?,
              locationName: data['location_name'] as String?,
            );
            if (kDebugMode) {
              debugPrint('[GbpAuth] ✅ Connected — location: ${result.locationId}');
            }
            onConnected?.call(result);
            return result;
          }
        }
      } catch (e) {
        if (kDebugMode) debugPrint('[GbpAuth] pollForConnection error: $e');
        // Non-fatal — keep polling
      }
    }

    return GbpAuthResult.failed('Connection timed out. Please try again.');
  }

  // ── Combined: getAuthUrl + openBrowser + startPolling ──────────────────────

  /// Full OAuth flow in one call.
  ///
  /// 1. Fetches auth URL from Railway
  /// 2. Opens it in browser
  /// 3. Starts background polling for connection
  ///
  /// [onBrowserOpened] — called after browser opens successfully; use this to
  ///                     show a "Waiting for Google..." spinner in the UI.
  /// [onConnected]     — called when polling detects successful connection.
  /// [onError]         — called if any step fails.
  Future<void> startOAuthFlow({
    required String companyId,
    void Function()? onBrowserOpened,
    void Function(GbpAuthResult)? onConnected,
    void Function(String error)? onError,
  }) async {
    // 1. Get auth URL
    final authUrl = await getAuthUrl(companyId);
    if (authUrl == null || authUrl.isEmpty) {
      onError?.call(
        'Could not reach the TradeRep server. Check your internet connection.',
      );
      return;
    }

    // 2. Open browser
    final opened = await openAuthBrowser(authUrl);
    if (!opened) {
      onError?.call('Could not open browser. Please try again.');
      return;
    }

    onBrowserOpened?.call();

    // 3. Poll for connection in background (don't await — caller controls UI)
    pollForConnection(
      companyId: companyId,
      onConnected: onConnected,
    ).then((result) {
      if (!result.success) {
        onError?.call(result.error ?? 'Connection timed out.');
      }
    });
  }
}
