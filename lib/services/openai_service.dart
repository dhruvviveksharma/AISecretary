import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
class OpenAIService {
  final _baseUrl = "https://api.openai.com/v1/chat/completions";
  final String? _apiKey;

  OpenAIService() : _apiKey = dotenv.env['OPENAI_API_KEY'] {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception("OpenAI API key not found in environment variables.");
    }
  }

  Map<String, String> get _headers => {
    "Content-Type": "application/json",
    "Authorization": "Bearer $_apiKey",
  };

  Future<String> sendMessage(String prompt, {String? context}) async {
    try {
      List<Map<String, String>> messages = [];
      
      if (context != null && context.isNotEmpty) {
        messages.add({"role": "system", "content": context});
      }
      
      messages.add({"role": "user", "content": prompt});

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: jsonEncode({
          "model": "gpt-4o-mini",
          "messages": messages, // Fixed: was "input"
          "temperature": 0.7,
          "max_tokens": 1000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data["choices"][0]["message"]["content"];
        return content.trim();
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData["error"]["message"] ?? "Unknown error";
        throw Exception("OpenAI API error: ${response.statusCode} - $errorMessage");
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw Exception("Network error: ${e.message}");
      }
      rethrow;
    }
  }
}