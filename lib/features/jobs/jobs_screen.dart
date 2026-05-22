import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/services/app_state.dart';
import '../../shared/widgets/tr_widgets.dart';
import '../../shared/models/models.dart';
import 'job_detail_screen.dart';
import 'create_job_screen.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  final List<String> _tabs = ['All', 'Lead', 'Scheduled', 'In Progress', 'Awaiting', 'Completed'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Job> _filteredJobs(AppState state, int tabIndex) {
    List<Job> jobs = state.jobs;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      jobs = jobs.where((j) =>
        j.customerName.toLowerCase().contains(q) ||
        j.jobType.toLowerCase().contains(q) ||
        j.address.toLowerCase().contains(q)
      ).toList();
    }
    switch (tabIndex) {
      case 1: return jobs.where((j) => j.status == JobStatus.lead).toList();
      case 2: return jobs.where((j) => j.status == JobStatus.scheduled).toList();
      case 3: return jobs.where((j) => j.status == JobStatus.inProgress).toList();
      case 4: return jobs.where((j) => j.status == JobStatus.awaitingApproval).toList();
      case 5: return jobs.where((j) => j.status == JobStatus.completed).toList();
      default: return jobs;
    }
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
            _buildSearch(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: List.generate(_tabs.length, (i) {
                  final jobs = _filteredJobs(state, i);
                  if (jobs.isEmpty) {
                    return TREmptyState(
                      icon: Icons.work_outline_rounded,
                      title: 'No jobs here',
                      subtitle: i == 0 ? 'Create your first job to get started' : 'No jobs with this status',
                      actionLabel: i == 0 ? '+ Create Job' : null,
                      onAction: i == 0 ? () => _openCreateJob(context) : null,
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    itemCount: jobs.length,
                    itemBuilder: (_, index) => JobCard(
                      job: jobs[index],
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => JobDetailScreen(job: jobs[index]),
                      )),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateJob(context),
        backgroundColor: TRColors.gold,
        foregroundColor: TRColors.navyDeep,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Job', style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          const Expanded(child: Text('Jobs', style: TextStyle(
            color: TRColors.white, fontSize: 24, fontWeight: FontWeight.w800,
          ))),
          Consumer<AppState>(
            builder: (_, state, __) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: TRColors.cardMid,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: TRColors.divider),
              ),
              child: Text('${state.jobs.length} total', style: const TextStyle(
                color: TRColors.grayLight, fontSize: 12, fontWeight: FontWeight.w600,
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(color: TRColors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search jobs, customers...',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          filled: true,
          fillColor: TRColors.cardDark,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            borderSide: const BorderSide(color: TRColors.gold, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _tabs.length,
          itemBuilder: (_, i) {
            return AnimatedBuilder(
              animation: _tabController,
              builder: (_, __) {
                final selected = _tabController.index == i;
                return GestureDetector(
                  onTap: () => _tabController.animateTo(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? TRColors.gold : TRColors.cardDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? TRColors.gold : TRColors.divider,
                      ),
                    ),
                    child: Text(_tabs[i], style: TextStyle(
                      color: selected ? TRColors.navyDeep : TRColors.grayLight,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    )),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _openCreateJob(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateJobScreen()));
  }
}
