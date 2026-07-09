// platform_admin_screen.dart — TradeRep Pro
// Internal platform-admin dashboard.  Accessible ONLY to The Marketing
// Millennial (gated by Firebase Auth email).  Never shown to company users.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/services/analytics_service.dart';

// ─── Platform Admin Gate ─────────────────────────────────────────────────────
// Add every authorized platform-admin email here.
const _kPlatformAdminEmails = <String>{
  kPlatformAdminEmail,                       // from analytics_service.dart
  'hello@themarketingmillennial.com',
};

bool _isPlatformAdmin(User? user) {
  if (user == null) return false;
  final email = user.email?.toLowerCase() ?? '';
  return _kPlatformAdminEmails.contains(email);
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class PlatformAdminScreen extends StatefulWidget {
  const PlatformAdminScreen({super.key});

  @override
  State<PlatformAdminScreen> createState() => _PlatformAdminScreenState();
}

class _PlatformAdminScreenState extends State<PlatformAdminScreen> {
  // ── State ────────────────────────────────────────────────────────────────
  List<CompanyOverview> _all    = [];
  List<CompanyOverview> _filtered = [];
  bool  _loading = true;
  String? _error;

  // Filters
  String _searchQuery    = '';
  String _tradeFilter    = 'All';
  String _statusFilter   = 'All';

  // Sort
  String _sortBy = 'Health Score';
  bool   _sortAsc = false;

  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Data loading ─────────────────────────────────────────────────────────

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final overviews = await AnalyticsService.getCompaniesOverview();
      setState(() {
        _all      = overviews;
        _loading  = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() {
        _error   = 'Failed to load company data: $e';
        _loading = false;
      });
    }
  }

  // ── Filtering + Sorting ──────────────────────────────────────────────────

  void _applyFilters() {
    List<CompanyOverview> list = List.from(_all);

    // Search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((c) =>
        c.companyName.toLowerCase().contains(q) ||
        c.tradeCategory.toLowerCase().contains(q) ||
        c.serviceArea.toLowerCase().contains(q)
      ).toList();
    }

    // Trade filter
    if (_tradeFilter != 'All') {
      list = list.where((c) =>
        c.tradeCategory.toLowerCase() == _tradeFilter.toLowerCase()).toList();
    }

    // Status filter
    if (_statusFilter != 'All') {
      list = list.where((c) =>
        c.subscriptionStatus.toLowerCase().contains(_statusFilter.toLowerCase())).toList();
    }

    // Sort
    list.sort((a, b) {
      int cmp;
      switch (_sortBy) {
        case 'Company Name':   cmp = a.companyName.compareTo(b.companyName); break;
        case 'Health Score':   cmp = a.healthScore.compareTo(b.healthScore); break;
        case 'Logins':         cmp = a.totalLogins.compareTo(b.totalLogins); break;
        case 'GBP Posts':      cmp = a.totalGooglePosts.compareTo(b.totalGooglePosts); break;
        case 'Reviews Sent':   cmp = a.totalReviewRequests.compareTo(b.totalReviewRequests); break;
        case 'Last Activity':
          final aT = a.lastActivity ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bT = b.lastActivity ?? DateTime.fromMillisecondsSinceEpoch(0);
          cmp = aT.compareTo(bT);
          break;
        default: cmp = 0;
      }
      return _sortAsc ? cmp : -cmp;
    });

    setState(() { _filtered = list; });
  }

  // ── Export CSV ───────────────────────────────────────────────────────────

  void _exportCsv() {
    final csv = AnalyticsService.exportToCsv(_filtered);
    if (kDebugMode) debugPrint('[Admin] CSV export:\n$csv');
    showDialog(
      context: context,
      builder: (_) => _CsvExportDialog(csv: csv, rowCount: _filtered.length),
    );
  }

  // ── Unique filter options derived from loaded data ────────────────────────

  List<String> get _tradeOptions {
    final trades = _all.map((c) => c.tradeCategory).toSet().toList()..sort();
    return ['All', ...trades];
  }

  List<String> get _statusOptions {
    return ['All', 'trial', 'trialing', 'active', 'past_due', 'canceled', 'unknown'];
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (!_isPlatformAdmin(currentUser)) {
      return _AccessDeniedScreen(email: currentUser?.email);
    }

    return Scaffold(
      backgroundColor: TRColors.navyDeep,
      appBar: AppBar(
        backgroundColor: TRColors.navyDark,
        foregroundColor: TRColors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Platform Admin', style: TextStyle(
              color: TRColors.gold, fontWeight: FontWeight.w800, fontSize: 17,
            )),
            Text('The Marketing Millennial — Internal Only', style: TextStyle(
              color: TRColors.grayMid, fontSize: 11,
            )),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: TRColors.grayLight),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, color: TRColors.gold),
            onPressed: _filtered.isEmpty ? null : _exportCsv,
            tooltip: 'Export CSV',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryBanner(),
          _buildFilterBar(),
          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator(color: TRColors.gold))
              : _error != null
                ? _ErrorView(error: _error!, onRetry: _load)
                : _filtered.isEmpty
                  ? _EmptyView(hasFilters: _searchQuery.isNotEmpty ||
                      _tradeFilter != 'All' || _statusFilter != 'All')
                  : _buildCompanyList(),
          ),
        ],
      ),
    );
  }

  // ── Summary banner ────────────────────────────────────────────────────────

  Widget _buildSummaryBanner() {
    if (_loading) return const SizedBox.shrink();
    final total   = _all.length;
    final active  = _all.where((c) => c.subscriptionStatus == 'active').length;
    final trial   = _all.where((c) =>
        c.subscriptionStatus.contains('trial') ||
        c.subscriptionStatus == 'trialing').length;
    final pastDue = _all.where((c) =>
        c.subscriptionStatus.contains('past') ||
        c.subscriptionStatus == 'unpaid').length;
    final avgHealth = total == 0 ? 0 :
        (_all.fold(0, (s, c) => s + c.healthScore) / total).round();

    return Container(
      color: TRColors.navyMid,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _StatPill(label: 'Total', value: '$total', color: TRColors.info),
          const SizedBox(width: 8),
          _StatPill(label: 'Active', value: '$active', color: TRColors.success),
          const SizedBox(width: 8),
          _StatPill(label: 'Trial', value: '$trial', color: TRColors.gold),
          const SizedBox(width: 8),
          _StatPill(label: 'Past Due', value: '$pastDue', color: TRColors.error),
          const Spacer(),
          _StatPill(label: 'Avg Health', value: '$avgHealth', color: TRColors.goldLight),
        ],
      ),
    );
  }

  // ── Filter bar ────────────────────────────────────────────────────────────

  Widget _buildFilterBar() {
    return Container(
      color: TRColors.navyDark,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        children: [
          // Search
          TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: TRColors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search company, trade, city…',
              hintStyle: TextStyle(color: TRColors.grayMid, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: TRColors.grayMid, size: 18),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: TRColors.grayMid, size: 16),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() { _searchQuery = ''; });
                        _applyFilters();
                      },
                    )
                  : null,
              filled: true,
              fillColor: TRColors.cardDark,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) { setState(() { _searchQuery = v; }); _applyFilters(); },
          ),
          const SizedBox(height: 8),
          // Dropdowns row
          Row(
            children: [
              Expanded(child: _Dropdown(
                label: 'Trade',
                value: _tradeFilter,
                items: _tradeOptions,
                onChanged: (v) { setState(() { _tradeFilter = v; }); _applyFilters(); },
              )),
              const SizedBox(width: 8),
              Expanded(child: _Dropdown(
                label: 'Status',
                value: _statusFilter,
                items: _statusOptions,
                onChanged: (v) { setState(() { _statusFilter = v; }); _applyFilters(); },
              )),
              const SizedBox(width: 8),
              Expanded(child: _Dropdown(
                label: 'Sort',
                value: _sortBy,
                items: const [
                  'Health Score', 'Company Name', 'Logins',
                  'GBP Posts', 'Reviews Sent', 'Last Activity',
                ],
                onChanged: (v) { setState(() { _sortBy = v; }); _applyFilters(); },
              )),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(
                  _sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
                  color: TRColors.gold, size: 18,
                ),
                onPressed: () { setState(() { _sortAsc = !_sortAsc; }); _applyFilters(); },
              ),
            ],
          ),
          // Results count
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${_filtered.length} of ${_all.length} companies',
                style: const TextStyle(color: TRColors.grayMid, fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Company list ──────────────────────────────────────────────────────────

  Widget _buildCompanyList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      itemCount: _filtered.length,
      itemBuilder: (ctx, i) => _CompanyRow(
        overview: _filtered[i],
        onTap: () => showModalBottomSheet(
          context: context,
          backgroundColor: TRColors.cardDark,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          isScrollControlled: true,
          builder: (_) => _CompanyDetailSheet(overview: _filtered[i]),
        ),
      ),
    );
  }
}

// ─── Company Row Card ─────────────────────────────────────────────────────────

class _CompanyRow extends StatelessWidget {
  final CompanyOverview overview;
  final VoidCallback onTap;

  const _CompanyRow({required this.overview, required this.onTap});

  Color _statusColor(String s) {
    if (s.contains('active')) return TRColors.success;
    if (s.contains('trial') || s == 'trialing') return TRColors.gold;
    if (s.contains('past') || s == 'unpaid') return TRColors.error;
    if (s.contains('cancel')) return TRColors.grayMid;
    return TRColors.info;
  }

  Color _healthColor(int score) {
    if (score >= 80) return TRColors.success;
    if (score >= 60) return TRColors.gold;
    if (score >= 40) return TRColors.warning;
    return TRColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(overview.subscriptionStatus);
    final healthColor = _healthColor(overview.healthScore);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: TRColors.cardMid,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: TRColors.divider, width: 0.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: name + status + health badge
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(overview.companyName, style: const TextStyle(
                          color: TRColors.white, fontWeight: FontWeight.w700, fontSize: 14,
                        )),
                        const SizedBox(height: 2),
                        Text(
                          '${overview.tradeCategory}${overview.serviceArea.isNotEmpty ? " · ${overview.serviceArea}" : ""}',
                          style: const TextStyle(color: TRColors.grayLight, fontSize: 11),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      overview.subscriptionStatus,
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Health score badge
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: healthColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: healthColor.withValues(alpha: 0.6), width: 1.5),
                    ),
                    child: Center(
                      child: Text('${overview.healthScore}', style: TextStyle(
                        color: healthColor, fontSize: 12, fontWeight: FontWeight.w800,
                      )),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Stats row
              Row(
                children: [
                  _MiniStat(icon: Icons.login_rounded, label: 'Logins', value: '${overview.totalLogins}'),
                  _MiniStat(icon: Icons.star_rounded, label: 'Reviews', value: '${overview.totalReviewRequests}'),
                  _MiniStat(icon: Icons.post_add_rounded, label: 'GBP Posts', value: '${overview.totalGooglePosts}'),
                  _MiniStat(icon: Icons.photo_camera_rounded, label: 'Photos', value: '${overview.totalPhotos}'),
                  _MiniStat(icon: Icons.work_rounded, label: 'Jobs', value: '${overview.totalJobs}'),
                  _MiniStat(icon: Icons.people_rounded, label: 'Seats', value: '${overview.seatCount}'),
                ],
              ),
              if (overview.lastActivity != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Last activity: ${_formatDate(overview.lastActivity!)}',
                  style: const TextStyle(color: TRColors.grayMid, fontSize: 10),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7)  return '${diff.inDays} days ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}

// ─── Mini stat widget ──────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniStat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: TRColors.grayMid, size: 13),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(
            color: TRColors.white, fontWeight: FontWeight.w700, fontSize: 12,
          )),
          Text(label, style: const TextStyle(color: TRColors.grayMid, fontSize: 9),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Company Detail Sheet ─────────────────────────────────────────────────────

class _CompanyDetailSheet extends StatelessWidget {
  final CompanyOverview overview;
  const _CompanyDetailSheet({required this.overview});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (ctx, ctrl) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: ListView(
          controller: ctrl,
          children: [
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: TRColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            )),
            const SizedBox(height: 16),
            Text(overview.companyName, style: const TextStyle(
              color: TRColors.white, fontWeight: FontWeight.w800, fontSize: 18,
            )),
            const SizedBox(height: 4),
            Text('${overview.tradeCategory} · ${overview.serviceArea}',
              style: const TextStyle(color: TRColors.grayLight, fontSize: 13)),
            const SizedBox(height: 4),
            Text('Company ID: ${overview.companyId}',
              style: const TextStyle(color: TRColors.grayMid, fontSize: 11)),
            const Divider(color: TRColors.divider, height: 24),

            // Subscription block
            _DetailRow('Subscription Status', overview.subscriptionStatus),
            _DetailRow('Seat Count', '${overview.seatCount}'),

            const Divider(color: TRColors.divider, height: 24),

            // Health score
            _DetailRow('Health Score', '${overview.healthScore}/100'),

            const Divider(color: TRColors.divider, height: 24),

            // Activity metrics
            const Text('Platform Activity (Current Month)',
              style: TextStyle(color: TRColors.grayMid, fontSize: 11,
                fontWeight: FontWeight.w700, letterSpacing: 0.8)),
            const SizedBox(height: 8),
            _DetailRow('Logins', '${overview.totalLogins}'),
            _DetailRow('Review Requests Sent', '${overview.totalReviewRequests}'),
            _DetailRow('Google Posts Published', '${overview.totalGooglePosts}'),
            _DetailRow('Photos Uploaded', '${overview.totalPhotos}'),
            _DetailRow('Jobs Created', '${overview.totalJobs}'),

            const Divider(color: TRColors.divider, height: 24),

            if (overview.lastActivity != null)
              _DetailRow('Last Activity', overview.lastActivity!.toLocal().toString().substring(0, 16)),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: TRColors.grayLight, fontSize: 13)),
        Text(value, style: const TextStyle(
          color: TRColors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    ),
  );
}

// ─── CSV Export Dialog ────────────────────────────────────────────────────────

class _CsvExportDialog extends StatelessWidget {
  final String csv;
  final int rowCount;
  const _CsvExportDialog({required this.csv, required this.rowCount});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: TRColors.cardDark,
      title: const Text('CSV Export Ready', style: TextStyle(color: TRColors.gold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$rowCount companies exported.',
            style: const TextStyle(color: TRColors.grayLight, fontSize: 13)),
          const SizedBox(height: 12),
          const Text(
            'The CSV data is printed to the debug console.\n\n'
            'To save as a file: copy the console output, paste\n'
            'into a text editor, and save with a .csv extension.\n\n'
            'Production tip: wire this to dart:html (web) or\n'
            'path_provider (mobile) to trigger a real download.',
            style: TextStyle(color: TRColors.grayMid, fontSize: 12),
          ),
          const SizedBox(height: 8),
          // Preview first line
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: TRColors.navyDeep,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              csv.split('\n').take(3).join('\n'),
              style: const TextStyle(color: TRColors.grayLight, fontSize: 10,
                fontFamily: 'monospace'),
              maxLines: 5, overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close', style: TextStyle(color: TRColors.grayLight)),
        ),
      ],
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;

  const _StatPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: TextStyle(
          color: color, fontWeight: FontWeight.w800, fontSize: 13,
        )),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(
          color: TRColors.grayLight, fontSize: 10,
        )),
      ],
    ),
  );
}

class _Dropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _Dropdown({
    required this.label, required this.value,
    required this.items, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: TRColors.cardDark,
      borderRadius: BorderRadius.circular(8),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
    child: DropdownButton<String>(
      value: value,
      dropdownColor: TRColors.cardDark,
      style: const TextStyle(color: TRColors.white, fontSize: 12),
      isExpanded: true,
      underline: const SizedBox.shrink(),
      hint: Text(label, style: const TextStyle(color: TRColors.grayMid, fontSize: 11)),
      items: items.map((v) => DropdownMenuItem(
        value: v,
        child: Text(v, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
      )).toList(),
      onChanged: (v) { if (v != null) onChanged(v); },
    ),
  );
}

// ─── Access Denied screen ─────────────────────────────────────────────────────

class _AccessDeniedScreen extends StatelessWidget {
  final String? email;
  const _AccessDeniedScreen({this.email});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: TRColors.navyDeep,
    appBar: AppBar(
      backgroundColor: TRColors.navyDark,
      foregroundColor: TRColors.white,
      title: const Text('Restricted', style: TextStyle(color: TRColors.white)),
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_rounded, color: TRColors.error, size: 64),
            const SizedBox(height: 24),
            const Text('Access Denied', style: TextStyle(
              color: TRColors.white, fontWeight: FontWeight.w800, fontSize: 22,
            )),
            const SizedBox(height: 12),
            Text(
              'This dashboard is restricted to\nplatform administrators only.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: TRColors.grayLight, fontSize: 14),
            ),
            if (email != null) ...[
              const SizedBox(height: 8),
              Text('Signed in as: $email',
                style: const TextStyle(color: TRColors.grayMid, fontSize: 12)),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: TRColors.navyMid),
              child: const Text('Go Back', style: TextStyle(color: TRColors.white)),
            ),
          ],
        ),
      ),
    ),
  );
}

// ─── Empty / Error views ──────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final bool hasFilters;
  const _EmptyView({required this.hasFilters});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business_center_rounded,
            color: TRColors.grayMid, size: 48),
          const SizedBox(height: 16),
          Text(
            hasFilters ? 'No companies match your filters.' : 'No companies found.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: TRColors.grayLight, fontSize: 14),
          ),
          const SizedBox(height: 8),
          if (!hasFilters)
            const Text(
              'Companies will appear here once users\nhave signed up and logged in.',
              textAlign: TextAlign.center,
              style: TextStyle(color: TRColors.grayMid, fontSize: 12),
            ),
        ],
      ),
    ),
  );
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: TRColors.error, size: 48),
          const SizedBox(height: 16),
          Text(error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: TRColors.grayLight, fontSize: 13)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(backgroundColor: TRColors.navyMid),
          ),
        ],
      ),
    ),
  );
}
