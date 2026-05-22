import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../models/sms_models.dart';
import '../../features/pricing/pricing_models.dart';
import 'firestore_service.dart';
import 'sms_service.dart';

class AppState extends ChangeNotifier {
  final FirestoreService _fs = FirestoreService();

  // ─── Firestore Stream Subscriptions ────────────────────────────────────────
  StreamSubscription<List<Job>>? _jobsSub;
  StreamSubscription<List<ContentPost>>? _postsSub;
  StreamSubscription<List<ReviewRequest>>? _reviewsSub;
  StreamSubscription<List<TRUser>>? _teamSub;
  StreamSubscription<Company?>? _companySub;
  StreamSubscription<List<ProjectTemplate>>? _templatesSub;
  StreamSubscription<List<PhotoSubmission>>? _photoSubmissionsSub;

  // ─── Auth State ─────────────────────────────────────────────────────────────
  bool _isLoggedIn = false;
  bool _onboardingComplete = false;
  TRUser? _currentUser;
  Company? _company;

  bool get isLoggedIn => _isLoggedIn;
  bool get onboardingComplete => _onboardingComplete;
  TRUser? get currentUser => _currentUser;
  Company? get company => _company;

  // ─── Loading State ──────────────────────────────────────────────────────────
  bool _firestoreReady = false;
  bool get firestoreReady => _firestoreReady;

  // ─── Theme ──────────────────────────────────────────────────────────────────
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  // ─── Jobs ───────────────────────────────────────────────────────────────────
  List<Job> _jobs = Job.sampleJobs;
  List<Job> get jobs => _jobs;
  List<Job> get activeJobs =>
      _jobs.where((j) => j.status != JobStatus.completed).toList();
  List<Job> get completedJobs =>
      _jobs.where((j) => j.status == JobStatus.completed).toList();

  List<Job> jobsByStatus(JobStatus status) =>
      _jobs.where((j) => j.status == status).toList();

  void addJob(Job job) {
    _jobs = [job, ..._jobs];
    notifyListeners();
    _fs.addJob(job).catchError((e) {
      if (kDebugMode) debugPrint('addJob Firestore error: $e');
    });
  }

  void updateJobStatus(String jobId, JobStatus newStatus) {
    _jobs = _jobs.map((j) {
      if (j.id == jobId) {
        return Job(
          id: j.id,
          companyId: j.companyId,
          customerName: j.customerName,
          address: j.address,
          phone: j.phone,
          email: j.email,
          jobType: j.jobType,
          templateId: j.templateId,
          status: newStatus,
          crewLeadId: j.crewLeadId,
          crewMemberIds: j.crewMemberIds,
          startDate: j.startDate,
          completionDate: newStatus == JobStatus.completed
              ? DateTime.now()
              : j.completionDate,
          notes: j.notes,
          photos: j.photos,
          reviewSent: j.reviewSent,
          createdAt: j.createdAt,
        );
      }
      return j;
    }).toList();
    notifyListeners();
    _fs.updateJobStatus(jobId, newStatus).catchError((e) {
      if (kDebugMode) debugPrint('updateJobStatus Firestore error: $e');
    });
  }

  // ─── Content Posts ───────────────────────────────────────────────────────────
  List<ContentPost> _posts = ContentPost.samplePosts;
  List<ContentPost> get posts => _posts;
  List<ContentPost> get pendingPosts =>
      _posts.where((p) => p.status == ContentStatus.pending).toList();

  void updatePostStatus(String postId, ContentStatus status) {
    _posts = _posts.map((p) {
      if (p.id == postId) {
        return ContentPost(
          id: p.id,
          jobId: p.jobId,
          beforePhotoUrl: p.beforePhotoUrl,
          afterPhotoUrl: p.afterPhotoUrl,
          suggestedCaption: p.suggestedCaption,
          suggestedHashtags: p.suggestedHashtags,
          projectSummary: p.projectSummary,
          status: status,
          scheduledFor: p.scheduledFor,
          createdAt: p.createdAt,
        );
      }
      return p;
    }).toList();
    notifyListeners();
    _fs.updatePostStatus(postId, status).catchError((e) {
      if (kDebugMode) debugPrint('updatePostStatus Firestore error: $e');
    });
  }

  // ─── Reviews ─────────────────────────────────────────────────────────────────
  List<ReviewRequest> _reviews = List<ReviewRequest>.from(ReviewRequest.sampleReviews);
  List<ReviewRequest> get reviews => _reviews;

  // ─── SMS ──────────────────────────────────────────────────────────────────
  final List<SmsMessage> _smsLog = [];
  List<SmsMessage> get smsLog => List.unmodifiable(_smsLog);
  bool _smsSending = false;
  bool get smsSending => _smsSending;

  // Send a review request SMS
  Future<SmsResult> sendReviewSms({
    required String jobId,
    required String customerName,
    required String toPhone,
    required String jobType,
    required String companyName,
    String? reviewLink,           // each company's own Google review URL
  }) async {
    _smsSending = true;
    notifyListeners();

    final body = SmsTemplates.reviewRequest.buildBody(
      customerName: customerName,
      jobType: jobType,
      companyName: companyName,
      reviewLink: reviewLink,
    );

    final result = await SmsService.instance.send(
      toPhone: toPhone,
      body: body,
      jobId: jobId,
      templateKey: SmsTemplates.reviewRequest.key,
      customerName: customerName,
      type: SmsType.reviewRequest,
    );

    if (result.success && result.message != null) {
      _smsLog.insert(0, result.message!);
      _markReviewSent(jobId, toPhone);
    }

    _smsSending = false;
    notifyListeners();
    return result;
  }

  // Send a job status SMS
  Future<SmsResult> sendStatusSms({
    required String jobId,
    required String customerName,
    required String toPhone,
    required String jobType,
    required String companyName,
    required SmsTemplate template,
  }) async {
    _smsSending = true;
    notifyListeners();

    final body = template.buildBody(
      customerName: customerName,
      jobType: jobType,
      companyName: companyName,
    );

    final result = await SmsService.instance.send(
      toPhone: toPhone,
      body: body,
      jobId: jobId,
      templateKey: template.key,
      customerName: customerName,
      type: SmsType.statusUpdate,
    );

    if (result.success && result.message != null) {
      _smsLog.insert(0, result.message!);
    }

    _smsSending = false;
    notifyListeners();
    return result;
  }

  // Returns all SMS messages for a specific job
  List<SmsMessage> smsForJob(String jobId) =>
      _smsLog.where((m) => m.jobId == jobId).toList();

  void _markReviewSent(String jobId, String toPhone) {
    _jobs = _jobs.map((j) {
      if (j.id != jobId) return j;
      return Job(
        id: j.id, companyId: j.companyId, customerName: j.customerName,
        address: j.address, phone: j.phone, email: j.email,
        jobType: j.jobType, templateId: j.templateId, status: j.status,
        crewLeadId: j.crewLeadId, crewMemberIds: j.crewMemberIds,
        startDate: j.startDate, completionDate: j.completionDate,
        notes: j.notes, photos: j.photos, reviewSent: true,
        createdAt: j.createdAt,
      );
    }).toList();
    final job = _jobs.firstWhere((j) => j.id == jobId, orElse: () => _jobs.first);
    final review = ReviewRequest(
      id: 'rv_${DateTime.now().millisecondsSinceEpoch}',
      jobId: jobId,
      customerName: job.customerName,
      sentTo: toPhone,
      method: 'sms',
      sentAt: DateTime.now(),
    );
    _reviews.insert(0, review);
  }

  // ─── Analytics ───────────────────────────────────────────────────────────────
  AnalyticsSummary _analytics = AnalyticsSummary.sample;
  AnalyticsSummary get analytics => _analytics;

  // ─── Templates ───────────────────────────────────────────────────────────────
  List<ProjectTemplate> _templates = ProjectTemplate.defaultTemplates;
  List<ProjectTemplate> get templates => _templates;

  // ─── Team ────────────────────────────────────────────────────────────────────
  List<TRUser> _team = TRUser.sampleTeam;
  List<TRUser> get team => _team;

  // ─── Photo Submissions ───────────────────────────────────────────────────────
  List<PhotoSubmission> _photoSubmissions = PhotoSubmission.samples;
  List<PhotoSubmission> get photoSubmissions => _photoSubmissions;

  /// Pending submissions waiting for approval.
  List<PhotoSubmission> get pendingSubmissions =>
      _photoSubmissions.where((s) => s.status == PhotoSubmissionStatus.pending).toList();

  /// True if the current user can approve/reject submissions.
  /// Roles: admin, officeManager, salesRep (marketing).
  bool get canApprovePhotos {
    final role = _currentUser?.role;
    return role == UserRole.admin ||
        role == UserRole.officeManager ||
        role == UserRole.salesRep;
  }

  /// Any crew member submits photos for a job.
  Future<void> submitPhotos({
    required String jobId,
    required String jobName,
    required List<XFile> pickedFiles,
    required PhotoType photoType,
    String? crewNote,
  }) async {
    final user = _currentUser;
    if (user == null) return;
    final ts = DateTime.now().millisecondsSinceEpoch;
    final photos = pickedFiles.asMap().entries.map((e) => SubmittedPhoto(
      id: 'ph_${ts}_${e.key}',
      localPath: e.value.path,
      type: photoType,
    )).toList();

    try {
      final submission = await _fs.submitPhotos(
        jobId: jobId,
        jobName: jobName,
        submittedById: user.id,
        submittedByName: user.name,
        photos: photos,
        crewNote: crewNote,
      );
      // Optimistic local insert
      _photoSubmissions = [submission, ..._photoSubmissions];
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('submitPhotos error: $e');
    }
  }

  /// Approver approves a submission with optional feedback note.
  Future<void> approveSubmission(String submissionId, {String? note}) async {
    final user = _currentUser;
    if (user == null || !canApprovePhotos) return;
    await _applySubmissionStatus(
      submissionId: submissionId,
      status: PhotoSubmissionStatus.approved,
      reviewedById: user.id,
      reviewedByName: user.name,
      note: note,
    );
  }

  /// Approver rejects a submission with optional note explaining why.
  Future<void> rejectSubmission(String submissionId, {String? note}) async {
    final user = _currentUser;
    if (user == null || !canApprovePhotos) return;
    await _applySubmissionStatus(
      submissionId: submissionId,
      status: PhotoSubmissionStatus.rejected,
      reviewedById: user.id,
      reviewedByName: user.name,
      note: note,
    );
  }

  Future<void> _applySubmissionStatus({
    required String submissionId,
    required PhotoSubmissionStatus status,
    required String reviewedById,
    required String reviewedByName,
    String? note,
  }) async {
    // Optimistic local update
    _photoSubmissions = _photoSubmissions.map((s) {
      if (s.id != submissionId) return s;
      return s.copyWith(
        status: status,
        reviewedById: reviewedById,
        reviewedByName: reviewedByName,
        reviewerNote: note,
        reviewedAt: DateTime.now(),
      );
    }).toList();
    notifyListeners();

    try {
      await _fs.updateSubmissionStatus(
        submissionId: submissionId,
        status: status,
        reviewedById: reviewedById,
        reviewedByName: reviewedByName,
        reviewerNote: note,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('updateSubmissionStatus error: $e');
    }
  }

  // ─── Google Status ───────────────────────────────────────────────────────────
  bool _googleConnected = false;
  bool get googleConnected => _googleConnected;

  void connectGoogle() {
    _googleConnected = true;
    notifyListeners();
    _fs.updateGoogleConnected(true).catchError((e) {
      if (kDebugMode) debugPrint('connectGoogle Firestore error: $e');
    });
  }

  // ─── Subscription ─────────────────────────────────────────────────────────
  ActiveSubscription _subscription = ActiveSubscription.demo;
  ActiveSubscription get subscription => _subscription;
  PlanTier get currentTier => _subscription.tier;
  bool get isInTrial => _subscription.isInTrial;
  int get trialDaysRemaining => _subscription.trialDaysRemaining;

  bool canAccess(String featureKey) {
    if (_subscription.isInTrial) {
      return FeatureAccess.canAccess(PlanTier.growth, featureKey);
    }
    if (_subscription.status == SubscriptionStatus.none) {
      return FeatureAccess.canAccess(PlanTier.starter, featureKey);
    }
    return FeatureAccess.canAccess(_subscription.tier, featureKey);
  }

  void selectPlan(PlanTier tier) {
    _subscription = ActiveSubscription(
      tier: tier,
      status: SubscriptionStatus.trial,
      trialStartDate: DateTime.now(),
      trialEndDate: DateTime.now().add(const Duration(days: 14)),
    );
    notifyListeners();
  }

  void upgradePlan(PlanTier tier) {
    _subscription = ActiveSubscription(
      tier: tier,
      status: SubscriptionStatus.active,
      trialStartDate: _subscription.trialStartDate,
      trialEndDate: _subscription.trialEndDate,
      billingStartDate: DateTime.now(),
      nextBillingDate: DateTime.now().add(const Duration(days: 30)),
      billingHistory: _subscription.billingHistory,
    );
    notifyListeners();
  }

  void startTrial(PlanTier tier) {
    _subscription = ActiveSubscription(
      tier: tier,
      status: SubscriptionStatus.trial,
      trialStartDate: DateTime.now(),
      trialEndDate: DateTime.now().add(const Duration(days: 14)),
    );
    notifyListeners();
  }

  // ─── Login ─────────────────────────────────────────────────────────────────
  Future<void> login() async {
    _currentUser = TRUser.sample;
    _company = Company.sample;
    _isLoggedIn = true;
    _onboardingComplete = true;
    notifyListeners();
    await _initFirestoreStreams();
  }

  Future<void> completeOnboarding() async {
    _onboardingComplete = true;
    _isLoggedIn = true;
    _currentUser = TRUser.sample;
    _company = Company.sample;
    notifyListeners();
    await _initFirestoreStreams();
  }

  void logout() {
    _cancelStreams();
    _isLoggedIn = false;
    _onboardingComplete = false;
    _currentUser = null;
    _company = null;
    _firestoreReady = false;
    // Reset to sample data
    _jobs = Job.sampleJobs;
    _posts = ContentPost.samplePosts;
    _reviews = List<ReviewRequest>.from(ReviewRequest.sampleReviews);
    _team = TRUser.sampleTeam;
    _templates = ProjectTemplate.defaultTemplates;
    _analytics = AnalyticsSummary.sample;
    _photoSubmissions = PhotoSubmission.samples;
    _smsLog.clear();
    notifyListeners();
  }

  // ─── Firestore Stream Initialization ──────────────────────────────────────
  Future<void> _initFirestoreStreams() async {
    try {
      // Load company + user from Firestore first
      final fsCompany = await _fs.getCompany();
      if (fsCompany != null) {
        _company = fsCompany;
        _googleConnected = fsCompany.googleConnected;
      }

      final fsUser = await _fs.getCurrentUser();
      if (fsUser != null) _currentUser = fsUser;

      // Load subscription from Firestore
      final fsSub = await _fs.getSubscription();
      _subscription = fsSub;

      // Load analytics
      final fsAnalytics = await _fs.getAnalytics();
      _analytics = fsAnalytics;

      notifyListeners();

      // Subscribe to real-time streams
      _jobsSub = _fs.jobsStream().listen((jobs) {
        if (jobs.isNotEmpty) _jobs = jobs;
        notifyListeners();
      }, onError: (e) {
        if (kDebugMode) debugPrint('Jobs stream error: $e');
      });

      _postsSub = _fs.postsStream().listen((posts) {
        if (posts.isNotEmpty) _posts = posts;
        notifyListeners();
      }, onError: (e) {
        if (kDebugMode) debugPrint('Posts stream error: $e');
      });

      _reviewsSub = _fs.reviewsStream().listen((_) {
        notifyListeners();
      }, onError: (e) {
        if (kDebugMode) debugPrint('Reviews stream error: $e');
      });

      _teamSub = _fs.teamStream().listen((team) {
        if (team.isNotEmpty) _team = team;
        notifyListeners();
      }, onError: (e) {
        if (kDebugMode) debugPrint('Team stream error: $e');
      });

      _companySub = _fs.companyStream().listen((company) {
        if (company != null) {
          _company = company;
          _googleConnected = company.googleConnected;
        }
        notifyListeners();
      }, onError: (e) {
        if (kDebugMode) debugPrint('Company stream error: $e');
      });

      _templatesSub = _fs.templatesStream().listen((templates) {
        if (templates.isNotEmpty) _templates = templates;
        notifyListeners();
      }, onError: (e) {
        if (kDebugMode) debugPrint('Templates stream error: $e');
      });

      _photoSubmissionsSub = _fs.photoSubmissionsStream().listen((subs) {
        if (subs.isNotEmpty) _photoSubmissions = subs;
        notifyListeners();
      }, onError: (e) {
        if (kDebugMode) debugPrint('PhotoSubmissions stream error: $e');
      });

      _firestoreReady = true;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('Firestore init error: $e — falling back to sample data');
      _firestoreReady = false;
      notifyListeners();
    }
  }

  void _cancelStreams() {
    _jobsSub?.cancel();
    _postsSub?.cancel();
    _reviewsSub?.cancel();
    _teamSub?.cancel();
    _companySub?.cancel();
    _templatesSub?.cancel();
    _photoSubmissionsSub?.cancel();
  }

  @override
  void dispose() {
    _cancelStreams();
    super.dispose();
  }
}
