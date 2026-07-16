class WardrobeAnalytics {
  final int totalItems;
  final Map<String, int> categoryCounts;
  final String mostCommonColor;

  WardrobeAnalytics({
    required this.totalItems,
    required this.categoryCounts,
    required this.mostCommonColor,
  });

  factory WardrobeAnalytics.fromJson(Map<String, dynamic> json) {
    // Safely parse category counts map
    final Map<String, int> counts = {};
    if (json['category_counts'] is Map) {
      (json['category_counts'] as Map).forEach((key, value) {
        counts[key.toString()] = (value as num?)?.toInt() ?? 0;
      });
    }

    return WardrobeAnalytics(
      totalItems: (json['total_items'] as num?)?.toInt() ?? 0,
      categoryCounts: counts,
      mostCommonColor: json['most_common_color']?.toString() ?? 'None',
    );
  }
}
