import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Foreground-service plumbing for GPS field tracking (doc 01).
///
/// The service only keeps the process alive on Android so the main-isolate GPS
/// loop, heartbeat and point uploads keep running while the app is backgrounded.
/// All tracking logic stays in `TrackingController`.

/// Configures notification + task options. Call once from `main()` before
/// `runApp`.
void initTrackingForegroundTask() {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'field_tracking',
      channelName: 'Field tracking',
      channelDescription:
          'Shown while your location is being recorded for the day.',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
    ),
    iosNotificationOptions: const IOSNotificationOptions(),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.nothing(),
      allowWakeLock: true,
      allowWifiLock: false,
      autoRunOnBoot: false,
    ),
  );
}

/// Background-isolate entry point — must be a top-level function.
@pragma('vm:entry-point')
void trackingServiceCallback() {
  FlutterForegroundTask.setTaskHandler(_TrackingTaskHandler());
}

/// No-op handler: the main isolate owns the GPS stream and uploads, this
/// isolate exists only to satisfy Android's foreground-service requirement.
class _TrackingTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}

/// Starts the Android foreground service (no-op on other platforms).
Future<void> startTrackingService() async {
  if (!Platform.isAndroid) return;
  if (await FlutterForegroundTask.isRunningService) return;

  if (await FlutterForegroundTask.checkNotificationPermission() !=
      NotificationPermission.granted) {
    await FlutterForegroundTask.requestNotificationPermission();
  }

  await FlutterForegroundTask.startService(
    serviceId: 4620,
    serviceTypes: [ForegroundServiceTypes.location],
    notificationTitle: 'Field tracking active',
    notificationText: 'Your location is being recorded.',
    callback: trackingServiceCallback,
  );
}

/// Stops the Android foreground service if it is running.
Future<void> stopTrackingService() async {
  if (!Platform.isAndroid) return;
  if (!await FlutterForegroundTask.isRunningService) return;
  await FlutterForegroundTask.stopService();
}
