import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../config/api_keys.dart';

class AIService {
  static const String _apiKey = ApiKeys.geminiApiKey;

  static GenerativeModel? _model;

  static GenerativeModel get model {
    _model ??= GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
    return _model!;
  }

  /// 웹페이지 내용을 가져와서 3줄 요약 생성
  static Future<String?> summarizeUrl(String url) async {
    try {
      // 1. 웹페이지 내용 가져오기
      final content = await _fetchWebContent(url);
      if (content == null || content.isEmpty) {
        return null;
      }

      // 2. Gemini API로 요약 요청
      final prompt = '''
다음 웹페이지 내용을 한국어로 3줄로 요약해주세요.
각 줄은 "• "로 시작하고, 핵심 내용만 간결하게 작성해주세요.

내용:
$content
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final summary = response.text;

      return summary;
    } catch (e) {
      print('AI 요약 오류: $e');
      return null;
    }
  }

  /// 웹페이지에서 텍스트 내용 추출
  static Future<String?> _fetchWebContent(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (compatible; ZoopBot/1.0)',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return null;
      }

      final document = html_parser.parse(response.body);

      // 스크립트, 스타일 태그 제거
      document.querySelectorAll('script, style, nav, header, footer, aside').forEach((e) => e.remove());

      // 본문 텍스트 추출
      final body = document.body;
      if (body == null) return null;

      String text = body.text
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      // 텍스트가 너무 길면 자르기 (토큰 제한)
      if (text.length > 5000) {
        text = text.substring(0, 5000);
      }

      return text;
    } catch (e) {
      print('웹페이지 가져오기 오류: $e');
      return null;
    }
  }
}
