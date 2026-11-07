import 'package:flutter/material.dart';

import '../models/incident.dart';
import '../theme/app_theme.dart';

class IncidentThumbnail extends StatelessWidget {
  const IncidentThumbnail({super.key, required this.incident, this.size = 64});

  final Incident incident;
  final double size;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      color: AppColors.primaryLight,
      child: Icon(incident.category.icon,
          color: AppColors.primary, size: size * 0.45),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: incident.thumbnail != null
          ? Image.memory(
              incident.thumbnail!,
              width: size,
              height: size,
              fit: BoxFit.cover,
            )
          : incident.imageUrl != null && incident.imageUrl!.isNotEmpty
              ? Image.network(
                  incident.imageUrl!,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => placeholder,
                  loadingBuilder: (context, child, progress) =>
                      progress == null ? child : placeholder,
                )
              : placeholder,
    );
  }
}
