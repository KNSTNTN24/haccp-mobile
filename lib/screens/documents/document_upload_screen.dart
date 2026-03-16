import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../../config/theme.dart';
import '../../models/document.dart';
import '../../models/profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/documents_provider.dart';
import '../../config/supabase.dart';

class DocumentUploadScreen extends ConsumerStatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  ConsumerState<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends ConsumerState<DocumentUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DocumentCategory _category = DocumentCategory.other;
  AccessLevel _accessLevel = AccessLevel.all;
  DateTime? _expiresAt;
  PlatformFile? _pickedFile;
  bool _uploading = false;
  List<Map<String, dynamic>> _teamMembers = [];
  final Set<String> _selectedMembers = {};

  @override
  void initState() {
    super.initState();
    _loadTeamMembers();
  }

  Future<void> _loadTeamMembers() async {
    try {
      final profile = await ref.read(profileProvider.future);
      if (profile == null) return;
      final data = await SupabaseConfig.client
          .from('profiles')
          .select('id, full_name, email, role')
          .eq('business_id', profile.businessId)
          .neq('id', SupabaseConfig.auth.currentUser!.id)
          .order('full_name');
      setState(() => _teamMembers = List<Map<String, dynamic>>.from(data));
    } catch (_) {}
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'docx', 'xlsx'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedFile = result.files.first);
      if (_titleCtrl.text.isEmpty) {
        _titleCtrl.text = _pickedFile!.name.split('.').first.replaceAll('_', ' ').replaceAll('-', ' ');
      }
    }
  }

  Future<void> _pickExpiryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date != null) {
      setState(() => _expiresAt = date);
    }
  }

  Future<void> _upload() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedFile == null || _pickedFile!.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _uploading = true);

    final success = await ref.read(documentsNotifierProvider.notifier).uploadDocument(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      category: _category.name,
      fileName: _pickedFile!.name,
      fileBytes: _pickedFile!.bytes!,
      mimeType: _getMimeType(_pickedFile!.name),
      accessLevel: _accessLevel.toDbValue(),
      expiresAt: _expiresAt,
      allowedProfileIds: _accessLevel == AccessLevel.custom ? _selectedMembers.toList() : null,
    );

    setState(() => _uploading = false);

    if (success && mounted) {
      ref.invalidate(documentsProvider(null));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Document uploaded successfully!'),
          backgroundColor: AppColors.primary,
        ),
      );
      context.go('/documents');
    } else if (mounted) {
      final error = ref.read(documentsNotifierProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${error.error ?? "Upload failed"}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      default:
        return 'application/octet-stream';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Document', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/documents'),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // File picker
            InkWell(
              onTap: _pickFile,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _pickedFile != null ? AppColors.primaryPale : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _pickedFile != null ? AppColors.primary : AppColors.divider,
                    width: _pickedFile != null ? 2 : 1,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _pickedFile != null ? Icons.check_circle : Icons.cloud_upload_outlined,
                      size: 48,
                      color: _pickedFile != null ? AppColors.primary : AppColors.lightText,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _pickedFile != null ? _pickedFile!.name : 'Tap to select file',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _pickedFile != null ? AppColors.darkText : AppColors.midText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_pickedFile != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${(_pickedFile!.size / 1024).toStringAsFixed(1)} KB',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.midText),
                      ),
                    ] else
                      Text(
                        'PDF, JPG, PNG, DOCX, XLSX (max 10 MB)',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.lightText),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Document Title *'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Title required' : null,
            ),
            const SizedBox(height: 14),

            // Description
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
              maxLines: 3,
            ),
            const SizedBox(height: 14),

            // Category
            Text('Category', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkText)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DocumentCategory.values.map((c) {
                final isSelected = _category == c;
                return ChoiceChip(
                  label: Text('${c.icon} ${c.label}'),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _category = c),
                  selectedColor: AppColors.primaryPale,
                  backgroundColor: AppColors.surface,
                  side: BorderSide(color: isSelected ? AppColors.primary : AppColors.divider),
                  labelStyle: GoogleFonts.inter(
                    fontSize: 13,
                    color: isSelected ? AppColors.primary : AppColors.darkText,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Expiry date
            Text('Expiry Date (optional)', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkText)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickExpiryDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event, color: _expiresAt != null ? AppColors.primary : AppColors.lightText),
                    const SizedBox(width: 12),
                    Text(
                      _expiresAt != null
                          ? '${_expiresAt!.day}/${_expiresAt!.month}/${_expiresAt!.year}'
                          : 'No expiry date',
                      style: GoogleFonts.inter(
                        color: _expiresAt != null ? AppColors.darkText : AppColors.lightText,
                      ),
                    ),
                    const Spacer(),
                    if (_expiresAt != null)
                      GestureDetector(
                        onTap: () => setState(() => _expiresAt = null),
                        child: Icon(Icons.close, size: 18, color: AppColors.midText),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Access level
            Text('Access Level', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkText)),
            const SizedBox(height: 8),
            ...AccessLevel.values.map((level) => RadioListTile<AccessLevel>(
              value: level,
              groupValue: _accessLevel,
              onChanged: (v) => setState(() => _accessLevel = v!),
              title: Text(level.label, style: GoogleFonts.inter(fontSize: 14)),
              secondary: Icon(_getAccessIcon(level), color: AppColors.primary),
              contentPadding: EdgeInsets.zero,
              dense: true,
            )),

            // Custom access: team member selection
            if (_accessLevel == AccessLevel.custom) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryPale,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select team members who can access this document:',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.darkText),
                    ),
                    const SizedBox(height: 8),
                    if (_teamMembers.isEmpty)
                      Text('Loading team...', style: GoogleFonts.inter(fontSize: 13, color: AppColors.midText))
                    else
                      ..._teamMembers.map((m) => CheckboxListTile(
                        value: _selectedMembers.contains(m['id']),
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selectedMembers.add(m['id']);
                            } else {
                              _selectedMembers.remove(m['id']);
                            }
                          });
                        },
                        title: Text(
                          m['full_name'] ?? m['email'] ?? 'Unknown',
                          style: GoogleFonts.inter(fontSize: 14),
                        ),
                        subtitle: Text(
                          m['role'] ?? '',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.midText),
                        ),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      )),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Upload button
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _uploading ? null : _upload,
                icon: _uploading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.upload_file),
                label: Text(_uploading ? 'Uploading...' : 'Upload Document'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  IconData _getAccessIcon(AccessLevel level) {
    switch (level) {
      case AccessLevel.all:
        return Icons.public;
      case AccessLevel.managersOnly:
        return Icons.admin_panel_settings;
      case AccessLevel.ownerOnly:
        return Icons.lock;
      case AccessLevel.custom:
        return Icons.people;
    }
  }
}
