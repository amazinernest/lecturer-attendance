import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/providers.dart';
import '../../../core/utils/class_list_parser.dart';

class ImportClassListScreen extends ConsumerStatefulWidget {
  final String courseId;

  const ImportClassListScreen({super.key, required this.courseId});

  @override
  ConsumerState<ImportClassListScreen> createState() => _ImportClassListScreenState();
}

class _ImportClassListScreenState extends ConsumerState<ImportClassListScreen> {
  bool _isPickingFile = false;
  bool _isImporting = false;

  String? _selectedFileName;
  ClassListImportResult? _parseResult;

  Future<void> _pickAndParseFile() async {
    setState(() => _isPickingFile = true);
    try {
      final db = ref.read(databaseProvider);
      final existingStudents = await db.getStudentsForCourse(widget.courseId);
      final existingMatrics = existingStudents.map((s) => s.matricNumber).toList();

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls', 'txt', 'pdf', 'doc', 'docx'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = file.bytes;

        if (bytes != null) {
          final parsed = ClassListParser.parseFile(
            bytes: bytes,
            fileName: file.name,
            courseId: widget.courseId,
            existingMatricNumbers: existingMatrics,
          );

          setState(() {
            _selectedFileName = file.name;
            _parseResult = parsed;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to read this file. Please check that it is a valid CSV, Excel, Word (DOC/DOCX), or PDF file.'),
            backgroundColor: AppColors.absentRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingFile = false);
    }
  }

  Future<void> _confirmImport() async {
    final result = _parseResult;
    if (result == null || result.validStudents.isEmpty) return;

    setState(() => _isImporting = true);
    try {
      final db = ref.read(databaseProvider);
      await db.batchInsertStudents(result.validStudents);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.validCount} students added successfully.'),
            backgroundColor: AppColors.presentGreen,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import students: $e'),
            backgroundColor: AppColors.absentRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _parseResult;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Import Class List'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Upload Area Card
            Card(
              elevation: 0,
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.primaryContainer, width: 1.5),
              ),
              child: InkWell(
                onTap: _isPickingFile ? null : _pickAndParseFile,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cloud_upload_outlined,
                          size: 40,
                          color: AppColors.primaryContainer,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _selectedFileName ?? 'Tap to Select CSV, Excel, PDF, or Word File',
                        style: AppTypography.titleMd.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryContainer,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Supports CSV, XLSX, PDF, DOC, and DOCX formats',
                        style: AppTypography.labelMd.copyWith(color: AppColors.secondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Preview Section
            if (result != null) ...[
              // Summary Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: result.hasErrors ? AppColors.warningBg : AppColors.presentBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: result.hasErrors ? AppColors.warningOrange : AppColors.presentGreen,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          result.hasErrors ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                          color: result.hasErrors ? AppColors.warningOrange : AppColors.presentGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${result.validCount} valid students found',
                          style: AppTypography.titleMd.copyWith(
                            fontSize: 16,
                            color: result.hasErrors ? AppColors.warningOrange : AppColors.presentGreen,
                          ),
                        ),
                      ],
                    ),
                    if (result.hasErrors) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${result.errorCount} records require attention and will be skipped.',
                        style: AppTypography.labelMd.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Import Preview (${result.validCount} Students)',
                style: AppTypography.titleMd.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 12),

              // Preview List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: result.validStudents.length.clamp(0, 50),
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final s = result.validStudents[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.1),
                      child: Text(
                        s.name.isNotEmpty ? s.name[0].toUpperCase() : 'S',
                        style: AppTypography.titleMd.copyWith(color: AppColors.primaryContainer, fontSize: 14),
                      ),
                    ),
                    title: Text(s.name, style: AppTypography.titleMd.copyWith(fontSize: 15)),
                    subtitle: Text(s.matricNumber, style: AppTypography.labelMd),
                  );
                },
              ),

              const SizedBox(height: 28),

              // Action Button
              ElevatedButton(
                onPressed: (_isImporting || result.validStudents.isEmpty) ? null : _confirmImport,
                child: _isImporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                      )
                    : Text('Import ${result.validCount} Students'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
