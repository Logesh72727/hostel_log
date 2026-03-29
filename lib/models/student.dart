import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  final String id;
  final String name;
  final String regNo;
  final String roomNo;
  final String phoneNo;
  final int fingerprintId;
  final String? photoUrl;
  final DateTime createdAt;

  Student({
    required this.id,
    required this.name,
    required this.regNo,
    required this.roomNo,
    required this.phoneNo,
    required this.fingerprintId,
    this.photoUrl,
    required this.createdAt,
  });

  factory Student.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Student(
      id: documentId,
      name: data['name'] ?? '',
      regNo: data['reg_no'] ?? '',
      roomNo: data['room_no'] ?? '',
      phoneNo: data['phone_no'] ?? '',
      fingerprintId: data['fingerprint_id'] ?? 0,
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'reg_no': regNo,
      'room_no': roomNo,
      'phone_no': phoneNo,
      'fingerprint_id': fingerprintId,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Student &&
        other.id == id &&
        other.fingerprintId == fingerprintId;
  }

  @override
  int get hashCode {
    return id.hashCode ^ fingerprintId.hashCode;
  }
}
