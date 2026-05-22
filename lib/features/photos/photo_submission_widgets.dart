// photo_submission_widgets.dart — TradeRep Pro
// Crew photo submission bottom sheet.
// Any role can submit; admin/officeManager/salesRep can approve.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';
import '../../shared/services/app_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PUBLIC HELPER — call from anywhere in the app
// ─────────────────────────────────────────────────────────────────────────────

Future<void> showSubmitPhotosSheet(BuildContext context, {Job? preselectedJob}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => SubmitPhotosSheet(preselectedJob: preselectedJob),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SUBMIT PHOTOS SHEET
// ─────────────────────────────────────────────────────────────────────────────

class SubmitPhotosSheet extends StatefulWidget {
  final Job? preselectedJob;
  const SubmitPhotosSheet({super.key, this.preselectedJob});

  @override
  State<SubmitPhotosSheet> createState() => _SubmitPhotosSheetState();
}

class _SubmitPhotosSheetState extends State<SubmitPhotosSheet> {
  final _noteController = TextEditingController();
  final _picker = ImagePicker();

  Job? _selectedJob;
  PhotoType _selectedType = PhotoType.after;
  List<XFile> _pickedFiles = [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedJob = widget.preselectedJob;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // ─── Picking ───────────────────────────────────────────────────────────────

  Future<void> _pickImages() async {
    try {
      final files = await _picker.pickMultiImage(imageQuality: 85);
      if (files.isNotEmpty) {
        setState(() => _pickedFiles = [..._pickedFiles, ...files]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open gallery: $e'), backgroundColor: TRColors.error),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (file != null) {
        setState(() => _pickedFiles = [..._pickedFiles, file]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera unavailable: $e'), backgroundColor: TRColors.error),
        );
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      final updated = [..._pickedFiles];
      updated.removeAt(index);
      _pickedFiles = updated;
    });
  }

  // ─── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_selectedJob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a job first.'), backgroundColor: TRColors.warning),
      );
      return;
    }
    if (_pickedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one photo.'), backgroundColor: TRColors.warning),
      );
      return;
    }

    setState(() => _submitting = true);

    final state = context.read<AppState>();
    await state.submitPhotos(
      jobId: _selectedJob!.id,
      jobName: '${_selectedJob!.customerName} — ${_selectedJob!.jobType}',
      pickedFiles: _pickedFiles,
      photoType: _selectedType,
      crewNote: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_rounded, color: TRColors.success, size: 18),
            const SizedBox(width: 10),
            Text('${_pickedFiles.length} photo${_pickedFiles.length == 1 ? '' : 's'} submitted for review!'),
          ]),
          backgroundColor: TRColors.cardDark,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final activeJobs = state.activeJobs;

    return DraggableScrollableSheet(
      initialChildSize: 0.90,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: TRColors.navyMid,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: TRColors.divider, borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const Icon(Icons.upload_rounded, color: TRColors.gold, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('Submit Photos', style: TextStyle(
                    color: TRColors.white, fontSize: 18, fontWeight: FontWeight.w800,
                  ))),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: TRColors.grayMid, size: 22),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),

            const Divider(color: TRColors.divider, height: 20),

            // Scrollable form body
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // 1 — Job selector
                  _SectionLabel(label: '1. Select Job', icon: Icons.work_outline_rounded),
                  const SizedBox(height: 8),
                  if (activeJobs.isEmpty)
                    _EmptyHint(text: 'No active jobs. Mark a job In Progress to submit photos.')
                  else
                    ...activeJobs.map((job) => _JobPickerTile(
                      job: job,
                      selected: _selectedJob?.id == job.id,
                      onTap: () => setState(() => _selectedJob = job),
                    )),

                  const SizedBox(height: 20),

                  // 2 — Photo type
                  _SectionLabel(label: '2. Photo Type', icon: Icons.category_outlined),
                  const SizedBox(height: 8),
                  Row(
                    children: PhotoType.values.map((type) {
                      final selected = _selectedType == type;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedType = type),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selected ? TRColors.gold : TRColors.cardDark,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected ? TRColors.gold : TRColors.divider,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(_typeIcon(type),
                                  color: selected ? TRColors.navyDeep : TRColors.grayLight,
                                  size: 18),
                                const SizedBox(height: 4),
                                Text(_typeLabel(type), textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: selected ? TRColors.navyDeep : TRColors.grayLight,
                                    fontSize: 11, fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // 3 — Pick photos
                  _SectionLabel(label: '3. Add Photos', icon: Icons.add_photo_alternate_outlined),
                  const SizedBox(height: 8),

                  // Source buttons
                  Row(
                    children: [
                      Expanded(child: _SourceButton(
                        icon: Icons.camera_alt_rounded,
                        label: 'Take Photo',
                        onTap: _takePhoto,
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: _SourceButton(
                        icon: Icons.photo_library_outlined,
                        label: 'From Gallery',
                        onTap: _pickImages,
                      )),
                    ],
                  ),

                  // Selected photos grid
                  if (_pickedFiles.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _pickedFiles.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                      ),
                      itemBuilder: (_, i) => _PickedPhotoThumb(
                        file: _pickedFiles[i],
                        onRemove: () => _removePhoto(i),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('${_pickedFiles.length} photo${_pickedFiles.length == 1 ? '' : 's'} selected',
                      style: const TextStyle(color: TRColors.grayMid, fontSize: 12)),
                  ],

                  const SizedBox(height: 20),

                  // 4 — Crew note (optional)
                  _SectionLabel(label: '4. Note for Approver (optional)', icon: Icons.notes_rounded),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    style: const TextStyle(color: TRColors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'e.g. "Before tear-off on north slope" or any context for the reviewer…',
                      hintStyle: const TextStyle(color: TRColors.grayMid, fontSize: 13),
                      filled: true,
                      fillColor: TRColors.cardDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: TRColors.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: TRColors.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: TRColors.gold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TRColors.gold,
                        disabledBackgroundColor: TRColors.gold.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation(TRColors.navyDeep),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.upload_rounded, color: TRColors.navyDeep, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Submit ${_pickedFiles.isEmpty ? '' : '${_pickedFiles.length} '}Photo${_pickedFiles.length == 1 ? '' : 's'} for Review',
                                  style: const TextStyle(
                                    color: TRColors.navyDeep, fontSize: 15, fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(PhotoType t) {
    switch (t) {
      case PhotoType.before:   return Icons.history_rounded;
      case PhotoType.progress: return Icons.trending_up_rounded;
      case PhotoType.after:    return Icons.check_circle_outline_rounded;
    }
  }

  String _typeLabel(PhotoType t) {
    switch (t) {
      case PhotoType.before:   return 'Before';
      case PhotoType.progress: return 'Progress';
      case PhotoType.after:    return 'After';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SMALL COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: TRColors.gold, size: 16),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(
          color: TRColors.grayLight, fontSize: 13, fontWeight: FontWeight.w600,
        )),
      ],
    );
  }
}

class _JobPickerTile extends StatelessWidget {
  final Job job;
  final bool selected;
  final VoidCallback onTap;
  const _JobPickerTile({required this.job, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? TRColors.goldDim : TRColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? TRColors.gold : TRColors.divider),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
              color: selected ? TRColors.gold : TRColors.grayMid,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.customerName, style: TextStyle(
                  color: selected ? TRColors.gold : TRColors.white,
                  fontSize: 14, fontWeight: FontWeight.w600,
                )),
                Text('${job.jobType} · ${job.status.displayName}', style: const TextStyle(
                  color: TRColors.grayMid, fontSize: 12,
                )),
              ],
            )),
          ],
        ),
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: TRColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: TRColors.divider),
        ),
        child: Column(
          children: [
            Icon(icon, color: TRColors.gold, size: 24),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(
              color: TRColors.white, fontSize: 12, fontWeight: FontWeight.w600,
            )),
          ],
        ),
      ),
    );
  }
}

class _PickedPhotoThumb extends StatelessWidget {
  final XFile file;
  final VoidCallback onRemove;
  const _PickedPhotoThumb({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            file.path,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => Container(
              color: TRColors.cardMid,
              child: const Icon(Icons.image_rounded, color: TRColors.grayMid),
            ),
          ),
        ),
        Positioned(
          top: 4, right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 20, height: 20,
              decoration: const BoxDecoration(color: TRColors.error, shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TRColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TRColors.divider),
      ),
      child: Row(children: [
        const Icon(Icons.info_outline_rounded, color: TRColors.grayMid, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(color: TRColors.grayMid, fontSize: 13))),
      ]),
    );
  }
}
