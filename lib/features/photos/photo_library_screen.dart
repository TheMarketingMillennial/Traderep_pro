// photo_library_screen.dart — TradeRep Pro
// Centralized admin photo library.
// Shows every upload session chronologically.
// Admins can view, download, search, filter, and delete sessions/photos.

import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/services/app_state.dart';
import '../../shared/models/models.dart';

// ─── Entry Point ──────────────────────────────────────────────────────────────
class PhotoLibraryScreen extends StatefulWidget {
  const PhotoLibraryScreen({super.key});

  @override
  State<PhotoLibraryScreen> createState() => _PhotoLibraryScreenState();
}

class _PhotoLibraryScreenState extends State<PhotoLibraryScreen> {
  String _searchQuery = '';
  String? _filterEmployee; // null = all employees
  DateTimeRange? _dateFilter;

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<PhotoSubmission> _filter(List<PhotoSubmission> all) {
    var results = all.where((s) => s.photos.any((p) => p.networkUrl != null)).toList();

    // Employee filter
    if (_filterEmployee != null) {
      results = results.where((s) => s.submittedByName == _filterEmployee).toList();
    }

    // Date range filter
    if (_dateFilter != null) {
      results = results.where((s) {
        final d = s.submittedAt;
        return !d.isBefore(_dateFilter!.start) && !d.isAfter(_dateFilter!.end);
      }).toList();
    }

    // Text search (employee name or job name)
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      results = results.where((s) =>
        s.submittedByName.toLowerCase().contains(q) ||
        s.jobName.toLowerCase().contains(q),
      ).toList();
    }

    // Newest first
    results.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final allSessions = state.photoSubmissions;
    final filtered   = _filter(allSessions);

    // Collect unique employee names for filter chip
    final employees = allSessions
        .map((s) => s.submittedByName)
        .toSet()
        .toList()
      ..sort();

    final totalPhotos = filtered.fold<int>(0, (sum, s) => sum + s.photos.length);

    return Scaffold(
      backgroundColor: TRColors.navyDeep,
      appBar: AppBar(
        backgroundColor: TRColors.navyDeep,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: TRColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Photo Library', style: TextStyle(
          color: TRColors.white, fontSize: 18, fontWeight: FontWeight.w700,
        )),
        actions: [
          if (_dateFilter != null || _filterEmployee != null)
            TextButton(
              onPressed: () => setState(() {
                _filterEmployee = null;
                _dateFilter = null;
              }),
              child: const Text('Clear', style: TextStyle(color: TRColors.gold, fontSize: 13)),
            ),
          IconButton(
            icon: const Icon(Icons.date_range_rounded, color: TRColors.grayLight, size: 20),
            tooltip: 'Filter by date',
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2024),
                lastDate: now,
                initialDateRange: _dateFilter ?? DateTimeRange(
                  start: now.subtract(const Duration(days: 30)),
                  end: now,
                ),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: TRColors.gold,
                      onPrimary: TRColors.navyDeep,
                      surface: TRColors.cardDark,
                      onSurface: TRColors.white,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) setState(() => _dateFilter = picked);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: TRColors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by employee or job name…',
                hintStyle: const TextStyle(color: TRColors.grayMid, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: TRColors.grayMid, size: 18),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: TRColors.grayMid, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: TRColors.cardDark,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),

          // ── Employee filter chips ──────────────────────────────────────────
          if (employees.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All Employees',
                    selected: _filterEmployee == null,
                    onTap: () => setState(() => _filterEmployee = null),
                  ),
                  ...employees.map((e) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _FilterChip(
                      label: e,
                      selected: _filterEmployee == e,
                      onTap: () => setState(() => _filterEmployee = e),
                    ),
                  )),
                ],
              ),
            ),

          // ── Summary row ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(children: [
              Text(
                '${filtered.length} session${filtered.length == 1 ? '' : 's'} · $totalPhotos photo${totalPhotos == 1 ? '' : 's'}',
                style: const TextStyle(color: TRColors.grayMid, fontSize: 12),
              ),
              if (_dateFilter != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: TRColors.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: TRColors.gold.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${_fmtDate(_dateFilter!.start)} – ${_fmtDate(_dateFilter!.end)}',
                    style: const TextStyle(color: TRColors.gold, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ]),
          ),

          // ── Session list ──────────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? _EmptyLibrary(hasFilters: _searchQuery.isNotEmpty || _filterEmployee != null || _dateFilter != null)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) => _SessionCard(
                      session: filtered[i],
                      onDelete: () => _confirmDeleteSession(ctx, filtered[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const mo = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${mo[d.month - 1]} ${d.day}';
  }

  void _confirmDeleteSession(BuildContext ctx, PhotoSubmission session) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: TRColors.cardDark,
        title: const Text('Delete Upload Session?', style: TextStyle(color: TRColors.white, fontWeight: FontWeight.w700)),
        content: Text(
          'This will permanently delete ${session.photos.length} photo${session.photos.length == 1 ? '' : 's'} '
          'from ${session.submittedByName}\'s upload on ${_fmtDate(session.submittedAt)}.',
          style: const TextStyle(color: TRColors.grayLight, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: TRColors.grayLight)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(
                  content: Text('Session deleted.'),
                  backgroundColor: TRColors.error,
                ),
              );
              // TODO: call state.deletePhotoSubmission(session.id)
            },
            child: const Text('Delete', style: TextStyle(color: TRColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─── Session Card ─────────────────────────────────────────────────────────────
class _SessionCard extends StatelessWidget {
  final PhotoSubmission session;
  final VoidCallback onDelete;

  const _SessionCard({required this.session, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final photos = session.photos.where((p) => p.networkUrl != null).toList();
    if (photos.isEmpty) return const SizedBox.shrink();

    final d = session.submittedAt;
    final dateStr = _formatDateTime(d);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: TRColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TRColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Session header ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(children: [
              // Avatar
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: TRColors.gold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    session.submittedByName.isNotEmpty
                        ? session.submittedByName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: TRColors.gold, fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.submittedByName, style: const TextStyle(
                    color: TRColors.white, fontSize: 14, fontWeight: FontWeight.w700,
                  )),
                  Text(dateStr, style: const TextStyle(color: TRColors.grayMid, fontSize: 11)),
                ],
              )),
              // Photo count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: TRColors.cardMid,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${photos.length} photo${photos.length == 1 ? '' : 's'}',
                  style: const TextStyle(color: TRColors.grayLight, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              // Actions menu
              _SessionMenu(session: session, onDelete: onDelete),
            ]),
          ),

          // ── Job name ──────────────────────────────────────────────────────
          if (session.jobName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Row(children: [
                const Icon(Icons.work_rounded, color: TRColors.grayMid, size: 12),
                const SizedBox(width: 5),
                Text(session.jobName, style: const TextStyle(color: TRColors.grayMid, fontSize: 12)),
              ]),
            ),

          // ── Photo strip ───────────────────────────────────────────────────
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
              itemCount: photos.length,
              itemBuilder: (ctx, i) => _PhotoThumb(
                photo: photos[i],
                onTap: () => _openPhoto(ctx, photos, i),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Action row ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(children: [
              Expanded(child: _ActionBtn(
                icon: Icons.download_rounded,
                label: 'Download All',
                onTap: () => _downloadAll(context, session),
              )),
              const SizedBox(width: 8),
              Expanded(child: _ActionBtn(
                icon: Icons.folder_zip_rounded,
                label: 'Download ZIP',
                color: TRColors.info,
                onTap: () => _downloadZip(context, session),
              )),
            ]),
          ),
        ],
      ),
    );
  }

  void _openPhoto(BuildContext ctx, List<SubmittedPhoto> photos, int index) {
    Navigator.push(ctx, MaterialPageRoute(
      builder: (_) => _PhotoViewerScreen(photos: photos, initialIndex: index),
    ));
  }

  void _downloadAll(BuildContext ctx, PhotoSubmission session) {
    final photos = session.photos.where((p) => p.networkUrl != null).toList();
    if (photos.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
        content: Text('No photos available to download.'),
        backgroundColor: TRColors.warning,
      ));
      return;
    }
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text('Opening ${photos.length} photo${photos.length == 1 ? "" : "s"} — save each from the new tab'),
      backgroundColor: TRColors.info,
      duration: const Duration(seconds: 4),
    ));
    // Open each photo in a new browser tab — Firebase URL has auth token baked in.
    // User can right-click → Save As in the tab, or use the browser download button.
    for (final photo in photos) {
      launchUrl(
        Uri.parse(photo.networkUrl!),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  void _downloadZip(BuildContext ctx, PhotoSubmission session) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text('Preparing ZIP for ${session.submittedByName}\'s ${session.photos.length} photos…'),
      backgroundColor: TRColors.info,
    ));
    // TODO: call Railway /zip-photos endpoint with list of URLs
  }

  String _formatDateTime(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final hour   = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final minute = d.minute.toString().padLeft(2, '0');
    final ampm   = d.hour >= 12 ? 'PM' : 'AM';
    return '${months[d.month - 1]} ${d.day}, ${d.year} · $hour:$minute $ampm';
  }
}

// ─── Session Context Menu ─────────────────────────────────────────────────────
class _SessionMenu extends StatelessWidget {
  final PhotoSubmission session;
  final VoidCallback onDelete;

  const _SessionMenu({required this.session, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: TRColors.grayMid, size: 18),
      color: TRColors.cardMid,
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'download',
          child: Row(children: [
            Icon(Icons.download_rounded, color: TRColors.grayLight, size: 16),
            SizedBox(width: 10),
            Text('Download All', style: TextStyle(color: TRColors.white, fontSize: 13)),
          ]),
        ),
        const PopupMenuItem(
          value: 'zip',
          child: Row(children: [
            Icon(Icons.folder_zip_rounded, color: TRColors.info, size: 16),
            SizedBox(width: 10),
            Text('Download ZIP', style: TextStyle(color: TRColors.white, fontSize: 13)),
          ]),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            Icon(Icons.delete_rounded, color: TRColors.error, size: 16),
            SizedBox(width: 10),
            Text('Delete Session', style: TextStyle(color: TRColors.error, fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
        ),
      ],
      onSelected: (action) {
        switch (action) {
          case 'download':
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Downloading ${session.photos.length} photos…'),
              backgroundColor: TRColors.info,
            ));
          case 'zip':
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Preparing ZIP for ${session.photos.length} photos…'),
              backgroundColor: TRColors.info,
            ));
          case 'delete':
            onDelete();
        }
      },
    );
  }
}

// ─── Photo Thumbnail ──────────────────────────────────────────────────────────
class _PhotoThumb extends StatelessWidget {
  final SubmittedPhoto photo;
  final VoidCallback onTap;

  const _PhotoThumb({required this.photo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final url = photo.networkUrl;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: TRColors.cardMid,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: TRColors.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url != null)
              Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator(
                    color: TRColors.gold, strokeWidth: 2,
                  ));
                },
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image_rounded, color: TRColors.grayMid, size: 28),
                ),
              )
            else
              const Center(child: Icon(Icons.image_rounded, color: TRColors.grayMid, size: 28)),

            // Type badge
            Positioned(
              bottom: 5, left: 5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: _badgeColor(photo.type).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _typeName(photo.type),
                  style: const TextStyle(color: TRColors.white, fontSize: 9, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _badgeColor(PhotoType type) {
    switch (type) {
      case PhotoType.before:   return TRColors.warning;
      case PhotoType.after:    return TRColors.success;
      case PhotoType.progress: return TRColors.info;
    }
  }

  String _typeName(PhotoType type) {
    switch (type) {
      case PhotoType.before:   return 'BEFORE';
      case PhotoType.after:    return 'AFTER';
      case PhotoType.progress: return 'PROGRESS';
    }
  }
}

// ─── Full-Screen Photo Viewer ─────────────────────────────────────────────────
class _PhotoViewerScreen extends StatefulWidget {
  final List<SubmittedPhoto> photos;
  final int initialIndex;

  const _PhotoViewerScreen({required this.photos, required this.initialIndex});

  @override
  State<_PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<_PhotoViewerScreen> {
  late int _current;
  late PageController _ctrl;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photos[_current];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: TRColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_current + 1} / ${widget.photos.length}',
          style: const TextStyle(color: TRColors.white, fontSize: 15),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: TRColors.white),
            onPressed: () {
              final url = photo.networkUrl;
              if (url != null) {
                launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Photo URL not available.'), backgroundColor: TRColors.warning),
                );
              }
            },
          ),
        ],
      ),
      body: PageView.builder(
        controller: _ctrl,
        itemCount: widget.photos.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (ctx, i) {
          final p = widget.photos[i];
          final url = p.networkUrl;
          if (url == null) {
            return const Center(child: Icon(Icons.broken_image_rounded, color: TRColors.grayMid, size: 64));
          }
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (ctx, child, prog) {
                  if (prog == null) return child;
                  return const Center(child: CircularProgressIndicator(color: TRColors.gold));
                },
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image_rounded, color: TRColors.grayMid, size: 64),
                ),
              ),
            ),
          );
        },
      ),
      // Navigation arrows
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: TRColors.grayLight),
            onPressed: _current > 0
                ? () => _ctrl.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut)
                : null,
          ),
          if (photo.label != null)
            Expanded(child: Text(
              photo.label!,
              style: const TextStyle(color: TRColors.grayLight, fontSize: 13),
              textAlign: TextAlign.center,
            )),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, color: TRColors.grayLight),
            onPressed: _current < widget.photos.length - 1
                ? () => _ctrl.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut)
                : null,
          ),
        ]),
      ),
    );
  }
}

// ─── Filter Chip ──────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? TRColors.goldDim : TRColors.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? TRColors.gold : TRColors.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? TRColors.gold : TRColors.grayLight,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─── Action Button ────────────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = TRColors.gold,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyLibrary extends StatelessWidget {
  final bool hasFilters;
  const _EmptyLibrary({required this.hasFilters});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: TRColors.goldDim,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.photo_library_rounded, color: TRColors.gold, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              hasFilters ? 'No photos match your filters' : 'No photos yet',
              style: const TextStyle(color: TRColors.white, fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Try clearing your filters or expanding the date range.'
                  : 'Once your team uploads photos, they\'ll all appear here for admin review.',
              style: const TextStyle(color: TRColors.grayMid, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
