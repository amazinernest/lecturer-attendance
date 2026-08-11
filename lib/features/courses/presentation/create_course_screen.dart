import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/providers.dart';
import '../../../shared/models/course.dart';

class CreateCourseScreen extends ConsumerStatefulWidget {
  final Course? existingCourse;

  const CreateCourseScreen({super.key, this.existingCourse});

  @override
  ConsumerState<CreateCourseScreen> createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends ConsumerState<CreateCourseScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _codeController;
  late TextEditingController _titleController;
  late TextEditingController _departmentController;
  late TextEditingController _levelController;
  late TextEditingController _semesterController;
  late TextEditingController _sessionController;
  late TextEditingController _expectedClassesController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.existingCourse;
    _codeController = TextEditingController(text: c?.courseCode ?? '');
    _titleController = TextEditingController(text: c?.courseTitle ?? '');
    _departmentController = TextEditingController(text: c?.department ?? 'Educational Foundations');
    _levelController = TextEditingController(text: c?.level ?? '200 Level');
    _semesterController = TextEditingController(text: c?.semester ?? 'First Semester');
    _sessionController = TextEditingController(text: c?.academicSession ?? '2026/2027');
    _expectedClassesController = TextEditingController(text: '${c?.expectedClasses ?? 15}');
  }

  @override
  void dispose() {
    _codeController.dispose();
    _titleController.dispose();
    _departmentController.dispose();
    _levelController.dispose();
    _semesterController.dispose();
    _sessionController.dispose();
    _expectedClassesController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('No logged in lecturer user.');

      final db = ref.read(databaseProvider);
      final now = DateTime.now();
      final expectedClasses = int.tryParse(_expectedClassesController.text.trim()) ?? 15;

      final course = Course(
        id: widget.existingCourse?.id ?? const Uuid().v4(),
        lecturerId: user.id,
        courseCode: _codeController.text.trim().toUpperCase(),
        courseTitle: _titleController.text.trim(),
        department: _departmentController.text.trim(),
        level: _levelController.text.trim(),
        semester: _semesterController.text.trim(),
        academicSession: _sessionController.text.trim(),
        expectedClasses: expectedClasses,
        status: widget.existingCourse?.status ?? CourseStatus.active,
        createdAt: widget.existingCourse?.createdAt ?? now,
        updatedAt: now,
        synced: false,
      );

      await db.upsertCourse(course);
      ref.read(syncServiceProvider).syncNow(lecturerId: user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingCourse == null ? 'Course created successfully' : 'Course updated successfully'),
            backgroundColor: AppColors.presentGreen,
          ),
        );

        if (widget.existingCourse == null) {
          // Offer to import students after creation
          context.pushReplacement('/courses/${course.id}/import');
        } else {
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save course: $e'),
            backgroundColor: AppColors.absentRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingCourse != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Course' : 'Create Course'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Course Code
              Text('Course Code', style: AppTypography.labelMd.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(hintText: 'e.g. GCE 202'),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Course code is required' : null,
              ),

              const SizedBox(height: 16),

              // Course Title
              Text('Course Title', style: AppTypography.labelMd.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'e.g. Adolescence Psychology & Counselling'),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Course title is required' : null,
              ),

              const SizedBox(height: 16),

              // Department
              Text('Department', style: AppTypography.labelMd.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _departmentController,
                decoration: const InputDecoration(hintText: 'e.g. Educational Foundations'),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Department is required' : null,
              ),

              const SizedBox(height: 16),

              // Row: Level & Semester
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Level', style: AppTypography.labelMd.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _levelController,
                          decoration: const InputDecoration(hintText: 'e.g. 200 Level'),
                          validator: (val) => (val == null || val.trim().isEmpty) ? 'Level required' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Semester', style: AppTypography.labelMd.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _semesterController,
                          decoration: const InputDecoration(hintText: 'e.g. First Semester'),
                          validator: (val) => (val == null || val.trim().isEmpty) ? 'Semester required' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Row: Academic Session & Expected Classes
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Academic Session', style: AppTypography.labelMd.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _sessionController,
                          decoration: const InputDecoration(hintText: 'e.g. 2026/2027'),
                          validator: (val) => (val == null || val.trim().isEmpty) ? 'Session required' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Expected Classes', style: AppTypography.labelMd.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _expectedClassesController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: 'e.g. 15'),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Required';
                            final parsed = int.tryParse(val.trim());
                            if (parsed == null || parsed <= 0) return 'Invalid number';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: _isSaving ? null : _submitForm,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                      )
                    : Text(isEditing ? 'Save Changes' : 'Create Course'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
