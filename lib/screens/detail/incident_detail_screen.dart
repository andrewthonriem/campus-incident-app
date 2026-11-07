import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/incident.dart';
import '../../models/incident_status.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/firebase_error_message.dart';
import '../../utils/time_format.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/status_timeline.dart';
import 'staff_status_panel.dart';

class IncidentDetailScreen extends StatefulWidget {
  const IncidentDetailScreen({super.key, required this.incidentId});

  final String incidentId;

  @override
  State<IncidentDetailScreen> createState() => _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends State<IncidentDetailScreen> {
  late final Stream<Incident?> _stream =
      context.read<IncidentProvider>().watch(widget.incidentId);

  String get incidentId => widget.incidentId;

  Future<void> _confirmWithdraw(BuildContext context, Incident incident) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final provider = context.read<IncidentProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Withdraw report?'),
        content:
            const Text('This permanently deletes the report and its photo.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Withdraw')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await provider.withdraw(incident);
    } on Object catch (e, st) {
      debugPrint('Update failed: $e\n$st');
      if (!mounted) return;
      final message = e is FirebaseException
          ? firebaseErrorMessage(e, action: 'withdraw the report')
          : 'Could not withdraw the report. Please try again.';
      messenger.showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }
    if (!mounted) return;
    navigator.pop();
    messenger.showSnackBar(const SnackBar(content: Text('Report withdrawn.')));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<IncidentProvider>();
    final user = context.watch<AuthProvider>().user;

    return StreamBuilder<Incident?>(
      stream: _stream,
      initialData: provider.byId(incidentId),
      builder: (context, snap) {
        final incident = snap.data;
        if (incident == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Incident Details')),
            body: snap.connectionState == ConnectionState.waiting
                ? const Center(child: CircularProgressIndicator())
                : const EmptyState(
                    icon: Icons.delete_outline,
                    title: 'This report no longer exists'),
          );
        }
        final isOwner = incident.reporterId == user?.uid;
        final canWithdraw =
            isOwner && incident.status == IncidentStatus.submitted;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Incident Details'),
            actions: [
              if (canWithdraw)
                PopupMenuButton<String>(
                  onSelected: (_) => _confirmWithdraw(context, incident),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                        value: 'withdraw', child: Text('Withdraw report')),
                  ],
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _HeaderCard(incident: incident),
              const SizedBox(height: 20),
              const _SectionTitle('Status Timeline'),
              StatusTimeline(incident: incident),
              const SizedBox(height: 20),
              const _SectionTitle('Description'),
              Text(incident.description, style: const TextStyle(height: 1.45)),
              const SizedBox(height: 20),
              if (incident.hasImage) ...[
                const _SectionTitle('Attached Photo'),
                GestureDetector(
                  onTap: () => _openPhoto(context, incident.imageUrl!),
                  child: Hero(
                    tag: 'photo-${incident.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        incident.imageUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox(
                          height: 120,
                          child:
                              Center(child: Icon(Icons.broken_image_outlined)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              if (incident.history.isNotEmpty) ...[
                const _SectionTitle('Activity'),
                for (final h in incident.history.reversed)
                  _HistoryTile(change: h),
                const SizedBox(height: 12),
              ],
              if (user?.isStaff ?? false) StaffStatusPanel(incident: incident),
            ],
          ),
        );
      },
    );
  }

  void _openPhoto(BuildContext context, String url) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
            backgroundColor: Colors.black, foregroundColor: Colors.white),
        body: Center(
          child: Hero(
            tag: 'photo-$incidentId',
            child: InteractiveViewer(child: Image.network(url)),
          ),
        ),
      ),
    ));
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.incident});
  final Incident incident;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(incident.category.icon, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(incident.title,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w800)),
                      Text(incident.category.label,
                          style:
                              const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StatusBadge(status: incident.status),
            const Divider(height: 24),
            _MetaRow(icon: Icons.location_on_outlined, text: incident.location),
            _MetaRow(
                icon: Icons.calendar_today_outlined,
                text: 'Submitted on ${fullDate(incident.createdAt)}'),
            _MetaRow(
                icon: Icons.person_outline,
                text: 'Reported by ${incident.reporterName}'),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.change});
  final StatusChange change;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: change.status.background,
        child: Icon(Icons.flag_outlined,
            size: 16, color: change.status.foreground),
      ),
      title: Text('${change.status.label} · ${change.changedByName}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(
        [shortDate(change.at), if (change.note.isNotEmpty) '“${change.note}”']
            .join('\n'),
      ),
    );
  }
}
