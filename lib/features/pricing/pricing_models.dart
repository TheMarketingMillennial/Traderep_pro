import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// ─── Plan Tier Enum ───────────────────────────────────────────────────────────
enum PlanTier { starter, growth, pro }

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
}

// ─── Plan Model ───────────────────────────────────────────────────────────────
class PricingPlan {
  final PlanTier tier;
  final String name;
  final int monthlyPrice;
  final String tagline;
  final String bestFor;
  final List<PlanFeature> features;
  final bool isMostPopular;
  final Color accentColor;
  final String stripePriceId; // live Stripe price ID
  final int maxUsers;
  final int maxLocations;

  const PricingPlan({
    required this.tier,
    required this.name,
    required this.monthlyPrice,
    required this.tagline,
    required this.bestFor,
    required this.features,
    required this.isMostPopular,
    required this.accentColor,
    required this.stripePriceId,
    required this.maxUsers,
    required this.maxLocations,
  });

  static List<PricingPlan> get all => [starter, growth, pro];

  // ─── STARTER ─────────────────────────────────────────────────────────────
  static const PricingPlan starter = PricingPlan(
    tier: PlanTier.starter,
    name: 'Starter',
    monthlyPrice: 99,
    tagline: 'Everything you need to start building your reputation.',
    bestFor: 'Solo contractors & small crews',
    isMostPopular: false,
    accentColor: TRColors.info,
    stripePriceId: 'price_1TcTIkCnWFtpnJDSLagxlQCu',
    maxUsers: 3,
    maxLocations: 1,
    features: [
      PlanFeature(label: '1 company account', included: true),
      PlanFeature(label: 'Up to 3 users', included: true),
      PlanFeature(label: 'Unlimited job creation', included: true),
      PlanFeature(label: 'Before & after photo uploads', included: true),
      PlanFeature(label: 'Google review requests', included: true),
      PlanFeature(label: 'Basic Google Business posting', included: true),
      PlanFeature(label: 'Basic analytics dashboard', included: true),
      PlanFeature(label: 'AI photo selection', included: false, lockedLabel: 'Growth+'),
      PlanFeature(label: 'Content approval dashboard', included: false, lockedLabel: 'Growth+'),
      PlanFeature(label: 'Review automation', included: false, lockedLabel: 'Growth+'),
      PlanFeature(label: 'Multi-location support', included: false, lockedLabel: 'Pro only'),
      PlanFeature(label: 'Reputation scoring', included: false, lockedLabel: 'Pro only'),
    ],
  );

  // ─── GROWTH ──────────────────────────────────────────────────────────────
  static const PricingPlan growth = PricingPlan(
    tier: PlanTier.growth,
    name: 'Growth',
    monthlyPrice: 179,
    tagline: 'Turn every completed job into online credibility — automatically.',
    bestFor: 'Growing contractor teams',
    isMostPopular: true,
    accentColor: TRColors.gold,
    stripePriceId: 'price_1TcTJXCnWFtpnJDSXlZpYOs9',
    maxUsers: 15,
    maxLocations: 1,
    features: [
      PlanFeature(label: 'Unlimited jobs', included: true),
      PlanFeature(label: 'Up to 15 team members', included: true),
      PlanFeature(label: 'AI photo selection & scoring', included: true),
      PlanFeature(label: 'Content approval dashboard', included: true),
      PlanFeature(label: 'Google Business Profile integration', included: true),
      PlanFeature(label: 'Enhanced analytics', included: true),
      PlanFeature(label: 'Review automation (SMS + Email)', included: true),
      PlanFeature(label: 'Social-ready image generation', included: true),
      PlanFeature(label: 'Everything in Starter', included: true),
      PlanFeature(label: 'Multi-location support', included: false, lockedLabel: 'Pro only'),
      PlanFeature(label: 'Reputation scoring', included: false, lockedLabel: 'Pro only'),
      PlanFeature(label: 'AI-generated recommendations', included: false, lockedLabel: 'Pro only'),
    ],
  );

  // ─── PRO ─────────────────────────────────────────────────────────────────
  static const PricingPlan pro = PricingPlan(
    tier: PlanTier.pro,
    name: 'Pro',
    monthlyPrice: 349,
    tagline: 'Full reputation operating system for serious trade brands.',
    bestFor: 'Larger contractors & multi-location companies',
    isMostPopular: false,
    accentColor: TRColors.statusLead,
    stripePriceId: 'price_1TcTKICnWFtpnJDSmXw4CrWZ',
    maxUsers: 999,
    maxLocations: 999,
    features: [
      PlanFeature(label: 'Unlimited users & locations', included: true),
      PlanFeature(label: 'Multiple business locations', included: true),
      PlanFeature(label: 'Advanced analytics suite', included: true),
      PlanFeature(label: 'Crew performance tracking', included: true),
      PlanFeature(label: 'Reputation scoring dashboard', included: true),
      PlanFeature(label: 'AI-generated recommendations', included: true),
      PlanFeature(label: 'Priority support (24h response)', included: true),
      PlanFeature(label: 'Future scalability modules', included: true),
      PlanFeature(label: 'Everything in Growth', included: true),
      PlanFeature(label: 'Dedicated onboarding call', included: true),
      PlanFeature(label: 'Custom photo templates', included: true),
      PlanFeature(label: 'API access (coming soon)', included: true),
    ],
  );
}

// ─── Feature Line ─────────────────────────────────────────────────────────────
class PlanFeature {
  final String label;
  final bool included;
  final String? lockedLabel; // e.g. "Growth+" or "Pro only"

  const PlanFeature({
    required this.label,
    required this.included,
    this.lockedLabel,
  });
}

// ─── Active Subscription Model ────────────────────────────────────────────────
class ActiveSubscription {
  final PlanTier tier;
  final SubscriptionStatus status;
  final DateTime trialStartDate;
  final DateTime trialEndDate;
  final DateTime? billingStartDate;
  final DateTime? nextBillingDate;
  final String? stripeCustomerId;
  final String? stripeSubscriptionId;
  final List<BillingRecord> billingHistory;

  ActiveSubscription({
    required this.tier,
    required this.status,
    required this.trialStartDate,
    required this.trialEndDate,
    this.billingStartDate,
    this.nextBillingDate,
    this.stripeCustomerId,
    this.stripeSubscriptionId,
    this.billingHistory = const [],
  });

  int get trialDaysRemaining {
    final now = DateTime.now();
    if (now.isAfter(trialEndDate)) return 0;
    return trialEndDate.difference(now).inDays + 1;
  }

  bool get isInTrial => status == SubscriptionStatus.trial && trialDaysRemaining > 0;

  double get trialProgress {
    const trialDays = 14;
    final elapsed = DateTime.now().difference(trialStartDate).inDays;
    return (elapsed / trialDays).clamp(0.0, 1.0);
  }

  PricingPlan get plan {
    switch (tier) {
      case PlanTier.starter: return PricingPlan.starter;
      case PlanTier.growth:  return PricingPlan.growth;
      case PlanTier.pro:     return PricingPlan.pro;
    }
  }

  /// Demo subscription — Growth plan, 8 days into trial
  static ActiveSubscription get demo => ActiveSubscription(
    tier: PlanTier.growth,
    status: SubscriptionStatus.trial,
    trialStartDate: DateTime.now().subtract(const Duration(days: 6)),
    trialEndDate: DateTime.now().add(const Duration(days: 8)),
    billingHistory: [
      BillingRecord(
        date: DateTime.now().subtract(const Duration(days: 30)),
        amount: 179.00,
        description: 'Growth Plan — Monthly',
        status: 'paid',
      ),
    ],
  );

  static ActiveSubscription get none => ActiveSubscription(
    tier: PlanTier.starter,
    status: SubscriptionStatus.none,
    trialStartDate: DateTime.now(),
    trialEndDate: DateTime.now().add(const Duration(days: 14)),
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

// ─── Feature Access Rules ─────────────────────────────────────────────────────
class FeatureAccess {
  static bool canAccess(PlanTier tier, String featureKey) {
    switch (featureKey) {
      // Starter+
      case 'jobs':
      case 'photos':
      case 'reviews_basic':
      case 'google_posting_basic':
      case 'analytics_basic':
        return true;

      // Growth+
      case 'ai_photo_selection':
      case 'content_approval':
      case 'review_automation':
      case 'social_images':
      case 'analytics_enhanced':
      case 'google_integration_full':
        return tier == PlanTier.growth || tier == PlanTier.pro;

      // Pro only
      case 'multi_location':
      case 'reputation_scoring':
      case 'ai_recommendations':
      case 'crew_performance':
      case 'advanced_analytics':
      case 'priority_support':
        return tier == PlanTier.pro;

      default:
        return true;
    }
  }

  static String requiredPlan(String featureKey) {
    switch (featureKey) {
      case 'ai_photo_selection':
      case 'content_approval':
      case 'review_automation':
      case 'analytics_enhanced':
        return 'Growth';
      case 'multi_location':
      case 'reputation_scoring':
      case 'ai_recommendations':
      case 'advanced_analytics':
        return 'Pro';
      default:
        return 'Growth';
    }
  }
}
