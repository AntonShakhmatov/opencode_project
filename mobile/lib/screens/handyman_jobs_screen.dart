import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_constants.dart';
import '../models/job.dart';
import '../providers/auth_provider.dart';
import '../providers/job_provider.dart';
import 'chat_screen.dart';
import 'job_detail_screen.dart';

class HandymanJobsScreen extends StatefulWidget {
  const HandymanJobsScreen({super.key});

  @override
  State<HandymanJobsScreen> createState() => _HandymanJobsScreenState();
}

class _HandymanJobsScreenState extends State<HandymanJobsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadJobs());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    final auth = context.read<AuthProvider>();
    final jobProvider = context.read<JobProvider>();
    if (auth.token != null && auth.userId != null) {
      await jobProvider.fetchHandymanJobs(auth.token!, auth.userId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobProvider = context.watch<JobProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Jobs'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Available (${jobProvider.availableJobs.length})'),
            Tab(text: 'Active (${jobProvider.activeJobs.length})'),
            Tab(text: 'Done (${jobProvider.completedJobs.length})'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadJobs,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildJobList(jobProvider.availableJobs, showActions: true),
            _buildJobList(jobProvider.activeJobs, showActions: true),
            _buildJobList(jobProvider.completedJobs, showActions: false),
          ],
        ),
      ),
    );
  }

  Widget _buildJobList(List<Job> jobs, {required bool showActions}) {
    if (jobs.isEmpty) {
      return const Center(
        child: Text(
          'No jobs found.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: jobs.length,
      itemBuilder: (context, index) => _buildJobCard(jobs[index], showActions),
    );
  }

  Widget _buildJobCard(Job job, bool showActions) {
    final auth = context.read<AuthProvider>();
    final jobProvider = context.read<JobProvider>();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetail(job),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: jobStatusColor(job.status).withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      jobStatusLabel(job.status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: jobStatusColor(job.status),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(job.createdAt),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.build, size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  job.serviceType.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              job.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
            if (job.address != null && job.address!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      job.address!,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (job.estimatedPrice != null) ...[
              const SizedBox(height: 8),
              Text(
                'Est. \$${job.estimatedPrice!.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],
            if (showActions) ...[
              const Divider(height: 24),
              _buildActionButtons(job, auth, jobProvider),
            ],
          ],
          ),
        ),
      ),
    );
  }

  void _openDetail(Job job) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobDetailScreen(job: job),
      ),
    );
  }

  Widget _buildActionButtons(Job job, AuthProvider auth, JobProvider jobProvider) {
    switch (job.status) {
      case 'matched':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: jobProvider.isLoading ? null : () => _declineJob(job.id),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Text('Decline'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: jobProvider.isLoading
                    ? null
                    : () => _acceptJob(job.id, auth, jobProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Accept'),
              ),
            ),
          ],
        );
      case 'accepted':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: jobProvider.isLoading
                ? null
                : () => jobProvider.updateJobStatus(
                      job.id,
                      'en_route',
                      token: auth.token,
                    ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Heading There'),
          ),
        );
      case 'en_route':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: jobProvider.isLoading
                ? null
                : () => jobProvider.updateJobStatus(
                      job.id,
                      'in_progress',
                      token: auth.token,
                    ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Work'),
          ),
        );
      case 'in_progress':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: jobProvider.isLoading
                    ? null
                    : () => _openChat(job, auth),
                child: const Text('Chat'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: jobProvider.isLoading
                    ? null
                    : () => jobProvider.updateJobStatus(
                          job.id,
                          'completed',
                          token: auth.token,
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Complete'),
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _acceptJob(
    String jobId,
    AuthProvider auth,
    JobProvider jobProvider,
  ) async {
    await jobProvider.acceptJob(jobId, auth.token);
  }

  Future<void> _declineJob(String jobId) async {
    final auth = context.read<AuthProvider>();
    final jobProvider = context.read<JobProvider>();
    try {
      await jobProvider.updateJobStatus(jobId, 'cancelled', token: auth.token);
    } catch (_) {}
  }

  void _openChat(Job job, AuthProvider auth) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          jobId: job.id,
          jobTitle: '${job.serviceType} — ${jobStatusLabel(job.status)}',
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}';
  }
}
