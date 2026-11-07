import 'package:flutter/material.dart';

/// Lifecycle of a report: submitted -> inProgress -> resolved.
/// Staff may also mark a report as rejected (e.g. duplicate or invalid).
enum IncidentStatus {
  submitted('Submitted', Color(0xFFE07B39), Color(0xFFFFE8DC)),
  inProgress('In Progress', Color(0xFF2D3A5A), Color(0xFFE3E7F2)),
  resolved('Resolved', Color(0xFF2E9E6B), Color(0xFFDDF4EA)),
  rejected('Rejected', Color(0xFFA65D5D), Color(0xFFF6E1E1));

  const IncidentStatus(this.label, this.foreground, this.background);

  final String label;
  final Color foreground;
  final Color background;

  static IncidentStatus fromName(String? name) {
    return IncidentStatus.values.firstWhere(
      (s) => s.name == name,
      orElse: () => IncidentStatus.submitted,
    );
  }

  /// The statuses shown as steps on the timeline (rejected is shown separately).
  static const List<IncidentStatus> timelineSteps = [
    IncidentStatus.submitted,
    IncidentStatus.inProgress,
    IncidentStatus.resolved,
  ];
}
