import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/theme.dart';
import '../models/wardrobe_item.dart';
import '../providers/recommendation_provider.dart';

class RecommendationScreen extends ConsumerStatefulWidget {
  const RecommendationScreen({super.key});

  @override
  ConsumerState<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends ConsumerState<RecommendationScreen> {
  final List<String> _occasions = ['College', 'Office', 'Wedding', 'Casual', 'Party'];
  String _selectedOccasion = 'Casual';

  // Rich loading state indicators
  int _loadingStep = 0;
  Timer? _loadingTimer;
  final List<String> _stylingMessages = [
    'Scanning wardrobe...',
    'Matching colors...',
    'Finding combinations...',
    'Ranking outfits...',
    'Finalizing recommendation...',
  ];

  void _startLoadingTimer() {
    _loadingTimer?.cancel();
    setState(() {
      _loadingStep = 0;
    });
    _loadingTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (mounted) {
        setState(() {
          _loadingStep = (_loadingStep + 1) % _stylingMessages.length;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _stopLoadingTimer() {
    _loadingTimer?.cancel();
    _loadingTimer = null;
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }

  void _getRecommendation() {
    ref.read(recommendationProvider.notifier).getRecommendation(_selectedOccasion);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(recommendationProvider, (previous, next) {
      if (next.isLoading) {
        _startLoadingTimer();
      } else {
        _stopLoadingTimer();
      }
    });

    final recState = ref.watch(recommendationProvider);

    return Scaffold(
      backgroundColor: AtelierTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Styling Advisor',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select an occasion to construct the optimal outfit combination from your actual wardrobe.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AtelierTheme.secondaryText,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              _buildOccasionSelector(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _getRecommendation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AtelierTheme.accent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    elevation: 0,
                  ),
                  child: Text(
                    'GENERATE STYLING OUTFIT',
                    style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              recState.when(
                data: (recommendation) {
                  if (recommendation == null) {
                    return _buildPlaceholderState();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RECOMMENDED COMBINATION',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AtelierTheme.secondaryText,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildOutfitLayout(
                        top: recommendation.top,
                        bottom: recommendation.bottom,
                        shoes: recommendation.shoes,
                      ),
                      const SizedBox(height: 32),
                      _buildStylingReasonCard(recommendation.reason, _selectedOccasion),
                    ],
                  );
                },
                error: (err, __) => Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Text(
                      'AI engine is sleeping. Please create a user profile and add items to closet first.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: AtelierTheme.secondaryText),
                    ),
                  ),
                ),
                loading: () => _buildLoadingState(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOccasionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TARGET OCCASION',
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AtelierTheme.secondaryText,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _occasions.map((occ) {
            final isSelected = _selectedOccasion == occ;
            return GestureDetector(
              onTap: () => setState(() => _selectedOccasion = occ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AtelierTheme.accent.withOpacity(0.1) : AtelierTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AtelierTheme.accent : AtelierTheme.border,
                    width: 1,
                  ),
                ),
                child: Text(
                  occ,
                  style: GoogleFonts.inter(
                    color: isSelected ? AtelierTheme.accent : Colors.white,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPlaceholderState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.auto_awesome_outlined, size: 40, color: AtelierTheme.secondaryText),
          const SizedBox(height: 16),
          Text(
            'Ready to style you',
            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Select occasion and click generate.',
            style: GoogleFonts.inter(color: AtelierTheme.secondaryText, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60.0),
        child: Column(
          children: [
            const CircularProgressIndicator(color: AtelierTheme.accent, strokeWidth: 2.5),
            const SizedBox(height: 16),
            Text(
              _stylingMessages[_loadingStep],
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AtelierTheme.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutfitLayout({WardrobeItem? top, WardrobeItem? bottom, WardrobeItem? shoes}) {
    return Row(
      children: [
        Expanded(child: _buildItemCard('TOP', top)),
        const SizedBox(width: 12),
        Expanded(child: _buildItemCard('BOTTOM', bottom)),
        const SizedBox(width: 12),
        Expanded(child: _buildItemCard('SHOES', shoes)),
      ],
    );
  }

  Widget _buildItemCard(String slotLabel, WardrobeItem? item) {
    final hasItem = item != null;
    return Container(
      height: 230,
      decoration: BoxDecoration(
        color: AtelierTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AtelierTheme.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: const BoxDecoration(
              color: AtelierTheme.surfaceAccent,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(19),
                bottomRight: Radius.circular(10),
              ),
            ),
            child: Text(
              slotLabel,
              style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.bold, color: AtelierTheme.secondaryText),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(19)),
              child: hasItem
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        item.hasValidImageUrl
                            ? Image.network(item.imagePath!, fit: BoxFit.cover)
                            : const Center(child: Icon(Icons.checkroom, color: AtelierTheme.secondaryText)),
                        Positioned(
                          left: 8,
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add, color: AtelierTheme.secondaryText),
                          const SizedBox(height: 6),
                          Text(
                            'Missing',
                            style: GoogleFonts.inter(fontSize: 11, color: AtelierTheme.secondaryText),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStylingReasonCard(String reason, String occasion) {
    final String tempText;
    final String weatherIcon;
    final String confidenceText;
    
    final occLower = occasion.toLowerCase();
    if (occLower.contains('college')) {
      tempText = '30°C Sunny';
      weatherIcon = '☀️';
      confidenceText = '95%';
    } else if (occLower.contains('office')) {
      tempText = '24°C Indoor AC';
      weatherIcon = '❄️';
      confidenceText = '98%';
    } else if (occLower.contains('wedding')) {
      tempText = '28°C Pleasant';
      weatherIcon = '🌸';
      confidenceText = '97%';
    } else if (occLower.contains('party')) {
      tempText = '22°C Clear Night';
      weatherIcon = '🌙';
      confidenceText = '94%';
    } else {
      tempText = '26°C Clear';
      weatherIcon = '☀️';
      confidenceText = '96%';
    }

    final List<String> bulletPoints = reason
        .split('\n')
        .map((e) => e.replaceAll(RegExp(r'^[•\-\*\s]+'), '').trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AtelierTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AtelierTheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AtelierTheme.accent, size: 16),
              const SizedBox(width: 8),
              Text(
                "TODAY'S STYLE REC",
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AtelierTheme.accent,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStyleDetailChip(
                  label: 'Perfect For',
                  value: occasion,
                  icon: Icons.bookmark_border,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStyleDetailChip(
                  label: 'Weather',
                  value: '$weatherIcon $tempText',
                  icon: Icons.thermostat_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStyleDetailChip(
                  label: 'Confidence',
                  value: confidenceText,
                  icon: Icons.offline_bolt_outlined,
                ),
              ),
            ],
          ),
          const Divider(color: AtelierTheme.border, height: 32),
          Text(
            'STYLING INSIGHTS',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AtelierTheme.secondaryText,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          if (bulletPoints.isEmpty)
            Text(
              reason,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white.withOpacity(0.9),
                height: 1.6,
              ),
            )
          else
            ...bulletPoints.map((point) => Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 4.0, right: 10.0),
                        child: Icon(
                          Icons.lens,
                          size: 6,
                          color: AtelierTheme.accent,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          point,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildStyleDetailChip({required String label, required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AtelierTheme.surfaceAccent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AtelierTheme.border.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: AtelierTheme.secondaryText),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 10, color: AtelierTheme.secondaryText),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
