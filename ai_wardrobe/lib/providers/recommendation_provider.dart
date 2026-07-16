import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_service.dart';
import '../models/outfit_recommendation.dart';
import 'api_provider.dart';

class RecommendationNotifier extends StateNotifier<AsyncValue<OutfitRecommendation?>> {
  final ApiService _apiService;

  RecommendationNotifier(this._apiService) : super(const AsyncValue.data(null));

  Future<void> getRecommendation(String occasion) async {
    state = const AsyncValue.loading();
    try {
      final result = await _apiService.getRecommendation(occasion);
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final recommendationProvider = StateNotifierProvider<RecommendationNotifier, AsyncValue<OutfitRecommendation?>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return RecommendationNotifier(apiService);
});
