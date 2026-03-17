import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase.dart';
import '../../config/theme.dart';
import '../../models/supplier.dart';
import '../../providers/auth_provider.dart';
import '../../providers/deliveries_provider.dart';
import '../suppliers/suppliers_screen.dart';

class _PhotoEntry {
  final String fileName;
  final Uint8List bytes;
  final String mime;
  _PhotoEntry({required this.fileName, required this.bytes, required this.mime});
}

class DeliveryNewScreen extends ConsumerStatefulWidget {
  const DeliveryNewScreen({super.key});

  @override
  ConsumerState<DeliveryNewScreen> createState() => _DeliveryNewScreenState();
}

class _DeliveryNewScreenState extends ConsumerState<DeliveryNewScreen> {
  String? _selectedSupplierId;
  final _tempController = TextEditingController();
  final _notesController = TextEditingController();
  final List<_PhotoEntry> _photos = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _tempController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 1920, imageQuality: 85);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final ext = picked.name.split('.').last.toLowerCase();
    final mime = ext == 'png' ? 'image/png' : 'image/jpeg';

    setState(() {
      _photos.add(_PhotoEntry(fileName: picked.name, bytes: bytes, mime: mime));
    });
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  Future<void> _submit() async {
    final profile = ref.read(profileProvider).value;
    if (profile == null) return;

    if (_selectedSupplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a supplier')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final temp = _tempController.text.trim().isNotEmpty
          ? double.tryParse(_tempController.text.trim())
          : null;

      // Create delivery record
      final deliveryData = await SupabaseConfig.client
          .from('deliveries')
          .insert({
            'supplier_id': _selectedSupplierId,
            'received_by': profile.id,
            'product_temperature': temp,
            'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
            'business_id': profile.businessId,
          })
          .select()
          .single();

      final deliveryId = deliveryData['id'] as String;

      // Upload photos
      for (final photo in _photos) {
        final storagePath =
            '${profile.businessId}/delivery-photos/${DateTime.now().millisecondsSinceEpoch}_${photo.fileName}';

        await SupabaseConfig.client.storage.from('documents').uploadBinary(
              storagePath,
              photo.bytes,
              fileOptions: FileOptions(contentType: photo.mime),
            );

        await SupabaseConfig.client.from('delivery_photos').insert({
          'delivery_id': deliveryId,
          'photo_url': storagePath,
          'file_name': photo.fileName,
        });
      }

      ref.invalidate(deliveriesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delivery recorded successfully!')),
        );
        context.go('/deliveries');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(suppliersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkText),
          onPressed: () => context.go('/deliveries'),
        ),
        title: Text(
          'Record Delivery',
          style: GoogleFonts.inter(
            color: AppColors.darkText,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Supplier dropdown
            _sectionLabel('Supplier *'),
            const SizedBox(height: 8),
            suppliersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (e, _) => Text('Error loading suppliers: $e'),
              data: (suppliers) {
                if (suppliers.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Text(
                      'No suppliers found. Add a supplier first.',
                      style: GoogleFonts.inter(fontSize: 14, color: AppColors.midText),
                    ),
                  );
                }
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSupplierId,
                      hint: Text('Select supplier', style: GoogleFonts.inter(color: AppColors.lightText)),
                      isExpanded: true,
                      items: suppliers
                          .map((s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(s.name, style: GoogleFonts.inter(fontSize: 15)),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedSupplierId = v),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Product temperature
            _sectionLabel('Product Temperature (optional)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _tempController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'e.g. 4.5',
                suffixText: '°C',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.divider),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Notes
            _sectionLabel('Notes (optional)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Any notes about this delivery...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.divider),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Photos section
            _sectionLabel('Photos (invoice/receipt)'),
            const SizedBox(height: 8),

            // Photo grid
            if (_photos.isNotEmpty) ...[
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photos.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                              _photos[index].bytes,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removePhoto(index),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickPhoto(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: Text('Camera', style: GoogleFonts.inter(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickPhoto(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: Text('Gallery', style: GoogleFonts.inter(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'Save Delivery',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.darkText,
      ),
    );
  }
}
