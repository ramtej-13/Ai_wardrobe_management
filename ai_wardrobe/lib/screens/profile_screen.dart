import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/theme.dart';
import '../core/utils/navigation_utils.dart';
import '../models/user.dart';
import '../providers/profile_provider.dart';
import 'onboarding_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final List<String> _scanHistory = [];

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AtelierTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AtelierTheme.primaryText),
          onPressed: () => NavigationUtils.showMenuSheet(context, ref),
        ),
        title: Text(
          'AI WARDROBE',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            color: AtelierTheme.accent,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AtelierTheme.primaryText),
            onPressed: () => NavigationUtils.showNotificationsSheet(context),
          ),
          const SizedBox(width: 4),
          const CircleAvatar(
            radius: 14,
            backgroundColor: AtelierTheme.surface,
            child: Icon(Icons.person, size: 14, color: AtelierTheme.secondaryText),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: profileState.profile.when(
          data: (user) {
            if (user == null) {
              return _buildEmptyState(context);
            }
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile Analysis',
                    style: GoogleFonts.poppins(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Precision biometric data and stylistic mapping powered by AI Wardrobe\'s Vision Engine.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AtelierTheme.secondaryText,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildBiometricConfidenceCard(user),
                  const SizedBox(height: 32),
                  _buildCoreAttributesCard(context, user),
                  const SizedBox(height: 32),
                  _buildVScanHistory(context),
                  const SizedBox(height: 32),
                  _buildPreferenceCard(
                    icon: Icons.credit_card,
                    title: 'Budget Preference',
                    value: user.budget == 'Luxury'
                        ? '\$1.5k / piece'
                        : user.budget == 'Moderate'
                            ? '\$500 / piece'
                            : '\$100 / piece',
                    subtitle: '${user.budget} tier curated items.',
                  ),
                  const SizedBox(height: 16),
                  _buildPreferenceCard(
                    icon: Icons.location_on_outlined,
                    title: 'Service Region',
                    value: user.location.isEmpty ? 'Not Specified' : user.location,
                    subtitle: 'Personal shopping & delivery active.',
                  ),
                ],
              ),
            );
          },
          error: (err, __) => Center(child: Text('Error loading profile: $err')),
          loading: () => const Center(
            child: CircularProgressIndicator(color: AtelierTheme.accent),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_circle_outlined, size: 64, color: AtelierTheme.secondaryText),
          const SizedBox(height: 16),
          Text(
            'No Profile Found',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your profile to unlock style recommendations.',
            style: GoogleFonts.inter(color: AtelierTheme.secondaryText),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OnboardingScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AtelierTheme.accent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('CREATE PROFILE'),
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricConfidenceCard(UserProfile user) {
    // Calculate average biometric confidence score
    final confidenceScores = [
      user.bodyType.confidence,
      user.bodyBuild.confidence,
      user.skinTone.confidence,
      user.undertone.confidence,
      user.faceShape.confidence,
      user.estimatedHeight.confidence,
    ];
    
    final averageConfidence = confidenceScores.reduce((a, b) => a + b) / confidenceScores.length;
    final displayMatch = (averageConfidence * 100).round();
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AtelierTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AtelierTheme.border, width: 1),
      ),
      child: Column(
        children: [
          Text(
            'BIOMETRIC CONFIDENCE',
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AtelierTheme.secondaryText,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            width: 160,
            child: CustomPaint(
              painter: ConcentricGaugePainter(
                rings: [
                  user.faceShape.confidence,
                  user.bodyType.confidence,
                  user.skinTone.confidence,
                ],
                matchPercent: displayMatch,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildBiometricStatRow('Facial Mapping', '${(user.faceShape.confidence * 100).round()}%'),
          const Divider(color: AtelierTheme.border, height: 24),
          _buildBiometricStatRow('Bone Structure', '${(user.bodyType.confidence * 100).round()}%'),
          const Divider(color: AtelierTheme.border, height: 24),
          _buildBiometricStatRow('Skin Tonality', '${(user.skinTone.confidence * 100).round()}%'),
        ],
      ),
    );
  }

  Widget _buildBiometricStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.circle, color: AtelierTheme.secondaryText, size: 8),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 14, color: AtelierTheme.secondaryText),
            ),
          ],
        ),
        Text(
          value,
          style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildCoreAttributesCard(BuildContext context, UserProfile user) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Core\nAttributes',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  );
                },
                icon: const Icon(Icons.edit, size: 14, color: Colors.black),
                label: const Text('Edit Profiles'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildAttributeItem(icon: Icons.aspect_ratio, label: 'Body Type', value: user.bodyType.value),
          const Divider(color: AtelierTheme.border, height: 20),
          _buildAttributeItem(icon: Icons.palette_outlined, label: 'Skin Tone', value: user.skinTone.value),
          const Divider(color: AtelierTheme.border, height: 20),
          _buildAttributeItem(icon: Icons.face_outlined, label: 'Face Shape', value: user.faceShape.value),
        ],
      ),
    );
  }

  Widget _buildAttributeItem({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AtelierTheme.secondaryText, size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 12, color: AtelierTheme.secondaryText),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVScanHistory(BuildContext context) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'V-SCAN HISTORY',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AtelierTheme.secondaryText,
                  letterSpacing: 1.5,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  );
                },
                child: Row(
                  children: [
                    const Icon(Icons.camera_alt_outlined, size: 14, color: AtelierTheme.accent),
                    const SizedBox(width: 6),
                    Text(
                      'Re-scan',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AtelierTheme.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildScanThumbnail('Front', 'assets/images/scan_front.png'),
                const SizedBox(width: 12),
                _buildScanThumbnail('Side', 'assets/images/scan_side.png'),
                const SizedBox(width: 12),
                _buildScanThumbnail('Face', 'assets/images/scan_face.png'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanThumbnail(String label, String imageAsset) {
    return Container(
      width: 90,
      decoration: BoxDecoration(
        color: AtelierTheme.surfaceAccent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AtelierTheme.border, width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: Colors.grey.shade900,
              child: const Icon(Icons.portrait, color: AtelierTheme.secondaryText, size: 28),
            ),
            Positioned(
              left: 8,
              bottom: 8,
              child: Text(
                label.toUpperCase(),
                style: GoogleFonts.manrope(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AtelierTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AtelierTheme.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AtelierTheme.surfaceAccent,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AtelierTheme.secondaryText, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AtelierTheme.secondaryText,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(fontSize: 12, color: AtelierTheme.secondaryText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ConcentricGaugePainter extends CustomPainter {
  final List<double> rings; // List of confidence levels (0.0 to 1.0)
  final int matchPercent;

  ConcentricGaugePainter({required this.rings, required this.matchPercent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = min(size.width, size.height) / 2;

    // Draw center text
    final textPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$matchPercent%\n',
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          TextSpan(
            text: 'Match',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AtelierTheme.secondaryText,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(canvas, center - Offset(textPainter.width / 2, textPainter.height / 2));

    // Paint properties for rings
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = AtelierTheme.surfaceAccent
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = AtelierTheme.accent
      ..strokeCap = StrokeCap.round;

    // Draw concentric progress rings
    for (int i = 0; i < rings.length; i++) {
      final radius = maxRadius - (i * 14) - 10;
      
      // Draw background circle
      canvas.drawCircle(center, radius, basePaint);

      // Draw progress arc
      final angle = rings[i] * 2 * pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        angle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
