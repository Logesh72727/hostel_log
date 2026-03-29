import 'package:flutter/material.dart';
import 'package:hostel_log/models/log_entry.dart';
import 'package:hostel_log/models/student.dart';
import 'package:hostel_log/services/firestore_service.dart';
import 'package:hostel_log/screens/student_profile_screen.dart';
import 'package:intl/intl.dart';

class LogTile extends StatelessWidget {
  final LogEntry log;

  const LogTile({Key? key, required this.log}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isEntry = log.type == 'entry';
    final statusColor = isEntry ? Colors.green : Colors.orange;
    final timeStr = DateFormat('hh:mm a').format(log.timestamp);
    final dateStr = DateFormat('dd MMM yyyy').format(log.timestamp);

    return FutureBuilder<Student?>(
      future: FirestoreService().getStudentByFingerprint(log.fingerprintId),
      builder: (context, snapshot) {
        final student = snapshot.data;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: student != null
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              StudentProfileScreen(student: student),
                        ),
                      )
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // Avatar / Icon Section
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            shape: BoxShape.circle,
                            image: student?.photoUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(student!.photoUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: student?.photoUrl == null
                              ? Icon(Icons.person_outline,
                                  color: Colors.indigo.shade300, size: 28)
                              : null,
                        ),
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isEntry
                                ? Icons.login_rounded
                                : Icons.logout_rounded,
                            color: statusColor,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),

                    // Main Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student?.name ?? 'Loading...',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.indigo.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  log.type.toUpperCase(),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Room ${student?.roomNo ?? '...'}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Time / Action
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.indigo.shade900,
                          ),
                        ),
                        Text(
                          dateStr,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),

                    // Right Image (Security Check)
                    if (log.imageUrl != null) ...[
                      const SizedBox(width: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          log.imageUrl!,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
