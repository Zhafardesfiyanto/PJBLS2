import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../shared/models/cheat_event.dart';

abstract class AntiCheatMonitor {
  Stream<CheatEvent> get violations;
  void startMonitoring();
  void stopMonitoring();
}

class WidgetsBindingObserverAntiCheatMonitor extends AntiCheatMonitor
    with WidgetsBindingObserver {
  WidgetsBindingObserverAntiCheatMonitor({required this.studentId});

  final String studentId;

  final StreamController<CheatEvent> _controller =
      StreamController<CheatEvent>.broadcast();

  @override
  Stream<CheatEvent> get violations => _controller.stream;

  @override
  void startMonitoring() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void stopMonitoring() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _controller.add(
        CheatEvent(
          type: CheatEventType.appSwitch,
          timestampUtc: DateTime.now().toUtc(),
          studentId: studentId,
        ),
      );
    }
  }

  void dispose() {
    stopMonitoring();
    _controller.close();
  }
}
