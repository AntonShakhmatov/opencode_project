import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../app_constants.dart';
import '../models/job.dart';
import '../providers/auth_provider.dart';
import '../providers/job_provider.dart';
import '../providers/review_provider.dart';
import '../services/socket_service.dart';
import 'chat_screen.dart';
import 'rate_job_screen.dart';

class JobDetailScreen extends StatefulWidget {
  final Job job;

  const JobDetailScreen({super.key, required this.job});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  late Job _job = widget.job;
  bool _refreshing = true;

  void Function(dynamic)? _statusHandler;
  void Function(dynamic)? _acceptedHandler;
  void Function(dynamic)? _foundHandler;

  static const List<String> _steps = [
    'matched',
    'accepted',
    'en_route',
    'in_progress',
    'completed',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    final socket = context.read<SocketService>();
    socket.leaveJob(_job.id);
    socket.off('jobStatusUpdated', _statusHandler);
    socket.off('jobAccepted', _acceptedHandler);
    socket.off('handymanFound', _foundHandler);
    super.dispose();
  }

  Future<void> _init() async {
    final auth = context.read<AuthProvider>();
    final socket = context.read<SocketService>();

    if (auth.token != null) {
      if (!socket.connected) {
        socket.connect(auth.token!);
      }
      if (auth.userId != null) {
        socket.registerUser(auth.userId!);
      }
      socket.joinJob(_job.id, auth.userId ?? '');

      _statusHandler = (data) {
        if (data is Map<String, dynamic> && data['jobId'] == _job.id) {
          _handleLiveUpdate({'status': data['status']});
        }
      };
      _acceptedHandler = (data) {
        if (data is Map<String, dynamic> && data['jobId'] == _job.id) {
          _handleLiveUpdate({
            'status': 'accepted',
            'handymanId': data['handymanId'],
            'handymanName': data['handymanName'],
          });
        }
      };
      _foundHandler = (data) {
        if (data is Map<String, dynamic> && data['jobId'] == _job.id) {
          _handleLiveUpdate({
            'handymanId': data['handymanId'],
            'handymanName': data['handymanName'],
          });
        }
      };
      socket.on('jobStatusUpdated', _statusHandler!);
      socket.on('jobAccepted', _acceptedHandler!);
      socket.on('handymanFound', _foundHandler!);
    }
    await _refresh();
  }

  void _handleLiveUpdate(Map<String, dynamic> changes) {
    if (!mounted) return;
    setState(() {});
    context.read<JobProvider>().updateJobFromSocket(_job.id, changes);
    _refresh();
  }

  Future<void> _refresh() async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null) return;
    final job = await context.read<JobProvider>().fetchJobById(_job.id, auth.token);
    if (mounted && job != null) setState(() => _job = job);
    if (mounted) setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final isHandyman = auth.userRole == 'handyman';

    return Scaffold(
      appBar: AppBar(
        title: Text(_job.serviceType.toUpperCase()),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (_refreshing) const LinearProgressIndicator(),
            _buildStatusHeader(),
            if (_job.status == 'cancelled')
              _buildCancelledBanner()
            else
              _buildStepper(),
            const SizedBox(height: 12),
            _buildDescriptionCard(),
            _buildMapCard(),
            if (_job.address != null && _job.address!.isNotEmpty)
              _buildAddressCard(),
            _buildDetailsCard(isHandyman),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: jobStatusColor(_job.status).withAlpha(30),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            jobStatusLabel(_job.status),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: jobStatusColor(_job.status),
            ),
          ),
        ),
        const Spacer(),
        Text(
          'Updated ${_fmtRelative(_job.updatedAt)}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildStepper() {
    final currentIndex = _steps.indexOf(_job.status);

    if (currentIndex == -1) {
      return const SizedBox(height: 16);
    }

    final labels = ['Matched', 'Accepted', 'On the Way', 'In Progress', 'Done'];

    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: List.generate(_steps.length, (i) {
            final isDone = i < currentIndex;
            final isCurrent = i == currentIndex;
            final color = isCurrent
                ? jobStatusColor(_job.status)
                : isDone
                    ? AppColors.success
                    : Colors.grey.shade400;
            return Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      if (i > 0)
                        Expanded(
                          child: Container(
                            height: 3,
                            color: i <= currentIndex
                                ? AppColors.success
                                : Colors.grey.shade300,
                          ),
                        ),
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: color,
                        child: Icon(
                          isDone || isCurrent
                              ? Icons.check
                              : Icons.circle,
                          size: isCurrent ? 12 : 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isCurrent ? color : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCancelledBanner() {
    return Card(
      margin: const EdgeInsets.only(top: 16),
      color: Colors.red.shade50,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'This job was cancelled.',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Description',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Text(_job.description, style: const TextStyle(fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _buildMapCard() {
    final hasCoords = _job.latitude != 0 || _job.longitude != 0;
    if (!hasCoords) return const SizedBox.shrink();
    final location = LatLng(_job.latitude, _job.longitude);

    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: SizedBox(
        height: 180,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: FlutterMap(
            options: MapOptions(
              initialCenter: location,
              initialZoom: 14,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.handyman',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: location,
                    width: 36,
                    height: 36,
                    child: const Icon(
                      Icons.location_on,
                      color: AppColors.primary,
                      size: 36,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressCard() {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.location_on, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _job.address!,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(bool isHandyman) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _detailRow('Service', _job.serviceType.toUpperCase()),
            if (_job.handymanName != null && !isHandyman)
              _detailRow('Handyman', _job.handymanName!),
            if (_job.estimatedPrice != null)
              _detailRow('Estimated', '\$${_fmtPrice(_job.estimatedPrice!)}'),
            if (_job.finalPrice != null)
              _detailRow('Final price', '\$${_fmtPrice(_job.finalPrice!)}'),
            _detailRow('Posted', _fmt(_job.createdAt)),
            if (_job.scheduledAt != null)
              _detailRow('Scheduled', _fmt(_job.scheduledAt!)),
            if (_job.startedAt != null)
              _detailRow('Started', _fmt(_job.startedAt!)),
            if (_job.completedAt != null)
              _detailRow('Completed', _fmt(_job.completedAt!)),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final auth = context.read<AuthProvider>();
    final jobProvider = context.read<JobProvider>();
    final isHandyman = auth.userRole == 'handyman';

    if (isHandyman) {
      return _buildHandymanActions(auth, jobProvider);
    }
    return _buildClientActions(auth, jobProvider);
  }

  Widget _buildHandymanActions(AuthProvider auth, JobProvider jobProvider) {
    switch (_job.status) {
      case 'matched':
        return Card(
          margin: const EdgeInsets.only(top: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: jobProvider.isLoading
                        ? null
                        : () => _setStatus('cancelled', auth),
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
                        : () => _accept(auth, jobProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ),
        );
      case 'accepted':
        return _actionCard('Start Heading There', AppColors.accent, () {
          _setStatus('en_route', auth);
        });
      case 'en_route':
        return _actionCard('Start Work', Colors.purple, () {
          _setStatus('in_progress', auth);
        });
      case 'in_progress':
        return Row(
          children: [
            Expanded(child: _chatButton()),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: jobProvider.isLoading
                    ? null
                    : () => _setStatus('completed', auth),
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

  Widget _buildClientActions(AuthProvider auth, JobProvider jobProvider) {
    final reviewProvider = context.watch<ReviewProvider>();
    final active = ['accepted', 'en_route', 'in_progress'];

    if (active.contains(_job.status)) {
      return _chatButton();
    }

    if (_job.status == 'completed' &&
        _job.handymanId != null &&
        !reviewProvider.isRated(_job.id)) {
      return ElevatedButton.icon(
        onPressed: () => _openRate(),
        icon: const Icon(Icons.star_outline, size: 16),
        label: const Text('Rate Handyman'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.warn,
          foregroundColor: Colors.black87,
        ),
      );
    }

    if (_job.status == 'matched' || _job.status == 'searching') {
      return Card(
        margin: const EdgeInsets.only(top: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Waiting for a handyman to accept this job...',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _actionCard(String label, Color color, VoidCallback onPressed) {
    final jobProvider = context.read<JobProvider>();
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: jobProvider.isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }

  Widget _chatButton() {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _openChat,
            icon: const Icon(Icons.chat_bubble_outline, size: 18),
            label: const Text('Chat'),
          ),
        ),
      ),
    );
  }

  Future<void> _accept(AuthProvider auth, JobProvider jobProvider) async {
    await jobProvider.acceptJob(_job.id, auth.token);
    await _refresh();
  }

  Future<void> _setStatus(String status, AuthProvider auth) async {
    await context
        .read<JobProvider>()
        .updateJobStatus(_job.id, status, token: auth.token);
    await _refresh();
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          jobId: _job.id,
          jobTitle: '${_job.serviceType} — ${jobStatusLabel(_job.status)}',
        ),
      ),
    );
  }

  Future<void> _openRate() async {
    final submitted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RateJobScreen(
          jobId: _job.id,
          revieweeId: _job.handymanId ?? '',
          revieweeName: _job.handymanName ?? 'the handyman',
        ),
      ),
    );
    if (submitted == true && mounted) setState(() {});
  }

  String _fmt(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '${dt.month}/${dt.day}/${dt.year} · '
        '${h}:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }

  String _fmtRelative(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}';
  }

  String _fmtPrice(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }
}