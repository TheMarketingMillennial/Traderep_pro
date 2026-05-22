import 'package:flutter/material.dart';

// ─── User Roles ──────────────────────────────────────────────────────────────
enum UserRole {
  admin,
  officeManager,
  salesRep,
  crewLead,
  crewMember;

  String get displayName {
    switch (this) {
      case UserRole.admin:         return 'Admin';
      case UserRole.officeManager: return 'Office Manager';
      case UserRole.salesRep:      return 'Sales Rep';
      case UserRole.crewLead:      return 'Crew Lead';
      case UserRole.crewMember:    return 'Crew Member';
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.admin:         return Icons.admin_panel_settings_rounded;
      case UserRole.officeManager: return Icons.business_center_rounded;
      case UserRole.salesRep:      return Icons.handshake_rounded;
      case UserRole.crewLead:      return Icons.engineering_rounded;
      case UserRole.crewMember:    return Icons.construction_rounded;
    }
  }
}

// ─── Job Status ───────────────────────────────────────────────────────────────
enum JobStatus {
  lead,
  scheduled,
  inProgress,
  awaitingApproval,
  completed;

  String get displayName {
    switch (this) {
      case JobStatus.lead:             return 'Lead';
      case JobStatus.scheduled:        return 'Scheduled';
      case JobStatus.inProgress:       return 'In Progress';
      case JobStatus.awaitingApproval: return 'Awaiting Approval';
      case JobStatus.completed:        return 'Completed';
    }
  }
}

// ─── Trade Category ──────────────────────────────────────────────────────────
enum TradeCategory {
  generalContractor,
  roofing,
  hvac,
  plumbing,
  electrical,
  flooring,
  painting,
  remodeling,
  homeServices,
  construction;

  String get displayName {
    switch (this) {
      case TradeCategory.generalContractor: return 'General Contractor';
      case TradeCategory.roofing:           return 'Roofing';
      case TradeCategory.hvac:              return 'HVAC';
      case TradeCategory.plumbing:          return 'Plumbing';
      case TradeCategory.electrical:        return 'Electrical';
      case TradeCategory.flooring:          return 'Flooring';
      case TradeCategory.painting:          return 'Painting';
      case TradeCategory.remodeling:        return 'Remodeling';
      case TradeCategory.homeServices:      return 'Home Services';
      case TradeCategory.construction:      return 'Construction';
    }
  }

  String get emoji {
    switch (this) {
      case TradeCategory.generalContractor: return '🏗️';
      case TradeCategory.roofing:           return '🏠';
      case TradeCategory.hvac:              return '❄️';
      case TradeCategory.plumbing:          return '🔧';
      case TradeCategory.electrical:        return '⚡';
      case TradeCategory.flooring:          return '🪵';
      case TradeCategory.painting:          return '🎨';
      case TradeCategory.remodeling:        return '🔨';
      case TradeCategory.homeServices:      return '🏡';
      case TradeCategory.construction:      return '👷';
    }
  }
}

// ─── Photo Type ───────────────────────────────────────────────────────────────
enum PhotoType { before, progress, after }

// ─── Content Status ───────────────────────────────────────────────────────────
enum ContentStatus { pending, approved, rejected, scheduled, published }

// ─────────────────────────────────────────────────────────────────────────────
// COMPANY MODEL
// ─────────────────────────────────────────────────────────────────────────────
class Company {
  final String id;
  final String name;
  final String? logoUrl;
  final String tradeCategory;
  final String serviceArea;
  final String phone;
  final String? website;
  final int teamSize;
  final bool googleConnected;
  final String? googleBusinessId;
  final DateTime createdAt;

  const Company({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.tradeCategory,
    required this.serviceArea,
    required this.phone,
    this.website,
    required this.teamSize,
    this.googleConnected = false,
    this.googleBusinessId,
    required this.createdAt,
  });

  static Company get sample => Company(
    id: 'co_001',
    name: 'Apex Roofing & Construction',
    tradeCategory: 'Roofing',
    serviceArea: 'Denver, CO (50-mile radius)',
    phone: '(720) 555-0189',
    website: 'apexroofingco.com',
    teamSize: 12,
    googleConnected: true,
    createdAt: DateTime(2024, 1, 15),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// USER MODEL
// ─────────────────────────────────────────────────────────────────────────────
class TRUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String companyId;
  final String? avatarUrl;
  final bool isActive;
  final DateTime joinedAt;

  const TRUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.companyId,
    this.avatarUrl,
    this.isActive = true,
    required this.joinedAt,
  });

  static TRUser get sample => TRUser(
    id: 'usr_001',
    name: 'Mike Torres',
    email: 'mike@apexroofing.com',
    phone: '(720) 555-0190',
    role: UserRole.admin,
    companyId: 'co_001',
    joinedAt: DateTime(2024, 1, 15),
  );

  static List<TRUser> get sampleTeam => [
    TRUser(id: 'usr_001', name: 'Mike Torres', email: 'mike@apex.com', phone: '720-555-0190', role: UserRole.admin, companyId: 'co_001', joinedAt: DateTime(2024, 1, 15)),
    TRUser(id: 'usr_002', name: 'Sarah Chen', email: 'sarah@apex.com', phone: '720-555-0191', role: UserRole.officeManager, companyId: 'co_001', joinedAt: DateTime(2024, 2, 1)),
    TRUser(id: 'usr_003', name: 'Jake Rivera', email: 'jake@apex.com', phone: '720-555-0192', role: UserRole.crewLead, companyId: 'co_001', joinedAt: DateTime(2024, 2, 15)),
    TRUser(id: 'usr_004', name: 'Tom Bradley', email: 'tom@apex.com', phone: '720-555-0193', role: UserRole.crewMember, companyId: 'co_001', joinedAt: DateTime(2024, 3, 1)),
    TRUser(id: 'usr_005', name: 'Luis Mendez', email: 'luis@apex.com', phone: '720-555-0194', role: UserRole.salesRep, companyId: 'co_001', joinedAt: DateTime(2024, 3, 10)),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// JOB MODEL
// ─────────────────────────────────────────────────────────────────────────────
class Job {
  final String id;
  final String companyId;
  final String customerName;
  final String address;
  final String phone;
  final String email;
  final String jobType;
  final String templateId;
  final JobStatus status;
  final String? crewLeadId;
  final List<String> crewMemberIds;
  final DateTime? startDate;
  final DateTime? completionDate;
  final String? notes;
  final List<JobPhoto> photos;
  final bool reviewSent;
  final DateTime createdAt;

  const Job({
    required this.id,
    required this.companyId,
    required this.customerName,
    required this.address,
    required this.phone,
    required this.email,
    required this.jobType,
    required this.templateId,
    required this.status,
    this.crewLeadId,
    this.crewMemberIds = const [],
    this.startDate,
    this.completionDate,
    this.notes,
    this.photos = const [],
    this.reviewSent = false,
    required this.createdAt,
  });

  static List<Job> get sampleJobs => [
    Job(
      id: 'job_001', companyId: 'co_001',
      customerName: 'Robert & Linda Hayes',
      address: '4521 Oak Street, Denver, CO 80203',
      phone: '(720) 555-1234', email: 'hayes@email.com',
      jobType: 'Full Roof Replacement', templateId: 'tmpl_roofing',
      status: JobStatus.inProgress,
      crewLeadId: 'usr_003',
      startDate: DateTime.now().subtract(const Duration(days: 2)),
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      photos: [],
    ),
    Job(
      id: 'job_002', companyId: 'co_001',
      customerName: 'Central Park HOA',
      address: '100 Park Ave, Denver, CO 80205',
      phone: '(720) 555-5678', email: 'hoa@centralparkdenver.com',
      jobType: 'Commercial Roof Repair', templateId: 'tmpl_roofing',
      status: JobStatus.scheduled,
      startDate: DateTime.now().add(const Duration(days: 3)),
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      photos: [],
    ),
    Job(
      id: 'job_003', companyId: 'co_001',
      customerName: 'David Kim',
      address: '789 Maple Drive, Lakewood, CO 80226',
      phone: '(720) 555-9012', email: 'dkim@gmail.com',
      jobType: 'Storm Damage Repair', templateId: 'tmpl_roofing',
      status: JobStatus.completed,
      startDate: DateTime.now().subtract(const Duration(days: 10)),
      completionDate: DateTime.now().subtract(const Duration(days: 1)),
      reviewSent: true,
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      photos: [],
    ),
    Job(
      id: 'job_004', companyId: 'co_001',
      customerName: 'Maria Rodriguez',
      address: '234 Elm Blvd, Aurora, CO 80012',
      phone: '(720) 555-3456', email: 'mrodriguez@yahoo.com',
      jobType: 'Roof Inspection + Repair', templateId: 'tmpl_roofing',
      status: JobStatus.awaitingApproval,
      startDate: DateTime.now().subtract(const Duration(days: 1)),
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      photos: [],
    ),
    Job(
      id: 'job_005', companyId: 'co_001',
      customerName: 'Sunrise Properties LLC',
      address: '501 Commerce St, Denver, CO 80201',
      phone: '(720) 555-7890', email: 'ops@sunriseprops.com',
      jobType: 'New Construction Roofing', templateId: 'tmpl_roofing',
      status: JobStatus.lead,
      createdAt: DateTime.now(),
      photos: [],
    ),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// JOB PHOTO MODEL
// ─────────────────────────────────────────────────────────────────────────────
class JobPhoto {
  final String id;
  final String jobId;
  final PhotoType type;
  final String url;
  final String? templateSlot;
  final double? lightingScore;
  final double? framingScore;
  final double? sharpnessScore;
  final double? overallScore;
  final String? aiCaption;
  final DateTime uploadedAt;
  final String uploadedBy;

  const JobPhoto({
    required this.id,
    required this.jobId,
    required this.type,
    required this.url,
    this.templateSlot,
    this.lightingScore,
    this.framingScore,
    this.sharpnessScore,
    this.overallScore,
    this.aiCaption,
    required this.uploadedAt,
    required this.uploadedBy,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// PROJECT TEMPLATE MODEL
// ─────────────────────────────────────────────────────────────────────────────
class ProjectTemplate {
  final String id;
  final String name;
  final String tradeCategory;
  final String emoji;
  final List<TemplateShot> shots;

  const ProjectTemplate({
    required this.id,
    required this.name,
    required this.tradeCategory,
    required this.emoji,
    required this.shots,
  });

  static List<ProjectTemplate> get defaultTemplates => [
    ProjectTemplate(
      id: 'tmpl_roofing',
      name: 'Roofing Job',
      tradeCategory: 'Roofing',
      emoji: '🏠',
      shots: [
        TemplateShot(id: 's1', name: 'Front Elevation', instruction: 'Stand back from the house, capture the full front roofline', phase: PhotoType.before),
        TemplateShot(id: 's2', name: 'Damage Area', instruction: 'Move close to document the damaged shingles or area', phase: PhotoType.before),
        TemplateShot(id: 's3', name: 'Completed Roof', instruction: 'Same angle as front elevation shot — show the new roof', phase: PhotoType.after),
        TemplateShot(id: 's4', name: 'Detail Close-Up', instruction: 'Capture ridge cap or flashing detail work', phase: PhotoType.after),
        TemplateShot(id: 's5', name: 'Cleanup Photo', instruction: 'Show clean yard with no debris', phase: PhotoType.after),
      ],
    ),
    ProjectTemplate(
      id: 'tmpl_bathroom',
      name: 'Bathroom Remodel',
      tradeCategory: 'Remodeling',
      emoji: '🚿',
      shots: [
        TemplateShot(id: 's1', name: 'Doorway Shot', instruction: 'Stand in doorway, capture the whole bathroom', phase: PhotoType.before),
        TemplateShot(id: 's2', name: 'Vanity Shot', instruction: 'Center the vanity in frame, landscape orientation', phase: PhotoType.before),
        TemplateShot(id: 's3', name: 'Shower Before', instruction: 'Capture the existing shower area', phase: PhotoType.before),
        TemplateShot(id: 's4', name: 'Completed Vanity', instruction: 'Center the new vanity — match before angle', phase: PhotoType.after),
        TemplateShot(id: 's5', name: 'Completed Shower', instruction: 'Capture the finished shower/tile work', phase: PhotoType.after),
        TemplateShot(id: 's6', name: 'Final Wide Shot', instruction: 'Doorway angle — show full transformed bathroom', phase: PhotoType.after),
      ],
    ),
    ProjectTemplate(
      id: 'tmpl_hvac',
      name: 'HVAC Installation',
      tradeCategory: 'HVAC',
      emoji: '❄️',
      shots: [
        TemplateShot(id: 's1', name: 'Old System', instruction: 'Capture the existing unit — include model label if visible', phase: PhotoType.before),
        TemplateShot(id: 's2', name: 'Install Location', instruction: 'Document the installation area — pad, ductwork', phase: PhotoType.progress),
        TemplateShot(id: 's3', name: 'Completed System', instruction: 'Wide shot of the new installed unit', phase: PhotoType.after),
        TemplateShot(id: 's4', name: 'Thermostat', instruction: 'Photograph the new thermostat display', phase: PhotoType.after),
      ],
    ),
    ProjectTemplate(
      id: 'tmpl_painting',
      name: 'Painting',
      tradeCategory: 'Painting',
      emoji: '🎨',
      shots: [
        TemplateShot(id: 's1', name: 'Room Before', instruction: 'Wide shot of the room to be painted', phase: PhotoType.before),
        TemplateShot(id: 's2', name: 'Wall Close-Up', instruction: 'Show existing paint condition or damage', phase: PhotoType.before),
        TemplateShot(id: 's3', name: 'Room After', instruction: 'Same wide angle — show the color transformation', phase: PhotoType.after),
        TemplateShot(id: 's4', name: 'Trim Detail', instruction: 'Close-up of crisp trim lines and edges', phase: PhotoType.after),
      ],
    ),
  ];
}

class TemplateShot {
  final String id;
  final String name;
  final String instruction;
  final PhotoType phase;

  const TemplateShot({
    required this.id,
    required this.name,
    required this.instruction,
    required this.phase,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTENT POST MODEL
// ─────────────────────────────────────────────────────────────────────────────
class ContentPost {
  final String id;
  final String jobId;
  final String beforePhotoUrl;
  final String afterPhotoUrl;
  final String suggestedCaption;
  final List<String> suggestedHashtags;
  final String projectSummary;
  final ContentStatus status;
  final DateTime? scheduledFor;
  final DateTime createdAt;

  const ContentPost({
    required this.id,
    required this.jobId,
    required this.beforePhotoUrl,
    required this.afterPhotoUrl,
    required this.suggestedCaption,
    required this.suggestedHashtags,
    required this.projectSummary,
    required this.status,
    this.scheduledFor,
    required this.createdAt,
  });

  static List<ContentPost> get samplePosts => [
    ContentPost(
      id: 'post_001',
      jobId: 'job_003',
      beforePhotoUrl: 'https://images.unsplash.com/photo-1570129477492-45c003edd2be?w=400',
      afterPhotoUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400',
      suggestedCaption: '🏠 Another beautiful roof transformation in Denver! This storm-damaged roof was holding our clients back — now they have total peace of mind with a brand new 50-year architectural shingle system. The difference speaks for itself. 💛 #ApexRoofing',
      suggestedHashtags: ['#Roofing', '#DenverRoofing', '#BeforeAfter', '#HomeImprovement', '#RoofReplacement', '#ContractorLife'],
      projectSummary: 'Full roof replacement following hail storm damage. Removed existing 3-tab shingles, installed 50-year architectural shingles with ice & water shield, new ridge cap and flashing.',
      status: ContentStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ContentPost(
      id: 'post_002',
      jobId: 'job_001',
      beforePhotoUrl: 'https://images.unsplash.com/photo-1509358271058-acd22cc93898?w=400',
      afterPhotoUrl: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=400',
      suggestedCaption: '✅ Roof replacement complete at this beautiful Denver home. Our crew knocked it out in one day — clean, efficient, and built to last. Ask us about our free inspection! 👷‍♂️',
      suggestedHashtags: ['#RoofingContractor', '#Denver', '#HomeRepair', '#QualityWork', '#Trades'],
      projectSummary: 'Residential roof replacement, 2,400 sq ft. GAF Timberline HDZ shingles, upgraded ventilation, 6 new pipe boots.',
      status: ContentStatus.approved,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// REVIEW MODEL
// ─────────────────────────────────────────────────────────────────────────────
class ReviewRequest {
  final String id;
  final String jobId;
  final String customerName;
  final String sentTo;
  final String method; // 'sms' or 'email'
  final DateTime sentAt;
  final bool opened;
  final bool reviewed;
  final int? starRating;

  const ReviewRequest({
    required this.id,
    required this.jobId,
    required this.customerName,
    required this.sentTo,
    required this.method,
    required this.sentAt,
    this.opened = false,
    this.reviewed = false,
    this.starRating,
  });

  static List<ReviewRequest> get sampleReviews => [
    ReviewRequest(id: 'rv_001', jobId: 'job_003', customerName: 'David Kim', sentTo: '(720) 555-9012', method: 'sms', sentAt: DateTime.now().subtract(const Duration(days: 1)), opened: true, reviewed: true, starRating: 5),
    ReviewRequest(id: 'rv_002', jobId: 'job_002', customerName: 'Central Park HOA', sentTo: 'hoa@centralparkdenver.com', method: 'email', sentAt: DateTime.now().subtract(const Duration(days: 3)), opened: true, reviewed: false),
    ReviewRequest(id: 'rv_003', jobId: 'job_001', customerName: 'Robert & Linda Hayes', sentTo: '(720) 555-1234', method: 'sms', sentAt: DateTime.now().subtract(const Duration(hours: 6)), opened: false, reviewed: false),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// ANALYTICS MODEL
// ─────────────────────────────────────────────────────────────────────────────
class AnalyticsSummary {
  final int projectsCompleted;
  final int reviewsGenerated;
  final int photosUploaded;
  final int googlePosts;
  final double reviewResponseRate;
  final double avgRating;
  final double avgPhotoScore;
  final List<MonthlyData> monthlyData;

  const AnalyticsSummary({
    required this.projectsCompleted,
    required this.reviewsGenerated,
    required this.photosUploaded,
    required this.googlePosts,
    required this.reviewResponseRate,
    this.avgRating = 4.8,
    this.avgPhotoScore = 87.4,
    required this.monthlyData,
  });

  static AnalyticsSummary get sample => const AnalyticsSummary(
    projectsCompleted: 47,
    reviewsGenerated: 38,
    photosUploaded: 284,
    googlePosts: 22,
    reviewResponseRate: 0.81,
    avgRating: 4.8,
    avgPhotoScore: 87.4,
    monthlyData: [
      MonthlyData('Nov', 8, 6),
      MonthlyData('Dec', 11, 9),
      MonthlyData('Jan', 9, 7),
      MonthlyData('Feb', 14, 11),
      MonthlyData('Mar', 16, 13),
      MonthlyData('Apr', 19, 15),
    ],
  );
}

class MonthlyData {
  final String month;
  final int jobs;
  final int reviews;
  const MonthlyData(this.month, this.jobs, this.reviews);
}
