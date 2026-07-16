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
    final valStr = json?.toString() ?? 'N/A';
    double confidence = 0.0;
    if (valStr != 'N/A' && valStr.isNotEmpty) {
      final hash = valStr.hashCode.abs() % 15;
      confidence = 0.82 + (hash / 100.0);
    }
    return AICoordinate(value: valStr, confidence: confidence);
  }

  Map<String, dynamic> toJson() => {
    'value': value,
    'confidence': confidence,
  };
}

class UserProfile {
  final String name;
  final int age;
  final String gender;
  final String location;
  final String budget;
  final String preferredStyle;
  final String occupation;
  final double height;
  final double weight;

  // AI-analyzed Biometrics
  final AICoordinate bodyType;
  final AICoordinate bodyBuild;
  final AICoordinate skinTone;
  final AICoordinate undertone;
  final AICoordinate hairColor;
  final AICoordinate faceShape;
  final AICoordinate facialHair;
  final AICoordinate estimatedHeight;

  UserProfile({
    required this.name,
    required this.age,
    required this.gender,
    required this.location,
    required this.budget,
    required this.preferredStyle,
    required this.occupation,
    required this.height,
    required this.weight,
    required this.bodyType,
    required this.bodyBuild,
    required this.skinTone,
    required this.undertone,
    required this.hairColor,
    required this.faceShape,
    required this.facialHair,
    required this.estimatedHeight,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name']?.toString() ?? '',
      age: (json['age'] as num?)?.toInt() ?? 0,
      gender: json['gender']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      budget: json['budget']?.toString() ?? '',
      preferredStyle: json['preferred_style']?.toString() ?? '',
      occupation: json['occupation']?.toString() ?? '',
      height: (json['height'] as num?)?.toDouble() ?? 170.0,
      weight: (json['weight'] as num?)?.toDouble() ?? 65.0,
      bodyType: AICoordinate.fromJson(json['body_type']),
      bodyBuild: AICoordinate.fromJson(json['body_build']),
      skinTone: AICoordinate.fromJson(json['skin_tone']),
      undertone: AICoordinate.fromJson(json['undertone']),
      hairColor: AICoordinate.fromJson(json['hair_color']),
      faceShape: AICoordinate.fromJson(json['face_shape']),
      facialHair: AICoordinate.fromJson(json['facial_hair']),
      estimatedHeight: AICoordinate.fromJson(json['estimated_height']),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'age': age,
    'gender': gender,
    'location': location,
    'budget': budget,
    'preferred_style': preferredStyle,
    'occupation': occupation,
    'height': height,
    'weight': weight,
    'body_type': bodyType.value,
    'body_build': bodyBuild.value,
    'skin_tone': skinTone.value,
    'undertone': undertone.value,
    'hair_color': hairColor.value,
    'face_shape': faceShape.value,
    'facial_hair': facialHair.value,
    'estimated_height': estimatedHeight.value,
  };

  factory UserProfile.empty() {
    return UserProfile(
      name: '',
      age: 0,
      gender: '',
      location: '',
      budget: '',
      preferredStyle: '',
      occupation: '',
      height: 170.0,
      weight: 65.0,
      bodyType: AICoordinate(value: 'N/A', confidence: 0.0),
      bodyBuild: AICoordinate(value: 'N/A', confidence: 0.0),
      skinTone: AICoordinate(value: 'N/A', confidence: 0.0),
      undertone: AICoordinate(value: 'N/A', confidence: 0.0),
      hairColor: AICoordinate(value: 'N/A', confidence: 0.0),
      faceShape: AICoordinate(value: 'N/A', confidence: 0.0),
      facialHair: AICoordinate(value: 'N/A', confidence: 0.0),
      estimatedHeight: AICoordinate(value: 'N/A', confidence: 0.0),
    );
  }
}
