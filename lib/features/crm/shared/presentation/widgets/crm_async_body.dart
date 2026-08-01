import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared loading / error / empty shell for CRM thin screens.
class CrmAsyncBody<T> extends StatelessWidget {
  final AsyncValue<T> async;
  final VoidCallback onRetry;
  final String emptyLabel;
  final Widget Function(T data) builder;

  const CrmAsyncBody({
    super.key,
    required this.async,
    required this.onRetry,
    required this.builder,
    this.emptyLabel = 'No data',
  });

  @override
  Widget build(BuildContext context) {
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                e.toString().replaceFirst('Exception: ', ''),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
      data: builder,
    );
  }
}

class CrmLogicHint extends StatelessWidget {
  final String text;

  const CrmLogicHint(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
