# Gemini API 설정 가이드

## API 키 발급

1. [Google AI Studio](https://makersuite.google.com/app/apikey)에서 API 키 발급
2. 또는 [Google Cloud Console](https://console.cloud.google.com/)에서 Gemini API 활성화 후 API 키 생성

## API 키 설정 방법

### 방법 1: 환경 변수 사용 (권장)

터미널에서 실행:

```bash
export GEMINI_API_KEY=your_api_key_here
flutter run
```

### 방법 2: 코드에서 직접 설정

`lib/services/ai_service.dart` 파일에서 `_apiKey` 상수를 직접 수정:

```dart
static const String _apiKey = 'your_api_key_here';
```

### 방법 3: 빌드 시 환경 변수 전달

```bash
flutter run --dart-define=GEMINI_API_KEY=your_api_key_here
```

## 보안 주의사항

- ⚠️ API 키를 Git에 커밋하지 마세요
- ⚠️ 프로덕션 환경에서는 안전한 키 관리 시스템 사용을 권장합니다
- ⚠️ `.gitignore`에 API 키가 포함된 파일을 추가하세요
