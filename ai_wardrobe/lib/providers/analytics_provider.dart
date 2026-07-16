import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wardrobe_analytics.dart';
import 'api_provider.dart';

final analyticsProvider = FutureProvider<WardrobeAnalytics>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.fetchAnalytics();
});
