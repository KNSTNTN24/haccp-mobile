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

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _nameController = TextEditingController();
  final _businessController = TextEditingController();
  final _addressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _businessController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleSetup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Check if there's an invite token
    final uri = GoRouterState.of(context).uri;
    final token = uri.queryParameters['token'];

    bool success;
    if (token != null) {
      success = await ref.read(authNotifierProvider.notifier).joinWithInvite(
            token: token,
            fullName: _nameController.text.trim(),
          );
    } else {
      success = await ref.read(authNotifierProvider.notifier).setupBusiness(
            businessName: _businessController.text.trim(),
            fullName: _nameController.text.trim(),
            address: _addressController.text.trim().isNotEmpty
                ? _addressController.text.trim()
                : null,
          );
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ref.invalidate(profileProvider);
        ref.invalidate(businessProvider);
        context.go('/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uri = GoRouterState.of(context).uri;
    final hasToken = uri.queryParameters['token'] != null;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
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
                    child: const Icon(
                      Icons.business,
                      size: 40,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    hasToken ? 'Join Team' : 'Set Up Your Business',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasToken
                        ? 'Enter your name to join'
                        : 'Tell us about your business',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 40),

                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Your Full Name',
                      prefixIcon: Icon(Icons.person_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter your name';
                      return null;
                    },
                  ),

                  if (!hasToken) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _businessController,
                      decoration: const InputDecoration(
                        labelText: 'Business Name',
                        prefixIcon: Icon(Icons.storefront_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter business name';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address (optional)',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      maxLines: 2,
                    ),
                  ],

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSetup,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                            )
                          : Text(
                              hasToken ? 'Join Team' : 'Get Started',
                              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
