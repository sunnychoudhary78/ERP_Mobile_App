import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Can extends ConsumerWidget {
  final List<String> anyOf;
  final Widget child;
  final Widget? fallback;

  const Can({
    super.key,
    required this.anyOf,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (!authState.canAny(anyOf)) {
      return fallback ?? const SizedBox.shrink();
    }
    return child;
  }
}