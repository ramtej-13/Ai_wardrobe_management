import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/theme.dart';
import '../models/wardrobe_item.dart';
import '../models/outfit_recommendation.dart';
import '../providers/recommendation_provider.dart';

class RecommendationScreen extends ConsumerStatefulWidget {
  const RecommendationScreen({super.key});

  @override
  ConsumerState<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends ConsumerState<RecommendationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Posh collection category suggestions
  final List<Map<String, String>> _quickSuggestions = [
    {'display': '01 / CASUAL', 'value': 'Casual'},
    {'display': '02 / SOIREE', 'value': 'Party'},
    {'display': '03 / OFFICE', 'value': 'Office'},
    {'display': '04 / WEDDING', 'value': 'Wedding'},
    {'display': '05 / COLLEGE', 'value': 'College'},
    {'display': '06 / SKIP DETAILS', 'value': 'Skip details & recommend outfits'},
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage([String? text]) {
    final msg = text ?? _messageController.text;
    if (msg.trim().isEmpty) return;

    ref.read(recommendationProvider.notifier).sendChatMessage(msg);
    if (text == null) {
      _messageController.clear();
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(recommendationProvider);

    // Auto-scroll on new messages
    ref.listen(recommendationProvider, (previous, next) {
      if (previous?.history.length != next.history.length || next.isLoading) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: AtelierTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'A T E L I E R   S T Y L I S T',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.white,
            letterSpacing: 6.0,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(recommendationProvider.notifier).reset();
            },
            child: Text(
              'RESET',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AtelierTheme.secondaryText,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Soft floating ambient backgrounds glows (Vision Pro style)
            Positioned(
              top: -120,
              right: -100,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AtelierTheme.accent.withOpacity(0.04),
                  boxShadow: [
                    BoxShadow(
                      color: AtelierTheme.accent.withOpacity(0.04),
                      blurRadius: 120,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              left: -120,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD980FF).withOpacity(0.02),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD980FF).withOpacity(0.02),
                      blurRadius: 140,
                      spreadRadius: 50,
                    ),
                  ],
                ),
              ),
            ),

            // Main chat layout column
            Column(
              children: [
                const Divider(color: Colors.white10, height: 1),
                // Chat history list
                Expanded(
                  child: chatState.history.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 20),
                          physics: const BouncingScrollPhysics(),
                          itemCount: chatState.history.length,
                          itemBuilder: (context, index) {
                            final msg = chatState.history[index];
                            return _buildChatBubble(msg);
                          },
                        ),
                ),

                // Loading Indicator
                if (chatState.isLoading) _buildTypingIndicator(),

                // Error display
                if (chatState.error != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AtelierTheme.warning.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AtelierTheme.warning.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AtelierTheme.warning, size: 16),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            chatState.error!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AtelierTheme.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Quick suggestion chips (Posh editorial style)
                _buildQuickSuggestions(chatState.isLoading),

                // Minimalist Input Bar
                _buildInputBar(chatState.isLoading),
                const SizedBox(height: 100), // Avoid bottom navigation shell overlay
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome_outlined, size: 36, color: Colors.white10),
          const SizedBox(height: 16),
          Text(
            'DESIGN YOUR IDENTITY',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white30,
              letterSpacing: 3.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'State your styling parameters below.',
            style: GoogleFonts.inter(fontSize: 12, color: AtelierTheme.secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatBubbleMessage msg) {
    final isUser = msg.sender == 'user';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row with luxury label indicator tags
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isUser
                      ? const Color(0xFFD980FF).withOpacity(0.08)
                      : AtelierTheme.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isUser
                        ? const Color(0xFFD980FF).withOpacity(0.2)
                        : AtelierTheme.accent.withOpacity(0.2),
                    width: 0.6,
                  ),
                ),
                child: Text(
                  isUser ? "CLIENT" : "STYLIST",
                  style: GoogleFonts.outfit(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: isUser ? const Color(0xFFD980FF) : AtelierTheme.accent,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isUser ? "REQUEST" : "ANALYSIS",
                style: GoogleFonts.outfit(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.white24,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Pure text block (no generic box/bubble background!)
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Text(
              msg.text,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: Colors.white.withOpacity(0.9),
                height: 1.5,
              ),
            ),
          ),
          
          // Wardrobe limited warning box
          if (!isUser && msg.wardrobeLimited)
            Container(
              margin: const EdgeInsets.only(top: 8, left: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AtelierTheme.warning.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AtelierTheme.warning.withOpacity(0.15)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Limited Wardrobe Choice Detected. Results might be mismatched or fallback items.",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.orange.shade300,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 3D Overlapping Collage Layout (Replaces grid cards list)
          if (!isUser && msg.recommendations.isNotEmpty) ...[
            const SizedBox(height: 20),
            OutfitCollageWidget(recommendations: msg.recommendations),
          ],
          
          const SizedBox(height: 16),
          const Divider(color: Colors.white10, height: 1, thickness: 0.5),
        ],
      ),
    );
  }

  Widget _buildQuickSuggestions(bool isLoading) {
    return Container(
      height: 34,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _quickSuggestions.length,
        itemBuilder: (context, index) {
          final display = _quickSuggestions[index]['display']!;
          final value = _quickSuggestions[index]['value']!;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              backgroundColor: Colors.white.withOpacity(0.01),
              side: BorderSide(color: Colors.white.withOpacity(0.06), width: 0.6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              label: Text(
                display,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                  letterSpacing: 1.0,
                ),
              ),
              onPressed: isLoading ? null : () => _sendMessage(value),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar(bool isLoading) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.01),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.05), width: 0.8),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 18),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: !isLoading,
                      style: GoogleFonts.inter(fontSize: 13.5, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'STATE YOUR REQUISITE...',
                        hintStyle: GoogleFonts.outfit(
                          color: Colors.white24,
                          fontSize: 11,
                          letterSpacing: 1.5,
                        ),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: isLoading ? null : () => _sendMessage(),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isLoading ? Colors.white.withOpacity(0.01) : Colors.white.withOpacity(0.95),
                shape: BoxShape.circle,
                boxShadow: [
                  if (!isLoading)
                    BoxShadow(
                      color: AtelierTheme.accent.withOpacity(0.2),
                      blurRadius: 8,
                    )
                ],
              ),
              child: Icon(
                Icons.arrow_upward,
                color: isLoading ? Colors.white24 : Colors.black,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 1.5,
            height: 38,
            color: AtelierTheme.accent.withOpacity(0.3),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.008),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.025), width: 0.6),
            ),
            child: Row(
              children: [
                Text(
                  'CURATING COMBINATIONS',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white30,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(width: 10),
                const SizedBox(
                  width: 8,
                  height: 8,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: AtelierTheme.accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 3D Overlapping Editorial Collage Widget
class OutfitCollageWidget extends StatefulWidget {
  final List<OutfitRecommendation> recommendations;
  const OutfitCollageWidget({super.key, required this.recommendations});

  @override
  State<OutfitCollageWidget> createState() => _OutfitCollageWidgetState();
}

class _OutfitCollageWidgetState extends State<OutfitCollageWidget> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.recommendations.isEmpty) return const SizedBox.shrink();
    final rec = widget.recommendations[_selectedIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab selector row
        Row(
          children: List.generate(widget.recommendations.length, (index) {
            final isSelected = index == _selectedIndex;
            return GestureDetector(
              onTap: () => setState(() => _selectedIndex = index),
              child: Container(
                margin: const EdgeInsets.only(right: 12, bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AtelierTheme.accent.withOpacity(0.08) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AtelierTheme.accent.withOpacity(0.3) : Colors.white.withOpacity(0.06),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  "EDITION 0${index + 1}",
                  style: GoogleFonts.outfit(
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AtelierTheme.accent : Colors.white60,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            );
          }),
        ),

        // 3D overlapping collage stack
        Container(
          height: 380,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.005),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.02), width: 0.8),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Bottom Card (stacked first so it stays behind)
              Positioned(
                right: 24,
                top: 40,
                child: Transform.rotate(
                  angle: 0.04, // 2 degrees
                  child: _buildCollageCard('BOTTOM', rec.bottom, 140, 210),
                ),
              ),
              // Top Card (stacked on top, overlapping Bottom)
              Positioned(
                left: 24,
                top: 20,
                child: Transform.rotate(
                  angle: -0.05, // -3 degrees
                  child: _buildCollageCard('TOP', rec.top, 160, 240),
                ),
              ),
              // Shoes Card (stacked on top in the middle foreground)
              Positioned(
                left: 110,
                top: 200,
                child: Transform.rotate(
                  angle: -0.02,
                  child: _buildCollageCard('SHOES', rec.shoes, 110, 110),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Styling notes
        _buildEditorialInsights(rec.reason),
      ],
    );
  }

  Widget _buildCollageCard(String label, WardrobeItem? item, double width, double height) {
    final hasItem = item != null;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AtelierTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasItem && item.hasValidImageUrl)
              Image.network(item.imagePath!, fit: BoxFit.cover)
            else
              Center(
                child: Icon(
                  label == 'TOP' ? Icons.checkroom : label == 'BOTTOM' ? Icons.layers : Icons.auto_awesome,
                  color: Colors.white10,
                  size: 24,
                ),
              ),
            // Minimal Glass label
            if (hasItem)
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      color: Colors.black.withOpacity(0.5),
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // Small Category Overlay
            Positioned(
              left: 10,
              top: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 7,
                    fontWeight: FontWeight.w600,
                    color: Colors.white60,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorialInsights(String reason) {
    final bulletPoints = reason
        .split('\n')
        .map((e) => e.replaceAll(RegExp(r'^[•\-\*\s]+'), '').trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.005),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.02), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "EDITORIAL INSIGHTS",
            style: GoogleFonts.outfit(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: AtelierTheme.accent,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 12),
          if (bulletPoints.isEmpty)
            Text(
              reason,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.white70,
                height: 1.6,
              ),
            )
          else
            ...bulletPoints.map((pt) => Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 6.0, right: 8.0),
                        child: Icon(Icons.circle, size: 3, color: AtelierTheme.accent),
                      ),
                      Expanded(
                        child: Text(
                          pt,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.white70,
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
}
