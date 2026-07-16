import 'wardrobe_item.dart';

class OutfitRecommendation {
  final WardrobeItem? top;
  final WardrobeItem? bottom;
  final WardrobeItem? shoes;
  final String reason;

  OutfitRecommendation({
    this.top,
    this.bottom,
    this.shoes,
    required this.reason,
  });

  factory OutfitRecommendation.fromJson(Map<String, dynamic> json) {
    return OutfitRecommendation(
      top: json['top'] != null ? WardrobeItem.fromJson(json['top']) : null,
      bottom: json['bottom'] != null ? WardrobeItem.fromJson(json['bottom']) : null,
      shoes: json['shoes'] != null ? WardrobeItem.fromJson(json['shoes']) : null,
      reason: json['reason']?.toString() ?? 'No recommendation styling details provided.',
    );
  }
}
