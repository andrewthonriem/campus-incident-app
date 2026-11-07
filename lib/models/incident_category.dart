import 'package:flutter/material.dart';

enum IncidentCategory {
  facilities('Facilities', Icons.apartment_rounded),
  water('Water', Icons.water_drop_outlined),
  electricity('Electricity', Icons.bolt_outlined),
  furniture('Furniture', Icons.chair_outlined),
  sanitation('Sanitation', Icons.delete_outline),
  safety('Safety', Icons.shield_outlined);

  const IncidentCategory(this.label, this.icon);

  final String label;
  final IconData icon;

  /// Parses the value stored in Firestore. Unknown values fall back to
  /// [IncidentCategory.facilities] so old or malformed documents never crash the UI.
  static IncidentCategory fromName(String? name) {
    return IncidentCategory.values.firstWhere(
      (c) => c.name == name,
      orElse: () => IncidentCategory.facilities,
    );
  }
}
