import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color, ThemeMode;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import '../../features/pricing/pricing_models.dart';

// ─── Result types ─────────────────────────────────────────────────────────────

class StripeResult {
  final bool success;
  final String? error;
  final String? subscriptionId;
  final String? customerId;

  const StripeResult._({
    required this.success,
    this.error,
    this.subscriptionId,
    this.customerId,
  });

  factory StripeResult.ok({String? subscriptionId, String? customerId}) =>
      StripeResult._(
        success: true,
        subscriptionId: subscriptionId,
        customerId: customerId,
      );

  factory StripeResult.fail(String message) =>
      StripeResult._(success: false, error: message);
}

// ─── StripeService ────────────────────────────────────────────────────────────

class StripeService {
  static final String _baseUrl = AppConfig.stripeServerUrl;

  /// Creates a Stripe subscription with a 14-day trial on the Railway backend,
  /// then presents the Flutter Stripe payment sheet to collect card details.
  ///
  /// The server always uses [TRPlan.basePriceId] ($75/mo) as the base item.
  /// If [extraSeats] > 0, [TRPlan.seatPriceId] ($14.99/seat/mo) is added at
  /// the given quantity.
  ///
  /// [companyId] is required — the server needs it to look up/create the
  /// Stripe Customer and write the subscription back to Firestore.
  ///
  /// Returns [StripeResult.ok] on sheet confirmation or
  /// [StripeResult.fail] with a human-readable message on any error.
  static Future<StripeResult> startTrialSubscription({
    required String email,
    required String name,
    required String companyId,
    int extraSeats = 0,
  }) async {
    try {
      debugPrint('[Stripe] Creating subscription — company: $companyId, email: $email, extraSeats: $extraSeats');

      // ── 1. Call Railway to create subscription + get client secret ──────
      final response = await http
          .post(
            Uri.parse('$_baseUrl/create-subscription'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'companyId':  companyId,
              'email':      email,
              'name':       name,
              'extraSeats': extraSeats,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        final body = _tryDecode(response.body);
        final msg = body?['error'] as String? ?? 'Server error (${response.statusCode})';
        debugPrint('[Stripe] Server error: $msg');
        return StripeResult.fail(msg);
      }

      final data = _tryDecode(response.body);
      if (data == null) {
        return StripeResult.fail('Invalid response from server.');
      }

      final clientSecret   = data['clientSecret'] as String?;
      final subscriptionId = data['subscriptionId'] as String?;
      final customerId     = data['customerId'] as String?;

      if (clientSecret == null || clientSecret.isEmpty) {
        return StripeResult.fail('No payment intent received from server.');
      }

      debugPrint('[Stripe] Got clientSecret — subscriptionId=$subscriptionId, customerId=$customerId');

      // ── 2. Init payment sheet ────────────────────────────────────────────
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'TradeRep Pro',
          style: ThemeMode.dark,
          appearance: PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: const Color(0xFFD4A843),   // TRColors.gold
              background: const Color(0xFF0F1E35),
              componentBackground: const Color(0xFF162236),
              componentText: const Color(0xFFFFFFFF),
              placeholderText: const Color(0xFF8899AA),
            ),
            shapes: const PaymentSheetShape(borderRadius: 12),
          ),
        ),
      );

      // ── 3. Present payment sheet ─────────────────────────────────────────
      await Stripe.instance.presentPaymentSheet();

      debugPrint('[Stripe] Payment sheet confirmed ✅');
      return StripeResult.ok(
        subscriptionId: subscriptionId,
        customerId: customerId,
      );
    } on StripeException catch (e) {
      final msg = e.error.localizedMessage ?? e.error.message ?? 'Payment cancelled.';
      debugPrint('[Stripe] StripeException: $msg');
      return StripeResult.fail(msg);
    } on http.ClientException catch (e) {
      debugPrint('[Stripe] Network error: $e');
      return StripeResult.fail('Network error — check your connection and try again.');
    } catch (e) {
      debugPrint('[Stripe] Unexpected error: $e');
      return StripeResult.fail('Something went wrong. Please try again.');
    }
  }

  /// Adds one seat to an existing Stripe subscription in-place.
  ///
  /// Calls `/add-seat` on the Railway backend which:
  ///   - Finds the growth (per-seat) item on the subscription
  ///   - Increments its quantity by 1 (or adds it fresh if missing)
  ///   - Writes updated `purchased_seats` / `extra_seats` to Firestore
  ///
  /// Does NOT cancel or recreate the subscription.
  ///
  /// Returns [StripeResult.ok] with updated seat counts in the response
  /// fields, or [StripeResult.fail] on error.
  static Future<StripeResult> addSeatToSubscription({
    required String subscriptionId,
    required String companyId,
  }) async {
    try {
      debugPrint('[Stripe] add-seat — subscription: $subscriptionId, company: $companyId');

      final response = await http
          .post(
            Uri.parse('$_baseUrl/add-seat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'subscriptionId': subscriptionId,
              'companyId':      companyId,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        final body = _tryDecode(response.body);
        final msg = body?['error'] as String? ?? 'Server error (${response.statusCode})';
        debugPrint('[Stripe] add-seat server error: $msg');
        return StripeResult.fail(msg);
      }

      final data = _tryDecode(response.body);
      if (data == null || data['success'] != true) {
        return StripeResult.fail('Unexpected response from server.');
      }

      debugPrint('[Stripe] Seat added ✅ — purchasedSeats: ${data['purchasedSeats']}, extraSeats: ${data['extraSeats']}');
      return StripeResult.ok(subscriptionId: subscriptionId);
    } on http.ClientException catch (e) {
      debugPrint('[Stripe] Network error (add-seat): $e');
      return StripeResult.fail('Network error — check your connection and try again.');
    } catch (e) {
      debugPrint('[Stripe] Unexpected error (add-seat): $e');
      return StripeResult.fail('Could not add seat. Please try again.');
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static Map<String, dynamic>? _tryDecode(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
