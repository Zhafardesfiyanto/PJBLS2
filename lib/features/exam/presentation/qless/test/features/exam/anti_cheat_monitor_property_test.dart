import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qless/shared/models/cheat_event.dart';

// ---------------------------------------------------------------------------
// FakeAntiCheatMonitor — in-memory implementation for property testing
// ---------------------------------------------------------------------------

/// A testable in-memory implementation of the AntiCheatMonitor contract.
///
/// Mirrors the logic of [WidgetsBindingObserverAntiCheatMonitor] without
/// depending on [WidgetsBinding.instance], making it safe to run in pure
/// Dart unit tests.
class FakeAntiCheatMonitor {
  FakeAntiCheatMonitor({required this.studentId});

  final String studentId;

  final StreamController<CheatEvent> _controller =
      StreamController<CheatEvent>.broadcast();

  Stream<CheatEvent> get violations => _controller.stream;

  /// Simulates a [WidgetsBindingObserver.didChangeAppLifecycleState] callback.
  ///
  /// Emits exactly one [CheatEvent] with [CheatEventType.appSwitch] when
  /// [state] is [AppLifecycleState.paused] or [AppLifecycleState.inactive].
  /// Does nothing for all other states.
  void simulateLifecycleEvent(AppLifecycleState state) {
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
    _controller.close();
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// All lifecycle states under test.
const _allStates = AppLifecycleState.values;

/// States that MUST produce exactly one CheatEvent.
const _violatingStates = {
  AppLifecycleState.paused,
  AppLifecycleState.inactive,
};

/// Collects all events emitted synchronously by [monitor] when
/// [simulateLifecycleEvent] is called with [state].
Future<List<CheatEvent>> _collectEvents(
  FakeAntiCheatMonitor monitor,
  AppLifecycleState state,
) async {
  final events = <CheatEvent>[];
  final sub = monitor.violations.listen(events.add);
  monitor.simulateLifecycleEvent(state);
  // Allow microtasks / stream callbacks to flush.
  await Future<void>.delayed(Duration.zero);
  await sub.cancel();
  return events;
}

// ---------------------------------------------------------------------------
// Property tests
// ---------------------------------------------------------------------------

void main() {
  /// **Validates: Requirements 8.3**
  ///
  /// Property 2:
  ///   For all AppLifecycleState events:
  ///     IF state == paused OR state == inactive:
  ///       THEN exactly 1 CheatEvent is emitted on violations stream
  ///     ELSE:
  ///       THEN 0 CheatEvents are emitted on violations stream
  group(
    'AntiCheatMonitor — Property 2: app-switch lifecycle events produce '
    'exactly one CheatEvent',
    () {
      // -----------------------------------------------------------------------
      // Core property: violating states emit exactly 1 event
      // -----------------------------------------------------------------------

      test(
        'paused state emits exactly 1 CheatEvent',
        () async {
          final monitor = FakeAntiCheatMonitor(studentId: 'student-001');
          final events =
              await _collectEvents(monitor, AppLifecycleState.paused);
          expect(
            events.length,
            equals(1),
            reason: 'paused must emit exactly 1 CheatEvent',
          );
          monitor.dispose();
        },
      );

      test(
        'inactive state emits exactly 1 CheatEvent',
        () async {
          final monitor = FakeAntiCheatMonitor(studentId: 'student-001');
          final events =
              await _collectEvents(monitor, AppLifecycleState.inactive);
          expect(
            events.length,
            equals(1),
            reason: 'inactive must emit exactly 1 CheatEvent',
          );
          monitor.dispose();
        },
      );

      // -----------------------------------------------------------------------
      // Core property: non-violating states emit 0 events
      // -----------------------------------------------------------------------

      test(
        'resumed state emits 0 CheatEvents',
        () async {
          final monitor = FakeAntiCheatMonitor(studentId: 'student-001');
          final events =
              await _collectEvents(monitor, AppLifecycleState.resumed);
          expect(
            events.length,
            equals(0),
            reason: 'resumed must emit 0 CheatEvents',
          );
          monitor.dispose();
        },
      );

      test(
        'detached state emits 0 CheatEvents',
        () async {
          final monitor = FakeAntiCheatMonitor(studentId: 'student-001');
          final events =
              await _collectEvents(monitor, AppLifecycleState.detached);
          expect(
            events.length,
            equals(0),
            reason: 'detached must emit 0 CheatEvents',
          );
          monitor.dispose();
        },
      );

      test(
        'hidden state emits 0 CheatEvents',
        () async {
          final monitor = FakeAntiCheatMonitor(studentId: 'student-001');
          final events =
              await _collectEvents(monitor, AppLifecycleState.hidden);
          expect(
            events.length,
            equals(0),
            reason: 'hidden must emit 0 CheatEvents',
          );
          monitor.dispose();
        },
      );

      // -----------------------------------------------------------------------
      // CheatEvent field correctness
      // -----------------------------------------------------------------------

      test(
        'emitted CheatEvent has type appSwitch',
        () async {
          final monitor = FakeAntiCheatMonitor(studentId: 'student-abc');
          final events =
              await _collectEvents(monitor, AppLifecycleState.paused);
          expect(events.single.type, equals(CheatEventType.appSwitch));
          monitor.dispose();
        },
      );

      test(
        'emitted CheatEvent carries the correct studentId',
        () async {
          const id = 'student-xyz-42';
          final monitor = FakeAntiCheatMonitor(studentId: id);
          final events =
              await _collectEvents(monitor, AppLifecycleState.inactive);
          expect(events.single.studentId, equals(id));
          monitor.dispose();
        },
      );

      test(
        'emitted CheatEvent has a UTC timestamp',
        () async {
          final before = DateTime.now().toUtc();
          final monitor = FakeAntiCheatMonitor(studentId: 'student-001');
          final events =
              await _collectEvents(monitor, AppLifecycleState.paused);
          final after = DateTime.now().toUtc();

          final ts = events.single.timestampUtc;
          expect(
            ts.isUtc,
            isTrue,
            reason: 'timestampUtc must be in UTC',
          );
          expect(
            ts.isAfter(before.subtract(const Duration(seconds: 1))),
            isTrue,
            reason: 'timestamp must not be before the test started',
          );
          expect(
            ts.isBefore(after.add(const Duration(seconds: 1))),
            isTrue,
            reason: 'timestamp must not be after the test ended',
          );
          monitor.dispose();
        },
      );

      // -----------------------------------------------------------------------
      // Universal property: 20+ combinations across all lifecycle states
      // -----------------------------------------------------------------------

      test(
        'property holds for 20+ combinations of lifecycle states and student IDs',
        () async {
          // Build 25 combinations: cycle through all states with varied IDs.
          const combinationCount = 25;
          final states = _allStates;

          for (var i = 0; i < combinationCount; i++) {
            final state = states[i % states.length];
            final studentId = 'student-${i.toString().padLeft(3, '0')}';
            final monitor = FakeAntiCheatMonitor(studentId: studentId);

            final events = await _collectEvents(monitor, state);

            if (_violatingStates.contains(state)) {
              expect(
                events.length,
                equals(1),
                reason:
                    'Combination $i: state=$state must emit exactly 1 CheatEvent',
              );
              expect(
                events.single.type,
                equals(CheatEventType.appSwitch),
                reason:
                    'Combination $i: CheatEvent type must be appSwitch',
              );
              expect(
                events.single.studentId,
                equals(studentId),
                reason:
                    'Combination $i: CheatEvent studentId must match',
              );
              expect(
                events.single.timestampUtc.isUtc,
                isTrue,
                reason:
                    'Combination $i: CheatEvent timestamp must be UTC',
              );
            } else {
              expect(
                events.length,
                equals(0),
                reason:
                    'Combination $i: state=$state must emit 0 CheatEvents',
              );
            }

            monitor.dispose();
          }
        },
      );

      // -----------------------------------------------------------------------
      // Multiple sequential events on the same monitor instance
      // -----------------------------------------------------------------------

      test(
        'each violating event on the same monitor emits exactly 1 CheatEvent independently',
        () async {
          const studentId = 'student-seq';
          final monitor = FakeAntiCheatMonitor(studentId: studentId);

          // Fire 5 paused + 5 inactive events, collecting each independently.
          for (var i = 0; i < 5; i++) {
            final pausedEvents =
                await _collectEvents(monitor, AppLifecycleState.paused);
            expect(
              pausedEvents.length,
              equals(1),
              reason: 'paused event $i must emit exactly 1 CheatEvent',
            );

            final inactiveEvents =
                await _collectEvents(monitor, AppLifecycleState.inactive);
            expect(
              inactiveEvents.length,
              equals(1),
              reason: 'inactive event $i must emit exactly 1 CheatEvent',
            );
          }

          monitor.dispose();
        },
      );

      test(
        'non-violating events interspersed with violating events do not produce extra emissions',
        () async {
          const studentId = 'student-interleaved';
          final monitor = FakeAntiCheatMonitor(studentId: studentId);

          // Sequence: resumed → paused → detached → inactive → hidden
          final sequence = [
            AppLifecycleState.resumed,
            AppLifecycleState.paused,
            AppLifecycleState.detached,
            AppLifecycleState.inactive,
            AppLifecycleState.hidden,
          ];

          final expectedCounts = [0, 1, 0, 1, 0];

          for (var i = 0; i < sequence.length; i++) {
            final events = await _collectEvents(monitor, sequence[i]);
            expect(
              events.length,
              equals(expectedCounts[i]),
              reason:
                  'Step $i (${sequence[i]}): expected ${expectedCounts[i]} events',
            );
          }

          monitor.dispose();
        },
      );
    },
  );
}
