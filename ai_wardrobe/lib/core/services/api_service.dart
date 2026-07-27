import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/config.dart';
import '../../models/user.dart';
import '../../models/wardrobe_item.dart';
import '../../models/outfit_recommendation.dart';
import '../../models/wardrobe_analytics.dart';

class ApiServiceException implements Exception {
  final String message;
  final int? statusCode;
  ApiServiceException(this.message, {this.statusCode});
  @override
  String toString() => 'ApiServiceException: $message (Status: $statusCode)';
}

class ApiService {
  final http.Client _client = http.Client();

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email') ?? '';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-User-Email': email,
    };
  }

  // --- USER PROFILE ENDPOINTS ---

  Future<UserProfile?> fetchProfile() async {
    final url = Uri.parse('${AppConfig.baseUrl}/user');
    try {
      final headers = await _getHeaders();
      final response = await _client.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserProfile.fromJson(data);
      } else if (response.statusCode == 404 || response.statusCode == 400) {
        // No profile exists yet
        return null;
      } else {
        throw ApiServiceException('Failed to fetch user profile', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiServiceException) rethrow;
      throw ApiServiceException('Network error while loading profile: ${e.toString()}');
    }
  }

  Future<UserProfile> saveProfile(UserProfile profile) async {
    final url = Uri.parse('${AppConfig.baseUrl}/user');
    try {
      final headers = await _getHeaders();
      final response = await _client.post(
        url,
        headers: headers,
        body: jsonEncode(profile.toJson()),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return UserProfile.fromJson(data['user'] ?? data);
      } else {
        throw ApiServiceException('Failed to save user profile', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiServiceException) rethrow;
      throw ApiServiceException('Network error while saving profile: ${e.toString()}');
    }
  }

  Future<UserProfile> analyzeProfilePhotos({
    required XFile frontPhoto,
    required XFile sidePhoto,
    required XFile facePhoto,
  }) async {
    final url = Uri.parse('${AppConfig.baseUrl}/profile/analyze');
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email') ?? '';
      final request = http.MultipartRequest('POST', url);
      request.headers['X-User-Email'] = email;
      
      request.files.add(http.MultipartFile.fromBytes(
        'front_image',
        await frontPhoto.readAsBytes(),
        filename: _sanitizeFilename(frontPhoto.name),
      ));
      request.files.add(http.MultipartFile.fromBytes(
        'side_image',
        await sidePhoto.readAsBytes(),
        filename: _sanitizeFilename(sidePhoto.name),
      ));
      request.files.add(http.MultipartFile.fromBytes(
        'face_image',
        await facePhoto.readAsBytes(),
        filename: _sanitizeFilename(facePhoto.name),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserProfile.fromJson(data);
      } else {
        final errBody = jsonDecode(response.body);
        throw ApiServiceException(errBody['detail']?.toString() ?? 'Profile photo scan failed', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiServiceException) rethrow;
      throw ApiServiceException('Network error while scanning profile: ${e.toString()}');
    }
  }

  // --- WARDROBE ITEMS ENDPOINTS ---

  Future<List<WardrobeItem>> fetchItems() async {
    final url = Uri.parse('${AppConfig.baseUrl}/items');
    try {
      final headers = await _getHeaders();
      final response = await _client.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List itemsJson = data['items'] ?? [];
        return itemsJson.map((x) => WardrobeItem.fromJson(x)).toList();
      } else {
        throw ApiServiceException('Failed to fetch wardrobe items', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiServiceException) rethrow;
      throw ApiServiceException('Network error while loading items: ${e.toString()}');
    }
  }

  Future<WardrobeItem> addItem(WardrobeItem item) async {
    final url = Uri.parse('${AppConfig.baseUrl}/items');
    try {
      // Remove id when adding because backend generates the id (e.g. C001)
      final body = item.toJson()..remove('id');
      final headers = await _getHeaders();
      final response = await _client.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return WardrobeItem.fromJson(data['item']);
      } else {
        throw ApiServiceException('Failed to add clothing item', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiServiceException) rethrow;
      throw ApiServiceException('Network error while adding clothing: ${e.toString()}');
    }
  }

  Future<WardrobeItem> editItem(String itemId, WardrobeItem item) async {
    final url = Uri.parse('${AppConfig.baseUrl}/items/$itemId');
    try {
      final body = item.toJson()..remove('id');
      final headers = await _getHeaders();
      final response = await _client.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WardrobeItem.fromJson(data['item']);
      } else {
        throw ApiServiceException('Failed to edit clothing item', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiServiceException) rethrow;
      throw ApiServiceException('Network error while editing clothing: ${e.toString()}');
    }
  }

  Future<void> deleteItem(String itemId) async {
    final url = Uri.parse('${AppConfig.baseUrl}/items/$itemId');
    try {
      final headers = await _getHeaders();
      final response = await _client.delete(url, headers: headers);
      if (response.statusCode != 200) {
        throw ApiServiceException('Failed to delete clothing item', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiServiceException) rethrow;
      throw ApiServiceException('Network error while deleting clothing: ${e.toString()}');
    }
  }

  // --- CLOTHING ANALYSIS ---

  Future<AIClothingAnalysis> analyzeClothing(XFile imageFile) async {
    final url = Uri.parse('${AppConfig.baseUrl}/items/analyze');
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email') ?? '';
      final request = http.MultipartRequest('POST', url);
      request.headers['X-User-Email'] = email;
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        await imageFile.readAsBytes(),
        filename: _sanitizeFilename(imageFile.name),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AIClothingAnalysis.fromJson(data);
      } else {
        final errBody = jsonDecode(response.body);
        throw ApiServiceException(errBody['detail']?.toString() ?? 'Clothing analysis failed', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiServiceException) rethrow;
      throw ApiServiceException('Network error while analyzing clothing: ${e.toString()}');
    }
  }

  // --- OUTFIT RECOMMENDATION ENGINE ---

  Future<OutfitRecommendation> getRecommendation(String occasion) async {
    final url = Uri.parse('${AppConfig.baseUrl}/recommend');
    try {
      final headers = await _getHeaders();
      final response = await _client.post(
        url,
        headers: headers,
        body: jsonEncode({'occasion': occasion}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return OutfitRecommendation.fromJson(data);
      } else {
        final errBody = jsonDecode(response.body);
        throw ApiServiceException(errBody['detail']?.toString() ?? 'Recommendation failed', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiServiceException) rethrow;
      throw ApiServiceException('Network error during recommendation request: ${e.toString()}');
    }
  }

  Future<ChatResponse> chatRecommend(List<Map<String, String>> history, String message) async {
    final url = Uri.parse('${AppConfig.baseUrl}/recommend/chat');
    try {
      final headers = await _getHeaders();
      final response = await _client.post(
        url,
        headers: headers,
        body: jsonEncode({
          'history': history,
          'message': message,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChatResponse.fromJson(data);
      } else {
        final errBody = jsonDecode(response.body);
        throw ApiServiceException(errBody['detail']?.toString() ?? 'Chat recommendation failed', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiServiceException) rethrow;
      throw ApiServiceException('Network error during chat recommendation: ${e.toString()}');
    }
  }

  // --- ANALYTICS ---

  Future<WardrobeAnalytics> fetchAnalytics() async {
    final url = Uri.parse('${AppConfig.baseUrl}/wardrobe/analytics');
    try {
      final headers = await _getHeaders();
      final response = await _client.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WardrobeAnalytics.fromJson(data);
      } else {
        throw ApiServiceException('Failed to load wardrobe metrics', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiServiceException) rethrow;
      throw ApiServiceException('Network error while loading analytics: ${e.toString()}');
    }
  }

  String _sanitizeFilename(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp')) {
      return filename;
    }
    return 'image.jpg';
  }
}
