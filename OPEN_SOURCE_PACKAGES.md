# 오픈소스 패키지 사용 현황

## 문제 정의 및 프로젝트 소개

### 문제 정의

대학생들이 같은 학교 내에서 새로운 사람들을 만나고 친구를 사귀는 것은 쉽지 않습니다. 특히 다음과 같은 문제들이 있습니다:

1. **공간적 제약**: 같은 학교에 다니더라도 서로의 존재를 모르거나, 만날 기회가 없습니다.
2. **소통의 어려움**: 처음 만나는 사람과 대화를 시작하는 것이 부담스럽고, 적절한 말투를 선택하기 어렵습니다.
3. **프라이버시 우려**: 개인 정보를 공개하는 것에 대한 부담이 있어 자연스러운 만남이 어렵습니다.
4. **신뢰 부족**: 상대방의 진정성을 확인하기 어려워 관계 형성이 어렵습니다.

### 프로젝트 소개

**Campus Match**는 대학생들을 위한 위치 기반 소셜 매칭 앱입니다. 같은 학교 내에서 반경 1km 이내의 사용자들을 지도에서 확인하고, 웃음 감지를 통해 자연스럽게 정보를 공개하며, AI 기반 말투 변환 기능으로 편안한 대화를 시작할 수 있도록 돕습니다.

**주요 기능:**

- **지도 기반 사용자 탐색**: Google Maps를 활용하여 반경 1km 내 사용자들의 위치를 시각적으로 확인
- **웃음 감지 정보 공개**: Google ML Kit을 사용한 실시간 얼굴 인식으로 웃음 확률 95% 이상 시 자동 정보 공개
- **AI 말투 변환 채팅**: Google Gemini AI를 활용하여 사용자가 선택한 말투 스타일로 메시지를 자동 변환
- **프로필 관리**: 학교, 전공, 자기소개 등 상세 프로필 정보 관리
- **좋아요 시스템**: 관심 있는 사용자에게 좋아요를 보내고 지도에서 확인

이 프로젝트는 Google의 오픈소스 패키지들을 활용하여 현대적이고 안정적인 모바일 앱을 구현했습니다.

---

## Widget / Plugin 구성

### 주요 Flutter Widget

**페이지 위젯 (StatefulWidget):**

- `ResponsiveLoginPage` - 로그인 페이지 (Google 로그인)
- `MainNavigation` - 하단 네비게이션 바 (검색, 좋아요, 프로필)
- `MainPage` - 사용자 검색 및 프로필 카드 스와이프 페이지
- `LikesPage` - Google Maps 기반 좋아요한 사용자 지도 표시
- `ProfilePage` - 내 프로필 관리 페이지
- `ProfileEditPage` - 프로필 편집 페이지
- `ChatPage` - 1:1 채팅 페이지 (AI 말투 변환 포함)
- `ChatListPage` - 채팅방 목록 페이지
- `SmileDetectionPage` - 웃음 감지 카메라 페이지
- `SchoolInfoPage` - 학교/전공 정보 입력 페이지
- `PreferenceStylePage` - 선호 스타일 선택 페이지

**주요 UI 위젯:**

- `GoogleMap` - 지도 표시 (google_maps_flutter)
- `CameraPreview` - 카메라 미리보기 (camera)
- `TextField` - 텍스트 입력
- `ListView.builder` - 스크롤 가능한 리스트
- `PageView` - 스와이프 가능한 페이지 뷰
- `CircleAvatar` - 프로필 이미지 표시
- `RiveAnimation` - 하트 애니메이션 (rive)

### 주요 Plugin / Package

**Firebase 관련:**

- `firebase_core` - Firebase 초기화
- `firebase_auth` - 사용자 인증
- `cloud_firestore` - NoSQL 데이터베이스
- `firebase_storage` - 파일 저장소

**Google 서비스:**

- `google_sign_in` - Google 로그인
- `google_maps_flutter` - Google Maps 지도
- `google_mlkit_face_detection` - 얼굴 감지
- `google_generative_ai` - Gemini AI

**미디어/카메라:**

- `camera` - 카메라 접근
- `image_picker` - 이미지 선택

**위치/권한:**

- `geolocator` - 위치 정보
- `permission_handler` - 권한 관리

**상태 관리:**

- `provider` - 상태 관리 (Provider 패턴)

**애니메이션:**

- `rive` - Rive 애니메이션

---

## Firebase Service 사용 현황

### 1. Firebase Authentication

**사용 위치:** `lib/services/auth_service.dart`

**주요 기능:**

- Google 로그인 (`signInWithGoogle`)
- 로그아웃 (`signOut`)
- 인증 상태 스트림 (`authStateChanges`)
- 현재 사용자 확인 (`currentUser`)

**구현 방식:**

```dart
// Google 로그인 플로우
1. GoogleSignIn으로 사용자 인증
2. GoogleAuthProvider.credential 생성
3. FirebaseAuth.signInWithCredential로 Firebase 인증
```

**사용 예시:**

- 로그인 페이지에서 Google 로그인 버튼 클릭 시 사용
- Provider를 통해 전역 인증 상태 관리

---

### 2. Cloud Firestore

**사용 위치:** `lib/services/firestore_service.dart`

**주요 컬렉션 구조:**

**users/{uid}** - 사용자 프로필 정보

- `school`, `major` - 학교/전공
- `name`, `age`, `bio` - 기본 정보
- `profileImageUrl` - 프로필 이미지 URL
- `latitude`, `longitude` - 위치 정보
- `styleKeywords`, `personalityKeywords` - 키워드
- `preferredAppearanceStyles`, `preferredPersonalities`, `preferredHobbies` - 선호 스타일
- `instagramId`, `kakaoId` - SNS 정보

**users/{uid}/likes/{targetUserId}** - 좋아요 정보

- 서브컬렉션으로 좋아요한 사용자 저장

**users/{uid}/sharedInfo/{targetUserId}** - 정보 공개 기록

- 서브컬렉션으로 공개한 사용자 정보 저장

**chats/{chatRoomId}** - 채팅방 정보

- `participants` - 참여자 배열
- `lastMessage` - 마지막 메시지
- `lastMessageAt` - 마지막 메시지 시간

**chats/{chatRoomId}/messages/{messageId}** - 채팅 메시지

- `senderId`, `receiverId` - 송수신자
- `text` - 메시지 내용
- `createdAt` - 생성 시간

**주요 메서드:**

- `getCurrentUser()` - 현재 사용자 정보 조회
- `getUserDocument()` - 특정 사용자 정보 조회
- `upsertSchoolInfo()` - 학교/전공 정보 저장
- `upsertProfile()` - 프로필 정보 저장
- `saveLocation()` - 위치 정보 저장
- `likeUser()` - 사용자 좋아요
- `getLikedUserIds()` - 좋아요한 사용자 목록
- `shareInfoWithUser()` - 정보 공개
- `sendChatMessage()` - 채팅 메시지 전송
- `getChatMessages()` - 채팅 메시지 조회
- `getChatRooms()` - 채팅방 목록 조회
- `createOrGetChatRoom()` - 채팅방 생성/조회

**쿼리 예시:**

```dart
// 사용자 목록 조회 (필터링)
Query query = _db.collection('users')
  .where(FieldPath.documentId, isNotEqualTo: uid)
  .where('school', isEqualTo: school)
  .limit(20);

// 채팅방 목록 조회
Query query = _db.collection('chats')
  .where('participants', arrayContains: uid)
  .orderBy('lastMessageAt', descending: true);
```

---

### 3. Firebase Storage

**사용 위치:** `lib/services/storage_service.dart`

**주요 기능:**

- 프로필 이미지 업로드 (`uploadProfileImage`)
- 프로필 이미지 삭제 (`deleteProfileImage`)

**저장 경로 구조:**

```
profile_images/
  └── {uid}/
      └── profile.{extension}
```

**구현 방식:**

```dart
1. File 객체를 Storage 참조로 업로드
2. putFile()로 파일 업로드
3. getDownloadURL()로 다운로드 URL 획득
4. Firestore에 URL 저장
```

**사용 예시:**

- 프로필 편집 페이지에서 이미지 선택 시 자동 업로드
- 업로드된 URL을 Firestore 사용자 문서에 저장

---

### 4. Firebase Functions

**사용 현황:**

- 현재 프로젝트에서는 Firebase Functions를 사용하지 않습니다.
- 모든 비즈니스 로직은 클라이언트 측 Flutter 코드에서 처리됩니다.

---

### Firebase 사용 패턴

**1. 서비스 레이어 패턴:**

- 각 Firebase 서비스를 별도 클래스로 분리
- `AuthService`, `FirestoreService`, `StorageService`
- 비즈니스 로직 캡슐화

**2. Provider 패턴:**

- Firebase 데이터를 Provider로 전역 상태 관리
- `AuthProvider`, `ProfileProvider`, `ChatProvider` 등
- UI와 데이터 로직 분리

**3. 에러 처리:**

- try-catch로 모든 Firebase 작업 감싸기
- 사용자 친화적 에러 메시지 표시
- 로그 출력으로 디버깅 지원

**4. 보안 규칙:**

- Firestore Security Rules로 데이터 접근 제어
- Storage Security Rules로 파일 접근 제어
- 사용자별 데이터 격리 (uid 기반)

---

## 1. Google Maps Flutter

### 이름

**google_maps_flutter**

### pub.dev URL

https://pub.dev/packages/google_maps_flutter

### 오픈소스 패키지 소개

Google이 공식 제공하는 Flutter용 지도 패키지. iOS/Android 네이티브 Google Maps SDK를 Flutter 위젯으로 제공합니다.

**주요 기능:** 지도 표시, 마커/원형 영역 표시, 사용자 위치 표시, 카메라 제어

### 사용된 부분 스크린샷 + 설명

**사용 위치:** `lib/likes_page.dart`

**기능:**

- 좋아요 탭의 지도 화면에서 사용
- 현재 사용자 위치 중심으로 반경 1km 원형 영역 표시
- 좋아요한 사용자 위치를 마커로 표시
- 마커 탭 시 프로필 모달 표시

**스크린샷 위치:**
앱 실행 → "좋아요" 탭 → 지도 화면 (현재 위치 파란 점, 사용자 마커, 반경 1km 원형 영역)

---

## 2. Google ML Kit Face Detection

### 이름

**google_mlkit_face_detection**

### pub.dev URL

https://pub.dev/packages/google_mlkit_face_detection

### 오픈소스 패키지 소개

Google ML Kit 기반 얼굴 감지 패키지. 디바이스에서 실시간 얼굴 감지 및 웃음 확률 측정 기능을 제공합니다.

**주요 기능:** 실시간 얼굴 감지, 웃음 확률 측정 (0.0~1.0), 얼굴 랜드마크 감지

### 사용된 부분 스크린샷 + 설명

**사용 위치:** `lib/smile_detection_page.dart`

**기능:**

- 전면 카메라로 실시간 얼굴 감지
- 웃음 확률 95% 이상 시 자동으로 SNS 정보 공개
- 화면에 실시간 웃음의 정도 표시

**스크린샷 위치:**
앱 실행 → 좋아요 탭 → 사용자 프로필 → "내 정보 공개하기" → 웃음 감지 카메라 화면

---

## 3. Google Generative AI (Gemini)

### 이름

**google_generative_ai**

### pub.dev URL

https://pub.dev/packages/google_generative_ai

### 오픈소스 패키지 소개

Google의 Gemini AI 모델을 Flutter에서 사용할 수 있게 해주는 공식 패키지. Gemini 2.5 Flash 모델을 사용하여 빠른 텍스트 변환을 제공합니다.

**주요 기능:** 텍스트 생성/변환, 대화형 AI, 빠른 응답 속도

### 사용된 부분 스크린샷 + 설명

**사용 위치:** `lib/services/ai_service.dart`, `lib/chat_page.dart`

**기능:**

- 채팅 메시지를 선택한 말투 스타일로 AI 변환
- 지원 말투: 친근한 말투, 존댓말, 반말, 귀여운 말투, 차분한 말투, 밝은 말투
- "수정" 버튼으로 메시지 변환 후 확인 가능
- 변환 완료 시 입력창 위 스낵바 표시

**스크린샷 위치:**
앱 실행 → 검색 탭 → 채팅 버튼 → 채팅방 선택 → 말투 선택 바 확인 → 메시지 입력 후 "수정" 버튼 클릭

---

## 참고사항

- 모든 패키지는 Google 공식 오픈소스 패키지입니다.
- 스크린샷은 실제 앱 실행 화면을 캡처하여 추가해주세요.
