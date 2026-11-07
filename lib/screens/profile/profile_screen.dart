import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/incident_status.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sign out')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<AuthProvider>().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final incidents = context.watch<IncidentProvider>();
    if (user == null) return const SizedBox.shrink();
    final mine = incidents.myIncidents;
    int count(IncidentStatus s) => mine.where((i) => i.status == s).length;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          const Text('Profile',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(user.initials,
                        style: const TextStyle(
                            fontSize: 22,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(user.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: user.isStaff
                                    ? AppColors.primary
                                    : AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                user.role.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: user.isStaff
                                      ? Colors.white
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(user.email,
                            style: const TextStyle(
                                color: AppColors.textSecondary)),
                        if (user.department.isNotEmpty)
                          Text(user.department,
                              style: const TextStyle(
                                  color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Stat(
                  value: mine.length,
                  label: 'Total Reports',
                  color: AppColors.primary),
              const SizedBox(width: 8),
              _Stat(
                  value: count(IncidentStatus.inProgress),
                  label: 'In Progress',
                  color: IncidentStatus.inProgress.foreground),
              const SizedBox(width: 8),
              _Stat(
                  value: count(IncidentStatus.resolved),
                  label: 'Resolved',
                  color: IncidentStatus.resolved.foreground),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.verified_user_outlined),
                  title: const Text('Account type'),
                  subtitle: Text(user.isStaff
                      ? 'Staff — can review and update all reports'
                      : 'Student — can submit and track reports'),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('About Campus Fix'),
                  subtitle: Text('Version 1.0.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.brick),
                  title: const Text('Sign out',
                      style: TextStyle(color: AppColors.brick)),
                  onTap: () => _signOut(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.color});
  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text('$value',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
