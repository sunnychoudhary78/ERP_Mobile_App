import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app_root.dart';
import 'app/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final prefs = await SharedPreferences.getInstance();
  final settings = ThemeController.readFrom(prefs);
  // Apply the persisted palette before the first frame.
  AppColors.apply(
    AppPalette.forBrightness(
      settings.effectiveBrightness(
        WidgetsBinding.instance.platformDispatcher.platformBrightness,
      ),
      settings.seedColor,
    ),
  );

  runApp(Root(key: Root.rootKey, prefs: prefs));
}

/// Root widget that can restart [ProviderScope] on logout.
class Root extends StatefulWidget {
  final SharedPreferences prefs;

  const Root({super.key, required this.prefs});

  static final GlobalKey<RootState> rootKey = GlobalKey<RootState>();

  @override
  State<Root> createState() => RootState();

  static void restartApp() {
    rootKey.currentState?.restart();
  }
}

class RootState extends State<Root> {
  Key _key = UniqueKey();

  void restart() {
    setState(() => _key = UniqueKey());
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _key,
      child: ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(widget.prefs),
        ],
        child: const ErpApp(),
      ),
    );
  }
}

class ErpApp extends ConsumerStatefulWidget {
  const ErpApp({super.key});

  @override
  ConsumerState<ErpApp> createState() => _ErpAppState();
}

class _ErpAppState extends ConsumerState<ErpApp> with WidgetsBindingObserver {
  late Brightness _platformBrightness =
      WidgetsBinding.instance.platformDispatcher.platformBrightness;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    setState(() {
      _platformBrightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(themeControllerProvider);

    // Keep the global palette in sync with the active theme before the
    // subtree builds.
    AppColors.apply(
      AppPalette.forBrightness(
        settings.effectiveBrightness(_platformBrightness),
        settings.seedColor,
      ),
    );

    return MaterialApp(
      title: 'Immortal ERP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(settings.seedColor),
      darkTheme: AppTheme.dark(settings.seedColor),
      themeMode: settings.mode,
      navigatorKey: navigatorKey,
      home: ThemeRebuilder(childBuilder: (_) => const AppRoot()),
      routes: AppRoutes.routes,
    );
  }
}
