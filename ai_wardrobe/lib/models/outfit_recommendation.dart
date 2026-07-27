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

class ChatResponse {
  final String chatResponse;
  final List<OutfitRecommendation> recommendations;
  final Map<String, dynamic> extractedDetails;
  final bool wardrobeLimited;

  ChatResponse({
    required this.chatResponse,
    required this.recommendations,
    required this.extractedDetails,
    required this.wardrobeLimited,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    final recList = json['recommendations'] as List?;
    final List<OutfitRecommendation> recs = recList != null
        ? recList.map((e) => OutfitRecommendation.fromJson(e)).toList()
        : [];
    final Map<String, dynamic> details = json['extracted_details'] is Map
        ? Map<String, dynamic>.from(json['extracted_details'])
        : {'occasion': null, 'location': null, 'time': null};
    return ChatResponse(
      chatResponse: json['chat_response']?.toString() ?? '',
      recommendations: recs,
      extractedDetails: details,
      wardrobeLimited: json['wardrobe_limited'] == true,
    );
  }
}
