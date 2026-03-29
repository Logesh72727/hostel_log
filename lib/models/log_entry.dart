import 'package:cloud_firestore/cloud_firestore.dart';

class LogEntry {
  final String id;
  final int fingerprintId;
  final DateTime timestamp;
  final String type; // 'entry' or 'exit'
  final String? imageUrl;

  LogEntry({
    required this.id,
    required this.fingerprintId,
    required this.timestamp,
    required this.type,
    this.imageUrl,
  });

  factory LogEntry.fromFirestore(Map<String, dynamic> data, String documentId) {
    DateTime parsedTimestamp = DateTime.now();
    if (data['timestamp'] is Timestamp) {
      parsedTimestamp = (data['timestamp'] as Timestamp).toDate();
    } else if (data['timestamp'] is String) {
      parsedTimestamp = DateTime.tryParse(data['timestamp']) ?? DateTime.now();
    }

    return LogEntry(
      id: documentId,
      fingerprintId: data['fingerprint_id'] ?? 0,
      timestamp: parsedTimestamp,
      type: data['type'] ?? 'entry',
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fingerprint_id': fingerprintId,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type,
      'imageUrl': imageUrl,
    };
  }
}
