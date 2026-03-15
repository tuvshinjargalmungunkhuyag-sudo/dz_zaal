import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;

  ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

class ClaudeService {
  static const _endpoint = 'https://api.anthropic.com/v1/messages';

  static const _system = '''Та бол "Говийн Спорт" аппликейшний туслах ажилтан юм.
Даланзадгад хотын спорт заалнуудын захиалга хийхэд тусалдаг.

Манай заалнууд:
- Говийн Аренa (Сагсан бөмбөг) — 15,000₮/цаг, 1-р хороо
- Өмнөговь Фитнес — 10,000₮/цаг, 2-р хороо
- Говийн Теннис Клуб — 20,000₮/цаг, Голомт
- Хурдан Хөл Бөмбөг — 25,000₮/цаг, Стадион
- Говийн Бөхийн Танхим — 12,000₮/цаг, 3-р хороо

Цагийн хуваарь: 08:00–20:00 (1 цагийн слот)
Захиалгын процесс: Заал сонгох → Өдөр сонгох → Цаг сонгох → Баталгаажуулах

Монгол хэлээр товч, хэрэгтэй мэдээллийг өгнө үү.
Говийн амьтад: 🐪 тэмээ, 🦅 ёл шувуу, 🐻 мазаалай — манай бэлэгдэл!''';

  Future<String> sendMessage(List<ChatMessage> history) async {
    try {
      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': AppConfig.claudeApiKey,
              'anthropic-version': '2023-06-01',
            },
            body: jsonEncode({
              'model': AppConfig.claudeModel,
              'max_tokens': 1024,
              'system': _system,
              'messages': history.map((m) => m.toJson()).toList(),
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'] as String;
      } else {
        final err = jsonDecode(response.body);
        return 'Алдаа гарлаа: ${err['error']?['message'] ?? response.statusCode}';
      }
    } catch (e) {
      return 'Холболтын алдаа: $e';
    }
  }
}
