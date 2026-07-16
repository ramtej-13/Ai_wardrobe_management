import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/theme.dart';
import '../models/wardrobe_item.dart';
import '../providers/wardrobe_provider.dart';

class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({super.key});

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen> {
  final _searchController = TextEditingController();

  final List<String> _categories = ['All', 'Shirt', 'Pants', 'Shoes', 'Dress', 'Jacket', 'Accessory'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wardrobeState = ref.watch(wardrobeProvider);
    final filteredItems = ref.watch(filteredItemsProvider);

    return Scaffold(
      backgroundColor: AtelierTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Wardrobe',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              _buildSearchBar(),
              const SizedBox(height: 20),
              _buildCategorySelector(wardrobeState.selectedCategory),
              const SizedBox(height: 20),
              Expanded(
                child: wardrobeState.items.when(
                  data: (items) {
                    if (filteredItems.isEmpty) {
                      return _buildEmptyState();
                    }
                    return GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 120),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 20,
                        childAspectRatio: 0.62,
                      ),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return _buildWardrobeGridCard(item);
                      },
                    );
                  },
                  error: (err, __) => Center(
                    child: Text(
                      'Failed to load closet: $err',
                      style: GoogleFonts.inter(color: AtelierTheme.warning),
                    ),
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AtelierTheme.accent),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AtelierTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AtelierTheme.border, width: 1),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          ref.read(wardrobeProvider.notifier).setSearchQuery(val);
        },
        style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search by color, name, fit...',
          hintStyle: GoogleFonts.inter(color: AtelierTheme.secondaryText, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: AtelierTheme.secondaryText, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCategorySelector(String selectedCategory) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = selectedCategory.toLowerCase() == cat.toLowerCase();
          return GestureDetector(
            onTap: () {
              ref.read(wardrobeProvider.notifier).setSelectedCategory(cat);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : AtelierTheme.surface,
                borderRadius: BorderRadius.circular(19),
                border: Border.all(
                  color: isSelected ? Colors.white : AtelierTheme.border,
                  width: 1,
                ),
              ),
              child: Text(
                cat,
                style: GoogleFonts.manrope(
                  color: isSelected ? Colors.black : Colors.white,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWardrobeGridCard(WardrobeItem item) {
    return GestureDetector(
      onTap: () => _showItemDetailsSheet(item),
      child: Container(
        decoration: BoxDecoration(
          color: AtelierTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AtelierTheme.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
                  color: AtelierTheme.surfaceAccent,
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                  child: item.hasValidImageUrl
                      ? Image.network(
                          item.imagePath!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image_outlined, color: AtelierTheme.secondaryText),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.checkroom, color: AtelierTheme.secondaryText, size: 36),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.color,
                        style: GoogleFonts.inter(fontSize: 11, color: AtelierTheme.secondaryText),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AtelierTheme.surfaceAccent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.fit,
                          style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w600, color: AtelierTheme.accent),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
          const Icon(Icons.inventory_2_outlined, size: 48, color: AtelierTheme.secondaryText),
          const SizedBox(height: 16),
          Text(
            'No matching items found',
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Try adjusting your search criteria.',
            style: GoogleFonts.inter(color: AtelierTheme.secondaryText, fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _showItemDetailsSheet(WardrobeItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(28),
          decoration: const BoxDecoration(
            color: AtelierTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: AtelierTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: AtelierTheme.surfaceAccent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AtelierTheme.border, width: 1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: item.hasValidImageUrl
                          ? Image.network(item.imagePath!, fit: BoxFit.cover)
                          : const Icon(Icons.checkroom, color: AtelierTheme.secondaryText),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Category: ${item.category}',
                          style: GoogleFonts.inter(color: AtelierTheme.secondaryText, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Color: ${item.color}',
                          style: GoogleFonts.inter(color: AtelierTheme.secondaryText, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Fit: ${item.fit}',
                          style: GoogleFonts.inter(color: AtelierTheme.accent, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'DESCRIPTION',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 10),
              Text(
                item.description.isNotEmpty ? item.description : 'No description provided.',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirmed = await _showDeleteConfirmation();
                        if (confirmed == true && mounted) {
                          await ref.read(wardrobeProvider.notifier).deleteItem(item.id);
                          if (mounted) Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.delete_outline, color: AtelierTheme.warning),
                      label: const Text('DELETE'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AtelierTheme.warning,
                        side: const BorderSide(color: AtelierTheme.warning),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.done, color: Colors.black),
                      label: const Text('CLOSE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool?> _showDeleteConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AtelierTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Item?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to remove this clothing piece permanently?', style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('CANCEL', style: GoogleFonts.manrope(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('DELETE', style: GoogleFonts.manrope(color: AtelierTheme.warning, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
