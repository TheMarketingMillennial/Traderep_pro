// pricing_models.dart — TradeRep Pro
// Single plan: $75/month (3 seats included) + $14.99/month per additional seat.

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// ─── Subscription Status ──────────────────────────────────────────────────────
enum SubscriptionStatus {
  trial,
  active,
  pastDue,
  cancelled,
  none;

  String get displayName {
    switch (this) {
      case SubscriptionStatus.trial:     return 'Free Trial';
      case SubscriptionStatus.active:    return 'Active';
      case SubscriptionStatus.pastDue:   return 'Past Due';
      case SubscriptionStatus.cancelled: return 'Cancelled';
      case SubscriptionStatus.none:      return 'No Subscription';
    }
  }

  Color get color {
    switch (this) {
      case SubscriptionStatus.trial:     return TRColors.gold;
      case SubscriptionStatus.active:    return TRColors.success;
      case SubscriptionStatus.pastDue:   return TRColors.error;
      case SubscriptionStatus.cancelled: return TRColors.grayMid;
      case SubscriptionStatus.none:      return TRColors.grayMid;
    }
  }
}

// ─── Single Plan Definition ───────────────────────────────────────────────────
class TRPlan {
  static const String name           = 'TradeRep Pro';
  static const double monthlyPrice   = 75.00;       // base price
  static const int    includedSeats  = 3;            // seats in base price
  static const double extraSeatPrice = 14.99;        // per additional seat/month
  static const String stripePriceId  = 'price_1TcTIkCnWFtpnJDSLagxlQCu'; // update with real ID

  static const List<String> features = [
    'Up to 3 team members included',
    'Unlimited customers',
    'Unlimited projects',
    'Unlimited photos',
    'Unlimited review requests',
    'Google Business Profile integration',
    'Team management',
    'Admin dashboard',
    'Company dashboard',
    'Additional team members at \$14.99/month each',
  ];

  /// Calculate total monthly cost given purchased extra seats
  static double totalMonthly(int extraSeats) =>
      monthlyPrice + (extraSeats.clamp(0, 999) * extraSeatPrice);

  static String formatPrice(double price) =>
      '\$${price.toStringAsFixed(price == price.roundToDouble() ? 0 : 2)}';
}

// ─── Active Subscription Model ────────────────────────────────────────────────
class ActiveSubscription {
  final SubscriptionStatus status;
  final DateTime trialStartDate;
  final DateTime trialEndDate;
  final DateTime? billingStartDate;
  final DateTime? nextBillingDate;
  final String? stripeCustomerId;
  final String? stripeSubscriptionId;
  final int purchasedSeats;          // total seats purchased (base 3 + extras)
  final int extraSeats;              // seats beyond the 3 included
  final List<BillingRecord> billingHistory;

  const ActiveSubscription({
    required this.status,
    required this.trialStartDate,
    required this.trialEndDate,
    this.billingStartDate,
    this.nextBillingDate,
    this.stripeCustomerId,
    this.stripeSubscriptionId,
    this.purchasedSeats = TRPlan.includedSeats,
    this.extraSeats = 0,
    this.billingHistory = const [],
  });

  int get trialDaysRemaining {
    final now = DateTime.now();
    if (now.isAfter(trialEndDate)) return 0;
    return trialEndDate.difference(now).inDays + 1;
  }

  bool get isInTrial  => status == SubscriptionStatus.trial && trialDaysRemaining > 0;
  bool get isActive   => status == SubscriptionStatus.active;
  bool get canUseApp  => isInTrial || isActive;

  double get trialProgress {
    const trialDays = 14;
    final elapsed = DateTime.now().difference(trialStartDate).inDays;
    return (elapsed / trialDays).clamp(0.0, 1.0);
  }

  double get currentMonthlyTotal => TRPlan.totalMonthly(extraSeats);

  ActiveSubscription copyWith({
    SubscriptionStatus? status,
    int? purchasedSeats,
    int? extraSeats,
    String? stripeCustomerId,
    String? stripeSubscriptionId,
    DateTime? billingStartDate,
    DateTime? nextBillingDate,
  }) => ActiveSubscription(
    status:               status               ?? this.status,
    trialStartDate:       trialStartDate,
    trialEndDate:         trialEndDate,
    billingStartDate:     billingStartDate     ?? this.billingStartDate,
    nextBillingDate:      nextBillingDate      ?? this.nextBillingDate,
    stripeCustomerId:     stripeCustomerId     ?? this.stripeCustomerId,
    stripeSubscriptionId: stripeSubscriptionId ?? this.stripeSubscriptionId,
    purchasedSeats:       purchasedSeats       ?? this.purchasedSeats,
    extraSeats:           extraSeats           ?? this.extraSeats,
    billingHistory:       billingHistory,
  );

  static ActiveSubscription get demo => ActiveSubscription(
    status:         SubscriptionStatus.active,
    trialStartDate: DateTime.now().subtract(const Duration(days: 20)),
    trialEndDate:   DateTime.now().subtract(const Duration(days: 6)),
    billingStartDate: DateTime.now().subtract(const Duration(days: 6)),
    nextBillingDate:  DateTime.now().add(const Duration(days: 24)),
    purchasedSeats: 3,
    extraSeats: 0,
    billingHistory: [
      BillingRecord(
        date: DateTime.now().subtract(const Duration(days: 6)),
        amount: 75.00,
        description: 'TradeRep Pro — Monthly',
        status: 'paid',
      ),
    ],
  );

  static ActiveSubscription get trial => ActiveSubscription(
    status:         SubscriptionStatus.trial,
    trialStartDate: DateTime.now(),
    trialEndDate:   DateTime.now().add(const Duration(days: 14)),
    purchasedSeats: TRPlan.includedSeats,
    extraSeats: 0,
  );

  static ActiveSubscription get none => ActiveSubscription(
    status:         SubscriptionStatus.none,
    trialStartDate: DateTime.now(),
    trialEndDate:   DateTime.now().add(const Duration(days: 14)),
  );
}

// ─── Billing Record ───────────────────────────────────────────────────────────
class BillingRecord {
  final DateTime date;
  final double amount;
  final String description;
  final String status; // 'paid', 'failed', 'refunded'

  const BillingRecord({
    required this.date,
    required this.amount,
    required this.description,
    required this.status,
  });
}

// ─── Seat Purchase Request ────────────────────────────────────────────────────
// Used when inviting a user beyond included seat count.
class SeatPurchaseRequest {
  final int currentSeats;
  final int requestedSeats;
  final double additionalMonthlyCost;

  const SeatPurchaseRequest({
    required this.currentSeats,
    required this.requestedSeats,
    required this.additionalMonthlyCost,
  });

  int get extraSeatsNeeded => requestedSeats - currentSeats;

  String get confirmationMessage =>
      'Add $extraSeatsNeeded team member seat${extraSeatsNeeded == 1 ? '' : 's'} '
      'for \$${additionalMonthlyCost.toStringAsFixed(2)}/month?';
}
