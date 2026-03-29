import 'package:flutter/material.dart';
import 'package:hostel_log/models/student.dart';
import 'package:hostel_log/services/firestore_service.dart';
import 'package:hostel_log/screens/student_profile_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentsScreen extends StatefulWidget {
  @override
  _StudentsScreenState createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final FirestoreService _firestore = FirestoreService();
  String _searchQuery = '';
  final _searchController = TextEditingController();
  bool _isSearchFocused = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.indigo.shade50, Colors.white],
        ),
      ),
      child: Column(
        children: [
          // Premium Search Bar Section
          _buildSearchHeader(),

          Expanded(
            child: StreamBuilder<List<Student>>(
              stream: _firestore.getStudents(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildErrorState();
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.indigo),
                  );
                }

                var students = snapshot.data!;

                if (_searchQuery.isNotEmpty) {
                  students = students.where((s) {
                    return s.name.toLowerCase().contains(_searchQuery) ||
                        s.regNo.toLowerCase().contains(_searchQuery) ||
                        s.roomNo.toLowerCase().contains(_searchQuery);
                  }).toList();
                }

                if (students.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    return _AnimatedStudentCard(
                      student: students[index],
                      firestore: _firestore,
                      index: index,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Students Directory',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Focus(
            onFocusChange: (hasFocus) {
              setState(() => _isSearchFocused = hasFocus);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _isSearchFocused
                        ? Colors.indigo.withOpacity(0.2)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: _isSearchFocused ? 12 : 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _searchQuery = value.toLowerCase());
                },
                decoration: InputDecoration(
                  hintText: 'Search Name, Reg No, Room...',
                  hintStyle: TextStyle(color: Colors.indigo.shade200),
                  prefixIcon: Icon(Icons.search, color: Colors.indigo.shade400),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 16),
          const Text('Something went wrong fetching students'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_outlined,
              size: 64, color: Colors.indigo.shade100),
          const SizedBox(height: 16),
          Text(
            'No students found',
            style: TextStyle(color: Colors.indigo.shade300, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _AnimatedStudentCard extends StatelessWidget {
  final Student student;
  final FirestoreService firestore;
  final int index;

  const _AnimatedStudentCard({
    required this.student,
    required this.firestore,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 50).clamp(0, 400)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 4,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StudentProfileScreen(student: student),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Avatar with premium border
                Hero(
                  tag: 'student_avatar_${student.id}',
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: Colors.indigo.shade100, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.indigo.shade50,
                      backgroundImage: student.photoUrl != null
                          ? NetworkImage(student.photoUrl!)
                          : null,
                      child: student.photoUrl == null
                          ? const Icon(Icons.person, color: Colors.indigo)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Info Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${student.regNo} • Room ${student.roomNo}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      if (student.phoneNo.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          student.phoneNo,
                          style: TextStyle(
                            color: Colors.indigo.shade400,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Actions & Status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FutureBuilder<String?>(
                      future: firestore
                          .getStudentLatestLogType(student.fingerprintId),
                      builder: (context, snapshot) {
                        final type = snapshot.data;
                        final isOut = type == 'exit';
                        final isLoading =
                            snapshot.connectionState == ConnectionState.waiting;

                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isLoading
                                ? Colors.grey.shade100
                                : (isOut
                                    ? Colors.red.shade50
                                    : Colors.green.shade50),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isLoading ? '...' : (isOut ? 'OUT' : 'IN'),
                            style: TextStyle(
                              color: isLoading
                                  ? Colors.grey
                                  : (isOut
                                      ? Colors.red.shade700
                                      : Colors.green.shade700),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (student.phoneNo.isNotEmpty)
                          _QuickActionButton(
                            icon: Icons.call,
                            color: Colors.indigo.shade400,
                            onTap: () async {
                              final phone = student.phoneNo;
                              if (phone.isNotEmpty) {
                                final cleanPhone =
                                    phone.replaceAll(RegExp(r'[^\d+]'), '');
                                final Uri url = Uri.parse('tel:$cleanPhone');
                                try {
                                  if (!await launchUrl(url,
                                      mode: LaunchMode.externalApplication)) {
                                    throw Exception('Could not launch dialer');
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Error launching dialer: $e')),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
