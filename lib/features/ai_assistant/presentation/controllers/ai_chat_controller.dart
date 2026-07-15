import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/gemini_service.dart';
import '../../domain/entities/chat_message.dart';

/// Provider for GeminiService
final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

/// AI Chat state model holding message history list and loading flag
class AiChatState {
  final List<ChatMessage> messages;
  final bool isLoading;

  const AiChatState({
    required this.messages,
    required this.isLoading,
  });

  AiChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AiChatController extends StateNotifier<AiChatState> {
  final GeminiService _geminiService;

  AiChatController(this._geminiService)
      : super(
          AiChatState(
            messages: [
              ChatMessage(
                text: 'नमस्ते! म सुरक्शा नेपालको AI आपतकालीन सहायक हुँ। म तपाईंलाई प्राथमिक उपचार वा विपद् सुरक्षा सम्बन्धी जानकारी दिन सक्छु। मलाई केहि सोध्नुहोस्।\n\n(Hello! I am the Suraksha Nepal AI Emergency Assistant. Ask me anything about first aid or disaster safety guidelines.)',
                isUser: false,
                timestamp: DateTime.now(),
              ),
            ],
            isLoading: false,
          ),
        );

  /// Appends user message, toggles loading, triggers query, and appends AI response
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
    );

    try {
      final reply = await _geminiService.queryGemini(text);
      final aiMsg = ChatMessage(
        text: reply,
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, aiMsg],
        isLoading: false,
      );
    } catch (e) {
      final aiErrorMsg = ChatMessage(
        text: 'Sorry, I encountered an issue: $e. Please verify network access and try again.',
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, aiErrorMsg],
        isLoading: false,
      );
    }
  }

  void clearChat() {
    state = AiChatState(
      messages: [
        ChatMessage(
          text: 'नमस्ते! म सुरक्शा नेपालको AI आपतकालीन सहायक हुँ। म तपाईंलाई प्राथमिक उपचार वा विपद् सुरक्षा सम्बन्धी जानकारी दिन सक्छु। मलाई केहि सोध्नुहोस्।\n\n(Hello! I am the Suraksha Nepal AI Emergency Assistant. Ask me anything about first aid or disaster safety guidelines.)',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ],
      isLoading: false,
    );
  }
}

final aiChatControllerProvider = StateNotifierProvider.autoDispose<AiChatController, AiChatState>((ref) {
  final geminiService = ref.watch(geminiServiceProvider);
  return AiChatController(geminiService);
});
