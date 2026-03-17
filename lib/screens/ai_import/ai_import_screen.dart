import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/supabase.dart';
import '../../config/theme.dart';
import '../../models/recipe.dart';
import '../../providers/auth_provider.dart';
import '../recipes/recipes_screen.dart';

class AiImportScreen extends ConsumerStatefulWidget {
  const AiImportScreen({super.key});

  @override
  ConsumerState<AiImportScreen> createState() => _AiImportScreenState();
}

class _AiImportScreenState extends ConsumerState<AiImportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isAnalyzing = false;
  bool _isSaving = false;
  String? _error;

  // Text input
  final _textController = TextEditingController();

  // PDF input
  String? _pdfFileName;
  Uint8List? _pdfBytes;

  // Photo input
  String? _photoFileName;
  Uint8List? _photoBytes;

  // Optional video URL (just saved with recipe, not analyzed)
  final _videoUrlController = TextEditingController();

  // Parsed recipe data
  Map<String, dynamic>? _parsedRecipe;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      final file = result.files.single;
      if (file.size > 10 * 1024 * 1024) {
        setState(() => _error = 'PDF must be under 10 MB');
        return;
      }
      setState(() {
        _pdfFileName = file.name;
        _pdfBytes = file.bytes;
        _error = null;
        _parsedRecipe = null;
      });
    }
  }

  Future<void> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'heic'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      final file = result.files.single;
      if (file.size > 10 * 1024 * 1024) {
        setState(() => _error = 'Photo must be under 10 MB');
        return;
      }
      setState(() {
        _photoFileName = file.name;
        _photoBytes = file.bytes;
        _error = null;
        _parsedRecipe = null;
      });
    }
  }

  Future<void> _analyze() async {
    final tabIndex = _tabController.index;

    if (tabIndex == 0 && _textController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter recipe text');
      return;
    }
    if (tabIndex == 1 && _pdfBytes == null) {
      setState(() => _error = 'Please select a PDF file');
      return;
    }
    if (tabIndex == 2 && _photoBytes == null) {
      setState(() => _error = 'Please select a photo');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _error = null;
      _parsedRecipe = null;
    });

    try {
      final Map<String, dynamic> body;

      if (tabIndex == 0) {
        body = {'text': _textController.text.trim()};
      } else if (tabIndex == 1) {
        body = {
          'pdf_base64': base64Encode(_pdfBytes!),
          'filename': _pdfFileName ?? 'recipe.pdf',
        };
      } else {
        final ext = (_photoFileName ?? 'photo.jpg').split('.').last.toLowerCase();
        final mimeType = ext == 'png'
            ? 'image/png'
            : ext == 'webp'
                ? 'image/webp'
                : 'image/jpeg';
        body = {
          'image_base64': base64Encode(_photoBytes!),
          'image_mime': mimeType,
          'filename': _photoFileName ?? 'recipe.jpg',
        };
      }

      final response = await SupabaseConfig.client.functions.invoke(
        'import-recipe',
        body: body,
      );

      if (response.status != 200) {
        throw Exception(response.data?['error'] ?? 'Failed to analyze recipe');
      }

      final data = response.data as Map<String, dynamic>;
      setState(() => _parsedRecipe = data);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  Future<void> _saveRecipe() async {
    if (_parsedRecipe == null) return;
    setState(() => _isSaving = true);

    try {
      final profile = ref.read(profileProvider).value;
      final user = ref.read(currentUserProvider);
      if (profile == null || user == null) return;

      final db = SupabaseConfig.client;
      final r = _parsedRecipe!;

      final videoUrl = _videoUrlController.text.trim();

      final recipeResult = await db.from('recipes').insert({
        'name': r['name'] ?? 'Imported Recipe',
        'description': r['description'],
        'category': r['category'] ?? 'other',
        'instructions': r['instructions'] ?? '',
        'cooking_method': r['cookingMethod'],
        'cooking_temp': r['cookingTemp'] != null
            ? double.tryParse('${r['cookingTemp']}')
            : null,
        'cooking_time': r['cookingTime'] != null
            ? double.tryParse('${r['cookingTime']}')
            : null,
        'cooking_time_unit': r['cookingTimeUnit'] ?? 'minutes',
        if (videoUrl.isNotEmpty) 'source_video_url': videoUrl,
        'business_id': profile.businessId,
        'created_by': user.id,
        'active': true,
      }).select('id').single();

      final recipeId = recipeResult['id'] as String;

      final ingredients = r['ingredients'] as List<dynamic>? ?? [];
      for (final ing in ingredients) {
        final ingMap = ing as Map<String, dynamic>;
        final ingName = (ingMap['name'] as String?)?.trim() ?? '';
        if (ingName.isEmpty) continue;

        final allergens =
            (ingMap['allergens'] as List<dynamic>?)?.cast<String>() ?? [];

        final existing = await db
            .from('ingredients')
            .select('id')
            .eq('name', ingName)
            .eq('business_id', profile.businessId)
            .maybeSingle();

        String ingredientId;
        if (existing != null) {
          ingredientId = existing['id'] as String;
        } else {
          final newIng = await db.from('ingredients').insert({
            'name': ingName,
            'allergens': allergens,
            'business_id': profile.businessId,
          }).select('id').single();
          ingredientId = newIng['id'] as String;
        }

        await db.from('recipe_ingredients').insert({
          'recipe_id': recipeId,
          'ingredient_id': ingredientId,
          'quantity': ingMap['quantity']?.toString(),
          'unit': ingMap['unit'],
        });
      }

      ref.invalidate(recipesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Recipe imported!'),
              backgroundColor: Colors.green),
        );
        context.go('/recipes');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error saving: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Recipe Import'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.auto_awesome, size: 48, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Import Recipe with AI',
                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText),
              ),
            ),
            Center(
              child: Text(
                'Paste text, upload PDF, or snap a photo',
                style: GoogleFonts.inter(
                    fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            // Tabs: Text / PDF
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey.shade600,
                labelStyle: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Text'),
                  Tab(text: 'PDF'),
                  Tab(text: 'Photo'),
                ],
                onTap: (_) => setState(() {
                  _error = null;
                  _parsedRecipe = null;
                }),
              ),
            ),
            const SizedBox(height: 20),

            // Tab content
            AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                if (_tabController.index == 0) {
                  return _buildTextInput();
                } else if (_tabController.index == 1) {
                  return _buildPdfInput();
                } else {
                  return _buildPhotoInput();
                }
              },
            ),

            const SizedBox(height: 16),

            // Optional video URL
            Text(
              'Video URL (optional)',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _videoUrlController,
              decoration: InputDecoration(
                hintText: 'https://instagram.com/reel/...',
                hintStyle: GoogleFonts.inter(
                    fontSize: 14, color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.videocam_rounded,
                    color: Colors.grey.shade400, size: 20),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              style: GoogleFonts.inter(fontSize: 14),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.red50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        size: 18, color: AppColors.red600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style: GoogleFonts.inter(
                              fontSize: 13, color: AppColors.red600)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Analyze button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isAnalyzing ? null : _analyze,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                icon: _isAnalyzing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  _isAnalyzing ? 'Analyzing...' : 'Analyze with AI',
                  style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            // Parsed recipe preview
            if (_parsedRecipe != null) ...[
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              Text('Recipe Preview',
                  style: GoogleFonts.inter(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              _PreviewCard(data: _parsedRecipe!),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveRecipe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    _isSaving ? 'Saving...' : 'Save Recipe',
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTextInput() {
    return TextField(
      controller: _textController,
      maxLines: 8,
      decoration: InputDecoration(
        hintText:
            'Paste recipe text here...\n\nExample:\nPasta Carbonara\n- 400g spaghetti\n- 200g guanciale\n- 4 egg yolks\n- 100g pecorino\n...',
        hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.primary),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
      style: GoogleFonts.inter(fontSize: 14, height: 1.5),
    );
  }

  Widget _buildPdfInput() {
    return GestureDetector(
      onTap: _isAnalyzing ? null : _pickPdf,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: _pdfFileName != null
              ? AppColors.primary.withValues(alpha: 0.05)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _pdfFileName != null
                ? AppColors.primary.withValues(alpha: 0.3)
                : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              _pdfFileName != null
                  ? Icons.picture_as_pdf_rounded
                  : Icons.upload_file_rounded,
              size: 40,
              color: _pdfFileName != null
                  ? AppColors.primary
                  : Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              _pdfFileName ?? 'Tap to select PDF',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight:
                    _pdfFileName != null ? FontWeight.w600 : FontWeight.w400,
                color: _pdfFileName != null
                    ? AppColors.darkText
                    : Colors.grey.shade500,
              ),
            ),
            if (_pdfFileName == null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'PDF — max 10 MB',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: Colors.grey.shade400),
                ),
              ),
            if (_pdfBytes != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${(_pdfBytes!.length / 1024 / 1024).toStringAsFixed(1)} MB',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: Colors.grey.shade500),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoInput() {
    return GestureDetector(
      onTap: _isAnalyzing ? null : _pickPhoto,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: _photoBytes != null
              ? AppColors.primary.withValues(alpha: 0.05)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _photoBytes != null
                ? AppColors.primary.withValues(alpha: 0.3)
                : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            if (_photoBytes != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  _photoBytes!,
                  height: 160,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _photoFileName ?? 'photo.jpg',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${(_photoBytes!.length / 1024 / 1024).toStringAsFixed(1)} MB — tap to change',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: Colors.grey.shade500),
                ),
              ),
            ] else ...[
              Icon(Icons.camera_alt_rounded,
                  size: 40, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                'Tap to select photo',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade500,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'JPG, PNG, WebP — max 10 MB',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: Colors.grey.shade400),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _PreviewCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? 'Untitled';
    final description = data['description'] ?? '';
    final category = data['category'] ?? 'other';
    final instructions = data['instructions'] ?? '';
    final ingredients = (data['ingredients'] as List<dynamic>?) ?? [];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$name',
              style:
                  GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$category',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary),
              ),
            ),
            if (description.toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('$description',
                  style: GoogleFonts.inter(
                      fontSize: 14, color: Colors.grey.shade700)),
            ],
            if (ingredients.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Ingredients',
                  style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...ingredients.map((ing) {
                final m = ing as Map<String, dynamic>;
                final ingName = m['name'] ?? '';
                final qty = m['quantity'] ?? '';
                final unit = m['unit'] ?? '';
                final allergens =
                    (m['allergens'] as List<dynamic>?)?.join(', ') ?? '';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.circle,
                          size: 6, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$ingName${qty.toString().isNotEmpty ? ' — $qty $unit' : ''}',
                          style: GoogleFonts.inter(fontSize: 14),
                        ),
                      ),
                      if (allergens.isNotEmpty)
                        Icon(Icons.warning_amber_rounded,
                            size: 16, color: AppColors.orange600),
                    ],
                  ),
                );
              }),
            ],
            if (instructions.toString().isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Instructions',
                  style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('$instructions',
                  style: GoogleFonts.inter(fontSize: 14, height: 1.5)),
            ],
          ],
        ),
      ),
    );
  }
}
