import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/incident_status.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/incident_card.dart';
import '../../widgets/summary_card.dart';
import '../detail/incident_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.onSeeAllReports,
    required this.onReport,
  });

  final VoidCallback onSeeAllReports;
  final VoidCallback onReport;

  void _openFiltered(BuildContext context, IncidentStatus? status) {
    final p = context.read<IncidentProvider>();
    final isStaff = context.read<AuthProvider>().isStaff;
    p.clearFilters();
    p.setMineOnly(!isStaff);
    p.setStatus(status);
    onSeeAllReports();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final incidents = context.watch<IncidentProvider>();
    final isStaff = user?.isStaff ?? false;
    final summary = incidents.summary;
    final recent = (isStaff
            ? incidents.all.where((i) => i.status == IncidentStatus.submitted)
            : incidents.myIncidents)
        .take(5)
        .toList();
    final firstName = (user?.name ?? '').split(' ').first;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () =>
            Future<void>.delayed(const Duration(milliseconds: 600)),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hello, $firstName!',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(
                        isStaff
                            ? 'Review new reports and keep students updated.'
                            : 'Help make our campus safer.',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(user?.initials ?? '?',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (isStaff)
              _StaffBanner(onReviewReports: onSeeAllReports)
            else
              _ReportBanner(onReport: onReport),
            const SizedBox(height: 24),
            _SectionHeader(
              title: isStaff ? 'Campus Overview' : 'Report Summary',
              onSeeAll: () => _openFiltered(context, null),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SummaryCard(
                    icon: Icons.description_outlined,
                    count: incidents.summaryTotal,
                    label: isStaff ? 'All Reports' : 'My Reports',
                    color: AppColors.primary,
                    onTap: () => _openFiltered(context, null),
                  ),
                ),
                const SizedBox(width: 8),
                for (final s in [
                  IncidentStatus.submitted,
                  IncidentStatus.inProgress,
                  IncidentStatus.resolved,
                ]) ...[
                  Expanded(
                    child: SummaryCard(
                      icon: switch (s) {
                        IncidentStatus.submitted => Icons.error_outline,
                        IncidentStatus.inProgress => Icons.schedule,
                        _ => Icons.check_circle_outline,
                      },
                      count: summary[s] ?? 0,
                      label: s.label,
                      color: s.foreground,
                      onTap: () => _openFiltered(context, s),
                    ),
                  ),
                  if (s != IncidentStatus.resolved) const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              title: isStaff ? 'Awaiting Review' : 'Recent Reports',
              onSeeAll: () => _openFiltered(
                  context, isStaff ? IncidentStatus.submitted : null),
            ),
            const SizedBox(height: 12),
            if (incidents.isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (incidents.error != null)
              EmptyState(icon: Icons.cloud_off, title: incidents.error!)
            else if (recent.isEmpty)
              EmptyState(
                icon: isStaff ? Icons.inbox_outlined : Icons.campaign_outlined,
                title: isStaff ? 'No new reports' : 'No reports yet',
                message: isStaff
                    ? 'Everything submitted has been reviewed.'
                    : 'When you report an issue it will appear here.',
              )
            else
              for (final i in recent)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: IncidentCard(
                    incident: i,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => IncidentDetailScreen(incidentId: i.id),
                    )),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onSeeAll});

  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ),
        TextButton(onPressed: onSeeAll, child: const Text('See all')),
      ],
    );
  }
}

class _ReportBanner extends StatelessWidget {
  const _ReportBanner({required this.onReport});

  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: AssetImage(
            '.campus pics/WhatsApp Image 2026-10-15 at 11.39.28 PM.jpeg',
          ),
          fit: BoxFit.cover,
          opacity: 0.18,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('See an issue on campus?',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Report it and help improve our learning environment.',
              style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onReport,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.accent,
                      child: Icon(Icons.add, size: 18, color: Colors.white),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text('Report an Issue',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                    ),
                    Icon(Icons.chevron_right, color: AppColors.primary),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffBanner extends StatelessWidget {
  const _StaffBanner({required this.onReviewReports});

  final VoidCallback onReviewReports;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: AssetImage(
            '.campus pics/WhatsApp Image 2026-10-15 at 11.39.28 PM.jpeg',
          ),
          fit: BoxFit.cover,
          opacity: 0.18,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Staff dashboard',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Review campus issues and keep students updated as they are resolved.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onReviewReports,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.accent,
                      child: Icon(
                        Icons.admin_panel_settings_outlined,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Review campus reports',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: AppColors.primary),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
