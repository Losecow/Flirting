import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/api_key.dart';

// AI 말투 변환 서비스 (Gemini API 사용)
class AIService {
  AIService();

  // Gemini API 키 (config/api_key.dart에서 가져옴)
  static const String _apiKey = ApiKey.geminiApiKey;

  /// 말투 스타일별 프롬프트 생성
  String _getStylePrompt(String style) {
    switch (style) {
      case '친근한 말투':
        return '친근하고 편안한 말투로 바꿔주세요. 반말을 사용하되 예의를 지키는 느낌으로 작성해주세요.';
      case '존댓말':
        return '정중하고 존중하는 존댓말로 바꿔주세요. "-요", "-습니다" 같은 높임말을 사용해주세요.';
      case '반말':
        return '편안하고 친근한 반말로 바꿔주세요. "-야", "-어" 같은 반말 어미를 사용해주세요.';
      case '귀여운 말투':
        return '귀엽고 사랑스러운 말투로 바꿔주세요. 이모티콘은 사용하지 말고 말투만 바꿔주세요.';
      case '차분한 말투':
        return '차분하고 침착한 말투로 바꿔주세요. 부드럽고 안정적인 느낌으로 작성해주세요.';
      case '밝은 말투':
        return '밝고 긍정적인 말투로 바꿔주세요. 활기차고 에너지 넘치는 느낌으로 작성해주세요.';
      default:
        return '자연스럽고 친근한 말투로 바꿔주세요.';
    }
  }

  /// 말투 변환 (Gemini API 사용)
  Future<String> convertSpeechStyle(String text, String style) async {
    if (text.trim().isEmpty) {
      return text;
    }

    // API 키 확인
    if (_apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      print('⚠️ Gemini API 키가 설정되지 않았습니다.');
      print('   환경 변수 GEMINI_API_KEY를 설정하거나 코드에서 API 키를 설정해주세요.');
      throw Exception('Gemini API 키가 설정되지 않았습니다.');
    }

    try {
      // Gemini 모델 초기화
      // google_generative_ai 패키지에서 사용 가능한 모델 이름 사용
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);

      // 프롬프트 생성
      final prompt =
          '''
다음 텍스트를 ${style}로 바꿔주세요.

원본 텍스트: "$text"

${_getStylePrompt(style)}

변환된 텍스트만 출력해주세요. 설명이나 추가 텍스트 없이 변환된 텍스트만 반환해주세요.
''';

      print('🤖 Gemini API 호출:');
      print('   - 원본 텍스트: $text');
      print('   - 변환 스타일: $style');

      // API 호출
      final response = await model.generateContent([Content.text(prompt)]);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Gemini API가 빈 응답을 반환했습니다.');
      }

      final convertedText = response.text!.trim();
      print('✅ 변환 완료: $convertedText');

      return convertedText;
    } catch (e) {
      print('❌ Gemini API 호출 실패: $e');
      rethrow;
    }
  }
}
