import '../models/incident.dart';
import '../models/incident_category.dart';
import '../models/incident_status.dart';

class IncidentFilter {
  const IncidentFilter({
    this.query = '',
    this.category,
    this.status,
    this.mineOnly = false,
  });

  final String query;
  final IncidentCategory? category;
  final IncidentStatus? status;
  final bool mineOnly;

  bool get isActive =>
      query.trim().isNotEmpty || category != null || status != null || mineOnly;

  IncidentFilter copyWith({
    String? query,
    IncidentCategory? Function()? category,
    IncidentStatus? Function()? status,
    bool? mineOnly,
  }) {
    return IncidentFilter(
      query: query ?? this.query,
      category: category != null ? category() : this.category,
      status: status != null ? status() : this.status,
      mineOnly: mineOnly ?? this.mineOnly,
    );
  }
}

List<Incident> applyIncidentFilter(
  List<Incident> incidents,
  IncidentFilter filter, {
  String? currentUid,
}) {
  final q = filter.query.trim().toLowerCase();
  return incidents.where((i) {
    if (filter.mineOnly && i.reporterId != currentUid) return false;
    if (filter.category != null && i.category != filter.category) return false;
    if (filter.status != null && i.status != filter.status) return false;
    if (q.isEmpty) return true;
    return i.title.toLowerCase().contains(q) ||
        i.description.toLowerCase().contains(q) ||
        i.location.toLowerCase().contains(q) ||
        i.category.label.toLowerCase().contains(q);
  }).toList();
}

Map<IncidentStatus, int> countByStatus(Iterable<Incident> incidents) {
  final counts = {for (final s in IncidentStatus.values) s: 0};
  for (final i in incidents) {
    counts[i.status] = counts[i.status]! + 1;
  }
  return counts;
}
