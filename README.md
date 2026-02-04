# 💘 Fluting (플루팅)

**Fluting**은 AI와 스마일 감지 기술을 결합한 새로운 감각의 소셜/데이팅 애플리케이션입니다.
사용자의 미소를 인식하고, AI를 활용하여 더욱 즐거운 매칭 경험을 제공합니다.

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase)
![Gemini](https://img.shields.io/badge/Google%20Gemini-8E75B2?style=for-the-badge&logo=googlegemini&logoColor=white)

---

## ✨ 주요 기능 (Key Features)

| 기능 | 설명 |
| --- | --- |
| **😊 스마일 디텍션** | Google ML Kit를 활용하여 사용자의 미소를 감지하고 인증합니다. |
| **🤖 AI 매칭/챗** | Google Gemini AI를 도입하여 스마트한 대화 보조 및 매칭 추천을 제공합니다. |
| **💬 실시간 채팅** | Firebase Firestore 기반의 빠르고 안정적인 실시간 메시징 시스템입니다. |
| **📍 위치 기반** | 사용자 위치를 기반으로 주변의 친구나 매칭 상대를 탐색합니다. |
| **🏫 학교 인증** | 신뢰할 수 있는 커뮤니티를 위해 학교 및 전공 정보를 기반으로 프로필을 생성합니다. |
| **❤️ 좋아요 & 매칭** | 마음에 드는 상대에게 호감을 표시하고 매칭될 수 있습니다. |

<br/>

## 📱 스크린샷 (Screenshots)

| 로그인 / 인증 | 메인 홈 | 스마일 감지 | 채팅 화면 |
| :---: | :---: | :---: | :---: |
| <img src="" alt="Login" width="200" /> | <img src="" alt="Home" width="200" /> | <img src="" alt="Smile" width="200" /> | <img src="" alt="Chat" width="200" /> |
> *스크린샷 이미지를 `assets/screenshots` 폴더에 추가하고 경로를 수정해주세요.*

<br/>

## 🛠 기술 스택 (Tech Stack)

*   **Framework**: Flutter SDK
*   **Language**: Dart
*   **State Management**: Provider
*   **Backend & DB**:
    *   Firebase Auth (Google Sign In)
    *   Cloud Firestore
    *   Firebase Storage
*   **AI & ML**:
    *   Google Generative AI (Gemini)
    *   Google ML Kit (Face Detection)
*   **Location & Maps**: Google Maps Flutter, Geolocator
*   **UI/UX**: Rive (Animation), Custom Fonts (Bagel Fat One, Inter)

<br/>

## 🚀 시작하기 (Getting Started)

### 1. 전제 조건 (Prerequisites)
*   Flutter SDK 설치
*   Firebase 프로젝트 설정 (`google-services.json`, `GoogleService-Info.plist`)
*   Google Maps API Key

### 2. 설치 및 실행 (Installation)

1. **레포지토리 클론**
   ```bash
   git clone https://github.com/your-username/fluting.git
   cd fluting
   ```

2. **패키지 설치**
   ```bash
   flutter pub get
   ```

3. **환경 변수 설정**
   `lib/config/api_key.example.dart` 파일을 복사하여 `api_key.dart`를 생성하고 키를 입력하세요.
   ```dart
   // lib/config/api_key.dart
   const String apiKey = "YOUR_GEMINI_API_KEY";
   // 기타 필요한 키 설정
   ```

4. **앱 실행**
   ```bash
   flutter run
   ```

<br/>

## 📂 프로젝트 구조 (Project Structure)

```
lib/
├── config/          # API 키 및 설정 파일
├── providers/       # 상태 관리 (Provider)
├── screens/         # UI 화면
│   ├── auth/        # 로그인, 정보 입력
│   ├── chat/        # 채팅 관련 화면
│   ├── home/        # 메인 홈
│   ├── likes/       # 좋아요/매칭 화면
│   ├── profile/     # 프로필 관리
│   └── smile/       # 스마일 감지 기능
├── services/        # 비즈니스 로직 (Firebase, AI, Location)
└── main.dart        # 앱 진입점
```

---

Copyright © 2026 Fluting. All Rights Reserved.
