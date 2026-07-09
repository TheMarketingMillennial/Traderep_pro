// analytics_service.dart — TradeRep Pro
// Internal Firestore analytics storage.
// Writes activity events, monthly snapshots, GBP baselines, and health scores
// under each company's subcollections.  All reads are restricted to platform
// admins via Firestore security rules.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// ─── Platform Admin Gate ─────────────────────────────────────────────────────
// The Marketing Millennial's Firebase Auth UID.  Update this to the actual UID
// from Firebase Console → Authentication → Users.
// This is also the check used by Firestore Security Rules.
const kPlatformAdminEmail = 'admin@themarketingmillennial.com';

// ─── Activity Event Types ─────────────────────────────────────────────────────
class ActivityEventType {
  static const String login               = 'login';
  static const String jobCreated          = 'job_created';
  static const String photosUploaded      = 'photos_uploaded';
  static const String reviewRequestSent   = 'review_request_sent';
  static const String googlePostPublished = 'google_post_published';
  static const String seatAdded          = 'seat_added';
}

// ─── Models ──────────────────────────────────────────────────────────────────

/// A single timestamped platform activity event stored under
/// companies/{companyId}/analytics/activity_events/{eventId}
class ActivityEvent {
  final String id;
  final String eventType;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const ActivityEvent({
    required this.id,
    required this.eventType,
    required this.timestamp,
    this.metadata = const {},
  });

  Map<String, dynamic> toFirestore() => {
    'event_type': eventType,
    'timestamp':  Timestamp.fromDate(timestamp),
    'metadata':   metadata,
  };

  factory ActivityEvent.fromFirestore(Map<String, dynamic> d, String id) =>
      ActivityEvent(
        id:        id,
        eventType: (d['event_type'] as String?) ?? '',
        timestamp: (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        metadata:  (d['metadata']  as Map<String, dynamic>?) ?? {},
      );
}

/// Monthly aggregated performance snapshot stored under
/// companies/{companyId}/analytics/monthly_snapshots/{monthId}
/// monthId format: 'YYYY-MM'
class MonthlySnapshot {
  final String monthId;           // e.g. '2025-06'
  final int    reviewRequestsSent;
  final int    googlePostsPublished;
  final int    photosUploaded;
  final int    loginCount;
  final int    activeUsers;
  final int    jobsCreated;
  final String subscriptionStatus;
  final int    seatCount;
  final DateTime updatedAt;

  const MonthlySnapshot({
    required this.monthId,
    this.reviewRequestsSent   = 0,
    this.googlePostsPublished = 0,
    this.photosUploaded       = 0,
    this.loginCount           = 0,
    this.activeUsers          = 0,
    this.jobsCreated          = 0,
    this.subscriptionStatus   = '',
    this.seatCount            = 3,
    required this.updatedAt,
  });

  Map<String, dynamic> toFirestore() => {
    'month_id':                monthId,
    'review_requests_sent':    reviewRequestsSent,
    'google_posts_published':  googlePostsPublished,
    'photos_uploaded':         photosUploaded,
    'login_count':             loginCount,
    'active_users':            activeUsers,
    'jobs_created':            jobsCreated,
    'subscription_status':     subscriptionStatus,
    'seat_count':              seatCount,
    'updated_at':              FieldValue.serverTimestamp(),
  };

  factory MonthlySnapshot.fromFirestore(Map<String, dynamic> d) =>
      MonthlySnapshot(
        monthId:                (d['month_id']               as String?)  ?? '',
        reviewRequestsSent:    (d['review_requests_sent']   as num?)?.toInt() ?? 0,
        googlePostsPublished:  (d['google_posts_published'] as num?)?.toInt() ?? 0,
        photosUploaded:        (d['photos_uploaded']        as num?)?.toInt() ?? 0,
        loginCount:            (d['login_count']            as num?)?.toInt() ?? 0,
        activeUsers:           (d['active_users']           as num?)?.toInt() ?? 0,
        jobsCreated:           (d['jobs_created']           as num?)?.toInt() ?? 0,
        subscriptionStatus:    (d['subscription_status']    as String?)  ?? '',
        seatCount:             (d['seat_count']             as num?)?.toInt() ?? 3,
        updatedAt:             (d['updated_at']             as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}

/// GBP (Google Business Profile) performance baseline snapshot stored under
/// companies/{companyId}/analytics/gbp_baseline/{snapshotId}
class GbpBaseline {
  final String snapshotId;
  final DateTime capturedAt;
  final int    reviewCount;
  final double averageRating;
  final int    phoneCallClicks;
  final int    websiteClicks;
  final int    directionRequests;
  final int    searchViews;
  final int    mapsViews;

  const GbpBaseline({
    required this.snapshotId,
    required this.capturedAt,
    this.reviewCount       = 0,
    this.averageRating     = 0.0,
    this.phoneCallClicks   = 0,
    this.websiteClicks     = 0,
    this.directionRequests = 0,
    this.searchViews       = 0,
    this.mapsViews         = 0,
  });

  Map<String, dynamic> toFirestore() => {
    'snapshot_id':       snapshotId,
    'captured_at':       Timestamp.fromDate(capturedAt),
    'review_count':      reviewCount,
    'average_rating':    averageRating,
    'phone_call_clicks': phoneCallClicks,
    'website_clicks':    websiteClicks,
    'direction_requests':directionRequests,
    'search_views':      searchViews,
    'maps_views':        mapsViews,
  };

  factory GbpBaseline.fromFirestore(Map<String, dynamic> d) => GbpBaseline(
    snapshotId:       (d['snapshot_id']        as String?)  ?? '',
    capturedAt:       (d['captured_at']        as Timestamp?)?.toDate() ?? DateTime.now(),
    reviewCount:     (d['review_count']        as num?)?.toInt()    ?? 0,
    averageRating:   (d['average_rating']      as num?)?.toDouble() ?? 0.0,
    phoneCallClicks: (d['phone_call_clicks']   as num?)?.toInt()    ?? 0,
    websiteClicks:   (d['website_clicks']      as num?)?.toInt()    ?? 0,
    directionRequests:(d['direction_requests'] as num?)?.toInt()    ?? 0,
    searchViews:     (d['search_views']        as num?)?.toInt()    ?? 0,
    mapsViews:       (d['maps_views']          as num?)?.toInt()    ?? 0,
  );
}

/// Company health score stored at
/// companies/{companyId}/analytics/health_score/current
class CompanyHealthScore {
  final int    score;           // 0–100
  final String grade;           // A / B / C / D / F
  final Map<String, int> breakdown; // component scores
  final DateTime computedAt;

  const CompanyHealthScore({
    required this.score,
    required this.grade,
    required this.breakdown,
    required this.computedAt,
  });

  Map<String, dynamic> toFirestore() => {
    'score':       score,
    'grade':       grade,
    'breakdown':   breakdown,
    'computed_at': Timestamp.fromDate(computedAt),
  };

  factory CompanyHealthScore.fromFirestore(Map<String, dynamic> d) => CompanyHealthScore(
    score:       (d['score'] as num?)?.toInt() ?? 0,
    grade:       (d['grade'] as String?) ?? 'F',
    breakdown:   (d['breakdown'] as Map<String, dynamic>?)
                   ?.map((k, v) => MapEntry(k, (v as num).toInt())) ?? {},
    computedAt:  (d['computed_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );
}

/// Aggregated company overview used by the platform admin dashboard.
class CompanyOverview {
  final String companyId;
  final String companyName;
  final String tradeCategory;
  final String serviceArea;
  final String subscriptionStatus;
  final int    seatCount;
  final int    totalLogins;
  final int    totalReviewRequests;
  final int    totalGooglePosts;
  final int    totalPhotos;
  final int    totalJobs;
  final int    healthScore;
  final DateTime? lastActivity;

  const CompanyOverview({
    required this.companyId,
    required this.companyName,
    required this.tradeCategory,
    required this.serviceArea,
    required this.subscriptionStatus,
    required this.seatCount,
    required this.totalLogins,
    required this.totalReviewRequests,
    required this.totalGooglePosts,
    required this.totalPhotos,
    required this.totalJobs,
    required this.healthScore,
    this.lastActivity,
  });

  /// Convert to CSV row (matches csvHeaders order).
  List<String> toCsvRow() => [
    companyId,
    companyName,
    tradeCategory,
    serviceArea,
    subscriptionStatus,
    seatCount.toString(),
    totalLogins.toString(),
    totalReviewRequests.toString(),
    totalGooglePosts.toString(),
    totalPhotos.toString(),
    totalJobs.toString(),
    healthScore.toString(),
    lastActivity?.toIso8601String() ?? '',
  ];

  static List<String> get csvHeaders => [
    'Company ID',
    'Company Name',
    'Trade Category',
    'Service Area',
    'Subscription Status',
    'Seat Count',
    'Total Logins',
    'Review Requests Sent',
    'Google Posts Published',
    'Photos Uploaded',
    'Jobs Created',
    'Health Score',
    'Last Activity',
  ];
}

// ─── Analytics Service ────────────────────────────────────────────────────────

class AnalyticsService {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  // ── Path helpers ──────────────────────────────────────────────────────────

  static CollectionReference<Map<String, dynamic>> _activityEvents(String companyId) =>
      _db.collection('companies').doc(companyId)
         .collection('analytics').doc('activity_events')
         .collection('events');

  static DocumentReference<Map<String, dynamic>> _monthlySnapshot(
      String companyId, String monthId) =>
      _db.collection('companies').doc(companyId)
         .collection('analytics').doc('monthly_snapshots')
         .collection('months').doc(monthId);

  static CollectionReference<Map<String, dynamic>> _gbpBaselines(String companyId) =>
      _db.collection('companies').doc(companyId)
         .collection('analytics').doc('gbp_baseline')
         .collection('snapshots');

  static DocumentReference<Map<String, dynamic>> _healthScore(String companyId) =>
      _db.collection('companies').doc(companyId)
         .collection('analytics').doc('health_score')
         .collection('scores').doc('current');

  // ── Month ID helper ───────────────────────────────────────────────────────

  static String monthId([DateTime? dt]) {
    final d = dt ?? DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}';
  }

  // ── Event Recording ───────────────────────────────────────────────────────

  /// Records a single activity event under the company's analytics subcollection.
  /// Fire-and-forget — never throws; errors are logged in debug mode only.
  static Future<void> recordEvent({
    required String companyId,
    required String eventType,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      final eventId = '${eventType}_${DateTime.now().millisecondsSinceEpoch}';
      final event = ActivityEvent(
        id: eventId, eventType: eventType,
        timestamp: DateTime.now(), metadata: metadata,
      );
      await _activityEvents(companyId).doc(eventId).set(event.toFirestore());
      // Increment the monthly counter for this event type
      await _incrementMonthlyCounter(companyId, eventType);
      if (kDebugMode) debugPrint('[Analytics] Recorded: $eventType for $companyId');
    } catch (e) {
      if (kDebugMode) debugPrint('[Analytics] recordEvent error ($eventType): $e');
    }
  }

  /// Atomically increments the relevant monthly snapshot field.
  static Future<void> _incrementMonthlyCounter(
      String companyId, String eventType) async {
    final field = _counterField(eventType);
    if (field == null) return;
    try {
      final ref = _monthlySnapshot(companyId, monthId());
      await ref.set(
        {field: FieldValue.increment(1), 'month_id': monthId(),
         'updated_at': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[Analytics] _incrementMonthlyCounter error: $e');
    }
  }

  static String? _counterField(String eventType) {
    switch (eventType) {
      case ActivityEventType.login:               return 'login_count';
      case ActivityEventType.jobCreated:          return 'jobs_created';
      case ActivityEventType.photosUploaded:      return 'photos_uploaded';
      case ActivityEventType.reviewRequestSent:   return 'review_requests_sent';
      case ActivityEventType.googlePostPublished: return 'google_posts_published';
      default: return null;
    }
  }

  // ── Monthly Snapshot ──────────────────────────────────────────────────────

  /// Writes (merges) a full monthly snapshot with subscription info + seat count.
  /// Called on first login of each month or when subscription changes.
  static Future<void> writeMonthlySnapshot({
    required String companyId,
    required String subscriptionStatus,
    required int    seatCount,
  }) async {
    try {
      final mid = monthId();
      final ref = _monthlySnapshot(companyId, mid);
      await ref.set({
        'month_id':            mid,
        'subscription_status': subscriptionStatus,
        'seat_count':          seatCount,
        'updated_at':          FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (kDebugMode) debugPrint('[Analytics] Monthly snapshot updated: $mid for $companyId');
    } catch (e) {
      if (kDebugMode) debugPrint('[Analytics] writeMonthlySnapshot error: $e');
    }
  }

  // ── GBP Baseline ─────────────────────────────────────────────────────────

  /// Writes a GBP performance baseline snapshot.
  static Future<void> writeGbpBaseline({
    required String companyId,
    required GbpBaseline baseline,
  }) async {
    try {
      final snapId = 'gbp_${DateTime.now().millisecondsSinceEpoch}';
      await _gbpBaselines(companyId).doc(snapId).set(baseline.toFirestore());
      if (kDebugMode) debugPrint('[Analytics] GBP baseline written: $snapId');
    } catch (e) {
      if (kDebugMode) debugPrint('[Analytics] writeGbpBaseline error: $e');
    }
  }

  // ── Health Score ──────────────────────────────────────────────────────────

  /// Computes and persists a company health score (0–100).
  /// Score components:
  ///   • Has published ≥1 GBP post this month     → 25 pts
  ///   • Sent ≥1 review request this month         → 25 pts
  ///   • Uploaded ≥1 photo this month              → 20 pts
  ///   • Active subscription                       → 20 pts
  ///   • Has ≥2 team members                       → 10 pts
  static Future<void> computeAndSaveHealthScore({
    required String companyId,
    required int    gbpPostsThisMonth,
    required int    reviewRequestsThisMonth,
    required int    photosThisMonth,
    required String subscriptionStatus,
    required int    teamSize,
  }) async {
    try {
      int score = 0;
      final breakdown = <String, int>{};

      final gbpPts = gbpPostsThisMonth >= 1 ? 25 : (gbpPostsThisMonth > 0 ? 12 : 0);
      breakdown['gbp_posts'] = gbpPts;
      score += gbpPts;

      final reviewPts = reviewRequestsThisMonth >= 1 ? 25 : 0;
      breakdown['review_requests'] = reviewPts;
      score += reviewPts;

      final photoPts = photosThisMonth >= 1 ? 20 : 0;
      breakdown['photos'] = photoPts;
      score += photoPts;

      final subPts = (subscriptionStatus == 'active' || subscriptionStatus == 'trialing'
          || subscriptionStatus == 'trial') ? 20 : 0;
      breakdown['subscription'] = subPts;
      score += subPts;

      final teamPts = teamSize >= 2 ? 10 : 0;
      breakdown['team'] = teamPts;
      score += teamPts;

      final grade = score >= 90 ? 'A'
          : score >= 75 ? 'B'
          : score >= 60 ? 'C'
          : score >= 40 ? 'D'
          : 'F';

      final healthScore = CompanyHealthScore(
        score: score, grade: grade,
        breakdown: breakdown, computedAt: DateTime.now(),
      );

      await _healthScore(companyId).set(healthScore.toFirestore(), SetOptions(merge: true));
      if (kDebugMode) debugPrint('[Analytics] Health score: $score ($grade) for $companyId');
    } catch (e) {
      if (kDebugMode) debugPrint('[Analytics] computeAndSaveHealthScore error: $e');
    }
  }

  // ── Admin: Get All Companies Overview ────────────────────────────────────

  /// Platform-admin-only: fetches all company docs and aggregates their
  /// latest monthly snapshot + health score into [CompanyOverview] objects.
  static Future<List<CompanyOverview>> getCompaniesOverview() async {
    try {
      // 1. Fetch all company docs
      final companiesSnap = await _db.collection('companies').get();

      final overviews = <CompanyOverview>[];

      for (final companyDoc in companiesSnap.docs) {
        final cData = companyDoc.data();
        final cId   = companyDoc.id;

        // 2. Read subscription from nested map
        final subMap = cData['subscription'] as Map<String, dynamic>?;
        final subStatus = (subMap?['subscription_status'] as String?) ??
            (cData['subscription_status'] as String?) ?? 'unknown';
        final seatCount = (subMap?['purchased_seats'] as num?)?.toInt() ?? 3;

        // 3. Get latest monthly snapshot
        MonthlySnapshot? latestSnapshot;
        try {
          final snapDocs = await _db.collection('companies').doc(cId)
              .collection('analytics').doc('monthly_snapshots')
              .collection('months')
              .orderBy('month_id', descending: true)
              .limit(1)
              .get();
          if (snapDocs.docs.isNotEmpty) {
            latestSnapshot = MonthlySnapshot.fromFirestore(snapDocs.docs.first.data());
          }
        } catch (_) { /* No analytics yet — skip */ }

        // 4. Get health score
        int healthScore = 0;
        try {
          final hDoc = await _db.collection('companies').doc(cId)
              .collection('analytics').doc('health_score')
              .collection('scores').doc('current').get();
          if (hDoc.exists) {
            healthScore = (hDoc.data()?['score'] as num?)?.toInt() ?? 0;
          }
        } catch (_) {}

        // 5. Get last activity event timestamp
        DateTime? lastActivity;
        try {
          final evtDocs = await _db.collection('companies').doc(cId)
              .collection('analytics').doc('activity_events')
              .collection('events')
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get();
          if (evtDocs.docs.isNotEmpty) {
            lastActivity = (evtDocs.docs.first.data()['timestamp'] as Timestamp?)?.toDate();
          }
        } catch (_) {}

        overviews.add(CompanyOverview(
          companyId:          cId,
          companyName:        (cData['name'] as String?) ?? 'Unknown',
          tradeCategory:      (cData['trade_category'] as String?) ?? 'Unknown',
          serviceArea:        (cData['service_area'] as String?) ?? '',
          subscriptionStatus: subStatus,
          seatCount:          seatCount,
          totalLogins:        latestSnapshot?.loginCount ?? 0,
          totalReviewRequests:latestSnapshot?.reviewRequestsSent ?? 0,
          totalGooglePosts:   latestSnapshot?.googlePostsPublished ?? 0,
          totalPhotos:        latestSnapshot?.photosUploaded ?? 0,
          totalJobs:          latestSnapshot?.jobsCreated ?? 0,
          healthScore:        healthScore,
          lastActivity:       lastActivity,
        ));
      }

      // Sort: highest health score first
      overviews.sort((a, b) => b.healthScore.compareTo(a.healthScore));
      return overviews;
    } catch (e) {
      if (kDebugMode) debugPrint('[Analytics] getCompaniesOverview error: $e');
      return [];
    }
  }

  // ── CSV Export ────────────────────────────────────────────────────────────

  /// Converts a list of [CompanyOverview] to a CSV string.
  static String exportToCsv(List<CompanyOverview> overviews) {
    final buf = StringBuffer();
    // Header row
    buf.writeln(CompanyOverview.csvHeaders.join(','));
    // Data rows
    for (final o in overviews) {
      buf.writeln(o.toCsvRow().map(_csvEscape).join(','));
    }
    return buf.toString();
  }

  static String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
