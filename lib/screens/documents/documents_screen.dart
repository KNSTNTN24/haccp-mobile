import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/document.dart';
import '../../models/profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/documents_provider.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  String? _selectedCategory;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(documentsProvider(_selectedCategory));
    final profileAsync = ref.watch(profileProvider);
    final profile = profileAsync.value;
    final canUpload = profile != null &&
        (profile.role == UserRole.owner || profile.role == UserRole.manager);

    return Scaffold(
      appBar: AppBar(
        title: Text('Documents', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search documents...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
            ),
          ),
          // Category filter chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              children: [
                _buildChip(null, 'All'),
                ...DocumentCategory.values.map((c) => _buildChip(c.name, '${c.icon} ${c.label}')),
              ],
            ),
          ),
          const Divider(height: 1),
          // Documents list
          Expanded(
            child: docsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 12),
                      Text('Error: $e', textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
              data: (docs) {
                final filtered = _searchQuery.isEmpty
                    ? docs
                    : docs.where((d) =>
                        d.title.toLowerCase().contains(_searchQuery) ||
                        (d.description?.toLowerCase().contains(_searchQuery) ?? false) ||
                        d.fileName.toLowerCase().contains(_searchQuery)).toList();

                if (filtered.isEmpty) {
                  return _buildEmptyState(canUpload);
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(documentsProvider(_selectedCategory));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _buildDocCard(filtered[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: canUpload
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/documents/upload'),
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildChip(String? categoryName, String label) {
    final isSelected = _selectedCategory == categoryName;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label, style: GoogleFonts.inter(fontSize: 13)),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _selectedCategory = isSelected ? null : categoryName);
          ref.invalidate(documentsProvider(_selectedCategory));
        },
        selectedColor: AppColors.primaryPale,
        checkmarkColor: AppColors.primary,
        backgroundColor: AppColors.surface,
        side: BorderSide(color: isSelected ? AppColors.primary : AppColors.divider),
      ),
    );
  }

  Widget _buildEmptyState(bool canUpload) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_outlined, size: 72, color: AppColors.lightText),
            const SizedBox(height: 16),
            Text(
              _selectedCategory != null ? 'No documents in this category' : 'No documents yet',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.darkText),
            ),
            const SizedBox(height: 8),
            Text(
              canUpload
                  ? 'Upload certificates, policies, and other important files'
                  : 'Documents will appear here when uploaded by your manager',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.midText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocCard(Document doc) {
    final dateFormat = DateFormat('d MMM yyyy');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/documents/${doc.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // File type icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryPale,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(doc.fileIcon, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 12),
              // Doc info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.title,
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkText),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${doc.category.icon} ${doc.category.label}',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.midText),
                        ),
                        if (doc.fileSizeFormatted.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            doc.fileSizeFormatted,
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.lightText),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 12, color: AppColors.lightText),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(doc.createdAt),
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.lightText),
                        ),
                        if (doc.uploaderName != null) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.person_outline, size: 12, color: AppColors.lightText),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              doc.uploaderName!,
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.lightText),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Status badges
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildAccessBadge(doc.accessLevel),
                  if (doc.isExpired)
                    _buildStatusBadge('Expired', AppColors.error, AppColors.red50)
                  else if (doc.isExpiringSoon)
                    _buildStatusBadge('Expiring', AppColors.warning, AppColors.yellow50),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccessBadge(AccessLevel level) {
    IconData icon;
    Color color;
    switch (level) {
      case AccessLevel.all:
        icon = Icons.public;
        color = AppColors.primary;
        break;
      case AccessLevel.managersOnly:
        icon = Icons.admin_panel_settings;
        color = AppColors.blue600;
        break;
      case AccessLevel.ownerOnly:
        icon = Icons.lock;
        color = AppColors.orange600;
        break;
      case AccessLevel.custom:
        icon = Icons.people;
        color = AppColors.purple600;
        break;
    }
    return Icon(icon, size: 18, color: color);
  }

  Widget _buildStatusBadge(String text, Color textColor, Color bgColor) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
      ),
    );
  }
}
