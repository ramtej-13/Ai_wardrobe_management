class WardrobeItem {
  final String id;
  final String name;
  final String category;
  final String color;
  final String description;
  final String dateAdded;
  final String fit;
  final String? imagePath;

  WardrobeItem({
    required this.id,
    required this.name,
    required this.category,
    required this.color,
    required this.description,
    required this.dateAdded,
    required this.fit,
    this.imagePath,
  });

  factory WardrobeItem.fromJson(Map<String, dynamic> json) {
    return WardrobeItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      color: json['color']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      dateAdded: json['date_added']?.toString() ?? '',
      fit: json['fit']?.toString() ?? 'Regular',
      imagePath: json['image_path']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'color': color,
    'description': description,
    'date_added': dateAdded,
    'fit': fit,
    'image_path': imagePath,
  };

  bool get hasValidImageUrl => imagePath != null && (imagePath!.startsWith('http://') || imagePath!.startsWith('https://'));
}

class AIClothingAnalysis {
  final AICoordinate category;
  final AICoordinate color;
  final AICoordinate description;
  final AICoordinate fit;
  final String imagePath;

  AIClothingAnalysis({
    required this.category,
    required this.color,
    required this.description,
    required this.fit,
    required this.imagePath,
  });

  factory AIClothingAnalysis.fromJson(Map<String, dynamic> json) {
    return AIClothingAnalysis(
      category: AICoordinate.fromJson(json['category']),
      color: AICoordinate.fromJson(json['color']),
      description: AICoordinate.fromJson(json['description']),
      fit: AICoordinate.fromJson(json['fit']),
      imagePath: json['image_path']?.toString() ?? '',
    );
  }
}

class AICoordinate {
  final String value;
  final double confidence;

  AICoordinate({required this.value, required this.confidence});

  factory AICoordinate.fromJson(dynamic json) {
    if (json is Map) {
      return AICoordinate(
        value: json['value']?.toString() ?? 'N/A',
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      );
    }
    return AICoordinate(value: json?.toString() ?? 'N/A', confidence: 0.0);
  }
}
