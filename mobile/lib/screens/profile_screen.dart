import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _syncProfile();
  }

  Future<void> _syncProfile() async {
    setState(() => _isSyncing = true);
    await context.read<AuthProvider>().loadProfile();
    if (mounted) setState(() => _isSyncing = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (_isSyncing)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _syncProfile,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),
            Center(
              child: CircleAvatar(
                radius: 48,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 40, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                user.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Chip(
                avatar: Icon(
                  user.role == 'handyman' ? Icons.build : Icons.person,
                  size: 18,
                ),
                label: Text(user.role.toUpperCase()),
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                user.email,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            if (user.phone != null && user.phone!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.phone, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      user.phone!,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Divider(),
            _InfoRow(
              icon: Icons.star,
              label: 'Rating',
              value: user.rating != null ? '${user.rating!.toStringAsFixed(1)} / 5' : 'No rating',
            ),
            _InfoRow(
              icon: Icons.reviews,
              label: 'Reviews',
              value: user.reviewCount != null ? '${user.reviewCount}' : '0',
            ),
            if (user.role == 'handyman') ...[
              _InfoRow(
                icon: Icons.circle,
                label: 'Status',
                value: user.isAvailable == true ? 'Available' : 'Unavailable',
                valueColor: user.isAvailable == true ? Colors.green : Colors.orange,
              ),
              if (user.skills != null && user.skills!.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Skills', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: user.skills!
                      .map((s) => Chip(label: Text(s.replaceAll('_', ' '))))
                      .toList(),
                ),
              ],
            ],
            const SizedBox(height: 24),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Profile'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await auth.logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(color: valueColor ?? Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}