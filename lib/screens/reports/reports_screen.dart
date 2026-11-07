import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/incident_category.dart';
import '../../models/incident_status.dart';
import '../../providers/incident_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/incident_card.dart';
import '../detail/incident_detail_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _search.text = context.read<IncidentProvider>().filter.query;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<IncidentProvider>().setQuery(value);
    });
  }

  Future<void> _pickCategory() async {
    final provider = context.read<IncidentProvider>();
    final picked = await showModalBottomSheet<_CategoryChoice>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.apps),
              title: const Text('All categories'),
              onTap: () => Navigator.pop(ctx, const _CategoryChoice(null)),
            ),
            for (final c in IncidentCategory.values)
              ListTile(
                leading: Icon(c.icon, color: AppColors.primary),
                title: Text(c.label),
                trailing: provider.filter.category == c
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, _CategoryChoice(c)),
              ),
          ],
        ),
      ),
    );
    if (picked != null) provider.setCategory(picked.category);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<IncidentProvider>();
    final f = p.filter;
    final results = p.filtered;

    if (f.query.isEmpty &&
        _search.text.isNotEmpty &&
        !(_debounce?.isActive ?? false)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _search.clear();
      });
    }

    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Reports',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _search,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search by title, location or description',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _search.clear();
                          p.setQuery('');
                        },
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                    value: false,
                    label: Text('All reports'),
                    icon: Icon(Icons.public)),
                ButtonSegment(
                    value: true,
                    label: Text('My reports'),
                    icon: Icon(Icons.person)),
              ],
              selected: {f.mineOnly},
              showSelectedIcon: false,
              onSelectionChanged: (s) => p.setMineOnly(s.first),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _FilterChip(
                  label: 'All',
                  selected: f.status == null,
                  onTap: () => p.setStatus(null),
                ),
                for (final s in IncidentStatus.values)
                  _FilterChip(
                    label: s.label,
                    selected: f.status == s,
                    onTap: () => p.setStatus(f.status == s ? null : s),
                  ),
                const SizedBox(width: 4),
                ActionChip(
                  avatar: Icon(f.category?.icon ?? Icons.tune, size: 18),
                  label: Text(f.category?.label ?? 'Category'),
                  onPressed: _pickCategory,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
            child: Row(
              children: [
                Text(
                    '${results.length} result${results.length == 1 ? '' : 's'}',
                    style: const TextStyle(color: AppColors.textSecondary)),
                const Spacer(),
                if (f.isActive)
                  TextButton.icon(
                    onPressed: () {
                      _search.clear();
                      p.clearFilters();
                    },
                    icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                    label: const Text('Clear filters'),
                  ),
              ],
            ),
          ),
          Expanded(child: _buildList(context, p)),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, IncidentProvider p) {
    if (p.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (p.error != null) {
      return EmptyState(icon: Icons.cloud_off, title: p.error!);
    }
    final results = p.filtered;
    if (results.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off,
        title: 'No matching reports',
        message: 'Try a different search term or clear the filters.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => IncidentCard(
        incident: results[i],
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => IncidentDetailScreen(incidentId: results[i].id),
        )),
      ),
    );
  }
}

class _CategoryChoice {
  const _CategoryChoice(this.category);
  final IncidentCategory? category;
}

class _FilterChip extends StatelessWidget {
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        onSelected: (_) => onTap(),
      ),
    );
  }
}
