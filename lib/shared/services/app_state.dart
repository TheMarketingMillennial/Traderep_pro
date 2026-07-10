import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../models/sms_models.dart';
import '../../features/pricing/pricing_models.dart';
import '../../core/config/app_config.dart';
import 'firestore_service.dart';
import 'auth_service.dart';
import 'sms_service.dart';
import 'gbp_service.dart';
import 'gbp_auth_service.dart';
import 'ai_service.dart';
import 'analytics_service.dart';

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
  StreamSubscription<List<TeamInvite>>? _pendingInvitesSub;
  StreamSubscription<ActiveSubscription>? _subscriptionSub;
  StreamSubscription<User?>? _authStateSub; // Firebase Auth persistence listener

  // ─── Auth State ─────────────────────────────────────────────────────────────
  bool _isLoggedIn = false;
  /// True once the Firebase Auth state check has completed on startup.
  /// While false, the app shows a loading splash instead of the login screen.
  bool _authCheckComplete = false;
  bool get authCheckComplete => _authCheckComplete;
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

  /// Exposes the company ID that FirestoreService is currently keyed to.
  /// This is the Firebase Auth UID set by onFirebaseSignIn().
  /// Use this as the authoritative companyId when company doc hasn't loaded yet.
  String get firestoreCompanyId => _fs.companyId;

  // ─── Theme ──────────────────────────────────────────────────────────────────
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  // ─── Constructor — subscribe to Firebase Auth state for session persistence ──
  AppState() {
    _subscribeToAuthState();
  }

  /// Listens to Firebase Auth state changes.
  /// On web, Firebase restores the session from localStorage immediately after
  /// the first event. Without this listener, refreshing the browser always
  /// sends the user back to the login screen because AppState starts with
  /// _isLoggedIn = false.
  void _subscribeToAuthState() {
    if (!AppConfig.isFirebaseConfigured) {
      // No Firebase — mark check complete so the app doesn't hang on the splash.
      _authCheckComplete = true;
      return;
    }
    _authStateSub = FirebaseAuth.instance.authStateChanges().listen(
      (User? user) {
        if (_isLoggedIn) {
          // Already logged in (e.g. from SignInScreen) — nothing to do on
          // subsequent events unless the user signs out externally.
          if (user == null) {
            // Signed out from another tab or token revoked.
            logout();
          }
          return;
        }
        if (user != null) {
          // Firebase restored an existing session (web refresh, app reopen).
          debugPrint('[AppState] Auth state restored — uid: ${user.uid}');
          onFirebaseSignIn(user);
        } else {
          debugPrint('[AppState] Auth state: no user (unauthenticated)');
        }
        // Mark auth check done so the splash screen gives way to the real UI.
        if (!_authCheckComplete) {
          _authCheckComplete = true;
          notifyListeners();
        }
      },
      onError: (e) {
        debugPrint('[AppState] authStateChanges error: $e');
        if (!_authCheckComplete) {
          _authCheckComplete = true;
          notifyListeners();
        }
      },
    );
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  // ─── Jobs ───────────────────────────────────────────────────────────────────
  List<Job> _jobs = [];
  List<Job> get jobs => _jobs;
  List<Job> get activeJobs =>
      _jobs.where((j) => j.status != JobStatus.completed).toList();
  List<Job> get completedJobs =>
      _jobs.where((j) => j.status == JobStatus.completed).toList();

  List<Job> jobsByStatus(JobStatus status) =>
      _jobs.where((j) => j.status == status).toList();

  // ── Live stat counts (derived from real data — always start at 0) ──────────
  /// Total jobs ever created (all statuses).
  int get totalJobsCount => _jobs.length;

  /// Jobs that have been marked completed.
  int get completedJobsCount => completedJobs.length;

  /// Jobs where a review request was sent.
  int get reviewsSentCount => _jobs.where((j) => j.reviewSent).length;

  /// Total photos across all jobs.
  /// Total photos uploaded via the photo submission system (crew uploads).
  /// Counts photos with a real Storage URL across all approved + pending submissions.
  int get photosUploadedCount =>
      _photoSubmissions.fold(0, (sum, s) =>
          sum + s.photos.where((p) => p.networkUrl != null).length);

  /// Published Google posts.
  int get googlePostsCount =>
      _posts.where((p) => p.status == ContentStatus.published).length;

  void addJob(Job job) {
    _jobs = [job, ..._jobs];
    notifyListeners();
    _fs.addJob(job).catchError((e) {
      if (kDebugMode) debugPrint('addJob Firestore error: $e');
    });
  }

  /// Async variant used by CreateJobScreen — awaits Firestore write so the
  /// caller can catch errors and show them to the user instead of swallowing.
  Future<void> addJobAsync(Job job) async {
    // Optimistic local insert first so the list updates immediately
    _jobs = [job, ..._jobs];
    notifyListeners();
    // Await the Firestore write — throws on failure so caller can react
    await _fs.addJob(job);
    // Analytics: record job_created event
    AnalyticsService.recordEvent(
      companyId: _fs.companyId,
      eventType: ActivityEventType.jobCreated,
      metadata: {'job_type': job.jobType, 'job_id': job.id},
    );
  }

  void updateJob(Job updated) {
    _jobs = _jobs.map((j) => j.id == updated.id ? updated : j).toList();
    notifyListeners();
    _fs.updateJobFields(updated).catchError((e) {
      if (kDebugMode) debugPrint('updateJob Firestore error: $e');
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
  List<ContentPost> _posts = [];
  List<ContentPost> get posts => _posts;
  List<ContentPost> get pendingPosts =>
      _posts.where((p) => p.status == ContentStatus.pending).toList();

  void updatePostStatus(String postId, ContentStatus status) {
    // Find the post before updating so we can access its content for history.
    final targetPost = _posts.where((p) => p.id == postId).firstOrNull;

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
          sourceSubmissionId: p.sourceSubmissionId,
          companyId: p.companyId,
        );
      }
      return p;
    }).toList();
    notifyListeners();
    _fs.updatePostStatus(postId, status).catchError((e) {
      if (kDebugMode) debugPrint('updatePostStatus Firestore error: $e');
    });

    // Save to anti-repetition history whenever a post is published.
    if (status == ContentStatus.published && targetPost != null) {
      _fs.savePublishedGbpPost(
        postId:   postId,
        caption:  targetPost.suggestedCaption,
        hashtags: targetPost.suggestedHashtags,
        jobType:  targetPost.projectSummary,
      );
    }
  }

  /// Bridges photo-submission pipeline → content-post pipeline.
  /// Picks best before/after photo from [submission], generates a draft
  /// caption from company context, writes to Firestore, and returns the
  /// new [ContentPost] so the caller can open CreatePostSheet.
  Future<ContentPost?> createPostFromSubmission(PhotoSubmission submission) async {
    try {
      final company = _company;
      // Pick before photo: first with PhotoType.before, else first photo
      final photos = submission.photos;
      final beforePhoto = photos.firstWhere(
        (p) => p.type == PhotoType.before,
        orElse: () => photos.first,
      );
      // Pick after photo: first with PhotoType.after, else last photo
      final afterPhoto = photos.firstWhere(
        (p) => p.type == PhotoType.after,
        orElse: () => photos.last,
      );

      // Find the job to enrich caption
      final job = _jobs.firstWhere(
        (j) => j.id == submission.jobId,
        orElse: () => Job(
          id: submission.jobId,
          companyId: '',
          customerName: '',
          address: '',
          phone: '',
          email: '',
          jobType: submission.jobName,
          templateId: '',
          status: JobStatus.inProgress,
          crewLeadId: '',
          crewMemberIds: const [],
          photos: const [],
          reviewSent: false,
          createdAt: DateTime.now(),
        ),
      );

      // Build draft caption — try AI first, fall back to template
      final tradeName = company?.tradeCategory ?? 'Trade';
      final area      = company?.serviceArea ?? '';
      final bizName   = company?.name ?? '';
      final jobType   = job.jobType.isNotEmpty ? job.jobType : submission.jobName;

      String draftCaption;
      List<String> hashtags;

      // ── Try AI caption ──────────────────────────────────────────────────────
      final aiResult = await AiService.generateCaption(
        jobType:        jobType,
        companyName:    bizName,
        trade:          tradeName,
        serviceArea:    area,
        jobDescription: submission.crewNote ?? '',
        tone:           CaptionTone.professional,
      );

      if (aiResult != null) {
        draftCaption = aiResult.caption;
        hashtags     = aiResult.hashtags;
        if (kDebugMode) debugPrint('[AppState] AI caption applied ✅');
      } else {
        // ── Template fallback (Railway unreachable or OpenAI not configured) ──
        if (kDebugMode) debugPrint('[AppState] AI unavailable — using template caption');
        final areaStr   = area.isNotEmpty ? ' in $area' : '';
        final bizPrefix = bizName.isNotEmpty ? 'Trusted by $bizName — ' : '';
        final areaServe = area.isNotEmpty ? ' serving $area' : '';
        draftCaption =
            '$jobType complete$areaStr!\n\n'
            'Our crew delivered a clean, professional result for another '
            'happy customer. Every job gets our full attention from start '
            'to finish.\n\n'
            '${bizPrefix}Trusted $tradeName Experts$areaServe.\n\n'
            'Call or message us for a free estimate!';
        hashtags = [
          '#$tradeName'.replaceAll(' ', ''),
          '#BeforeAndAfter',
          '#${tradeName}Contractor'.replaceAll(' ', ''),
          '#HomeImprovement',
          '#QualityWork',
          '#ContractorLife',
        ];
      }

      final companyId = _fs.companyId;
      final newPost = ContentPost(
        id: '', // Firestore will assign
        jobId: submission.jobId,
        beforePhotoUrl: beforePhoto.networkUrl ?? '',
        afterPhotoUrl: afterPhoto.networkUrl ?? '',
        suggestedCaption: draftCaption,
        suggestedHashtags: hashtags,
        projectSummary: submission.crewNote ?? '',
        status: ContentStatus.pending,
        createdAt: DateTime.now(),
        sourceSubmissionId: submission.id,
        companyId: companyId,
      );

      // Write to Firestore and get real ID
      final docId = await _fs.addPost(newPost);
      final savedPost = ContentPost(
        id: docId,
        jobId: newPost.jobId,
        beforePhotoUrl: newPost.beforePhotoUrl,
        afterPhotoUrl: newPost.afterPhotoUrl,
        suggestedCaption: newPost.suggestedCaption,
        suggestedHashtags: newPost.suggestedHashtags,
        projectSummary: newPost.projectSummary,
        status: newPost.status,
        createdAt: newPost.createdAt,
        sourceSubmissionId: newPost.sourceSubmissionId,
        companyId: newPost.companyId,
      );

      // Optimistic local insert
      _posts = [savedPost, ..._posts];
      notifyListeners();

      return savedPost;
    } catch (e) {
      if (kDebugMode) debugPrint('createPostFromSubmission error: $e');
      return null;
    }
  }

  /// Replaces an existing post in the local list (used after CreatePostSheet
  /// edits the caption / hashtags / photo URLs post-creation).
  void replacePost(ContentPost updated) {
    _posts = _posts.map((p) => p.id == updated.id ? updated : p).toList();
    notifyListeners();
  }

  // ─── Reviews ─────────────────────────────────────────────────────────────────
  List<ReviewRequest> _reviews = [];
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

    // Try AI-personalized message first, fall back to template
    final aiMessage = await AiService.generateSms(
      type:         SmsTemplates.reviewRequest.key,
      customerName: customerName,
      jobType:      jobType,
      companyName:  companyName,
      reviewLink:   reviewLink ?? '',
    );
    final body = aiMessage ?? SmsTemplates.reviewRequest.buildBody(
      customerName: customerName,
      jobType:      jobType,
      companyName:  companyName,
      reviewLink:   reviewLink,
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
      // Analytics: record review request sent event
      AnalyticsService.recordEvent(
        companyId: _fs.companyId,
        eventType: ActivityEventType.reviewRequestSent,
        metadata: {'job_id': jobId, 'job_type': jobType},
      );
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

    // Try AI-personalized message first, fall back to template
    final aiMessage = await AiService.generateSms(
      type:         template.key,
      customerName: customerName,
      jobType:      jobType,
      companyName:  companyName,
    );
    final body = aiMessage ?? template.buildBody(
      customerName: customerName,
      jobType:      jobType,
      companyName:  companyName,
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
  AnalyticsSummary _analytics = AnalyticsSummary.empty;
  AnalyticsSummary get analytics => _analytics;

  // ─── Templates ───────────────────────────────────────────────────────────────
  List<ProjectTemplate> _templates = ProjectTemplate.defaultTemplates;
  List<ProjectTemplate> get templates => _templates;

  /// The company's trade category string (e.g. 'Roofing', 'Plumbing').
  /// Returns empty string if not yet loaded.
  String get companyTrade => _company?.tradeCategory ?? '';

  /// Templates whose `tradeCategory` matches the company's trade, sorted to
  /// the front.  Other trades follow (so the user can still browse them).
  List<ProjectTemplate> get templatesForCompanyTrade {
    final trade = companyTrade;
    if (trade.isEmpty) return _templates;
    final matched = _templates
        .where((t) => t.tradeCategory.toLowerCase() == trade.toLowerCase())
        .toList();
    final others = _templates
        .where((t) => t.tradeCategory.toLowerCase() != trade.toLowerCase())
        .toList();
    return [...matched, ...others];
  }

  // ─── Team ────────────────────────────────────────────────────────────────────
  List<TRUser> _team = [];
  List<TRUser> get team => _team;

  // ─── Pending Invites (admin-visible) ─────────────────────────────────────────
  List<TeamInvite> _pendingInvites = [];
  List<TeamInvite> get pendingInvites => _pendingInvites;

  // ─── Photo Submissions ───────────────────────────────────────────────────────
  List<PhotoSubmission> _photoSubmissions = [];
  List<PhotoSubmission> get photoSubmissions => _photoSubmissions;

  /// Pending submissions waiting for approval.
  List<PhotoSubmission> get pendingSubmissions =>
      _photoSubmissions.where((s) => s.status == PhotoSubmissionStatus.pending).toList();

  /// Callback fired when new pending submissions arrive from Firestore.
  /// The integer is the count of NEW submissions since the last check.
  /// Admins can subscribe to this to show an in-app snackbar/banner.
  void Function(int newCount)? onNewPendingSubmissions;

  // Tracks the count from the last stream event so we can detect arrivals.
  int _lastKnownPendingCount = 0;

  /// True if the current user can approve/reject submissions.
  /// Roles: admin, officeManager, salesRep (marketing).
  bool get canApprovePhotos {
    final role = _currentUser?.role;
    return role == UserRole.admin ||
        role == UserRole.officeManager ||
        role == UserRole.salesRep;
  }

  /// Admin sends a team invite. Returns the invite ID on success, null on error.
  Future<String?> sendTeamInvite({
    required String phone,
    required String name,
    required UserRole role,
  }) async {
    final company = _company;
    final admin = _currentUser;
    if (company == null || admin == null) return null;
    try {
      final id = await _fs.sendInvite(
        phone: phone,
        name: name,
        role: role,
        companyName: company.name,
        invitedByName: admin.name,
      );
      if (kDebugMode) debugPrint('[AppState] Invite sent: $id to $phone');
      return id;
    } catch (e) {
      if (kDebugMode) debugPrint('[AppState] sendTeamInvite error: $e');
      return null;
    }
  }

  /// Admin cancels a pending invite.
  Future<void> cancelInvite(String inviteId) async {
    try {
      await FirestoreService().cancelInvite(inviteId);
    } catch (e) {
      if (kDebugMode) debugPrint('[AppState] cancelInvite error: $e');
    }
  }

  /// Any crew member submits photos for a job.
  Future<void> submitPhotos({
    required String jobId,
    required String jobName,
    required List<XFile> pickedFiles,
    required PhotoType photoType,
    String? crewNote,
    String? customerHighlight,
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
        customerHighlight: customerHighlight,
        // Pass original XFile list so FirestoreService can read bytes on
        // both mobile (file path) and web (blob/data URL via readAsBytes())
        xFiles: pickedFiles,
      );
      // Optimistic local insert
      _photoSubmissions = [submission, ..._photoSubmissions];
      notifyListeners();
      // Analytics: record photos_uploaded event
      AnalyticsService.recordEvent(
        companyId: _fs.companyId,
        eventType: ActivityEventType.photosUploaded,
        metadata: {'job_id': jobId, 'photo_count': pickedFiles.length},
      );
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

  // ─── Google / GBP Status ─────────────────────────────────────────────────────
  bool _googleConnected = false;
  bool get googleConnected => _googleConnected;

  void updateCompany({
    required String name,
    required String phone,
    required String serviceArea,
    String? website,
  }) {
    if (_company == null) return;
    _company = Company(
      id:              _company!.id,
      name:            name,
      logoUrl:         _company!.logoUrl,
      tradeCategory:   _company!.tradeCategory,
      serviceArea:     serviceArea,
      phone:           phone,
      website:         website,
      teamSize:        _company!.teamSize,
      googleConnected: _company!.googleConnected,
      googleBusinessId: _company!.googleBusinessId,
      googleReviewLink: _company!.googleReviewLink,
      gbpLocationId:   _company!.gbpLocationId,
      createdAt:       _company!.createdAt,
    );
    notifyListeners();
    _fs.updateCompanyFields(
      name: name, phone: phone, serviceArea: serviceArea, website: website,
    ).catchError((e) {
      if (kDebugMode) debugPrint('updateCompany Firestore error: $e');
    });
  }

  void connectGoogle() {
    _googleConnected = true;
    notifyListeners();
    _fs.updateGoogleConnected(true).catchError((e) {
      if (kDebugMode) debugPrint('connectGoogle Firestore error: $e');
    });
  }

  /// Marks GBP as connected and optionally stores the OAuth-detected locationId.
  /// Called by [GbpAuthService] polling callback after successful OAuth.
  void connectGoogleViaOAuth(GbpAuthResult result) {
    _googleConnected = true;
    // Store location and review link in company object if we got them from OAuth
    if (_company != null) {
      _company = Company(
        id:                _company!.id,
        name:              _company!.name,
        logoUrl:           _company!.logoUrl,
        tradeCategory:     _company!.tradeCategory,
        serviceArea:       _company!.serviceArea,
        phone:             _company!.phone,
        website:           _company!.website,
        teamSize:          _company!.teamSize,
        googleConnected:   true,
        googleBusinessId:  _company!.googleBusinessId,
        // Use review link from OAuth result; keep existing if not returned
        googleReviewLink:  result.googleReviewLink ?? _company!.googleReviewLink,
        gbpLocationId:     result.locationId ?? _company!.gbpLocationId,
        createdAt:         _company!.createdAt,
      );
    }
    notifyListeners();
    // Persist to Firestore — server already wrote google_review_link via callback,
    // but we sync the connected flag here for immediate in-app update.
    _fs.updateGoogleConnected(true).catchError((e) {
      if (kDebugMode) debugPrint('connectGoogleViaOAuth Firestore error: $e');
    });
    if (result.locationId != null) {
      _fs.updateGbpLocationId(result.locationId).catchError((e) {
        if (kDebugMode) debugPrint('connectGoogleViaOAuth updateGbpLocationId error: $e');
      });
    }
  }

  /// Disconnects Google Business Profile — clears location ID, resets connected flag.
  /// After this the user can reconnect with any Google account.
  void disconnectGbp() {
    _googleConnected = false;
    if (_company != null) {
      _company = Company(
        id:                _company!.id,
        name:              _company!.name,
        logoUrl:           _company!.logoUrl,
        tradeCategory:     _company!.tradeCategory,
        serviceArea:       _company!.serviceArea,
        phone:             _company!.phone,
        website:           _company!.website,
        teamSize:          _company!.teamSize,
        googleConnected:   false,
        googleBusinessId:  null,
        googleReviewLink:  null,
        gbpLocationId:     null,
        createdAt:         _company!.createdAt,
      );
    }
    notifyListeners();
    // Persist to Firestore
    _fs.updateGoogleConnected(false).catchError((e) {
      if (kDebugMode) debugPrint('disconnectGbp Firestore error: $e');
    });
    _fs.updateGbpLocationId(null).catchError((e) {
      if (kDebugMode) debugPrint('disconnectGbp clearLocationId error: $e');
    });
  }

  /// Persists the GBP location resource name for this company.
  /// Pass null to clear (reverts to manual Phase 1 posting flow in PublishSheet).
  Future<void> updateGbpLocationId(String? locationId) async {
    // Optimistic update to Company object in-memory
    if (_company != null) {
      _company = Company(
        id:                _company!.id,
        name:              _company!.name,
        logoUrl:           _company!.logoUrl,
        tradeCategory:     _company!.tradeCategory,
        serviceArea:       _company!.serviceArea,
        phone:             _company!.phone,
        website:           _company!.website,
        teamSize:          _company!.teamSize,
        googleConnected:   _company!.googleConnected,
        googleBusinessId:  _company!.googleBusinessId,
        googleReviewLink:  _company!.googleReviewLink,
        gbpLocationId:     locationId,
        createdAt:         _company!.createdAt,
        adminPreferences:  _company!.adminPreferences,
        brandVoice:        _company!.brandVoice,
      );
      notifyListeners();
    }
    await _fs.updateGbpLocationId(locationId);
  }

  /// Updates the company brand voice for AI-generated GBP posts.
  Future<void> updateBrandVoice(String voice) async {
    if (_company != null) {
      _company = Company(
        id:                _company!.id,
        name:              _company!.name,
        logoUrl:           _company!.logoUrl,
        tradeCategory:     _company!.tradeCategory,
        serviceArea:       _company!.serviceArea,
        phone:             _company!.phone,
        website:           _company!.website,
        teamSize:          _company!.teamSize,
        googleConnected:   _company!.googleConnected,
        googleBusinessId:  _company!.googleBusinessId,
        googleReviewLink:  _company!.googleReviewLink,
        gbpLocationId:     _company!.gbpLocationId,
        createdAt:         _company!.createdAt,
        adminPreferences:  _company!.adminPreferences,
        brandVoice:        voice,
      );
      notifyListeners();
    }
    await _fs.updateBrandVoice(voice);
  }

  /// Publishes a ContentPost to Google Business Profile via the Railway server.
  ///
  /// Requires [company.gbpLocationId] to be set. On success, marks the post
  /// as [ContentStatus.published] in Firestore.
  ///
  /// Returns a [GbpResult] — caller decides how to surface success/failure UI.
  /// Retrieves recent published GBP posts for anti-repetition context.
  Future<List<Map<String, dynamic>>> getRecentGbpPosts({int limit = 60}) {
    return _fs.getRecentGbpPosts(limit: limit);
  }

  Future<GbpResult> publishToGbp(ContentPost post) async {
    final locationId = _company?.gbpLocationId;
    if (locationId == null || locationId.isEmpty) {
      return GbpResult.failure(
        error: 'No GBP location configured. Set Location ID in Settings.',
        errorCode: 'GBP_NOT_CONFIGURED',
      );
    }

    // Build the full post text: caption + hashtags
    final summary = [
      post.suggestedCaption,
      if (post.suggestedHashtags.isNotEmpty) post.suggestedHashtags.join(' '),
    ].join('\n\n');

    // Use after photo as the primary post image; fall back to before photo
    final photoUrl = post.afterPhotoUrl.isNotEmpty
        ? post.afterPhotoUrl
        : post.beforePhotoUrl;

    // Build CTA from company phone if available
    final phone = _company?.phone ?? '';
    final ctaType = phone.isNotEmpty ? 'CALL' : 'LEARN_MORE';
    final ctaUrl  = phone.isNotEmpty
        ? 'tel:${phone.replaceAll(RegExp(r'[^\d+]'), '')}'
        : (_company?.website ?? '');

    final result = await GbpService.instance.publishPost(
      locationId:          locationId,
      summary:             summary,
      photoUrl:            photoUrl,
      callToActionType:    ctaType,
      callToActionUrl:     ctaUrl,
    );

    if (result.success) {
      // Mark as published in Firestore + local state
      updatePostStatus(post.id, ContentStatus.published);
      // Save to anti-repetition history so future AI generations avoid
      // repeating openings, closings, hashtags and phrases.
      _fs.savePublishedGbpPost(
        postId:   post.id,
        caption:  post.suggestedCaption,
        hashtags: post.suggestedHashtags,
        jobType:  post.projectSummary,
      );
      // Analytics: record google_post_published event
      AnalyticsService.recordEvent(
        companyId: _fs.companyId,
        eventType: ActivityEventType.googlePostPublished,
        metadata: {'post_id': post.id},
      );
    }

    return result;
  }

  // ─── Subscription ─────────────────────────────────────────────────────────
  // ─── Subscription (single plan — no tiers) ─────────────────────────────────
  ActiveSubscription _subscription = ActiveSubscription.none;
  ActiveSubscription get subscription => _subscription;
  bool get isInTrial => _subscription.isInTrial;
  int get trialDaysRemaining => _subscription.trialDaysRemaining;

  /// All features are available on the single plan.
  /// Kept for API compatibility — always returns true when app is accessible.
  bool canAccess(String featureKey) => _subscription.canUseApp;

  /// Starts a 14-day trial (no tier required — single plan).
  void startTrial({
    String? stripeCustomerId,
    String? stripeSubscriptionId,
  }) {
    final now = DateTime.now();
    final trialEnd = now.add(const Duration(days: 14));
    _subscription = ActiveSubscription(
      status: SubscriptionStatus.trial,
      trialStartDate: now,
      trialEndDate: trialEnd,
      stripeCustomerId: stripeCustomerId,
      stripeSubscriptionId: stripeSubscriptionId,
      purchasedSeats: TRPlan.includedSeats,
      extraSeats: 0,
    );
    notifyListeners();

    // Persist to Firestore so trial survives app restarts
    _fs.saveSubscription(
      status: SubscriptionStatus.trial.name,
      trialStartDate: now,
      trialEndDate: trialEnd,
      stripeCustomerId: stripeCustomerId,
      stripeSubscriptionId: stripeSubscriptionId,
    ).catchError((e) {
      if (kDebugMode) debugPrint('[AppState] startTrial error: $e');
    });
  }

  /// Activates a paid subscription after Stripe checkout.
  void activateSubscription({
    String? stripeCustomerId,
    String? stripeSubscriptionId,
    int extraSeats = 0,
  }) {
    final now = DateTime.now();
    _subscription = _subscription.copyWith(
      status: SubscriptionStatus.active,
      stripeCustomerId: stripeCustomerId,
      stripeSubscriptionId: stripeSubscriptionId,
      billingStartDate: now,
      nextBillingDate: now.add(const Duration(days: 30)),
      purchasedSeats: TRPlan.includedSeats + extraSeats,
      extraSeats: extraSeats,
    );
    notifyListeners();

    _fs.saveSubscription(
      status: SubscriptionStatus.active.name,
      trialStartDate: _subscription.trialStartDate,
      trialEndDate: _subscription.trialEndDate,
      stripeCustomerId: stripeCustomerId,
      stripeSubscriptionId: stripeSubscriptionId,
      purchasedSeats: TRPlan.includedSeats + extraSeats,
      extraSeats: extraSeats,
    ).catchError((e) {
      if (kDebugMode) debugPrint('[AppState] activateSubscription error: $e');
    });
  }

  /// Adds extra seats (called after Stripe seat upgrade confirms).
  void addSeats(int count) {
    final newExtra = _subscription.extraSeats + count;
    _subscription = _subscription.copyWith(
      purchasedSeats: TRPlan.includedSeats + newExtra,
      extraSeats: newExtra,
    );
    notifyListeners();

    _fs.saveSubscription(
      status: _subscription.status.name,
      trialStartDate: _subscription.trialStartDate,
      trialEndDate: _subscription.trialEndDate,
      stripeCustomerId: _subscription.stripeCustomerId,
      stripeSubscriptionId: _subscription.stripeSubscriptionId,
      purchasedSeats: _subscription.purchasedSeats,
      extraSeats: newExtra,
    ).catchError((e) {
      if (kDebugMode) debugPrint('[AppState] addSeats error: $e');
    });
  }

  // ─── Legacy compat: startTrialWithStripe → startTrial ─────────────────────
  void startTrialWithStripe({
    String? stripeCustomerId,
    String? stripeSubscriptionId,
  }) => startTrial(
    stripeCustomerId: stripeCustomerId,
    stripeSubscriptionId: stripeSubscriptionId,
  );

  // ─── Login ─────────────────────────────────────────────────────────────────

  /// Demo / preview mode login — skips real auth.
  Future<void> login() async {
    _isLoggedIn = true;
    _onboardingComplete = true;
    notifyListeners();
    await _initFirestoreStreams();
  }

  /// Called by SignInScreen / SignUpScreen after a successful Firebase Auth
  /// credential. Sets companyId to the Firebase UID so Firestore reads the
  /// correct company document.
  ///
  /// IMPORTANT: notifyListeners() fires BEFORE _initFirestoreStreams() so the
  /// MaterialApp Consumer rebuilds to MainShell immediately. Firestore data
  /// loads in the background — the UI shows sample data first, then updates
  /// as streams emit.
  void onFirebaseSignIn(User? firebaseUser) {
    debugPrint('[AppState] onFirebaseSignIn() — uid: ${firebaseUser?.uid}');
    if (firebaseUser == null) {
      debugPrint('[AppState] No firebase user — falling back to demo login');
      // Fire-and-forget demo login (does not block caller)
      login().catchError((e) {
        if (kDebugMode) debugPrint('[AppState] demo login error: $e');
      });
      return;
    }
    // Key all Firestore queries to the authenticated UID
    _fs.setCompanyId(firebaseUser.uid);
    _isLoggedIn = true;
    _onboardingComplete = true;
    debugPrint('[AppState] isLoggedIn = true — notifyListeners() → MainShell');
    notifyListeners(); // ← triggers navigation to MainShell IMMEDIATELY
    // Analytics: record login event (fire-and-forget — never blocks navigation)
    AnalyticsService.recordEvent(
      companyId: firebaseUser.uid,
      eventType: ActivityEventType.login,
      metadata: {'uid': firebaseUser.uid},
    );
    // Load Firestore data in background — never blocks navigation
    _initFirestoreStreams().catchError((e) {
      if (kDebugMode) debugPrint('[AppState] _initFirestoreStreams error: $e');
    });
    debugPrint('[AppState] _initFirestoreStreams() launched in background');
  }

  Future<void> completeOnboarding() async {
    _onboardingComplete = true;
    _isLoggedIn = true;
    notifyListeners();
    await _initFirestoreStreams();
  }

  /// Saves admin preference selections to Firestore.
  /// Called from the onboarding preferences step.
  void saveAdminPreferences(List<String> preferences) {
    // Update local company if loaded
    if (_company != null) {
      _company = Company(
        id: _company!.id,
        name: _company!.name,
        logoUrl: _company!.logoUrl,
        tradeCategory: _company!.tradeCategory,
        serviceArea: _company!.serviceArea,
        phone: _company!.phone,
        website: _company!.website,
        teamSize: _company!.teamSize,
        googleConnected: _company!.googleConnected,
        googleBusinessId: _company!.googleBusinessId,
        googleReviewLink: _company!.googleReviewLink,
        gbpLocationId: _company!.gbpLocationId,
        createdAt: _company!.createdAt,
        adminPreferences: preferences,
      );
      notifyListeners();
    }
    // Persist to Firestore (fire-and-forget)
    _fs.updateAdminPreferences(preferences).catchError((e) {
      if (kDebugMode) debugPrint('[AppState] saveAdminPreferences error: $e');
    });
  }

  /// Signs out of Firebase and resets all local state.
  Future<void> logout() async {
    _cancelStreams();
    await AuthService.instance.signOut();
    _isLoggedIn = false;
    _onboardingComplete = false;
    _currentUser = null;
    _company = null;
    _firestoreReady = false;
    // Reset to sample data
    _jobs = [];
    _posts = [];
    _reviews = [];
    _team = [];
    _templates = ProjectTemplate.defaultTemplates;
    _analytics = AnalyticsSummary.empty;
    _photoSubmissions = [];
    _lastKnownPendingCount = 0;
    _smsLog.clear();
    notifyListeners();
  }

  // ─── Firestore Stream Initialization ──────────────────────────────────────
  Future<void> _initFirestoreStreams() async {
    // Skip entirely when Firebase credentials are not present — app runs on
    // sample data in preview / demo mode.
    if (!AppConfig.isFirebaseConfigured) {
      if (kDebugMode) debugPrint('AppState: Firebase not configured — using sample data only.');
      _firestoreReady = false;
      notifyListeners();
      return;
    }
    try {
      const fsTimeout = Duration(seconds: 8); // per-call — never hangs navigation

      // Load company + user from Firestore first
      final fsCompany = await _fs.getCompany().timeout(fsTimeout, onTimeout: () {
        if (kDebugMode) debugPrint('[AppState] getCompany() timed out');
        return null;
      });
      if (fsCompany != null) {
        _company = fsCompany;
        _googleConnected = fsCompany.googleConnected;
      }

      final fsUser = await _fs.getCurrentUser().timeout(fsTimeout, onTimeout: () {
        if (kDebugMode) debugPrint('[AppState] getCurrentUser() timed out');
        return null;
      });
      if (fsUser != null) _currentUser = fsUser;

      // Load subscription from Firestore.
      // If no record exists (brand new user), auto-start a 14-day trial
      // so they land directly in the app without hitting the gate.
      final fsSub = await _fs.getSubscription().timeout(fsTimeout, onTimeout: () {
        if (kDebugMode) debugPrint('[AppState] getSubscription() timed out — defaulting to none');
        return ActiveSubscription.none;
      });

      if (fsSub.status == SubscriptionStatus.none) {
        // Brand new user — auto-start 14-day trial and persist it
        if (kDebugMode) debugPrint('[AppState] New user — auto-starting 14-day trial');
        startTrial();
      } else {
        _subscription = fsSub;
      }

      // Analytics: write monthly snapshot with subscription info (fire-and-forget)
      AnalyticsService.writeMonthlySnapshot(
        companyId:          _fs.companyId,
        subscriptionStatus: _subscription.status.name,
        seatCount:          _subscription.purchasedSeats,
      );

      // Load analytics
      final fsAnalytics = await _fs.getAnalytics().timeout(fsTimeout, onTimeout: () {
        if (kDebugMode) debugPrint('[AppState] getAnalytics() timed out');
        return AnalyticsSummary.empty;
      });
      _analytics = fsAnalytics;

      notifyListeners();

      // Subscribe to real-time streams
      _jobsSub = _fs.jobsStream().listen((jobs) {
        _jobs = jobs;
        notifyListeners();
      }, onError: (e) {
        if (kDebugMode) debugPrint('Jobs stream error: $e');
      });

      _postsSub = _fs.postsStream().listen((posts) {
        _posts = posts;
        notifyListeners();
      }, onError: (e) {
        if (kDebugMode) debugPrint('Posts stream error: $e');
      });

      _reviewsSub = _fs.reviewsStream().listen((reviews) {
        _reviews = reviews;
        notifyListeners();
      }, onError: (e) {
        if (kDebugMode) debugPrint('Reviews stream error: $e');
      });

      _teamSub = _fs.teamStream().listen((team) {
        _team = team;
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
        _templates = templates.isNotEmpty ? templates : ProjectTemplate.defaultTemplates;
        notifyListeners();
      }, onError: (e) {
        if (kDebugMode) debugPrint('Templates stream error: $e');
      });

      _pendingInvitesSub = _fs.pendingInvitesStream().listen((invites) {
        _pendingInvites = invites;
        notifyListeners();
      }, onError: (e) {
        if (kDebugMode) debugPrint('Pending invites stream error: $e');
      });

      _photoSubmissionsSub = _fs.photoSubmissionsStream().listen((subs) {
        final newPending = subs.where((s) => s.status == PhotoSubmissionStatus.pending).length;
        _photoSubmissions = subs;
        notifyListeners();

        // Fire new-pending notification when count increases.
        // Only fires for admin-capable roles; skips the very first load
        // (when _lastKnownPendingCount == 0 and we haven't set a baseline yet).
        if (canApprovePhotos &&
            _lastKnownPendingCount > 0 &&
            newPending > _lastKnownPendingCount) {
          final arrived = newPending - _lastKnownPendingCount;
          onNewPendingSubmissions?.call(arrived);
        }
        _lastKnownPendingCount = newPending;
      }, onError: (e) {
        if (kDebugMode) debugPrint('PhotoSubmissions stream error: $e');
      });

      // Live subscription stream — picks up Stripe webhook changes
      // (trial→active on first payment, past_due on card failure, etc.)
      // without requiring an app restart.
      _subscriptionSub = _fs.subscriptionStream().listen((sub) {
        // Only overwrite if Firestore returns a real status (not 'none').
        // 'none' means the company doc exists but has no subscription map yet —
        // that's normal for the instant after account creation, before
        // startTrial() writes the first record.
        if (sub.status != SubscriptionStatus.none) {
          _subscription = sub;
          notifyListeners();
          if (kDebugMode) {
            debugPrint('[AppState] subscriptionStream → status: ${sub.status.name}, '
                'trialEnd: ${sub.trialEndDate}, days: ${sub.trialDaysRemaining}');
          }
        }
      }, onError: (e) {
        if (kDebugMode) debugPrint('Subscription stream error: $e');
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
    _pendingInvitesSub?.cancel();
    _subscriptionSub?.cancel();
  }

  @override
  void dispose() {
    _cancelStreams();
    _authStateSub?.cancel(); // cancel auth listener when AppState is torn down
    super.dispose();
  }
}
