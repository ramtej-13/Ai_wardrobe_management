import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/theme.dart';
import '../models/wardrobe_analytics.dart';
import '../providers/analytics_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsState = ref.watch(analyticsProvider);

    return Scaffold(
      backgroundColor: AtelierTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Closet Metrics',
          style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: analyticsState.when(
          data: (data) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wardrobe Analytics',
                    style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Stylistic breakdown and category allocations in your MongoDB Atlas closet.',
                    style: GoogleFonts.inter(fontSize: 14, color: AtelierTheme.secondaryText, height: 1.4),
                  ),
                  const SizedBox(height: 32),
                  _buildPrimaryStatsCard(data),
                  const SizedBox(height: 32),
                  _buildCategoryBreakdownSection(data),
                ],
              ),
            );
          },
          error: (err, __) => Center(
            child: Text(
              'Failed to load analytics: $err',
              style: GoogleFonts.inter(color: AtelierTheme.secondaryText),
            ),
          ),
          loading: () => const Center(
            child: CircularProgressIndicator(color: AtelierTheme.accent),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryStatsCard(WardrobeAnalytics data) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AtelierTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AtelierTheme.border, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL ITEMS',
                  style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.bold, color: AtelierTheme.secondaryText, letterSpacing: 1.5),
                ),
                const SizedBox(height: 8),
                Text(
                  '${data.totalItems}',
                  style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Container(
            height: 50,
            width: 1,
            color: AtelierTheme.border,
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PRIMARY SHADE',
                  style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.bold, color: AtelierTheme.secondaryText, letterSpacing: 1.5),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _getColorDot(data.mostCommonColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        data.mostCommonColor,
                        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AtelierTheme.accent),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getColorDot(String colorName) {
    Color displayColor;
    switch (colorName.toLowerCase()) {
      case 'white':
        displayColor = Colors.white;
        break;
      case 'black':
        displayColor = Colors.black;
        break;
      case 'red':
        displayColor = Colors.red;
        break;
      case 'blue':
        displayColor = Colors.blue;
        break;
      case 'green':
        displayColor = Colors.green;
        break;
      case 'yellow':
        displayColor = Colors.yellow;
        break;
      case 'grey':
      case 'gray':
        displayColor = Colors.grey;
        break;
      default:
        displayColor = AtelierTheme.surfaceAccent;
    }

    return Container(
      height: 16,
      width: 16,
      decoration: BoxDecoration(
        color: displayColor,
        shape: BoxShape.circle,
        border: Border.all(color: AtelierTheme.border, width: 1.5),
      ),
    );
  }

  Widget _buildCategoryBreakdownSection(WardrobeAnalytics data) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AtelierTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AtelierTheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CATEGORY ALLOCATION',
            style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.bold, color: AtelierTheme.secondaryText, letterSpacing: 1.5),
          ),
          const SizedBox(height: 24),
          if (data.categoryCounts.isEmpty)
            Center(
              child: Text(
                'No category data available.',
                style: GoogleFonts.inter(color: AtelierTheme.secondaryText),
              ),
            )
          else
            ...data.categoryCounts.entries.map((entry) {
              return _buildCategoryProgressRow(entry.key, entry.value, data.totalItems);
            }),
        ],
      ),
    );
  }

  Widget _buildCategoryProgressRow(String category, int count, int total) {
    final percent = total > 0 ? count / total : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                '$count items (${(percent * 100).round()}%)',
                style: GoogleFonts.inter(fontSize: 12, color: AtelierTheme.secondaryText),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 6,
              backgroundColor: AtelierTheme.surfaceAccent,
              valueColor: const AlwaysStoppedAnimation(AtelierTheme.accent),
            ),
          ),
        ],
      ),
    );
  }
}
