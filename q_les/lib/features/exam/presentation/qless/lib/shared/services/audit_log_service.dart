import 'package:firebase_database/firebase_database.dart';

import '../models/audit_entry.dart';

abstract class AuditLogService {
  Stream<List<AuditEntry>> watchAuditLog(String examId, {int limit = 50});
  Future<void> recordEntry(String examId, AuditEntry entry);
}

class FirebaseAuditLogService implements AuditLogService {
  FirebaseAuditLogService({FirebaseDatabase? database})
      : _database = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _database;

  @override
  Stream<List<AuditEntry>> watchAuditLog(String examId, {int limit = 50}) {
    final ref = _database
        .ref('audit_logs/$examId')
        .limitToLast(limit);

    return ref.onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) {
        return <AuditEntry>[];
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final entries = data.entries.map((e) {
        final entryMap = Map<String, dynamic>.from(e.value as Map);
        return AuditEntry.fromJson(entryMap);
      }).toList();

      // Sort by timestamp ascending (most recent last)
      entries.sort((a, b) => a.timestampUtc.compareTo(b.timestampUtc));
      return entries;
    });
  }

  @override
  Future<void> recordEntry(String examId, AuditEntry entry) async {
    final ref = _database.ref('audit_logs/$examId');
    await ref.push().set(entry.toJson());
  }
}
