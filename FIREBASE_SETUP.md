# Firebase 구글 로그인 설정 가이드

## 1. Firebase 프로젝트 생성 및 설정

### Firebase Console에서 프로젝트 생성
1. [Firebase Console](https://console.firebase.google.com/)에 접속
2. 새 프로젝트 생성 또는 기존 프로젝트 선택
3. 프로젝트에 Android 및 iOS 앱 추가

### Android 설정
1. Firebase Console에서 Android 앱 추가
   - 패키지 이름: `com.moapp.flirting`
2. `google-services.json` 파일 다운로드
3. 다운로드한 `google-services.json` 파일을 `android/app/` 디렉토리에 복사

### iOS 설정
1. Firebase Console에서 iOS 앱 추가
   - 번들 ID: 프로젝트의 번들 ID (Info.plist에서 확인)
2. `GoogleService-Info.plist` 파일 다운로드
3. 다운로드한 `GoogleService-Info.plist` 파일을 `ios/Runner/` 디렉토리에 복사
4. Xcode에서 `ios/Runner.xcworkspace`를 열고 파일을 프로젝트에 추가

## 2. Firebase Authentication 설정

1. Firebase Console에서 **Authentication** 메뉴로 이동
2. **Sign-in method** 탭 클릭
3. **Google** 제공업체 활성화
   - 지원 이메일 선택
   - 프로젝트의 공개 이름 입력
   - 저장

## 3. 패키지 설치

터미널에서 다음 명령어 실행:

```bash
flutter pub get
```

## 4. SHA-1 인증서 지문 추가 (Android)

Google Sign-In을 사용하려면 SHA-1 인증서 지문을 Firebase에 등록해야 합니다.

### 디버그 키스토어 SHA-1 가져오기

```bash
# macOS/Linux
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Windows
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

출력된 SHA-1 값을 복사하여 Firebase Console의 프로젝트 설정 > 일반 > Android 앱에 추가합니다.

## 5. iOS URL 스킴 설정 (필요한 경우)

iOS에서 Google Sign-In을 사용하려면 URL 스킴을 설정해야 할 수 있습니다. 
`ios/Runner/Info.plist`에 다음을 추가:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

`YOUR_REVERSED_CLIENT_ID`는 `GoogleService-Info.plist`의 `REVERSED_CLIENT_ID` 값을 사용하세요.

## 6. 앱 실행

모든 설정이 완료되면 앱을 실행하고 "Google 로 시작하기" 버튼을 테스트하세요.

```bash
flutter run
```

## 문제 해결

### Android에서 빌드 오류가 발생하는 경우
- `google-services.json` 파일이 `android/app/` 디렉토리에 있는지 확인
- `android/app/build.gradle.kts`에 Google Services 플러그인이 추가되었는지 확인

### iOS에서 빌드 오류가 발생하는 경우
- `GoogleService-Info.plist` 파일이 `ios/Runner/` 디렉토리에 있는지 확인
- Xcode에서 파일이 프로젝트에 제대로 추가되었는지 확인

### 로그인 시 오류가 발생하는 경우
- Firebase Console에서 Google Sign-In이 활성화되었는지 확인
- SHA-1 인증서 지문이 올바르게 등록되었는지 확인 (Android)
- 인터넷 연결 상태 확인

