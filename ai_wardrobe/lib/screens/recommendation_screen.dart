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
        child: Column(
          children: [
            const Divider(color: Colors.white10, height: 1),
            // Chat history list
            Expanded(
              child: chatState.history.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 20),
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
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // Subtle neon bar as status indicator rather than noisy avatar
            Container(
              width: 1.5,
              height: 38,
              color: AtelierTheme.accent,
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Text bubble
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.white.withOpacity(0.03) : Colors.white.withOpacity(0.01),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isUser ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.03),
                      width: 0.6,
                    ),
                  ),
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
                    margin: const EdgeInsets.only(top: 8),
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

                // Recommendations Carousel/Cards list
                if (!isUser && msg.recommendations.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildRecommendationsList(msg.recommendations),
                ],
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 32),
          ] else ...[
            const SizedBox(width: 24),
          ]
        ],
      ),
    );
  }

  Widget _buildRecommendationsList(List<OutfitRecommendation> recommendations) {
    return Container(
      height: 390,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: recommendations.length,
        itemBuilder: (context, index) {
          final rec = recommendations[index];
          return _buildOutfitCard(rec, index + 1, recommendations.length);
        },
      ),
    );
  }

  Widget _buildOutfitCard(OutfitRecommendation rec, int optionIndex, int totalOptions) {
    return Container(
      width: 310,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.01),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 0.8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lookbook Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              color: Colors.white.withOpacity(0.02),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "LOOKBOOK 0$optionIndex / 0$totalOptions",
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                      letterSpacing: 2.0,
                    ),
                  ),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AtelierTheme.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
            
            // Asymmetrical Editorial Grid Layout
            Expanded(
              child: Row(
                children: [
                  // Main Item: TOP (takes left side)
                  Expanded(
                    flex: 11,
                    child: _buildEditorialItem('TOP', rec.top),
                  ),
                  Container(width: 0.8, color: Colors.white.withOpacity(0.05)), // Vertical thin divider
                  // Stacking BOTTOM and SHOES (takes right side)
                  Expanded(
                    flex: 9,
                    child: Column(
                      children: [
                        Expanded(child: _buildEditorialItem('BOTTOM', rec.bottom)),
                        Container(height: 0.8, color: Colors.white.withOpacity(0.05)), // Horizontal thin divider
                        Expanded(child: _buildEditorialItem('SHOES', rec.shoes)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Collapsible Insights
            _buildCollapsibleReason(rec.reason),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorialItem(String slotLabel, WardrobeItem? item) {
    final hasItem = item != null;
    return Container(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Item Image or Placeholder
          if (hasItem && item.hasValidImageUrl)
            Image.network(
              item.imagePath!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(Icons.broken_image_outlined, color: Colors.white12, size: 24),
              ),
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    slotLabel == 'TOP'
                        ? Icons.checkroom_outlined
                        : slotLabel == 'BOTTOM'
                            ? Icons.layers_outlined
                            : Icons.auto_awesome_outlined,
                    color: Colors.white.withOpacity(0.04),
                    size: 24,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'NO ITEM',
                    style: GoogleFonts.manrope(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.08),
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            
          // Slot label overlay
          Positioned(
            left: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                slotLabel,
                style: GoogleFonts.outfit(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
          
          // Blur detail tag for item
          if (hasItem)
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    color: Colors.black.withOpacity(0.45),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${item.color} • ${item.fit}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 7.5,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleReason(String reason) {
    return _CollapsibleReasonWidget(reason: reason);
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
              backgroundColor: Colors.white.withOpacity(0.015),
              side: BorderSide(color: Colors.white.withOpacity(0.08), width: 0.6),
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
                color: Colors.white.withOpacity(0.015),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.06), width: 0.8),
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
                          color: Colors.white30,
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
                color: isLoading ? Colors.white.withOpacity(0.02) : Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
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
              color: Colors.white.withOpacity(0.01),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.03), width: 0.6),
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

class _CollapsibleReasonWidget extends StatefulWidget {
  final String reason;
  const _CollapsibleReasonWidget({required this.reason});

  @override
  State<_CollapsibleReasonWidget> createState() => _CollapsibleReasonWidgetState();
}

class _CollapsibleReasonWidgetState extends State<_CollapsibleReasonWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final bulletPoints = widget.reason
        .split('\n')
        .map((e) => e.replaceAll(RegExp(r'^[•\-\*\s]+'), '').trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: Colors.white.withOpacity(0.01),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isExpanded ? "CLOSE EDITORIAL NOTES" : "VIEW EDITORIAL NOTES",
                  style: GoogleFonts.outfit(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: AtelierTheme.accent,
                    letterSpacing: 2.0,
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: AtelierTheme.accent,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.015),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (bulletPoints.isEmpty)
                  Text(
                    widget.reason,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  )
                else
                  ...bulletPoints.map((pt) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 5.0, right: 8.0),
                              child: Icon(Icons.square, size: 3, color: AtelierTheme.accent),
                            ),
                            Expanded(
                              child: Text(
                                pt,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.8),
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
              ],
            ),
          ),
      ],
    );
  }
}
