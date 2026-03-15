import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nameController = TextEditingController();
  final _businessController = TextEditingController();
  final _addressController = TextEditingController();
  final _tokenController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Check if token in URL
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uri = GoRouterState.of(context).uri;
      final token = uri.queryParameters['token'];
      if (token != null) {
        _tokenController.text = token;
        _tabController.animateTo(1); // Switch to "Join Team" tab
      }
    });
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _businessController.dispose();
    _addressController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateBusiness() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });

    final success = await ref.read(authNotifierProvider.notifier).setupBusiness(
      businessName: _businessController.text.trim(),
      fullName: _nameController.text.trim(),
      address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ref.invalidate(profileProvider);
        ref.invalidate(businessProvider);
        context.go('/dashboard');
      } else {
        setState(() => _error = 'Failed to create business. Please try again.');
      }
    }
  }

  Future<void> _handleJoinTeam() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your name');
      return;
    }
    if (_tokenController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter the invite token');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    final success = await ref.read(authNotifierProvider.notifier).joinWithInvite(
      token: _tokenController.text.trim(),
      fullName: _nameController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ref.invalidate(profileProvider);
        ref.invalidate(businessProvider);
        context.go('/dashboard');
      } else {
        setState(() => _error = 'Invalid or expired invite token. Ask your manager for a new one.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.darkBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.business, size: 40, color: AppColors.gold),
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome!',
                  style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.darkBlue),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create a new business or join an existing team',
                  style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Tabs
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.darkBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: AppColors.darkBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.darkBlue,
                    labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                    tabs: const [
                      Tab(text: 'New Business'),
                      Tab(text: 'Join Team'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Form(
                  key: _formKey,
                  child: AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, _) {
                      final isJoin = _tabController.index == 1;
                      return Column(
                        children: [
                          // Name (always shown)
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Your Full Name *',
                              prefixIcon: Icon(Icons.person_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Enter your name' : null,
                          ),
                          const SizedBox(height: 16),

                          if (!isJoin) ...[
                            // New Business fields
                            TextFormField(
                              controller: _businessController,
                              decoration: const InputDecoration(
                                labelText: 'Business Name *',
                                prefixIcon: Icon(Icons.storefront_outlined),
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Enter business name' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _addressController,
                              decoration: const InputDecoration(
                                labelText: 'Address (optional)',
                                prefixIcon: Icon(Icons.location_on_outlined),
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 2,
                            ),
                          ] else ...[
                            // Join Team fields
                            TextFormField(
                              controller: _tokenController,
                              decoration: const InputDecoration(
                                labelText: 'Invite Token *',
                                prefixIcon: Icon(Icons.vpn_key_outlined),
                                border: OutlineInputBorder(),
                                hintText: 'Paste the token from your manager',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.gold.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, color: AppColors.gold, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Ask your manager for the invite token. They can create one in Team → Invite.',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center),
                          ],

                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : (isJoin ? _handleJoinTeam : _handleCreateBusiness),
                              child: _isLoading
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                                  : Text(
                                      isJoin ? 'Join Team' : 'Create Business',
                                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
