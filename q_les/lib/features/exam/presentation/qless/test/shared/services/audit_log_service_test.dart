import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:qless/shared/models/audit_entry.dart';
import 'package:qless/shared/services/audit_log_service.dart';

/// In-memory fake implementation of [AuditLogService] for testing.
class FakeAuditLogService implements AuditLogService {
  // Per-examId storage and stream controllers.
  final Map<String, List<AuditEntry>> _store = {};
  final Map<String, StreamController<List<AuditEntry>>> _controllers = {};

  StreamController<List<AuditEntry>> _controllerFor(String examId) {
    return _controllers.putIfAbsent(
      examId,
      () => StreamController<List<AuditEntry>>.broadcast(),
    );
  }

  List<AuditEntry> _entriesFor(String examId) {
    return _store.putIfAbsent(examId, () => []);
  }

  @override
  Stream<List<AuditEntry>> watchAuditLog(String examId, {int limit = 50}) {
    final controller = _controllerFor(examId);
    final entries = _entriesFor(examId);

    // Emit current state immediately via an async microtask so listeners
    // are attached before the first event fires.
    Future.microtask(() {
      if (!controller.isClosed) {
        final limited = entries.length <= limit
            ? List<AuditEntry>.from(entries)
            : entries.sublist(entries.length - limit);
        controller.add(limited);
      }
    });

    return controller.stream;
  }

  @override
  Future<void> recordEntry(String examId, AuditEntry entry) async {
    final entries = _entriesFor(examId);
    entries.add(entry);

    final controller = _controllerFor(examId);
    if (!controller.isClosed) {
      controller.add(List<AuditEntry>.from(entries));
    }
  }

  void dispose() {
    for (final c in _controllers.values) {
      c.close();
    }
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

AuditEntry makeEntry({
  String actorId = 'actor-1',
  String actorName = 'Alice',
  String action = 'exam_started',
  DateTime? timestampUtc,
}) {
  return AuditEntry(
    actorId: actorId,
    actorName: actorName,
    action: action,
    timestampUtc: timestampUtc ?? DateTime.utc(2024, 1, 1, 12, 0, 0),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  const examId = 'exam-42';

  late FakeAuditLogService service;

  setUp(() {
    service = FakeAuditLogService();
  });

  tearDown(() {
    service.dispose();
  });

  group('AuditLogService — watchAuditLog', () {
    test('emits an empty list initially', () async {
      final stream = service.watchAuditLog(examId);
      final first = await stream.first;
      expect(first, isEmpty);
    });

    test('emits the new entry after recordEntry', () async {
      final entry = makeEntry(action: 'exam_opened');

      // Start listening before recording.
      final stream = service.watchAuditLog(examId);

      // Skip the initial empty emission, then record.
      final future = stream.skip(1).first;
      await service.recordEntry(examId, entry);

      final emitted = await future;
      expect(emitted.length, 1);
      expect(emitted.first.action, 'exam_opened');
    });

    test('emits all entries after multiple recordEntry calls', () async {
      final entries = [
        makeEntry(action: 'exam_opened'),
        makeEntry(action: 'student_joined'),
        makeEntry(action: 'exam_closed'),
      ];

      final stream = service.watchAuditLog(examId);

      // Collect emissions: initial + one per recordEntry = 4 total.
      final collected = <List<AuditEntry>>[];
      final sub = stream.listen(collected.add);

      for (final e in entries) {
        await service.recordEntry(examId, e);
      }

      // Allow microtasks to settle.
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      // The last emission should contain all three entries.
      final last = collected.last;
      expect(last.length, 3);
      expect(last.map((e) => e.action).toList(),
          ['exam_opened', 'student_joined', 'exam_closed']);
    });

    test('respects the limit parameter — only returns last N entries', () async {
      // Record 5 entries.
      for (var i = 0; i < 5; i++) {
        await service.recordEntry(examId, makeEntry(action: 'action_$i'));
      }

      // Watch with limit = 3.
      final stream = service.watchAuditLog(examId, limit: 3);
      final emitted = await stream.first;

      expect(emitted.length, 3);
      // Should be the last 3 entries.
      expect(emitted.map((e) => e.action).toList(),
          ['action_2', 'action_3', 'action_4']);
    });
  });

  group('AuditLogService — recordEntry', () {
    test('stores entry with correct fields', () async {
      final ts = DateTime.utc(2024, 6, 15, 9, 30, 0);
      final entry = AuditEntry(
        actorId: 'teacher-99',
        actorName: 'Mr. Smith',
        action: 'exam_toggled_on',
        timestampUtc: ts,
      );

      final stream = service.watchAuditLog(examId);
      final future = stream.skip(1).first; // skip initial empty
      await service.recordEntry(examId, entry);

      final emitted = await future;
      expect(emitted.length, 1);

      final stored = emitted.first;
      expect(stored.actorId, 'teacher-99');
      expect(stored.actorName, 'Mr. Smith');
      expect(stored.action, 'exam_toggled_on');
      expect(stored.timestampUtc, ts);
    });
  });
}
