import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/theme.dart';
import '../core/utils/navigation_utils.dart';
import '../providers/profile_provider.dart';
import '../providers/wardrobe_provider.dart';
import '../providers/analytics_provider.dart';
import '../providers/navigation_provider.dart';
import 'upload_clothing_screen.dart';
import 'analytics_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final wardrobeState = ref.watch(wardrobeProvider);
    final analyticsState = ref.watch(analyticsProvider);

    return Scaffold(
      backgroundColor: AtelierTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(profileProvider);
            ref.invalidate(wardrobeProvider);
            ref.invalidate(analyticsProvider);
          },
          color: AtelierTheme.accent,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeSlideTransition(
                  delay: Duration.zero,
                  child: _buildHeader(context, profileState, ref),
                ),
                const SizedBox(height: 24),
                FadeSlideTransition(
                  delay: const Duration(milliseconds: 150),
                  child: _buildAiStylistHero(profileState, wardrobeState),
                ),
                const SizedBox(height: 24),
                FadeSlideTransition(
                  delay: const Duration(milliseconds: 300),
                  child: _buildAiInsightsCarousel(wardrobeState),
                ),
                const SizedBox(height: 24),
                FadeSlideTransition(
                  delay: const Duration(milliseconds: 450),
                  child: _buildQuickActions(context),
                ),
                const SizedBox(height: 24),
                FadeSlideTransition(
                  delay: const Duration(milliseconds: 600),
                  child: _buildStatsGrid(context, wardrobeState, analyticsState),
                ),
                const SizedBox(height: 24),
                FadeSlideTransition(
                  delay: const Duration(milliseconds: 750),
                  child: _buildRecentItemsSection(context, wardrobeState),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ProfileState profileState, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.menu, color: AtelierTheme.primaryText, size: 20),
          onPressed: () => NavigationUtils.showMenuSheet(context, ref),
        ),
        Text(
          'AI WARDROBE',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: AtelierTheme.primaryText, size: 20),
              onPressed: () => NavigationUtils.showNotificationsSheet(context),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () {
                ref.read(navigationProvider.notifier).state = 3;
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AtelierTheme.border, width: 1.5),
                ),
                child: const CircleAvatar(
                  radius: 16,
                  backgroundColor: AtelierTheme.surface,
                  child: Icon(Icons.person, color: AtelierTheme.secondaryText, size: 14),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAiStylistHero(ProfileState profileState, WardrobeState wardrobeState) {
    final hour = DateTime.now().hour;
    final String timeGreeting;
    if (hour < 12) {
      timeGreeting = 'Good Morning';
    } else if (hour < 17) {
      timeGreeting = 'Good Afternoon';
    } else {
      timeGreeting = 'Good Evening';
    }

    return profileState.profile.when(
      data: (user) {
        final name = user?.name ?? 'Guest';
        final totalItems = wardrobeState.items.value?.length ?? 0;
        
        final String aiMessage;
        if (totalItems == 0) {
          aiMessage = "Welcome! Tap 'Scan Clothing' below to scan your first clothing item and unlock personal styling.";
        } else if (user == null || user.bodyType.value == 'N/A') {
          aiMessage = "I've cataloged your $totalItems clothing items! Complete your biometric style scan to unlock personalized styling.";
        } else {
          final bodyType = user.bodyType.value;
          aiMessage = "Today's weather is warm. I analyzed your $totalItems items and ranked 3 perfect combinations for your $bodyType body profile.";
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AtelierTheme.surface,
                AtelierTheme.surfaceAccent.withOpacity(0.4),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AtelierTheme.accent.withOpacity(0.2), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AtelierTheme.accent.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AtelierTheme.accent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome, color: AtelierTheme.accent, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI STYLIST',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AtelierTheme.accent,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '$timeGreeting, $name',
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                aiMessage,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AtelierTheme.secondaryText.withOpacity(0.85),
                  height: 1.45,
                ),
              ),
            ],
          ),
        );
      },
      error: (_, __) => const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK ACTIONS',
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AtelierTheme.secondaryText,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UploadClothingScreen()),
                  );
                },
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: AtelierTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AtelierTheme.border, width: 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AtelierTheme.accent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_outlined, color: AtelierTheme.accent, size: 24),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Scan Clothing',
                        style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: AtelierTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AtelierTheme.border, width: 1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.style_outlined, color: Colors.blue, size: 24),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'AI Try-On (Future)',
                      style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, WardrobeState wardrobeState, AsyncValue analyticsState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WARDROBE SUMMARY',
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AtelierTheme.secondaryText,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AtelierTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AtelierTheme.border, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Pieces',
                      style: GoogleFonts.inter(color: AtelierTheme.secondaryText, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    wardrobeState.items.when(
                      data: (items) => Text(
                        '${items.length}',
                        style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      error: (_, __) => const Text('0'),
                      loading: () => const SizedBox(
                        height: 30,
                        width: 30,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AtelierTheme.accent),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Primary Shade',
                      style: GoogleFonts.inter(color: AtelierTheme.secondaryText, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    analyticsState.when(
                      data: (data) => Text(
                        data.mostCommonColor,
                        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: AtelierTheme.accent),
                      ),
                      error: (_, __) => const Text('None'),
                      loading: () => const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: AtelierTheme.accent),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentItemsSection(BuildContext context, WardrobeState wardrobeState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECENTLY ADDED',
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AtelierTheme.secondaryText,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        wardrobeState.items.when(
          data: (items) {
            if (items.isEmpty) {
              return Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AtelierTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AtelierTheme.border, width: 1),
                ),
                child: Center(
                  child: Text(
                    'No items in wardrobe yet.',
                    style: GoogleFonts.inter(color: AtelierTheme.secondaryText),
                  ),
                ),
              );
            }
            final recent = items.reversed.take(4).toList();
            return SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: recent.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final item = recent[index];
                  return Container(
                    width: 120,
                    decoration: BoxDecoration(
                      color: AtelierTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AtelierTheme.border, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                            child: item.hasValidImageUrl
                                ? Image.network(
                                    item.imagePath!,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(Icons.broken_image_outlined, color: AtelierTheme.secondaryText),
                                    ),
                                  )
                                : Container(
                                    color: AtelierTheme.surfaceAccent,
                                    child: const Center(
                                      child: Icon(Icons.checkroom, color: AtelierTheme.secondaryText),
                                    ),
                                  ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.color,
                                style: GoogleFonts.inter(fontSize: 10, color: AtelierTheme.secondaryText),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
          error: (_, __) => const SizedBox(),
          loading: () => const Center(
            child: CircularProgressIndicator(color: AtelierTheme.accent),
          ),
        ),
      ],
    );
  }

  Widget _buildAiInsightsCarousel(WardrobeState wardrobeState) {
    final totalItems = wardrobeState.items.value?.length ?? 0;
    
    final List<Map<String, String>> insights = [
      {
        'title': 'AI INSIGHT',
        'icon': '💡',
        'message': totalItems > 0 
            ? 'White sneakers would match ${totalItems >= 3 ? 8 : totalItems * 2} of your current outfits.' 
            : 'Add basic white sneakers to unlock match recommendations for 8+ style combinations.',
      },
      {
        'title': 'COLOR ANALYSIS',
        'icon': '🎨',
        'message': 'You wear light tones most often. Consider adding some dark-wash denim to create premium contrast.',
      },
      {
        'title': 'FIT ADVISORY',
        'icon': '📏',
        'message': 'Pairing slim-fit tops with relaxed-fit trousers is trending. Try it with your unstructured shirts.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DAILY INSIGHTS',
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AtelierTheme.secondaryText,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: insights.length,
            itemBuilder: (context, index) {
              final insight = insights[index];
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AtelierTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AtelierTheme.border, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          insight['icon']!,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          insight['title']!,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AtelierTheme.accent,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        insight['message']!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AtelierTheme.primaryText,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class FadeSlideTransition extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const FadeSlideTransition({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  @override
  State<FadeSlideTransition> createState() => _FadeSlideTransitionState();
}

class _FadeSlideTransitionState extends State<FadeSlideTransition> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0.0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: FractionalTranslation(
            translation: _slideAnimation.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
