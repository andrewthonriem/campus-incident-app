import 'package:flutter/material.dart';

import '../models/incident.dart';
import '../models/incident_status.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';

class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context) {
    if (incident.status == IncidentStatus.rejected) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: IncidentStatus.rejected.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.block, color: IncidentStatus.rejected.foreground),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('This report was closed by staff without action.'),
            ),
          ],
        ),
      );
    }

    const steps = IncidentStatus.timelineSteps;
    final currentIndex = steps.indexOf(incident.status);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Expanded(
            child: _Step(
              status: steps[i],
              state: i < currentIndex
                  ? _StepState.done
                  : i == currentIndex
                      ? (steps[i] == IncidentStatus.resolved
                          ? _StepState.done
                          : _StepState.current)
                      : _StepState.pending,
              date: incident.reachedAt(steps[i]),
            ),
          ),
        ],
      ],
    );
  }
}

enum _StepState { done, current, pending }

class _Step extends StatelessWidget {
  const _Step({required this.status, required this.state, this.date});

  final IncidentStatus status;
  final _StepState state;
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (state) {
      _StepState.done => AppColors.primary,
      _StepState.current => AppColors.primary,
      _StepState.pending => AppColors.border,
    };
    final IconData icon = switch (state) {
      _StepState.done => Icons.check,
      _StepState.current => Icons.more_horiz,
      _StepState.pending => Icons.circle_outlined,
    };
    return Column(
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: color,
          child: Icon(icon,
              size: 16,
              color: state == _StepState.pending
                  ? AppColors.textSecondary
                  : Colors.white),
        ),
        const SizedBox(height: 6),
        Text(
          status.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: state == _StepState.pending
                ? AppColors.textSecondary
                : AppColors.textPrimary,
          ),
        ),
        Text(
          date != null ? shortDate(date!) : '—',
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
