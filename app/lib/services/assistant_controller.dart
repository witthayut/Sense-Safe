import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'gemini_service.dart';

enum MessageRole { user, assistant }

class ChatMessage {
  const ChatMessage({required this.role, required this.text});
  final MessageRole role;
  final String text;

  /// Converts to Gemini REST API content format for history.
  Map<String, dynamic> toGeminiContent() => {
        'role': role == MessageRole.user ? 'user' : 'model',
        'parts': [
          {'text': text}
        ],
      };
}

class AssistantState {
  const AssistantState({
    this.messages = const [],
    this.isLoading = false,
    this.isOpen = false,
  });

  final List<ChatMessage> messages;
  final bool isLoading;

  /// Whether the floating chat popup is visible.
  final bool isOpen;

  AssistantState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isOpen,
  }) =>
      AssistantState(
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
        isOpen: isOpen ?? this.isOpen,
      );
}

class AssistantController extends Notifier<AssistantState> {
  late final GeminiService _gemini;

  @override
  AssistantState build() {
    _gemini = GeminiService();
    return const AssistantState();
  }

  void toggleOpen() {
    state = state.copyWith(isOpen: !state.isOpen);
  }

  void close() {
    state = state.copyWith(isOpen: false);
  }

  void clearHistory() {
    state = state.copyWith(messages: []);
  }

  Future<void> send(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message immediately so UI feels responsive.
    final userMsg = ChatMessage(role: MessageRole.user, text: text.trim());
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
    );

    // Build history from existing messages (excluding the one just added,
    // since we pass it separately in GeminiService.ask).
    final history = state.messages
        .take(state.messages.length - 1)
        .map((m) => m.toGeminiContent())
        .toList();

    final reply = await _gemini.ask(text.trim(), history: history);

    final assistantMsg = ChatMessage(
      role: MessageRole.assistant,
      text: reply ?? 'Sorry, I couldn\'t get a response. Please try again.',
    );

    state = state.copyWith(
      messages: [...state.messages, assistantMsg],
      isLoading: false,
    );
  }
}

final assistantControllerProvider =
    NotifierProvider<AssistantController, AssistantState>(
  AssistantController.new,
);