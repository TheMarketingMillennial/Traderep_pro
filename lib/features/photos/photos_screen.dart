import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/services/app_state.dart';
import '../../shared/widgets/tr_widgets.dart';
import '../../shared/models/models.dart';

class PhotosScreen extends StatefulWidget {
  const PhotosScreen({super.key});

  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // ignore: unused_field
  bool _showingGuidance = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: TRColors.navyDeep,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCaptureTab(context, state),
                  _buildGalleryTab(context, state),
                  _buildAnalysisTab(context, state),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          const Expanded(child: Text('Photos', style: TextStyle(
            color: TRColors.white, fontSize: 24, fontWeight: FontWeight.w800,
          ))),
          GestureDetector(
            onTap: () => _openCamera(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: TRColors.gold,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt_rounded, color: TRColors.navyDeep, size: 18),
                  SizedBox(width: 6),
                  Text('Capture', style: TextStyle(
                    color: TRColors.navyDeep, fontSize: 13, fontWeight: FontWeight.w700,
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = ['Capture Guide', 'Gallery', 'AI Analysis'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final selected = _tabController.index == entry.key;
          return Expanded(child: GestureDetector(
            onTap: () {
              _tabController.animateTo(entry.key);
              setState(() {});
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: selected ? TRColors.gold : TRColors.cardDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: selected ? TRColors.gold : TRColors.divider),
              ),
              child: Text(entry.value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? TRColors.navyDeep : TRColors.grayLight,
                  fontSize: 11, fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ));
        }).toList(),
      ),
    );
  }

  Widget _buildCaptureTab(BuildContext context, AppState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Select Job
          const Text('Select Active Job', style: TextStyle(
            color: TRColors.grayLight, fontSize: 13, fontWeight: FontWeight.w600,
          )),
          const SizedBox(height: 8),
          ...state.activeJobs.take(3).map((job) => _JobSelectTile(
            job: job,
            onTap: () => _openCameraForJob(context, job),
          )),
          const SizedBox(height: 20),

          // AI Shot Guide
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [TRColors.cardDark, TRColors.navyMid],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: TRColors.gold.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: TRColors.gold, size: 20),
                    SizedBox(width: 8),
                    Text('AI Photo Framing Guide', style: TextStyle(
                      color: TRColors.gold, fontSize: 15, fontWeight: FontWeight.w700,
                    )),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Our AI framing assistant gives real-time guidance to ensure every photo is marketing-ready.',
                  style: TextStyle(color: TRColors.grayLight, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 16),
                ..._framingTips.map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: (tip['color'] as Color).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(tip['icon'] as IconData, color: tip['color'] as Color, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tip['title'] as String, style: const TextStyle(
                            color: TRColors.white, fontSize: 13, fontWeight: FontWeight.w600,
                          )),
                          Text(tip['desc'] as String, style: const TextStyle(
                            color: TRColors.grayMid, fontSize: 12,
                          )),
                        ],
                      )),
                    ],
                  ),
                )),
              ],
            ),
          ),

          const SizedBox(height: 20),
          // Templates
          const Text('Photo Templates', style: TextStyle(
            color: TRColors.white, fontSize: 17, fontWeight: FontWeight.w700,
          )),
          const SizedBox(height: 12),
          ...state.templates.map((tmpl) => _TemplateTile(template: tmpl)),
        ],
      ),
    );
  }

  Widget _buildGalleryTab(BuildContext context, AppState state) {
    return const Center(
      child: TREmptyState(
        icon: Icons.photo_library_outlined,
        title: 'Your Photo Gallery',
        subtitle: 'Photos captured on jobs will appear here, organized by project and date.',
      ),
    );
  }

  Widget _buildAnalysisTab(BuildContext context, AppState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TRColors.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: TRColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.psychology_rounded, color: TRColors.gold, size: 22),
                    SizedBox(width: 8),
                    Text('AI Photo Analysis Engine', style: TextStyle(
                      color: TRColors.white, fontSize: 15, fontWeight: FontWeight.w700,
                    )),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'TradeRep automatically scores your project photos and selects the best before/after pairs for marketing.',
                  style: TextStyle(color: TRColors.grayLight, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 16),
                const Text('Sample Score — Last Analyzed Photo', style: TextStyle(
                  color: TRColors.grayLight, fontSize: 12, fontWeight: FontWeight.w600,
                )),
                const SizedBox(height: 12),
                PhotoScoreBar(label: 'Lighting Quality', score: 0.88),
                const SizedBox(height: 8),
                PhotoScoreBar(label: 'Framing & Composition', score: 0.75),
                const SizedBox(height: 8),
                PhotoScoreBar(label: 'Image Sharpness', score: 0.92),
                const SizedBox(height: 8),
                PhotoScoreBar(label: 'Scene Cleanliness', score: 0.84),
                const SizedBox(height: 8),
                PhotoScoreBar(label: 'Visual Transformation', score: 0.96, color: TRColors.success),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TRColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: TRColors.success.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: TRColors.success, size: 18),
                      SizedBox(width: 8),
                      Expanded(child: Text(
                        'Excellent transformation score! This pair will make a great Google post.',
                        style: TextStyle(color: TRColors.success, fontSize: 12, fontWeight: FontWeight.w600),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Output formats
          const Text('Generated Outputs', style: TextStyle(
            color: TRColors.white, fontSize: 17, fontWeight: FontWeight.w700,
          )),
          const SizedBox(height: 12),
          ..._outputFormats.map((fmt) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: TRColors.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: TRColors.divider),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (fmt['color'] as Color).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(fmt['icon'] as IconData, color: fmt['color'] as Color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fmt['title'] as String, style: const TextStyle(
                      color: TRColors.white, fontSize: 14, fontWeight: FontWeight.w700,
                    )),
                    Text(fmt['desc'] as String, style: const TextStyle(
                      color: TRColors.grayMid, fontSize: 12,
                    )),
                  ],
                )),
                Icon(Icons.download_rounded, color: TRColors.gold, size: 20),
              ],
            ),
          )),
        ],
      ),
    );
  }

  static final _framingTips = [
    {'title': 'Doorway Shot', 'desc': 'Stand in doorway for a full-room capture', 'icon': Icons.door_front_door_rounded, 'color': TRColors.info},
    {'title': 'Wide Angle', 'desc': 'Step back to show the complete scope of work', 'icon': Icons.open_in_full_rounded, 'color': TRColors.statusLead},
    {'title': 'Detail Close-Up', 'desc': 'Move close to highlight craftsmanship', 'icon': Icons.center_focus_strong_rounded, 'color': TRColors.warning},
    {'title': 'Landscape Mode', 'desc': 'Rotate for vanities, counters, and panels', 'icon': Icons.screen_rotation_rounded, 'color': TRColors.success},
  ];

  static final _outputFormats = [
    {'title': 'Best Before/After Pair', 'desc': 'Optimally matched transformation photo', 'icon': Icons.compare_rounded, 'color': TRColors.gold},
    {'title': 'Google-Ready Image', 'desc': '1200×900px, optimized for GBP posts', 'icon': Icons.business_rounded, 'color': TRColors.info},
    {'title': 'Social Media Crop', 'desc': '1080×1080px square for Instagram/Facebook', 'icon': Icons.crop_square_rounded, 'color': TRColors.statusLead},
    {'title': 'Portfolio Image', 'desc': '16:9 widescreen for website gallery', 'icon': Icons.web_rounded, 'color': TRColors.success},
  ];

  void _openCamera(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Camera with AI framing guide — available on mobile device'),
        backgroundColor: TRColors.navyMid,
      ),
    );
  }

  void _openCameraForJob(BuildContext context, Job job) {
    showModalBottomSheet(
      context: context,
      backgroundColor: TRColors.cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CameraGuideSheet(job: job),
    );
  }
}

class _JobSelectTile extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;
  const _JobSelectTile({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: TRColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: TRColors.divider),
        ),
        child: Row(
          children: [
            const Icon(Icons.work_rounded, color: TRColors.grayMid, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.customerName, style: const TextStyle(
                  color: TRColors.white, fontSize: 14, fontWeight: FontWeight.w600,
                )),
                Text(job.jobType, style: const TextStyle(color: TRColors.grayMid, fontSize: 12)),
              ],
            )),
            StatusBadge(status: job.status, compact: true),
            const SizedBox(width: 8),
            const Icon(Icons.camera_alt_rounded, color: TRColors.gold, size: 18),
          ],
        ),
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  final ProjectTemplate template;
  const _TemplateTile({required this.template});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TRColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TRColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(template.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(template.name, style: const TextStyle(
                color: TRColors.white, fontSize: 14, fontWeight: FontWeight.w700,
              )),
              const Spacer(),
              Text('${template.shots.length} shots', style: const TextStyle(
                color: TRColors.grayMid, fontSize: 12,
              )),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6, runSpacing: 4,
            children: template.shots.map((shot) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: TRColors.cardMid,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: TRColors.divider),
              ),
              child: Text(shot.name, style: const TextStyle(color: TRColors.grayLight, fontSize: 11)),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _CameraGuideSheet extends StatefulWidget {
  final Job job;
  const _CameraGuideSheet({required this.job});

  @override
  State<_CameraGuideSheet> createState() => _CameraGuideSheetState();
}

class _CameraGuideSheetState extends State<_CameraGuideSheet> {
  int _currentShot = 0;
  PhotoType _phase = PhotoType.before;

  static const _instructions = [
    'Stand in the doorway and capture the full scope of the project area',
    'Move left slightly to show the complete work zone',
    'Step back — capture wide angle to show the full roof/area',
    'Center the feature element in frame, keep horizon level',
    'Move in close to capture the quality of craftsmanship detail',
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollController) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: TRColors.divider, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(children: [
              const Icon(Icons.auto_awesome_rounded, color: TRColors.gold, size: 20),
              const SizedBox(width: 8),
              Text('AI Framing Guide — ${widget.job.customerName}',
                style: const TextStyle(color: TRColors.white, fontSize: 15, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 20),
            // Phase selector
            Row(children: PhotoType.values.map((type) {
              final selected = _phase == type;
              final colors = {
                PhotoType.before: TRColors.info,
                PhotoType.progress: TRColors.warning,
                PhotoType.after: TRColors.success,
              };
              return Expanded(child: GestureDetector(
                onTap: () => setState(() => _phase = type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? colors[type]!.withValues(alpha: 0.2) : TRColors.cardMid,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: selected ? colors[type]! : TRColors.divider),
                  ),
                  child: Text(type.name.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? colors[type]! : TRColors.grayMid,
                      fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5,
                    )),
                ),
              ));
            }).toList()),
            const SizedBox(height: 20),
            // Camera viewfinder simulation
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: TRColors.gold.withValues(alpha: 0.4), width: 2),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      color: TRColors.navyDeep,
                      child: const Center(child: Icon(Icons.camera_rounded, color: TRColors.grayMid, size: 60)),
                    ),
                  ),
                  // Grid overlay
                  CustomPaint(painter: _GridPainter()),
                  // Instruction overlay
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                        ),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.my_location_rounded, color: TRColors.gold, size: 14),
                          const SizedBox(width: 6),
                          Expanded(child: Text(
                            _instructions[_currentShot % _instructions.length],
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Photo captured!'), backgroundColor: TRColors.success),
                    );
                  },
                  child: Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: TRColors.gold,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: TRColors.gold.withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 2)],
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: TRColors.navyDeep, size: 28),
                  ),
                ),
                Column(
                  children: [
                    Text('Shot ${_currentShot + 1} of 5', style: const TextStyle(color: TRColors.grayLight, fontSize: 13)),
                    const Text('Tap camera to capture', style: TextStyle(color: TRColors.grayMid, fontSize: 11)),
                  ],
                ),
                GestureDetector(
                  onTap: () => setState(() => _currentShot = (_currentShot + 1) % 5),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: TRColors.cardMid,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: TRColors.divider),
                    ),
                    child: const Text('Next Shot →', style: TextStyle(
                      color: TRColors.gold, fontSize: 13, fontWeight: FontWeight.w600,
                    )),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 0.5;

    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), paint);
    canvas.drawLine(Offset(size.width * 2 / 3, 0), Offset(size.width * 2 / 3, size.height), paint);
    canvas.drawLine(Offset(0, size.height / 3), Offset(size.width, size.height / 3), paint);
    canvas.drawLine(Offset(0, size.height * 2 / 3), Offset(size.width, size.height * 2 / 3), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
