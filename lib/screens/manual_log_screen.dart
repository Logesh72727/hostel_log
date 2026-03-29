import 'package:flutter/material.dart';
import 'package:hostel_log/services/firestore_service.dart';
import 'package:hostel_log/models/student.dart';
import 'package:hostel_log/models/log_entry.dart';

class ManualLogScreen extends StatefulWidget {
  @override
  _ManualLogScreenState createState() => _ManualLogScreenState();
}

class _ManualLogScreenState extends State<ManualLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestore = FirestoreService();

  Student? _selectedStudent;
  String _selectedType = 'entry'; // 'entry' or 'exit'
  List<String> _availableTypes = [
    'entry',
    'exit'
  ]; // Starts with both available
  bool _isLoading = false;

  Future<void> _submitLog() async {
    if (_formKey.currentState!.validate() && _selectedStudent != null) {
      setState(() => _isLoading = true);
      try {
        final logId = DateTime.now().millisecondsSinceEpoch.toString();
        final log = LogEntry(
          id: logId,
          fingerprintId: _selectedStudent!.fingerprintId,
          timestamp: DateTime.now(),
          type: _selectedType,
        );

        await _firestore.addLog(log);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Log entry added successfully!')),
        );
        // Reset the form instead of popping the screen since it's a tab now
        // Reset the form instead of popping the screen since it's a tab now
        _formKey.currentState!.reset();
        setState(() {
          _selectedStudent = null;
          _selectedType = 'entry';
          _availableTypes = [
            'entry',
            'exit'
          ]; // Reset options for the next student
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    } else if (_selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a student')),
      );
    }
  }

  void _selectStudent(Student student) async {
    setState(() {
      _selectedStudent = student;
      _isLoading = true;
    });

    try {
      final lastType =
          await _firestore.getStudentLatestLogType(student.fingerprintId);
      setState(() {
        if (lastType == 'entry') {
          _availableTypes = ['exit'];
          _selectedType = 'exit';
        } else if (lastType == 'exit') {
          _availableTypes = ['entry'];
          _selectedType = 'entry';
        } else {
          _availableTypes = ['exit'];
          _selectedType = 'exit';
        }
      });
    } catch (e) {
      debugPrint('Error fetching status: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showStudentSearchSheet(List<Student> students) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _StudentSearchSheet(
          students: students,
          onSelected: (student) {
            Navigator.pop(context);
            _selectStudent(student);
          },
        );
      },
    );
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Card(
              elevation: 8,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Manual Log Entry',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade900,
                        ),
                      ),
                      const SizedBox(height: 24),
                      StreamBuilder<List<Student>>(
                        stream: _firestore.getStudents(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError || !snapshot.hasData) {
                            return const Text('Failed to load students');
                          }

                          final students = snapshot.data!;
                          return _AnimatedSelectorWrapper(
                            child: TextFormField(
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'Select Student',
                                hintText: 'Tap to search student',
                                prefixIcon: const Icon(Icons.person_search,
                                    color: Colors.indigo),
                                suffixIcon: const Icon(Icons.arrow_drop_down),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              controller: TextEditingController(
                                text: _selectedStudent != null
                                    ? '${_selectedStudent!.name} (${_selectedStudent!.regNo})'
                                    : '',
                              ),
                              onTap: () => _showStudentSearchSheet(students),
                              validator: (value) =>
                                  _selectedStudent == null ? 'Required' : null,
                            ),
                          );
                        },
                      ),
                      if (_selectedStudent != null) ...[
                        const SizedBox(height: 20),
                        _StudentProfileCard(
                          student: _selectedStudent!,
                          isEntry: _selectedType == 'entry',
                          availableTypes: _availableTypes,
                        ),
                      ],
                      const SizedBox(height: 24),
                      const Text(
                        'Entry/Exit Selection',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.indigo),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _TypeToggleButton(
                              label: 'ENTRY',
                              icon: Icons.login_rounded,
                              isSelected: _selectedType == 'entry',
                              isEnabled: _availableTypes.contains('entry'),
                              onTap: () =>
                                  setState(() => _selectedType = 'entry'),
                              activeColor: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _TypeToggleButton(
                              label: 'EXIT',
                              icon: Icons.logout_rounded,
                              isSelected: _selectedType == 'exit',
                              isEnabled: _availableTypes.contains('exit'),
                              onTap: () =>
                                  setState(() => _selectedType = 'exit'),
                              activeColor: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _submitLog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                              child: const Text(
                                'SUBMIT LOG',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedSelectorWrapper extends StatefulWidget {
  final Widget child;
  const _AnimatedSelectorWrapper({required this.child});

  @override
  State<_AnimatedSelectorWrapper> createState() =>
      _AnimatedSelectorWrapperState();
}

class _AnimatedSelectorWrapperState extends State<_AnimatedSelectorWrapper> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focus) => setState(() => _isFocused = focus),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(_isFocused ? 1.02 : 1.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: _isFocused
              ? [
                  BoxShadow(
                    color: Colors.indigo.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: widget.child,
      ),
    );
  }
}

class _StudentProfileCard extends StatelessWidget {
  final Student student;
  final bool isEntry;
  final List<String> availableTypes;

  const _StudentProfileCard({
    required this.student,
    required this.isEntry,
    required this.availableTypes,
  });

  @override
  Widget build(BuildContext context) {
    // Infer current status based on available types
    // If only 'entry' is available, it means their last was 'exit' -> they are currently OUT
    final bool isActuallyIn = !availableTypes.contains('entry');

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.indigo.shade50.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.indigo.shade100),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.indigo.shade100,
              backgroundImage: student.photoUrl != null
                  ? NetworkImage(student.photoUrl!)
                  : null,
              child: student.photoUrl == null
                  ? const Icon(Icons.person, color: Colors.indigo)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Reg: ${student.regNo} | Room: ${student.roomNo}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                  Text(
                    'Phone: ${student.phoneNo}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isActuallyIn
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isActuallyIn ? 'Currently IN' : 'Currently OUT',
                      style: TextStyle(
                        color: isActuallyIn
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;
  final Color activeColor;

  const _TypeToggleButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? activeColor : Colors.grey.shade400;
    final bgColor =
        isSelected ? activeColor.withOpacity(0.1) : Colors.transparent;

    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEnabled ? color : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.4,
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentSearchSheet extends StatefulWidget {
  final List<Student> students;
  final Function(Student) onSelected;

  const _StudentSearchSheet({required this.students, required this.onSelected});

  @override
  _StudentSearchSheetState createState() => _StudentSearchSheetState();
}

class _StudentSearchSheetState extends State<_StudentSearchSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredStudents = widget.students.where((s) {
      final name = s.name.toLowerCase();
      final regNo = s.regNo.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || regNo.contains(query);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search by name or registration number...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filteredStudents.isEmpty
                ? const Center(child: Text('No students found'))
                : ListView.separated(
                    itemCount: filteredStudents.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final student = filteredStudents[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo.shade50,
                          child: const Icon(Icons.person, color: Colors.indigo),
                        ),
                        title: Text(student.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(student.regNo),
                        onTap: () => widget.onSelected(student),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
