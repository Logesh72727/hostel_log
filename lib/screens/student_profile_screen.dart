import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:hostel_log/models/student.dart';
import 'package:hostel_log/services/firestore_service.dart';
import 'package:hostel_log/models/log_entry.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentProfileScreen extends StatefulWidget {
  final Student student;

  const StudentProfileScreen({Key? key, required this.student})
      : super(key: key);

  @override
  _StudentProfileScreenState createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final FirestoreService _firestore = FirestoreService();
  bool _isEditing = false;
  bool _isSaving = false;

  late TextEditingController _nameController;
  late TextEditingController _regNoController;
  late TextEditingController _roomController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.student.name);
    _regNoController = TextEditingController(text: widget.student.regNo);
    _roomController = TextEditingController(text: widget.student.roomNo);
    _phoneController = TextEditingController(text: widget.student.phoneNo);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _regNoController.dispose();
    _roomController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _launchCaller(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri url = Uri.parse('tel:$cleanPhone');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch dialer');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch dialer: $e')),
        );
      }
    }
  }

  Future<void> _launchSMS(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri url = Uri.parse('sms:$cleanPhone');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch SMS');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch SMS: $e')),
        );
      }
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      final updatedStudent = Student(
        id: widget.student.id,
        name: _nameController.text,
        regNo: _regNoController.text,
        roomNo: _roomController.text,
        phoneNo: _phoneController.text,
        fingerprintId: widget.student.fingerprintId,
        photoUrl: widget.student.photoUrl,
        createdAt: widget.student.createdAt,
      );

      await _firestore.updateStudent(updatedStudent);
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Student'),
        content: const Text(
            'This will permanently remove the student and all their logs. Action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firestore.deleteStudent(
          widget.student.id, widget.student.fingerprintId);
      Navigator.pop(context);
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
        title: Text(_isEditing ? 'Editing Profile' : 'Student Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            IconButton(
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check),
              onPressed: _isSaving ? null : _handleSave,
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _handleDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Premium Header with Gradient
            _buildHeader(),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Stats Row
                  _buildQuickStats(),

                  const SizedBox(height: 20),

                  // Information Cards
                  _buildInfoSection(),

                  const SizedBox(height: 30),

                  // Logs Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Log History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade900,
                        ),
                      ),
                      Icon(Icons.history,
                          color: Colors.indigo.shade400, size: 20),
                    ],
                  ),
                  const Divider(height: 24),

                  // Logs Timeline
                  _buildLogsTimeline(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.indigo, Color(0xFF3949AB), Color(0xFF283593)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Hero(
                  tag: 'student_avatar_${widget.student.id}',
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.indigo.shade50,
                    backgroundImage: widget.student.photoUrl != null
                        ? NetworkImage(widget.student.photoUrl!)
                        : null,
                    child: widget.student.photoUrl == null
                        ? const Icon(Icons.person,
                            size: 60, color: Colors.indigo)
                        : null,
                  ),
                ),
              ),
              FutureBuilder<String?>(
                future: _firestore
                    .getStudentLatestLogType(widget.student.fingerprintId),
                builder: (context, snapshot) {
                  final type = snapshot.data;
                  final isOut = type == 'exit';
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOut ? Colors.red : Colors.green,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      isOut ? 'OUT' : 'IN',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!_isEditing)
            Text(
              _nameController.text.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          if (_isEditing)
            _buildInlineEditField(
                _nameController, "Student Name", Icons.person_outline),
          const SizedBox(height: 8),
          Text(
            'Fingerprint ID: ${widget.student.fingerprintId}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      children: [
        _buildInfoCard(
          title: "Contact Details",
          icon: Icons.contact_phone_outlined,
          children: [
            _buildDetailRow(
              icon: Icons.phone_android,
              label: "Phone Number",
              controller: _phoneController,
              isEditable: true,
              trailing: !_isEditing && _phoneController.text.isNotEmpty
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.message_outlined,
                              color: Colors.blue, size: 20),
                          onPressed: () => _launchSMS(_phoneController.text),
                        ),
                        IconButton(
                          icon: const Icon(Icons.call,
                              color: Colors.green, size: 20),
                          onPressed: () => _launchCaller(_phoneController.text),
                        ),
                      ],
                    )
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          title: "Academic Info",
          icon: Icons.school_outlined,
          children: [
            _buildDetailRow(
              icon: Icons.badge_outlined,
              label: "Registration No",
              controller: _regNoController,
              isEditable: true,
            ),
            const Divider(),
            _buildDetailRow(
              icon: Icons.meeting_room_outlined,
              label: "Room Number",
              controller: _roomController,
              isEditable: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard(
      {required String title,
      required IconData icon,
      required List<Widget> children}) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    bool isEditable = false,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: _isEditing && isEditable
                ? TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: label,
                      isDense: true,
                      border: const UnderlineInputBorder(),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12)),
                      Text(
                        controller.text.isEmpty
                            ? "Not Provided"
                            : controller.text,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    ],
                  ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildInlineEditField(
      TextEditingController controller, String label, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white70),
          hintText: label,
          hintStyle: const TextStyle(color: Colors.white54),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return StreamBuilder<List<LogEntry>>(
      stream: _firestore.getLogs(fingerprintId: widget.student.fingerprintId),
      builder: (context, snapshot) {
        final logs = snapshot.data ?? [];
        final totalLogs = logs.length;

        final now = DateTime.now();
        final oneWeekAgo = now.subtract(const Duration(days: 7));
        final weekLogs =
            logs.where((l) => l.timestamp.isAfter(oneWeekAgo)).length;

        return Row(
          children: [
            _buildStatItem("Total Activity", totalLogs.toString(),
                Icons.analytics_outlined, Colors.blue),
            const SizedBox(width: 12),
            _buildStatItem("This Week", weekLogs.toString(),
                Icons.event_available_outlined, Colors.orange),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade900,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsTimeline() {
    return StreamBuilder<List<LogEntry>>(
      stream: _firestore.getLogs(fingerprintId: widget.student.fingerprintId),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return const Center(child: Text('Error loading history'));
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final logs = snapshot.data!;
        if (logs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'No activity recorded yet.',
                style: TextStyle(color: Colors.grey.shade400),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            final bool isEntry = log.type == 'entry';
            final date =
                DateFormat('MMM dd, yyyy • hh:mm a').format(log.timestamp);

            return IntrinsicHeight(
              child: Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isEntry ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: (isEntry ? Colors.green : Colors.red)
                                  .withOpacity(0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      if (index != logs.length - 1)
                        Expanded(
                            child: Container(
                                width: 2, color: Colors.grey.shade200)),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isEntry
                                ? Icons.login_rounded
                                : Icons.logout_rounded,
                            color: isEntry ? Colors.green : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  log.type.toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isEntry
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                  ),
                                ),
                                Text(
                                  date,
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          if (log.imageUrl != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                log.imageUrl!,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
