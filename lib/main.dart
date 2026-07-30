import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app_root.dart';
import 'app/app_routes.dart';
import 'core/theme/app_theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(Root(key: Root.rootKey));
}

/// Root widget that can restart [ProviderScope] on logout.
class Root extends StatefulWidget {
  const Root({super.key});

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
      child: const ProviderScope(
        child: ErpApp(),
      ),
    );
  }
}

class ErpApp extends StatelessWidget {
  const ErpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Immortal ERP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      navigatorKey: navigatorKey,
      home: const AppRoot(),
      routes: AppRoutes.routes,
    );
  }
}
