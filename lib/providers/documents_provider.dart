import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase.dart';
import '../models/document.dart';

final documentsProvider = FutureProvider.family<List<Document>, String?>((ref, category) async {
  var query = SupabaseConfig.client
      .from('documents')
      .select('*, profiles(full_name)');

  if (category != null && category.isNotEmpty) {
    query = query.eq('category', category);
  }

  final data = await query.order('created_at', ascending: false);
  return (data as List).map((json) => Document.fromJson(json)).toList();
});

final documentDetailProvider = FutureProvider.family<Document, String>((ref, id) async {
  final data = await SupabaseConfig.client
      .from('documents')
      .select('*, profiles(full_name)')
      .eq('id', id)
      .single();
  return Document.fromJson(data);
});

final documentAccessListProvider = FutureProvider.family<List<DocumentAccess>, String>((ref, documentId) async {
  final data = await SupabaseConfig.client
      .from('document_access')
      .select('*, profiles(full_name, email)')
      .eq('document_id', documentId)
      .order('created_at', ascending: false);
  return (data as List).map((json) => DocumentAccess.fromJson(json)).toList();
});

class DocumentsNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<bool> uploadDocument({
    required String title,
    String? description,
    required String category,
    required String fileName,
    required Uint8List fileBytes,
    required String mimeType,
    required String accessLevel,
    DateTime? expiresAt,
    List<String>? allowedProfileIds,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = SupabaseConfig.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final profile = await SupabaseConfig.client
          .from('profiles')
          .select('business_id')
          .eq('id', user.id)
          .single();
      final businessId = profile['business_id'] as String;

      // Upload file to Storage
      final storagePath = '$businessId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      await SupabaseConfig.client.storage
          .from('documents')
          .uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: FileOptions(contentType: mimeType),
          );

      // Get signed URL (bucket is private)
      final fileUrl = storagePath; // Store path, generate signed URLs on demand

      // Insert document record
      final docData = await SupabaseConfig.client.from('documents').insert({
        'title': title,
        'description': description,
        'category': category,
        'file_url': fileUrl,
        'file_name': fileName,
        'file_size': fileBytes.length,
        'file_type': mimeType,
        'uploaded_by': user.id,
        'business_id': businessId,
        'access_level': accessLevel,
        'expires_at': expiresAt?.toIso8601String(),
      }).select().single();

      // If custom access, add access records
      if (accessLevel == 'custom' && allowedProfileIds != null) {
        final accessRecords = allowedProfileIds.map((profileId) => {
          'document_id': docData['id'],
          'profile_id': profileId,
          'granted_by': user.id,
        }).toList();
        if (accessRecords.isNotEmpty) {
          await SupabaseConfig.client.from('document_access').insert(accessRecords);
        }
      }

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
      return false;
    }
  }

  Future<bool> deleteDocument(String documentId) async {
    state = const AsyncValue.loading();
    try {
      final doc = await SupabaseConfig.client
          .from('documents')
          .select('file_url')
          .eq('id', documentId)
          .single();

      final filePath = doc['file_url'] as String;
      try {
        await SupabaseConfig.client.storage.from('documents').remove([filePath]);
      } catch (_) {}

      await SupabaseConfig.client.from('documents').delete().eq('id', documentId);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
      return false;
    }
  }

  Future<bool> updateAccessLevel({
    required String documentId,
    required String accessLevel,
    List<String>? allowedProfileIds,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = SupabaseConfig.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      await SupabaseConfig.client
          .from('documents')
          .update({'access_level': accessLevel})
          .eq('id', documentId);

      await SupabaseConfig.client
          .from('document_access')
          .delete()
          .eq('document_id', documentId);

      if (accessLevel == 'custom' && allowedProfileIds != null) {
        final accessRecords = allowedProfileIds.map((profileId) => {
          'document_id': documentId,
          'profile_id': profileId,
          'granted_by': user.id,
        }).toList();
        if (accessRecords.isNotEmpty) {
          await SupabaseConfig.client.from('document_access').insert(accessRecords);
        }
      }

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
      return false;
    }
  }

  Future<String?> getSignedUrl(String filePath) async {
    try {
      return await SupabaseConfig.client.storage
          .from('documents')
          .createSignedUrl(filePath, 3600);
    } catch (e) {
      return null;
    }
  }
}

final documentsNotifierProvider = NotifierProvider<DocumentsNotifier, AsyncValue<void>>(
  DocumentsNotifier.new,
);
