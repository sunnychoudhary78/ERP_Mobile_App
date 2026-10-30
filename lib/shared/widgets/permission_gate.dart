import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_state.dart';
import 'package:erp_app/shared/widgets/can_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Soft-guards a full screen: shows a no-access message when the user
/// lacks any of [anyOf], or fails the optional [entitlement] check.
/// Empty [anyOf] + null [entitlement] always allows (authenticated-only).
class PermissionGate extends ConsumerWidget {
  final List<String> anyOf;
  final Widget child;
  final String message;
  final bool Function(AuthState auth)? entitlement;

  const PermissionGate({
    super.key,
    required this.anyOf,
    required this.child,
    this.message = "You don't have permission to view this screen",
    this.entitlement,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final allowed =
        auth.canAny(anyOf) && (entitlement?.call(auth) ?? true);
    if (!allowed) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ),
      );
    }
    return child;
  }
}

/// Convenience: hide [child] when lacking permissions (same as [Can]).
typedef PermissionCan = Can;
