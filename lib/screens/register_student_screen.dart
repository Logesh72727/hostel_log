import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hostel_log/services/firestore_service.dart';
import 'package:hostel_log/services/storage_service.dart';
import 'package:hostel_log/models/student.dart';
import 'package:image_picker/image_picker.dart';

class RegisterStudentScreen extends StatefulWidget {
  @override
  _RegisterStudentScreenState createState() => _RegisterStudentScreenState();
}

class _RegisterStudentScreenState extends State<RegisterStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _regNoController = TextEditingController();
  final _roomController = TextEditingController();
  final _phoneController = TextEditingController();
  final _fingerprintController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;
  final FirestoreService _firestore = FirestoreService();
  final StorageService _storage = StorageService();

  @override
  void initState() {
    super.initState();
    // Add listeners to trigger rebuilds for Live ID Preview and Progress
    _nameController.addListener(_onFormUpdate);
    _regNoController.addListener(_onFormUpdate);
    _roomController.addListener(_onFormUpdate);
    _phoneController.addListener(_onFormUpdate);
    _fingerprintController.addListener(_onFormUpdate);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _regNoController.dispose();
    _roomController.dispose();
    _phoneController.dispose();
    _fingerprintController.dispose();
    super.dispose();
  }

  void _onFormUpdate() => setState(() {});

  double get _registrationProgress {
    double progress = 0;
    if (_nameController.text.isNotEmpty) progress += 0.2;
    if (_regNoController.text.isNotEmpty) progress += 0.2;
    if (_roomController.text.isNotEmpty) progress += 0.2;
    if (_phoneController.text.length >= 10) progress += 0.2;
    final id = int.tryParse(_fingerprintController.text);
    if (id != null && id >= 1 && id <= 1000) progress += 0.2;
    return progress;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final studentId = DateTime.now().millisecondsSinceEpoch.toString();
        String? photoUrl;
        if (_imageFile != null) {
          photoUrl = await _storage.uploadStudentImage(studentId, _imageFile!);
        }
        final student = Student(
          id: studentId,
          name: _nameController.text,
          regNo: _regNoController.text,
          roomNo: _roomController.text,
          phoneNo: _phoneController.text,
          fingerprintId: int.parse(_fingerprintController.text),
          photoUrl: photoUrl,
          createdAt: DateTime.now(),
        );
        await _firestore.addStudent(student);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Student registered successfully!')),
        );

        // Clear the form since it's a tab now
        _formKey.currentState!.reset();
        _nameController.clear();
        _regNoController.clear();
        _roomController.clear();
        _phoneController.clear();
        _fingerprintController.clear();
        setState(() {
          _imageFile = null;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return _AnimatedRegistrationField(
      controller: controller,
      label: label,
      icon: icon,
      keyboardType: keyboardType,
      validator: validator,
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
            // Registration Form Card
            Card(
              elevation: 8,
              shadowColor: Colors.black26,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: _registrationProgress,
                    backgroundColor: Colors.indigo.shade50,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.indigo),
                    minHeight: 6,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Student Registration',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo.shade900,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Restored Photo Picker
                          Center(
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.indigo.shade100,
                                        width: 4,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 60,
                                      backgroundColor: Colors.grey.shade200,
                                      backgroundImage: _imageFile != null
                                          ? FileImage(_imageFile!)
                                          : null,
                                      child: _imageFile == null
                                          ? const Icon(Icons.person_add_alt_1,
                                              size: 50, color: Colors.indigo)
                                          : null,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Colors.indigo,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.camera_alt,
                                          color: Colors.white, size: 20),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          _buildTextField(
                            controller: _nameController,
                            label: 'Full Name',
                            icon: Icons.person,
                            validator: (value) =>
                                value!.isEmpty ? 'Required' : null,
                          ),
                          _buildTextField(
                            controller: _regNoController,
                            label: 'Registration Number',
                            icon: Icons.badge,
                            validator: (value) =>
                                value!.isEmpty ? 'Required' : null,
                          ),
                          _buildTextField(
                            controller: _roomController,
                            label: 'Room Number',
                            icon: Icons.meeting_room,
                            validator: (value) =>
                                value!.isEmpty ? 'Required' : null,
                          ),
                          _buildTextField(
                            controller: _phoneController,
                            label: 'Phone Number',
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                            validator: (value) =>
                                (value == null || value.length < 10)
                                    ? 'Enter a valid phone number'
                                    : null,
                          ),
                          _buildTextField(
                            controller: _fingerprintController,
                            label: 'Fingerprint ID (1-1000)',
                            icon: Icons.fingerprint,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value!.isEmpty) return 'Required';
                              final id = int.tryParse(value);
                              if (id == null || id < 1 || id > 1000) {
                                return 'Enter a number between 1 and 1000';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                                  onPressed: _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.indigo,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                  ),
                                  child: const Text(
                                    'REGISTER STUDENT',
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
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Form Completion: ${(_registrationProgress * 100).toInt()}%',
              style: TextStyle(
                  color: Colors.indigo.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedRegistrationField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _AnimatedRegistrationField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  State<_AnimatedRegistrationField> createState() =>
      _AnimatedRegistrationFieldState();
}

class _AnimatedRegistrationFieldState
    extends State<_AnimatedRegistrationField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Focus(
        onFocusChange: (hasFocus) {
          setState(() => _isFocused = hasFocus);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          transform: Matrix4.identity()..scale(_isFocused ? 1.02 : 1.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: Colors.indigo.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: TextFormField(
            controller: widget.controller,
            keyboardType: widget.keyboardType,
            decoration: InputDecoration(
              labelText: widget.label,
              prefixIcon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  widget.icon,
                  key: ValueKey(_isFocused),
                  color: _isFocused ? Colors.indigo : Colors.grey.shade600,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.indigo, width: 2),
              ),
              filled: true,
              fillColor: _isFocused ? Colors.white : Colors.grey.shade50,
            ),
            validator: widget.validator,
          ),
        ),
      ),
    );
  }
}
