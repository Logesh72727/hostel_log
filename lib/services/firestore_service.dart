import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hostel_log/models/student.dart';
import 'package:hostel_log/models/log_entry.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Students collection
  CollectionReference<Map<String, dynamic>> get studentsCollection =>
      _db.collection('students');

  // Logs collection
  CollectionReference<Map<String, dynamic>> get logsCollection =>
      _db.collection('logs');

  // Add a new student
  Future<void> addStudent(Student student) async {
    await studentsCollection.doc(student.id).set(student.toMap());
  }

  // Update student
  Future<void> updateStudent(Student student) async {
    await studentsCollection.doc(student.id).update(student.toMap());
  }

  // Delete student and their associated logs
  Future<void> deleteStudent(String studentId, int fingerprintId) async {
    // Start a batch write
    WriteBatch batch = _db.batch();

    // 1. Delete the student document
    DocumentReference studentRef = studentsCollection.doc(studentId);
    batch.delete(studentRef);

    // 2. Find and delete all logs matching their fingerprintId
    final logsQuery = await logsCollection
        .where('fingerprint_id', isEqualTo: fingerprintId)
        .get();

    for (var doc in logsQuery.docs) {
      batch.delete(doc.reference);
    }

    // Commit the batch
    await batch.commit();
  }

  // Get all students
  Stream<List<Student>> getStudents() {
    return studentsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Student.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  // Get student by fingerprint ID
  Future<Student?> getStudentByFingerprint(int fingerprintId) async {
    final query = await studentsCollection
        .where('fingerprint_id', isEqualTo: fingerprintId)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      return Student.fromFirestore(
          query.docs.first.data(), query.docs.first.id);
    }
    return null;
  }

  // Logs
  Stream<List<LogEntry>> getLogs({int? fingerprintId}) {
    if (fingerprintId != null) {
      // Fetch by fingerprint and sort locally to avoid composite index error
      return logsCollection
          .where('fingerprint_id', isEqualTo: fingerprintId)
          .snapshots()
          .map((snapshot) {
        final logs = snapshot.docs.map((doc) {
          return LogEntry.fromFirestore(doc.data(), doc.id);
        }).toList();

        logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return logs;
      });
    }

    // No fingerprint, so single-field ordering works fine
    return logsCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return LogEntry.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  // Get latest log type for a student
  Future<String?> getStudentLatestLogType(int fingerprintId) async {
    try {
      final query = await logsCollection
          .where('fingerprint_id', isEqualTo: fingerprintId)
          .get();

      if (query.docs.isNotEmpty) {
        final docs = query.docs.toList();
        docs.sort((a, b) {
          final tA = a.data()['timestamp'] as Timestamp?;
          final tB = b.data()['timestamp'] as Timestamp?;
          if (tA == null && tB == null) return 0;
          if (tA == null) return 1;
          if (tB == null) return -1;
          return tB.compareTo(tA);
        });

        final data = docs.first.data();
        return data['type'] as String?;
      }
      return null;
    } catch (e) {
      print('Auto-status index lookup error: $e');
      return null;
    }
  }

  // Add log entry
  Future<void> addLog(LogEntry log) async {
    await logsCollection.doc(log.id).set(log.toMap());
  }
}
