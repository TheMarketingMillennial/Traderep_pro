// firestore_service.dart — TradeRep Pro
// Live Firestore data layer. All reads are real-time streams.
// Write operations update Firestore and notify listeners via AppState.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import '../models/models.dart';
import '../../features/pricing/pricing_models.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  // Lazy getter — only accesses FirebaseFirestore.instance when Firebase is
  // actually initialized. Prevents crash on web when no --dart-define secrets
  // are provided (preview / demo mode).
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // ─── Company ID (set after login) ─────────────────────────────────────────
  String _companyId = 'company_001';
  String get companyId => _companyId;
  void setCompanyId(String id) => _companyId = id;

  // ══════════════════════════════════════════════════════════════════════════
  // COMPANY
  // ══════════════════════════════════════════════════════════════════════════

  Stream<Company?> companyStream() {
    return _db
        .collection('companies')
        .doc(_companyId)
        .snapshots()
        .map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return _companyFromDoc(snap.data()!, snap.id);
    }).handleError((e) {
      if (kDebugMode) debugPrint('FirestoreService companyStream error: $e');
      return null;
    });
  }

  Future<Company?> getCompany() async {
    try {
      final doc = await _db.collection('companies').doc(_companyId).get();
      if (!doc.exists || doc.data() == null) return null;
      return _companyFromDoc(doc.data()!, doc.id);
    } catch (e) {
      if (kDebugMode) debugPrint('FirestoreService getCompany error: $e');
      return null;
    }
  }

  Future<void> updateCompanyFields({
    required String name,
    required String phone,
    required String serviceArea,
    String? website,
  }) async {
    await _db.collection('companies').doc(_companyId).update({
      'name': name,
      'phone': phone,
      'service_area': serviceArea,
      'website': website,
    });
  }

  Future<void> updateGoogleConnected(bool connected) async {
    await _db.collection('companies').doc(_companyId).update({
      'google_connected': connected,
    });
  }

  /// Persists the GBP location resource name for programmatic posting.
  /// Pass null to clear (revert to manual Phase 1 flow).
  Future<void> updateGbpLocationId(String? locationId) async {
    await _db.collection('companies').doc(_companyId).update({
      'gbp_location_id': locationId,
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // USERS / TEAM
  // ══════════════════════════════════════════════════════════════════════════

  Stream<List<TRUser>> teamStream() {
    return _db
        .collection('users')
        .where('company_id', isEqualTo: _companyId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => _userFromDoc(d.data(), d.id))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name)))
        .handleError((e) {
      if (kDebugMode) debugPrint('FirestoreService teamStream error: $e');
      return <TRUser>[];
    });
  }

  Future<TRUser?> getCurrentUser() async {
    try {
      // Use _companyId as the user UID (set to Firebase Auth UID after sign-in)
      // Falls back gracefully when the doc doesn't exist yet (new account).
      final doc = await _db.collection('users').doc(_companyId).get();
      if (!doc.exists || doc.data() == null) return null;
      return _userFromDoc(doc.data()!, doc.id);
    } catch (e) {
      if (kDebugMode) debugPrint('FirestoreService getCurrentUser error: $e');
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // JOBS
  // ══════════════════════════════════════════════════════════════════════════

  Stream<List<Job>> jobsStream() {
    return _db
        .collection('jobs')
        .where('company_id', isEqualTo: _companyId)
        .snapshots()
        .map((snap) {
      final jobs = snap.docs.map((d) => _jobFromDoc(d.data(), d.id)).toList();
      jobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return jobs;
    }).handleError((e) {
      if (kDebugMode) debugPrint('FirestoreService jobsStream error: $e');
      return <Job>[];
    });
  }

  Future<void> addJob(Job job) async {
    await _db.collection('jobs').doc(job.id).set(_jobToDoc(job));
  }

  Future<void> updateJobFields(Job job) async {
    await _db.collection('jobs').doc(job.id).update({
      'customer_name': job.customerName,
      'address': job.address,
      'phone': job.phone,
      'email': job.email,
      'job_type': job.jobType,
      'notes': job.notes,
      'start_date': job.startDate != null
          ? Timestamp.fromDate(job.startDate!)
          : null,
    });
  }

  Future<void> updateJobStatus(String jobId, JobStatus status) async {
    final updates = <String, dynamic>{
      'status': status.name,
    };
    if (status == JobStatus.completed) {
      updates['completion_date'] = FieldValue.serverTimestamp();
    }
    await _db.collection('jobs').doc(jobId).update(updates);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CONTENT POSTS
  // ══════════════════════════════════════════════════════════════════════════

  Stream<List<ContentPost>> postsStream() {
    return _db
        .collection('content_posts')
        .where('company_id', isEqualTo: _companyId)
        .snapshots()
        .map((snap) {
      final posts =
          snap.docs.map((d) => _postFromDoc(d.data(), d.id)).toList();
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return posts;
    }).handleError((e) {
      if (kDebugMode) debugPrint('FirestoreService postsStream error: $e');
      return <ContentPost>[];
    });
  }

  Future<void> updatePostStatus(String postId, ContentStatus status) async {
    final updates = <String, dynamic>{
      'status': status.name,
    };
    if (status == ContentStatus.published) {
      updates['published_at'] = FieldValue.serverTimestamp();
    }
    await _db.collection('content_posts').doc(postId).update(updates);
  }

  Future<String> addPost(ContentPost post) async {
    final data = post.toFirestore();
    // Always stamp company_id from the authenticated service context
    data['company_id'] = _companyId;
    data['created_at'] = FieldValue.serverTimestamp();
    final ref = await _db.collection('content_posts').add(data);
    return ref.id;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // REVIEW REQUESTS
  // ══════════════════════════════════════════════════════════════════════════

  Stream<List<ReviewRequest>> reviewsStream() {
    return _db
        .collection('review_requests')
        .where('company_id', isEqualTo: _companyId)
        .snapshots()
        .map((snap) {
      final reviews =
          snap.docs.map((d) => _reviewFromDoc(d.data(), d.id)).toList();
      reviews.sort((a, b) => b.sentAt.compareTo(a.sentAt));
      return reviews;
    }).handleError((e) {
      if (kDebugMode) debugPrint('FirestoreService reviewsStream error: $e');
      return <ReviewRequest>[];
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PROJECT TEMPLATES
  // ══════════════════════════════════════════════════════════════════════════

  Stream<List<ProjectTemplate>> templatesStream() {
    return _db
        .collection('project_templates')
        .where('company_id', isEqualTo: _companyId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => _templateFromDoc(d.data(), d.id)).toList())
        .handleError((e) {
      if (kDebugMode) debugPrint('FirestoreService templatesStream error: $e');
      return <ProjectTemplate>[];
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ANALYTICS
  // ══════════════════════════════════════════════════════════════════════════

  Future<AnalyticsSummary> getAnalytics() async {
    try {
      final snap = await _db
          .collection('analytics_events')
          .where('company_id', isEqualTo: _companyId)
          .get();

      if (snap.docs.isEmpty) return AnalyticsSummary.empty;

      final docs = snap.docs.map((d) => d.data()).toList();
      // Sort by month_date ascending
      docs.sort((a, b) {
        final aDate = (a['month_date'] as Timestamp?)?.toDate() ?? DateTime.now();
        final bDate = (b['month_date'] as Timestamp?)?.toDate() ?? DateTime.now();
        return aDate.compareTo(bDate);
      });

      // Latest month totals
      final latest = docs.last;
      final totalJobs = docs.fold<int>(0, (s, d) => s + ((d['jobs_completed'] as num?)?.toInt() ?? 0));
      final totalReviews = docs.fold<int>(0, (s, d) => s + ((d['reviews_generated'] as num?)?.toInt() ?? 0));
      final totalPhotos = docs.fold<int>(0, (s, d) => s + ((d['photos_uploaded'] as num?)?.toInt() ?? 0));
      final totalPosts = docs.fold<int>(0, (s, d) => s + ((d['google_posts'] as num?)?.toInt() ?? 0));

      final monthlyData = docs.map((d) => MonthlyData(
            (d['month'] as String?) ?? '',
            (d['jobs_completed'] as num?)?.toInt() ?? 0,
            (d['reviews_generated'] as num?)?.toInt() ?? 0,
          )).toList();

      return AnalyticsSummary(
        projectsCompleted: totalJobs,
        reviewsGenerated: totalReviews,
        photosUploaded: totalPhotos,
        googlePosts: totalPosts,
        reviewResponseRate: (latest['review_response_rate'] as num?)?.toDouble() ?? 0.78,
        avgPhotoScore: (latest['avg_photo_score'] as num?)?.toDouble() ?? 87.4,
        monthlyData: monthlyData,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('FirestoreService getAnalytics error: $e');
      return AnalyticsSummary.empty;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SUBSCRIPTION / SAAS METRICS
  // ══════════════════════════════════════════════════════════════════════════

  /// Reads subscription from companies/{companyId} subscription map (written by
  /// Railway Stripe webhook) OR from the legacy saas_metrics doc as fallback.
  Future<ActiveSubscription> getSubscription() async {
    try {
      Map<String, dynamic>? d;

      // Primary: read nested subscription map from companies doc
      // This is exactly what the Railway Stripe webhook writes.
      final companyDoc = await _db.collection('companies').doc(_companyId).get();
      if (companyDoc.exists && companyDoc.data() != null) {
        final compData = companyDoc.data()!;
        final subMap = compData['subscription'] as Map<String, dynamic>?;
        if (subMap != null) {
          // Normalise Railway field names -> our field names
          d = Map<String, dynamic>.from(subMap);
          d['plan_tier']              ??= d['price_key'];
          d['subscription_status']    ??= d['status'];
          d['trial_start_date']       ??= d['trial_start'];
          d['trial_end_date']         ??= d['trial_end'];
        }
      }

      // Fallback: legacy saas_metrics doc for users who signed up before v2
      if (d == null) {
        final metricsDoc = await _db
            .collection('saas_metrics')
            .doc('metrics_current')
            .get();
        if (metricsDoc.exists && metricsDoc.data() != null) {
          d = metricsDoc.data()!;
        }
      }

      if (d == null) return ActiveSubscription.none;

      final tierStr   = (d['plan_tier']           as String?) ?? 'growth';
      final statusStr = (d['subscription_status'] as String?) ?? 'trial';

      final tier = PlanTier.values.firstWhere(
        (t) => t.name == tierStr,
        orElse: () => PlanTier.growth,
      );
      final status = SubscriptionStatus.values.firstWhere(
        (s) => s.name == statusStr,
        orElse: () => SubscriptionStatus.trial,
      );

      DateTime tsToDate(dynamic v, DateTime fallback) {
        if (v is Timestamp) return v.toDate();
        if (v is String) return DateTime.tryParse(v) ?? fallback;
        return fallback;
      }

      final trialStart = tsToDate(
        d['trial_start_date'],
        DateTime.now().subtract(const Duration(days: 6)),
      );
      final trialEnd = tsToDate(
        d['trial_end_date'],
        DateTime.now().add(const Duration(days: 8)),
      );

      final billingRaw = (d['billing_history'] as List<dynamic>?) ?? [];
      final billingHistory = billingRaw.map((b) {
        final bMap = b as Map<String, dynamic>;
        return BillingRecord(
          date: DateTime.tryParse((bMap['date'] as String?) ?? '') ??
              DateTime.now(),
          amount: (bMap['amount'] as num?)?.toDouble() ?? 0.0,
          description: (bMap['description'] as String?) ?? '',
          status: (bMap['status'] as String?) ?? 'paid',
        );
      }).toList();

      return ActiveSubscription(
        tier: tier,
        status: status,
        trialStartDate: trialStart,
        trialEndDate: trialEnd,
        stripeCustomerId: d['stripe_customer_id'] as String?,
        stripeSubscriptionId: d['stripe_subscription_id'] as String?,
        billingHistory: billingHistory,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('FirestoreService getSubscription error: $e');
      return ActiveSubscription.none;
    }
  }

  /// Persists a newly created Stripe subscription to Firestore so the
  /// webhook and future app launches can read the correct state.
  Future<void> saveSubscription({
    required String tier,          // 'starter' | 'growth' | 'pro'
    required String status,        // 'trial'
    required DateTime trialStartDate,
    required DateTime trialEndDate,
    String? stripeCustomerId,
    String? stripeSubscriptionId,
  }) async {
    try {
      await _db
          .collection('saas_metrics')
          .doc('metrics_current')
          .set({
        'plan_tier': tier,
        'subscription_status': status,
        'trial_start_date': Timestamp.fromDate(trialStartDate),
        'trial_end_date': Timestamp.fromDate(trialEndDate),
        if (stripeCustomerId != null) 'stripe_customer_id': stripeCustomerId,
        if (stripeSubscriptionId != null)
          'stripe_subscription_id': stripeSubscriptionId,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) debugPrint('FirestoreService saveSubscription error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PHOTO SUBMISSIONS
  // ══════════════════════════════════════════════════════════════════════════

  /// Real-time stream of all photo submissions for this company,
  /// sorted newest-first. Approval queue watches this stream.
  Stream<List<PhotoSubmission>> photoSubmissionsStream() {
    return _db
        .collection('photo_submissions')
        .where('company_id', isEqualTo: _companyId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => PhotoSubmission.fromFirestore(d.data(), d.id))
          .toList();
      list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      return list;
    }).handleError((e) {
      if (kDebugMode) debugPrint('FirestoreService photoSubmissionsStream error: $e');
      return <PhotoSubmission>[];
    });
  }

  /// Crew member submits photos for a job.
  /// Uploads each local file to Firebase Storage, then writes the
  /// PhotoSubmission document to Firestore.
  Future<PhotoSubmission> submitPhotos({
    required String jobId,
    required String jobName,
    required String submittedById,
    required String submittedByName,
    required List<SubmittedPhoto> photos,
    String? crewNote,
  }) async {
    final submissionId = 'sub_${DateTime.now().millisecondsSinceEpoch}';

    // Upload each photo to Firebase Storage and collect network URLs
    final uploadedPhotos = <SubmittedPhoto>[];
    for (final photo in photos) {
      if (photo.localPath != null && !kIsWeb) {
        try {
          // Use XFile.readAsBytes() — works on all platforms, no dart:io needed.
          final bytes = await XFile(photo.localPath!).readAsBytes();
          final ref = FirebaseStorage.instance
              .ref('photo_submissions/$_companyId/$jobId/$submissionId/${photo.id}.jpg');
          final task = await ref.putData(Uint8List.fromList(bytes));
          final url = await task.ref.getDownloadURL();
          uploadedPhotos.add(SubmittedPhoto(
            id: photo.id,
            localPath: photo.localPath,
            networkUrl: url,
            type: photo.type,
            label: photo.label,
          ));
        } catch (e) {
          if (kDebugMode) debugPrint('Photo upload error for ${photo.id}: $e');
          // Keep the local path version if upload fails
          uploadedPhotos.add(photo);
        }
      } else {
        uploadedPhotos.add(photo);
      }
    }

    final submission = PhotoSubmission(
      id: submissionId,
      jobId: jobId,
      jobName: jobName,
      companyId: _companyId,
      submittedById: submittedById,
      submittedByName: submittedByName,
      photos: uploadedPhotos,
      crewNote: crewNote,
      status: PhotoSubmissionStatus.pending,
      submittedAt: DateTime.now(),
    );

    await _db
        .collection('photo_submissions')
        .doc(submissionId)
        .set(submission.toFirestore());

    return submission;
  }

  /// Approver updates a submission status (approve or reject) with an optional note.
  Future<void> updateSubmissionStatus({
    required String submissionId,
    required PhotoSubmissionStatus status,
    required String reviewedById,
    required String reviewedByName,
    String? reviewerNote,
  }) async {
    await _db.collection('photo_submissions').doc(submissionId).update({
      'status': status.name,
      'reviewed_by_id': reviewedById,
      'reviewed_by_name': reviewedByName,
      'reviewer_note': reviewerNote,
      'reviewed_at': FieldValue.serverTimestamp(),
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MAPPERS — Firestore doc → Model
  // ══════════════════════════════════════════════════════════════════════════

  Company _companyFromDoc(Map<String, dynamic> d, String id) {
    // Parse teamSize: Firestore stores '11-25', model expects int
    final teamSizeRaw = d['team_size'];
    int teamSizeInt = 5;
    if (teamSizeRaw is int) {
      teamSizeInt = teamSizeRaw;
    } else if (teamSizeRaw is String) {
      // e.g. '11-25' → take first number
      teamSizeInt = int.tryParse(teamSizeRaw.split('-').first) ?? 5;
    }
    return Company(
      id: id,
      name: (d['name'] as String?) ?? 'My Company',
      tradeCategory: (d['trade_category'] as String?) ?? 'General',
      serviceArea: (d['service_area'] as String?) ?? '',
      phone: (d['phone'] as String?) ?? '',
      website: d['website'] as String?,
      logoUrl: d['logo_url'] as String?,
      googleConnected: (d['google_connected'] as bool?) ?? false,
      googleReviewLink: d['google_review_link'] as String?,
      gbpLocationId: d['gbp_location_id'] as String?,
      teamSize: teamSizeInt,
      createdAt: (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  TRUser _userFromDoc(Map<String, dynamic> d, String id) {
    final roleStr = (d['role'] as String?) ?? 'crewMember';
    final role = UserRole.values.firstWhere(
      (r) => r.name == roleStr,
      orElse: () => UserRole.crewMember,
    );
    return TRUser(
      id: id,
      companyId: (d['company_id'] as String?) ?? '',
      name: (d['name'] as String?) ?? 'Team Member',
      email: (d['email'] as String?) ?? '',
      phone: (d['phone'] as String?) ?? '',
      role: role,
      avatarUrl: d['avatar_url'] as String?,
      isActive: (d['is_active'] as bool?) ?? true,
      joinedAt: (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Job _jobFromDoc(Map<String, dynamic> d, String id) {
    final statusStr = (d['status'] as String?) ?? 'lead';
    final status = JobStatus.values.firstWhere(
      (s) => s.name == statusStr,
      orElse: () => JobStatus.lead,
    );
    return Job(
      id: id,
      companyId: (d['company_id'] as String?) ?? '',
      customerName: (d['customer_name'] as String?) ?? '',
      address: (d['address'] as String?) ?? '',
      phone: (d['phone'] as String?) ?? '',
      email: (d['email'] as String?) ?? '',
      jobType: (d['job_type'] as String?) ?? '',
      templateId: (d['template_id'] as String?) ?? '',
      status: status,
      crewLeadId: (d['crew_lead_id'] as String?) ?? '',
      crewMemberIds: ((d['crew_member_ids'] as List<dynamic>?) ?? [])
          .map((e) => e.toString())
          .toList(),
      startDate: (d['start_date'] as Timestamp?)?.toDate(),
      completionDate: (d['completion_date'] as Timestamp?)?.toDate(),
      notes: (d['notes'] as String?) ?? '',
      photos: const [],
      reviewSent: (d['review_sent'] as bool?) ?? false,
      createdAt: (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  ContentPost _postFromDoc(Map<String, dynamic> d, String id) {
    final statusStr = (d['status'] as String?) ?? 'pending';
    final status = ContentStatus.values.firstWhere(
      (s) => s.name == statusStr,
      orElse: () => ContentStatus.pending,
    );
    return ContentPost(
      id: id,
      jobId: (d['job_id'] as String?) ?? '',
      beforePhotoUrl: (d['before_photo_url'] as String?) ?? '',
      afterPhotoUrl: (d['after_photo_url'] as String?) ?? '',
      suggestedCaption: (d['suggested_caption'] as String?) ?? '',
      suggestedHashtags: ((d['suggested_hashtags'] as List<dynamic>?) ?? [])
          .map((e) => e.toString())
          .toList(),
      projectSummary: (d['project_summary'] as String?) ?? '',
      status: status,
      scheduledFor: (d['scheduled_for'] as Timestamp?)?.toDate(),
      createdAt:
          (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      sourceSubmissionId: d['source_submission_id'] as String?,
      companyId: (d['company_id'] as String?) ?? '',
    );
  }

  ReviewRequest _reviewFromDoc(Map<String, dynamic> d, String id) {
    final statusStr = (d['status'] as String?) ?? 'sent';
    final opened = statusStr == 'opened' || statusStr == 'clicked' || statusStr == 'reviewed';
    final reviewed = statusStr == 'reviewed';
    return ReviewRequest(
      id: id,
      jobId: (d['job_id'] as String?) ?? '',
      customerName: (d['customer_name'] as String?) ?? '',
      sentTo: (d['customer_phone'] as String?) ?? (d['customer_email'] as String?) ?? '',
      method: (d['method'] as String?) ?? 'sms',
      sentAt: (d['sent_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      opened: opened,
      reviewed: reviewed,
      starRating: (d['rating'] as num?)?.toInt(),
    );
  }

  ProjectTemplate _templateFromDoc(Map<String, dynamic> d, String id) {
    final shotsRaw = (d['shots'] as List<dynamic>?) ?? [];
    final shots = shotsRaw.map((s) {
      final sm = s as Map<String, dynamic>;
      final phaseStr = (sm['phase'] as String?) ?? 'before';
      final phase = PhotoType.values.firstWhere(
        (p) => p.name == phaseStr,
        orElse: () => PhotoType.before,
      );
      return TemplateShot(
        id: id,
        name: (sm['name'] as String?) ?? '',
        instruction: (sm['instruction'] as String?) ?? '',
        phase: phase,
      );
    }).toList();

    return ProjectTemplate(
      id: id,
      name: (d['name'] as String?) ?? '',
      emoji: (d['emoji'] as String?) ?? '📷',
      tradeCategory: (d['trade_category'] as String?) ?? '',
      shots: shots,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MAPPERS — Model → Firestore doc
  // ══════════════════════════════════════════════════════════════════════════

  Map<String, dynamic> _jobToDoc(Job job) {
    return {
      'id': job.id,
      'company_id': job.companyId,
      'customer_name': job.customerName,
      'address': job.address,
      'phone': job.phone,
      'email': job.email,
      'job_type': job.jobType,
      'template_id': job.templateId,
      'status': job.status.name,
      'crew_lead_id': job.crewLeadId,
      'crew_member_ids': job.crewMemberIds,
      'start_date': job.startDate != null
          ? Timestamp.fromDate(job.startDate!)
          : null,
      'completion_date': job.completionDate != null
          ? Timestamp.fromDate(job.completionDate!)
          : null,
      'notes': job.notes,
      'review_sent': job.reviewSent,
      'photos_count': job.photos.length,
      'created_at': FieldValue.serverTimestamp(),
    };
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TEAM INVITES
  // ══════════════════════════════════════════════════════════════════════════

  /// Normalize a phone string to digits-only for consistent lookups.
  static String _normalizePhone(String phone) =>
      phone.replaceAll(RegExp(r'[^\d]'), '');

  /// Write a pending invite doc keyed by phone number. Returns the invite ID.
  Future<String> sendInvite({
    required String phone,
    required String name,
    required UserRole role,
    required String companyName,
    required String invitedByName,
  }) async {
    final inviteId = 'inv_${DateTime.now().millisecondsSinceEpoch}';
    await _db.collection('invites').doc(inviteId).set({
      'id':              inviteId,
      'company_id':      _companyId,
      'company_name':    companyName,
      'invited_by_name': invitedByName,
      'phone':           _normalizePhone(phone),
      'name':            name.trim(),
      'role':            role.name,
      'status':          'pending',
      'created_at':      FieldValue.serverTimestamp(),
    });
    return inviteId;
  }

  /// Look up a pending invite by phone number. Returns null if none found.
  Future<TeamInvite?> getPendingInviteByPhone(String phone) async {
    try {
      final normalized = _normalizePhone(phone);
      final snap = await _db
          .collection('invites')
          .where('phone', isEqualTo: normalized)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      final d = snap.docs.first.data();
      return TeamInvite(
        id:            snap.docs.first.id,
        companyId:     (d['company_id']       as String?) ?? '',
        companyName:   (d['company_name']      as String?) ?? '',
        invitedByName: (d['invited_by_name']   as String?) ?? '',
        phone:         (d['phone']             as String?) ?? '',
        name:          (d['name']              as String?) ?? '',
        role:          _roleFromString((d['role'] as String?) ?? 'crewMember'),
        status:        InviteStatus.pending,
        createdAt:     (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('FirestoreService getPendingInviteByPhone error: $e');
      return null;
    }
  }

  /// Admin cancels a pending invite.
  Future<void> cancelInvite(String inviteId) async {
    try {
      await _db.collection('invites').doc(inviteId).update({'status': 'cancelled'});
    } catch (e) {
      if (kDebugMode) debugPrint('FirestoreService cancelInvite error: $e');
    }
  }

  /// Mark an invite as accepted once the new user has joined.
  Future<void> acceptInvite(String inviteId) async {
    try {
      await _db.collection('invites').doc(inviteId).update({
        'status': 'accepted',
        'accepted_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) debugPrint('FirestoreService acceptInvite error: $e');
    }
  }

  /// Real-time stream of pending invites sent by this company.
  Stream<List<TeamInvite>> pendingInvitesStream() {
    return _db
        .collection('invites')
        .where('company_id', isEqualTo: _companyId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              return TeamInvite(
                id:            d.id,
                companyId:     (data['company_id']       as String?) ?? '',
                companyName:   (data['company_name']      as String?) ?? '',
                invitedByName: (data['invited_by_name']   as String?) ?? '',
                phone:         (data['phone']             as String?) ?? '',
                name:          (data['name']              as String?) ?? '',
                role:          _roleFromString((data['role'] as String?) ?? 'crewMember'),
                status:        InviteStatus.pending,
                createdAt:     (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
              );
            }).toList())
        .handleError((e) {
      if (kDebugMode) debugPrint('FirestoreService pendingInvitesStream error: $e');
      return <TeamInvite>[];
    });
  }

  UserRole _roleFromString(String s) {
    return UserRole.values.firstWhere(
      (r) => r.name == s,
      orElse: () => UserRole.crewMember,
    );
  }
}
