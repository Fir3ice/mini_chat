import 'package:dio/dio.dart';

class GroqService {
  final Dio _dio = Dio();
  final String _apiKey = '';
  final String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  Future<String> getChatResponse(List<Map<String, String>> history) async {
    try {
      final response = await _dio.post(
        _baseUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {
              "role": "system",
              "content": "Ти — онлайн помічник Llama. Відповідай чітко, по суті. Не вітайся у кожному повідомленні, якщо діалог вже триває. Допомагай користувачу з програмуванням та іншими питаннями."
            },
            ...history
          ],
          "temperature": 0.7,
        },
      );

      if (response.statusCode == 200) {
        return response.data['choices'][0]['message']['content'];
      }
      return "Помилка API: ${response.statusCode}";
    } on DioException catch (e) {
      return "Помилка зв'язку з Groq: ${e.message}";
    }
  }
}