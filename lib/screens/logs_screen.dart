import 'package:flutter/material.dart';
import 'package:hostel_log/services/firestore_service.dart';
import 'package:hostel_log/models/log_entry.dart';
import 'package:hostel_log/models/student.dart';
import 'package:hostel_log/widgets/log_tile.dart';
import 'package:intl/intl.dart';

class LogsScreen extends StatefulWidget {
  @override
  _LogsScreenState createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final FirestoreService _firestore = FirestoreService();
  String _searchQuery = '';
  String _filterType = 'all'; // all, entry, exit
  final _searchController = TextEditingController();
  List<Student> _allStudents = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final students = await _firestore.getStudents().first;
    if (mounted) {
      setState(() {
        _allStudents = students;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: const Text(
          'LOGS DASHBOARD',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
      ),
      body: Column(
        children: [
          // Stats & Search Header
          _buildTopHeader(),

          // Filter Section
          _buildFilterChips(),

          // Logs List
          Expanded(
            child: StreamBuilder<List<LogEntry>>(
              stream: _firestore.getLogs(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading logs'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var logs = snapshot.data!;

                // Filter by type
                if (_filterType != 'all') {
                  logs = logs.where((l) => l.type == _filterType).toList();
                }

                // Filter by name query
                if (_searchQuery.isNotEmpty) {
                  final studentIdsWithMatch = _allStudents
                      .where((s) => s.name.toLowerCase().contains(_searchQuery))
                      .map((s) => s.fingerprintId)
                      .toSet();
                  logs = logs
                      .where(
                          (l) => studentIdsWithMatch.contains(l.fingerprintId))
                      .toList();
                }

                if (logs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'No matching logs found',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return _buildGroupedLogs(logs);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.indigo,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Summary Stats
          _buildSummaryStats(),

          const SizedBox(height: 20),

          // Search Bar
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by student name...',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.indigo),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 15),
              ),
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats() {
    return StreamBuilder<List<LogEntry>>(
      stream: _firestore.getLogs(),
      builder: (context, snapshot) {
        final logs = snapshot.data ?? [];
        final entries = logs.where((l) => l.type == 'entry').length;
        final exits = logs.where((l) => l.type == 'exit').length;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatBox(
                'TOTAL', logs.length.toString(), Colors.white.withOpacity(0.2)),
            _buildStatBox('ENTRIES', entries.toString(),
                Colors.green.shade400.withOpacity(0.3)),
            _buildStatBox('EXITS', exits.toString(),
                Colors.orange.shade400.withOpacity(0.3)),
          ],
        );
      },
    );
  }

  Widget _buildStatBox(String label, String value, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Text(
            label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 10,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: Row(
        children: [
          _filterChip('all', 'All Logs'),
          const SizedBox(width: 8),
          _filterChip('entry', 'Entries'),
          const SizedBox(width: 8),
          _filterChip('exit', 'Exits'),
        ],
      ),
    );
  }

  Widget _filterChip(String type, String label) {
    final isSelected = _filterType == type;
    return GestureDetector(
      onTap: () => setState(() => _filterType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo : Colors.indigo.shade50,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.indigo,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildGroupedLogs(List<LogEntry> logs) {
    // Sort logs by date descending
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Grouping
    Map<String, List<LogEntry>> grouped = {};
    for (var log in logs) {
      String dayLabel = _getDayLabel(log.timestamp);
      if (!grouped.containsKey(dayLabel)) grouped[dayLabel] = [];
      grouped[dayLabel]!.add(log);
    }

    return ListView.builder(
      itemCount: grouped.keys.length,
      itemBuilder: (context, index) {
        String label = grouped.keys.elementAt(index);
        List<LogEntry> dayLogs = grouped[label]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            ...dayLogs.map((log) => LogTile(log: log)).toList(),
          ],
        );
      },
    );
  }

  String _getDayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final logDate = DateTime(date.year, date.month, date.day);

    if (logDate == today) return 'Today';
    if (logDate == yesterday) return 'Yesterday';
    return DateFormat('EEE, dd MMM').format(date);
  }
}
