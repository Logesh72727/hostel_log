import 'package:flutter/material.dart';
import 'package:hostel_log/services/auth_service.dart';
import 'package:hostel_log/services/firestore_service.dart';
import 'package:hostel_log/models/log_entry.dart';
import 'package:hostel_log/models/student.dart';
import 'package:hostel_log/widgets/log_tile.dart';
import 'package:provider/provider.dart';
import 'package:hostel_log/services/excel_service.dart';
import 'package:hostel_log/services/pdf_service.dart';
import 'register_student_screen.dart';
import 'students_screen.dart';
import 'manual_log_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirestoreService _firestore = FirestoreService();
  int _currentIndex = 0;

  final List<String> _titles = [
    'Recent Logs',
    'Students Directory',
    'Register Student',
    'Manual Log Entry',
  ];

  late final List<Widget> _children;

  @override
  void initState() {
    super.initState();
    _children = [
      _buildHomeTab(),
      StudentsScreen(),
      RegisterStudentScreen(),
      ManualLogScreen(),
    ];
  }

  Widget _buildHomeTab() {
    return StreamBuilder<List<Student>>(
      stream: _firestore.getStudents(),
      builder: (context, studentSnapshot) {
        if (studentSnapshot.hasError) {
          return Center(child: Text('Error: ${studentSnapshot.error}'));
        }
        if (!studentSnapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        final students = studentSnapshot.data!;

        return StreamBuilder<List<LogEntry>>(
          stream: _firestore.getLogs(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }
            final logs = snapshot.data!;

            // Calculate IN and OUT counts
            int studentsIn = 0;
            int studentsOut = 0;

            // Initialize latestStudentState for all registered students as IN (null state)
            Map<int, String?> latestStudentState = {};
            for (var student in students) {
              latestStudentState[student.fingerprintId] = null;
            }

            // Find the latest log for each student
            for (var log in logs) {
              // Since the logs stream is ordered by timestamp descending,
              // the first occurrence of a fingerprintId is their latest state.
              if (latestStudentState.containsKey(log.fingerprintId) &&
                  latestStudentState[log.fingerprintId] == null) {
                latestStudentState[log.fingerprintId] = log.type;
              }
            }

            // Count based on the latest state
            latestStudentState.forEach((fingerprintId, type) {
              if (type == 'exit') {
                studentsOut++;
              } else {
                // If type is 'entry' OR null (no logs), they are IN
                studentsIn++;
              }
            });

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Card(
                          color: Colors.green.shade100,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20.0),
                            child: Column(
                              children: [
                                Text(
                                  'Students IN',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade800),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '$studentsIn',
                                  style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade900),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Card(
                          color: Colors.orange.shade100,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20.0),
                            child: Column(
                              children: [
                                Text(
                                  'Students OUT',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade800),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '$studentsOut',
                                  style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade900),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      // PDF Button
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.red.shade400, Colors.red.shade800],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(15),
                              onTap: () async {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Generating PDF Report...'), duration: Duration(seconds: 1)),
                                );
                                try {
                                  await PdfService.generateStudentLogsReport(students, logs, studentsIn, studentsOut);
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('PDF Error: $e'), 
                                      duration: const Duration(seconds: 5), 
                                      backgroundColor: Colors.red
                                    ),
                                  );
                                }
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.picture_as_pdf, color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Download PDF',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Excel Button
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green.shade400, Colors.green.shade800],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(15),
                              onTap: () async {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Generating Excel Report...'), duration: Duration(seconds: 1)),
                                );
                                try {
                                  await ExcelService.generateStudentLogsReport(students, logs, studentsIn, studentsOut);
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Excel Error: $e'), 
                                      duration: const Duration(seconds: 5), 
                                      backgroundColor: Colors.red
                                    ),
                                  );
                                }
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.table_view, color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Download Excel',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Recent Logs',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Expanded(
                  child: logs.isEmpty
                      ? Center(child: Text('No logs yet.'))
                      : ListView.builder(
                          itemCount: logs.length,
                          itemBuilder: (context, index) {
                            final log = logs[index];
                            return LogTile(log: log);
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 10,
        shadowColor: Colors.indigo.withOpacity(0.3),
        title: Text(
          _titles[_currentIndex].toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.indigo, Color(0xFF3949AB)],
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.white, size: 20),
              tooltip: 'Sign Out',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to log out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('CANCEL'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('LOGOUT',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await auth.signOut();
                }
              },
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _children,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Logs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Students',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add),
            label: 'Register',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_note),
            label: 'Manual',
          ),
        ],
      ),
    );
  }
}
