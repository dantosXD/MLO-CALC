import 'package:flutter/material.dart';
import 'package:loan_ranger/src/core/models/calculation_history.dart';
import 'package:loan_ranger/src/core/navigation/feature_catalog.dart';
import 'package:loan_ranger/src/core/scenarios/scenario_catalog.dart';
import 'package:loan_ranger/src/features/calculator/application/controllers/history_controller.dart';
import 'package:provider/provider.dart';

class WorkspaceDashboardScreen extends StatelessWidget {
  const WorkspaceDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pinnedFeatures = FeatureCatalog.primaryFeatures
        .where((FeatureCatalogEntry entry) => entry.pinned)
        .toList();

    // totalCount is projected alongside the top-3 list so the hero badge
    // (which shows the full history count) updates when entries are added/removed
    // beyond position 3 — without requiring a separate subscription.
    return Selector<
      HistoryController,
      ({List<CalculationEntry> recent, int totalCount})
    >(
      selector: (_, h) {
        final all = h.entries;
        return (recent: all.take(3).toList(), totalCount: all.length);
      },
      shouldRebuild: (prev, next) {
        if (prev.totalCount != next.totalCount) return true;
        if (prev.recent.length != next.recent.length) return true;
        for (var i = 0; i < prev.recent.length; i++) {
          if (prev.recent[i].id != next.recent[i].id) return true;
        }
        return false;
      },
      builder: (context, history, _) {
        final recentEntries = history.recent;
        final totalCount = history.totalCount;
        return _buildBody(context, recentEntries, totalCount, pinnedFeatures);
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<CalculationEntry> recentEntries,
    int totalCount,
    List<FeatureCatalogEntry> pinnedFeatures,
  ) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workspace Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _WorkspaceHero(
            recentCount: totalCount,
            scenarioCount: ScenarioCatalog.defaults.length,
          ),
          const SizedBox(height: 20),
          _SectionTitle(
            title: 'Pinned Tools',
            subtitle:
                'Jump into the core workflow surfaces without hunting tabs.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: pinnedFeatures.map((FeatureCatalogEntry feature) {
              return _FeatureCard(
                feature: feature,
                compact: true,
                onOpen: () => Navigator.of(context).pop(feature.id),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          _SectionTitle(
            title: 'Scenario Templates',
            subtitle:
                'The current catalog is small, but the shell is ready for more MLO workflows.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ScenarioCatalog.defaults.map((definition) {
              return Chip(
                avatar: const Icon(Icons.layers_outlined, size: 18),
                label: Text('${definition.category}: ${definition.title}'),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          _SectionTitle(
            title: 'Recent Activity',
            subtitle:
                'Recent saved calculations can be reopened into the closest matching tool.',
          ),
          const SizedBox(height: 12),
          if (recentEntries.isEmpty)
            const _EmptyStateCard(
              icon: Icons.history_toggle_off,
              title: 'No recent scenarios yet',
              message:
                  'Run a quote or qualification flow and it will start surfacing here.',
            )
          else
            ...recentEntries.map((CalculationEntry entry) {
              final featureId = _featureIdForEntry(entry);
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.history, size: 18),
                  ),
                  title: Text(entry.title),
                  subtitle: Text(entry.summary),
                  trailing: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    tooltip: 'Open tool',
                    onPressed: () => Navigator.of(context).pop(featureId),
                  ),
                ),
              );
            }),
          const SizedBox(height: 24),
          _SectionTitle(
            title: 'Tool Catalog',
            subtitle:
                'Config-driven navigation now comes from a feature catalog instead of inline arrays.',
          ),
          const SizedBox(height: 12),
          ..._groupByCategory(FeatureCatalog.workspaceFeatures).entries.map((
            MapEntry<String, List<FeatureCatalogEntry>> group,
          ) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.key,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  ...group.value.map((FeatureCatalogEntry feature) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _FeatureCard(
                        feature: feature,
                        onOpen: () => Navigator.of(context).pop(feature.id),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _featureIdForEntry(CalculationEntry entry) {
    if (entry.type == CalculationEntryType.qualification) {
      return FeatureCatalog.qualificationId;
    }
    return FeatureCatalog.calculatorId;
  }

  Map<String, List<FeatureCatalogEntry>> _groupByCategory(
    List<FeatureCatalogEntry> features,
  ) {
    final grouped = <String, List<FeatureCatalogEntry>>{};
    for (final feature in features) {
      grouped.putIfAbsent(feature.category, () => <FeatureCatalogEntry>[]);
      grouped[feature.category]!.add(feature);
    }
    return grouped;
  }
}

class _WorkspaceHero extends StatelessWidget {
  const _WorkspaceHero({
    required this.recentCount,
    required this.scenarioCount,
  });

  final int recentCount;
  final int scenarioCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scenario workspace',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use the dashboard as the shell for quote, qualify, analyze, and follow-up tasks.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricChip(
                label: 'Templates',
                value: '$scenarioCount',
                icon: Icons.layers_outlined,
              ),
              _MetricChip(
                label: 'Recent items',
                value: '$recentCount',
                icon: Icons.history,
              ),
              _MetricChip(
                label: 'Pinned tools',
                value: '${FeatureCatalog.primaryFeatures.length}',
                icon: Icons.push_pin_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text('$label: $value'),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.feature,
    required this.onOpen,
    this.compact = false,
  });

  final FeatureCatalogEntry feature;
  final VoidCallback onOpen;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(child: feature.selectedIcon),
        const SizedBox(height: 12),
        Text(
          feature.title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          feature.description,
          maxLines: compact ? 2 : 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: onOpen,
          icon: const Icon(Icons.open_in_new),
          label: const Text('Open'),
        ),
      ],
    );

    return SizedBox(
      width: compact ? 240 : double.infinity,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: const EdgeInsets.all(16), child: content),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(message),
          ],
        ),
      ),
    );
  }
}
