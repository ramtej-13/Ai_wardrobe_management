import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_service.dart';
import '../models/wardrobe_item.dart';
import 'api_provider.dart';

class WardrobeState {
  final AsyncValue<List<WardrobeItem>> items;
  final String searchQuery;
  final String selectedCategory;
  final bool isAnalyzingClothing;
  final String? analysisError;

  WardrobeState({
    required this.items,
    this.searchQuery = '',
    this.selectedCategory = 'All',
    this.isAnalyzingClothing = false,
    this.analysisError,
  });

  WardrobeState copyWith({
    AsyncValue<List<WardrobeItem>>? items,
    String? searchQuery,
    String? selectedCategory,
    bool? isAnalyzingClothing,
    String? analysisError,
  }) {
    return WardrobeState(
      items: items ?? this.items,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isAnalyzingClothing: isAnalyzingClothing ?? this.isAnalyzingClothing,
      analysisError: analysisError ?? this.analysisError,
    );
  }
}

class WardrobeNotifier extends StateNotifier<WardrobeState> {
  final ApiService _apiService;

  WardrobeNotifier(this._apiService)
      : super(WardrobeState(items: const AsyncValue.loading())) {
    loadItems();
  }

  Future<void> loadItems() async {
    state = state.copyWith(items: const AsyncValue.loading());
    try {
      final list = await _apiService.fetchItems();
      state = state.copyWith(items: AsyncValue.data(list));
    } catch (e, st) {
      state = state.copyWith(items: AsyncValue.error(e, st));
    }
  }

  Future<bool> addItem(WardrobeItem item) async {
    try {
      final newItem = await _apiService.addItem(item);
      state.items.whenData((currentList) {
        state = state.copyWith(
          items: AsyncValue.data([...currentList, newItem]),
        );
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> editItem(String itemId, WardrobeItem item) async {
    try {
      final updated = await _apiService.editItem(itemId, item);
      state.items.whenData((currentList) {
        state = state.copyWith(
          items: AsyncValue.data(
            currentList.map((x) => x.id == itemId ? updated : x).toList(),
          ),
        );
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteItem(String itemId) async {
    try {
      await _apiService.deleteItem(itemId);
      state.items.whenData((currentList) {
        state = state.copyWith(
          items: AsyncValue.data(
            currentList.where((x) => x.id != itemId).toList(),
          ),
        );
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<AIClothingAnalysis?> scanClothing(XFile imageFile) async {
    state = state.copyWith(isAnalyzingClothing: true, analysisError: null);
    try {
      final analysis = await _apiService.analyzeClothing(imageFile);
      state = state.copyWith(isAnalyzingClothing: false);
      return analysis;
    } catch (e) {
      state = state.copyWith(
        isAnalyzingClothing: false,
        analysisError: e.toString(),
      );
      return null;
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSelectedCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }
}

// Exposed Providers
final wardrobeProvider = StateNotifierProvider<WardrobeNotifier, WardrobeState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return WardrobeNotifier(apiService);
});

final filteredItemsProvider = Provider<List<WardrobeItem>>((ref) {
  final wardrobeState = ref.watch(wardrobeProvider);
  
  return wardrobeState.items.maybeWhen(
    data: (items) {
      return items.where((item) {
        final matchesSearch = item.name.toLowerCase().contains(wardrobeState.searchQuery.toLowerCase()) ||
            item.description.toLowerCase().contains(wardrobeState.searchQuery.toLowerCase()) ||
            item.color.toLowerCase().contains(wardrobeState.searchQuery.toLowerCase());
        
        final matchesCategory = wardrobeState.selectedCategory == 'All' ||
            item.category.toLowerCase() == wardrobeState.selectedCategory.toLowerCase();

        return matchesSearch && matchesCategory;
      }).toList();
    },
    orElse: () => [],
  );
});
