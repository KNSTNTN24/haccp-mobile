import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/supabase.dart';
import '../../config/theme.dart';
import '../../models/delivery.dart';
import '../../providers/deliveries_provider.dart';

class DeliveriesScreen extends ConsumerWidget {
  const DeliveriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveriesAsync = ref.watch(deliveriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF065F46), Color(0xFF047857)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF047857).withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () => context.go('/deliveries/new'),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(deliveriesProvider),
        child: deliveriesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
          ),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded, size: 48, color: AppColors.red600),
                  const SizedBox(height: 16),
                  Text('$e', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, color: AppColors.midText)),
                ],
              ),
            ),
          ),
          data: (deliveries) {
            if (deliveries.isEmpty) {
              return _buildEmptyState(context);
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              itemCount: deliveries.length,
              itemBuilder: (context, index) => _DeliveryCard(delivery: deliveries[index]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.local_shipping_outlined, color: Color(0xFF059669), size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              'No deliveries yet',
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.darkText),
            ),
            const SizedBox(height: 8),
            Text(
              'Record incoming deliveries with\nsupplier info and photos',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 15, color: AppColors.midText, height: 1.5),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => context.go('/deliveries/new'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF065F46), Color(0xFF047857)]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF047857).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text('Record Delivery', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final Delivery delivery;
  const _DeliveryCard({required this.delivery});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(delivery.receivedAt);
    final photoCount = delivery.photos.length;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE9E3)),
        // no shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + chevron
          Row(
            children: [
              Expanded(
                child: Text(
                  delivery.supplierName ?? 'Unknown Supplier',
                  style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A2E)),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, size: 22, color: AppColors.lightText),
            ],
          ),
          const SizedBox(height: 6),
          // Date
          Text(dateStr, style: GoogleFonts.inter(fontSize: 13, color: AppColors.midText)),
          const SizedBox(height: 12),
          // Badges
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (delivery.receivedByName != null)
                _badge(Icons.person_rounded, delivery.receivedByName!, AppColors.primary),
              if (delivery.productTemperature != null)
                _badge(Icons.thermostat_rounded, '${delivery.productTemperature}°C', const Color(0xFF0891B2)),
              if (photoCount > 0)
                _badge(Icons.camera_alt_rounded, '$photoCount photo${photoCount > 1 ? 's' : ''}', const Color(0xFF7C3AED)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
