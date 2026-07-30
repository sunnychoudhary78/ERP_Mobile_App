import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shared stub screen for features not yet implemented.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? featurePath;

  const PlaceholderScreen({
    super.key,
    required this.title,
    this.subtitle,
    this.featurePath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle ??
                  'TODO: implement this screen. Replace PlaceholderScreen with real UI.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                  ),
            ),
            if (featurePath != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'Feature folder:\n$featurePath\n\n'
                  'Add: data/ (API + models) → presentation/providers → replace this screen.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: AppColors.text,
                        height: 1.45,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
