import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/incident.dart';
import '../../models/incident_status.dart';
import '../../providers/incident_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/firebase_error_message.dart';

class StaffStatusPanel extends StatefulWidget {
  const StaffStatusPanel({super.key, required this.incident});

  final Incident incident;

  @override
  State<StaffStatusPanel> createState() => _StaffStatusPanelState();
}

class _StaffStatusPanelState extends State<StaffStatusPanel> {
  final _note = TextEditingController();
  late IncidentStatus _selected = widget.incident.status;
  bool _saving = false;

  @override
  void didUpdateWidget(covariant StaffStatusPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.incident.status != widget.incident.status) {
      _selected = widget.incident.status;
    }
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selected == widget.incident.status) return;
    final selectedStatus = _selected;
    final note = _note.text;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<IncidentProvider>();
    try {
      await provider.updateStatus(widget.incident, selectedStatus, note: note);
    } on Object catch (e, st) {
      debugPrint('Update failed: $e\n$st');
      if (!mounted) return;
      setState(() => _saving = false);
      final message = e is FirebaseException
          ? firebaseErrorMessage(e, action: 'update the report')
          : 'Could not update the report. Please try again.';
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
      return;
    }
    if (!mounted) return;
    _note.clear();
    setState(() => _saving = false);
    messenger.showSnackBar(
      const SnackBar(content: Text('Report updated successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final changed = _selected != widget.incident.status;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.admin_panel_settings_outlined,
                  color: AppColors.primary),
              SizedBox(width: 8),
              Text('Staff: Update Status',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in IncidentStatus.values)
                ChoiceChip(
                  label: Text(s.label),
                  selected: _selected == s,
                  showCheckmark: false,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color:
                        _selected == s ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected:
                      _saving ? null : (_) => setState(() => _selected = s),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            enabled: !_saving,
            maxLength: 200,
            decoration: const InputDecoration(
              hintText:
                  'Note for the student (optional), e.g. "Plumber assigned"',
            ),
          ),
          const SizedBox(height: 4),
          FilledButton.icon(
            onPressed: (!changed || _saving) ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_outlined),
            label: const Text('Save status'),
          ),
        ],
      ),
    );
  }
}
