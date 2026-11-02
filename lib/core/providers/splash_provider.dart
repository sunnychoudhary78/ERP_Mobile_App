import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Tracks whether the initial splash screen animation has finished.
///
/// By keeping this in a provider, the state survives when [AppRoot] is disposed
/// and recreated (e.g. during a theme change), preventing the splash from
/// re-triggering when the user navigates back from a screen.
final splashCompleteProvider = StateProvider<bool>((ref) => false);
