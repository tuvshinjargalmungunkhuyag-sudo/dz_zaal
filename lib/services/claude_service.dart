import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class ChatMessage {
  final String role;
  final String content;

  ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

class ClaudeService {
  Future<String> sendMessage(List<ChatMessage> history) async {
    try {
      final response = await http
          .post(
            Uri.parse(AppConfig.chatEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'messages': history.map((m) => m.toJson()).toList(),
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'] as String;
      } else {
        final err = jsonDecode(response.body);
        return 'Алдаа гарлаа: ${err['error'] ?? response.statusCode}';
      }
    } catch (e) {
      return 'Холболтын алдаа: $e';
    }
  }
}
