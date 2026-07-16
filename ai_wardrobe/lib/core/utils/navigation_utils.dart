import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/wardrobe_provider.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/recommendation_provider.dart';
import '../../screens/upload_clothing_screen.dart';
import '../../screens/analytics_screen.dart';
import '../../screens/onboarding_screen.dart';
import '../../screens/splash_screen.dart';

class NavigationUtils {
  static void showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AtelierTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'NOTIFICATIONS',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AtelierTheme.accent,
                      letterSpacing: 1.5,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AtelierTheme.secondaryText, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildNotificationItem(
                icon: Icons.checkroom,
                title: 'Garment Scanned',
                body: 'Your new shirt was cataloged successfully by Vision AI.',
                time: '2 hours ago',
              ),
              const Divider(color: AtelierTheme.border, height: 24),
              _buildNotificationItem(
                icon: Icons.auto_awesome,
                title: 'Styling recommendation ready',
                body: 'AI Stylist generated 3 curated outfits for your Party occasion.',
                time: '5 hours ago',
              ),
              const Divider(color: AtelierTheme.border, height: 24),
              _buildNotificationItem(
                icon: Icons.person_outline,
                title: 'Profile Updated',
                body: 'Biometric confidence gauges recalculated.',
                time: '1 day ago',
              ),
            ],
          ),
        );
      },
    );
  }

  static void showMenuSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AtelierTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI ASSISTANT MENU',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AtelierTheme.accent,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              _buildMenuItem(
                icon: Icons.camera_alt_outlined,
                label: 'Scan New Clothing',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UploadClothingScreen()),
                  );
                },
              ),
              _buildMenuItem(
                icon: Icons.bar_chart_outlined,
                label: 'View Wardrobe Analytics',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                  );
                },
              ),
              _buildMenuItem(
                icon: Icons.edit_outlined,
                label: 'Edit Biometric Profile',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  );
                },
              ),
              const Divider(color: AtelierTheme.border, height: 32),
              _buildMenuItem(
                icon: Icons.logout,
                label: 'Logout Session',
                color: AtelierTheme.warning,
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(authProvider.notifier).logout();
                  
                  // Invalidate cached user data to prevent profile bleed across sessions
                  ref.invalidate(profileProvider);
                  ref.invalidate(wardrobeProvider);
                  ref.invalidate(analyticsProvider);
                  ref.invalidate(recommendationProvider);
                  
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const SplashScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildNotificationItem({
    required IconData icon,
    required String title,
    required String body,
    required String time,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AtelierTheme.surfaceAccent,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AtelierTheme.accent, size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: GoogleFonts.inter(fontSize: 12, color: AtelierTheme.secondaryText),
              ),
               const SizedBox(height: 4),
              Text(
                time,
                style: GoogleFonts.inter(fontSize: 10, color: AtelierTheme.secondaryText.withOpacity(0.6)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = AtelierTheme.primaryText,
  }) {
    return ListTile(
      leading: Icon(icon, color: color == AtelierTheme.primaryText ? AtelierTheme.accent : color, size: 20),
      title: Text(
        label,
        style: GoogleFonts.manrope(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: color,
        ),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}
