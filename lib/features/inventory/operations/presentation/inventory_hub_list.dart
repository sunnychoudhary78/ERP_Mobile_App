import 'package:flutter/material.dart';

/// One entry on an inventory hub screen.
class HubSection {
  const HubSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.requiredPermissions = const [],
    required this.builder,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> requiredPermissions;
  final WidgetBuilder builder;
}

/// A clean menu page: each entry opens its own full screen.
class InventoryHubScaffold extends StatelessWidget {
  const InventoryHubScaffold({
    super.key,
    required this.title,
    required this.sections,
  });

  final String title;
  final List<HubSection> sections;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final section = sections[index];
          return Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(section.icon, color: scheme.onPrimaryContainer),
              ),
              title: Text(
                section.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(section.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: section.builder),
              ),
            ),
          );
        },
      ),
    );
  }
}
