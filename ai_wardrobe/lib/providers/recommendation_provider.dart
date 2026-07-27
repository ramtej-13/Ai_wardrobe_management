import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_service.dart';
import '../models/outfit_recommendation.dart';
import 'api_provider.dart';

class ChatBubbleMessage {
  final String sender; // 'user' or 'ai'
  final String text;
  final List<OutfitRecommendation> recommendations;
  final bool wardrobeLimited;
  final DateTime timestamp;

  ChatBubbleMessage({
    required this.sender,
    required this.text,
    required this.recommendations,
    required this.wardrobeLimited,
    required this.timestamp,
  });

  Map<String, String> toApiMap() {
    return {
      'role': sender == 'user' ? 'user' : 'model',
      'text': text,
    };
  }
}

class ChatState {
  final List<ChatBubbleMessage> history;
  final bool isLoading;
  final String? error;

  ChatState({
    required this.history,
    required this.isLoading,
    this.error,
  });

  ChatState copyWith({
    List<ChatBubbleMessage>? history,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class RecommendationNotifier extends StateNotifier<ChatState> {
  final ApiService _apiService;

  RecommendationNotifier(this._apiService)
      : super(ChatState(
          history: [
            ChatBubbleMessage(
              sender: 'ai',
              text: "Hello! I am your AI Fashion Stylist. Let's design your perfect look! What occasion are you dressing up for?",
              recommendations: [],
              wardrobeLimited: false,
              timestamp: DateTime.now(),
            )
          ],
          isLoading: false,
        ));

  Future<void> sendChatMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatBubbleMessage(
      sender: 'user',
      text: text,
      recommendations: [],
      wardrobeLimited: false,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      history: [...state.history, userMsg],
      isLoading: true,
      error: null,
    );

    try {
      // API expects all previous messages except the current user prompt in history
      final apiHistory = state.history
          .sublist(0, state.history.length - 1)
          .map((msg) => msg.toApiMap())
          .toList();

      final response = await _apiService.chatRecommend(apiHistory, text);

      final aiMsg = ChatBubbleMessage(
        sender: 'ai',
        text: response.chatResponse,
        recommendations: response.recommendations,
        wardrobeLimited: response.wardrobeLimited,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        history: [...state.history, aiMsg],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('ApiServiceException:', '').trim(),
      );
    }
  }

  void reset() {
    state = ChatState(
      history: [
        ChatBubbleMessage(
          sender: 'ai',
          text: "Hello! I am your AI Fashion Stylist. Let's design your perfect look! What occasion are you dressing up for?",
          recommendations: [],
          wardrobeLimited: false,
          timestamp: DateTime.now(),
        )
      ],
      isLoading: false,
    );
  }
}

final recommendationProvider = StateNotifierProvider<RecommendationNotifier, ChatState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return RecommendationNotifier(apiService);
});
