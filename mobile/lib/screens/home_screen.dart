import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../app_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/job_provider.dart';
import '../services/socket_service.dart';
import 'create_job_screen.dart';
import 'job_list_screen.dart';
import 'profile_screen.dart';
import 'handyman_jobs_screen.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double _demoLatitude = DemoLocation.latitude;
  static const double _demoLongitude = DemoLocation.longitude;

  late final LatLng _center = LatLng(
    double.tryParse(const String.fromEnvironment('MAP_LAT')) ?? _demoLatitude,
    double.tryParse(const String.fromEnvironment('MAP_LNG')) ?? _demoLongitude,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSocket();
    });
  }

  void _initSocket() {
    final auth = context.read<AuthProvider>();
    final socket = context.read<SocketService>();
    final jobProvider = context.read<JobProvider>();

    if (auth.token != null && !socket.connected) {
      socket.connect(auth.token!);
      if (auth.userId != null) {
        socket.registerUser(auth.userId!);
      }

      socket.on('handymanFound', (data) {
        if (data is Map<String, dynamic> && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Found handyman: ${data['handymanName'] ?? 'Unknown'}'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      });

      socket.on('jobOffered', (data) {
        if (data is Map<String, dynamic> && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('New job offer!'),
              backgroundColor: AppColors.primary,
              action: SnackBarAction(
                label: 'View',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HandymanJobsScreen(),
                    ),
                  );
                },
              ),
            ),
          );
        }
      });

      socket.on('jobAccepted', (data) {
        if (data is Map<String, dynamic> && mounted) {
          final jobId = data['jobId'];
          if (jobId != null) {
            jobProvider.updateJobFromSocket(jobId, {
              'status': 'accepted',
              'handymanId': data['handymanId'],
            });
          }
        }
      });

      socket.on('jobStatusUpdated', (data) {
        if (data is Map<String, dynamic> && mounted) {
          final jobId = data['jobId'];
          final status = data['status'];
          if (jobId != null && status != null) {
            jobProvider.updateJobFromSocket(jobId, {'status': status});
          }
        }
      });
    }
  }

  Future<void> _refreshNearby(BuildContext context) async {
    final jobProvider = context.read<JobProvider>();
    final auth = context.read<AuthProvider>();
    await jobProvider.searchNearbyHandymen(
      latitude: _center.latitude,
      longitude: _center.longitude,
      radiusInMeters: 5000,
      token: auth.token,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isHandyman = auth.userRole == 'handyman';
    final jobProvider = context.watch<JobProvider>();
    final socket = context.watch<SocketService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Handyman App'),
        actions: [
          if (socket.connected)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.circle, size: 8, color: Colors.green),
            ),
          if (!isHandyman)
            IconButton(
              tooltip: 'Refresh nearby handymen',
              icon: const Icon(Icons.location_searching),
              onPressed: jobProvider.isLoading
                  ? null
                  : () => _refreshNearby(context),
            ),
        ],
      ),
      drawer: _buildDrawer(context, auth, isHandyman),
      body: isHandyman
          ? _buildHandymanBody(context, auth, jobProvider)
          : _buildClientBody(context, auth, jobProvider),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthProvider auth, bool isHandyman) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            accountName: Text(auth.userName ?? 'User'),
            accountEmail: Text(auth.userEmail ?? ''),
            currentAccountPicture: const CircleAvatar(
              child: Icon(Icons.person),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.map),
            title: const Text('Home'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('My Jobs'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => isHandyman
                      ? const HandymanJobsScreen()
                      : const JobListScreen(),
                ),
              );
            },
          ),
          if (!isHandyman) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Request Service'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateJobScreen()),
                );
              },
            ),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              context.read<SocketService>().disconnect();
              await auth.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildClientBody(
    BuildContext context,
    AuthProvider auth,
    JobProvider jobProvider,
  ) {
    return Column(
      children: [
        Expanded(
          flex: 6,
          child: _buildMap(auth, jobProvider),
        ),
        Expanded(
          flex: 4,
          child: _buildNearbyList(context, auth, jobProvider),
        ),
      ],
    );
  }

  Widget _buildHandymanBody(
    BuildContext context,
    AuthProvider auth,
    JobProvider jobProvider,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.handyman,
              size: 80,
              color: AppColors.primary.withAlpha(60),
            ),
            const SizedBox(height: 24),
            const Text(
              'Handyman Dashboard',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Welcome, ${auth.userName ?? 'Handyman'}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HandymanJobsScreen(),
                  ),
                ),
                icon: const Icon(Icons.work),
                label: const Text('View My Jobs'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfileScreen(),
                  ),
                ),
                icon: const Icon(Icons.person),
                label: const Text('Edit Profile'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(AuthProvider auth, JobProvider jobProvider) {
    final markers = <Marker>[
      Marker(
        point: LatLng(_center.latitude, _center.longitude),
        width: 80,
        height: 80,
        child: Icon(
          Icons.location_on,
          size: 40,
          color: Theme.of(context).colorScheme.error,
        ),
      ),
      ...jobProvider.nearbyHandymen.map((h) => Marker(
            point: LatLng(h.latitude, h.longitude),
            width: 60,
            height: 60,
            child: const Icon(
              Icons.handyman,
              size: 32,
              color: Color(0xFF2C6E49),
            ),
          )),
    ];

    return FlutterMap(
      options: MapOptions(
        initialCenter: _center,
        initialZoom: 13,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.handyman',
          maxZoom: 19,
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }

  Widget _buildNearbyList(
    BuildContext context,
    AuthProvider auth,
    JobProvider jobProvider,
  ) {
    final handymen = jobProvider.nearbyHandymen;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text(
                  'Nearby Handymen',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: jobProvider.isLoading
                      ? null
                      : () => _refreshNearby(context),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          ),
          Expanded(
            child: jobProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : handymen.isEmpty
                    ? const Center(
                        child: Text(
                          'No handymen found nearby.\nPull the map to a location and refresh.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: handymen.length,
                        itemBuilder: (context, index) {
                          final h = handymen[index];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(h.name.isNotEmpty
                                  ? h.name[0].toUpperCase()
                                  : '?'),
                            ),
                            title: Text(h.name),
                            subtitle: Text(
                              '${h.distanceInMeters.round()} m away'
                              '${h.skills != null && h.skills!.isNotEmpty ? ' · ${h.skills!.join(', ')}' : ''}',
                            ),
                            trailing: h.rating != null
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star,
                                          size: 18, color: Colors.amber),
                                      Text(
                                        h.rating!.toStringAsFixed(1),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  )
                                : null,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
