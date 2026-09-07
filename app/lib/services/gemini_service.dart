import 'dart:convert';
import 'package:http/http.dart' as http;

/// Thin wrapper around the Gemini REST API.
///
/// Used by both the floating AI assistant (general Q&A) and the
/// AI driving assistance feature. Keeping the HTTP layer here means
/// neither feature imports `http` directly, and swapping model
/// versions later only touches this one file.
///
/// API key is passed in via --dart-define=GEMINI_API_KEY=... at
/// run/build time so it never lives in source code.
class GeminiService {
  GeminiService({String? apiKey})
      : _apiKey = apiKey ??
            const String.fromEnvironment(
              'GEMINI_API_KEY',
              defaultValue: '',
            );

  final String _apiKey;

  static const _model = 'gemini-2.0-flash';
  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models'
      '/$_model:generateContent';

  /// System prompt that gives Gemini context about Sense&Safe,
  /// LD types, and haptic guidance — so it answers as a knowledgeable
  /// in-app assistant rather than a generic chatbot.
  static const _systemPrompt = '''
You are the AI assistant for Sense&Safe: LD Haptic Drive Assistant,
a navigation app designed specifically for people with Learning
Disabilities (LD) including Dyslexia, ADHD, Dyscalculia, and
Spatial Dyspraxia.

Your role is to:
1. Answer questions about the Sense&Safe app and its features
   (haptic wristbands, BLE connection, route selection, HAPU
   personalization, post-trip surveys, LD Score, etc.)
2. Explain LD types clearly and compassionately — what they are,
   how they affect driving, and how Sense&Safe helps.
3. Help users understand their haptic settings (vibration intensity,
   lead warning time, pulse rhythm, confirm style).
4. Give simple, short answers — users with LD benefit from clear,
   concise language without jargon.

Keep responses under 3 sentences unless the user asks for detail.
Use plain language. Never use the words "straightforward" or "honestly".
If a question is unrelated to driving, navigation, LD, or the app,
politely redirect to those topics.
''';

  /// Send a single-turn message and return the response text.
  /// Returns null if the API key is missing or the call fails.
  Future<String?> ask(String userMessage,
      {List<Map<String, dynamic>> history = const []}) async {
    if (_apiKey.isEmpty) {
      return 'API key not configured. Run with '
          '--dart-define=GEMINI_API_KEY=your_key';
    }

    // Build conversation contents: system prompt first, then history,
    // then the new user message.
    final contents = <Map<String, dynamic>>[
      {
        'role': 'user',
        'parts': [{'text': _systemPrompt}],
      },
      {
        'role': 'model',
        'parts': [
          {
            'text': 'Understood. I am the Sense&Safe assistant, '
                'ready to help with LD, haptic guidance, and the app.'
          }
        ],
      },
      ...history,
      {
        'role': 'user',
        'parts': [{'text': userMessage}],
      },
    ];

    try {
      final response = await http.post(
        Uri.parse('$_endpoint?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': contents,
          'generationConfig': {
            'temperature': 0.4,
            'maxOutputTokens': 300,
          },
        }),
      );

      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final text = json['candidates']?[0]?['content']?['parts']?[0]?['text']
          as String?;
      return text?.trim();
    } catch (_) {
      return null;
    }
  }
}