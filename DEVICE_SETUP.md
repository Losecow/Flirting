# 실제 기기에서 앱 실행하기

## iOS 기기 연결 방법

### 1. USB 케이블로 연결

1. iPhone/iPad를 Mac에 USB 케이블로 연결
2. 기기에서 "이 컴퓨터를 신뢰하시겠습니까?" 메시지가 뜨면 **신뢰** 선택
3. 기기 잠금 해제

### 2. 개발자 모드 활성화 (iOS 16 이상)

1. 기기 설정 > 개인정보 보호 및 보안 > 개발자 모드
2. 개발자 모드 켜기
3. 기기 재시작 (필요시)

### 3. 연결 확인

터미널에서 다음 명령어 실행:

```bash
flutter devices
```

기기가 보이면 연결 성공!

### 4. 앱 실행

```bash
flutter run
```

또는 특정 기기 지정:

```bash
flutter run -d <device-id>
```

---

## Android 기기 연결 방법

### 1. USB 디버깅 활성화

1. 기기 설정 > 휴대전화 정보 > 빌드 번호를 7번 연속 탭 (개발자 옵션 활성화)
2. 설정 > 개발자 옵션 > USB 디버깅 켜기

### 2. USB 케이블로 연결

1. Android 기기를 Mac에 USB 케이블로 연결
2. 기기에서 "USB 디버깅 허용" 팝업이 뜨면 **허용** 선택

### 3. 연결 확인

```bash
flutter devices
```

### 4. 앱 실행

```bash
flutter run
```

---

## 무선 연결 (Wi-Fi) - iOS

### 1. 처음 한 번은 USB로 연결

위의 USB 연결 방법으로 먼저 연결

### 2. 무선 연결 설정

1. Xcode 열기
2. Window > Devices and Simulators
3. 연결된 기기 선택
4. "Connect via network" 체크박스 선택

### 3. 이후부터는 Wi-Fi로 연결 가능

같은 Wi-Fi 네트워크에 연결되어 있으면 USB 없이도 실행 가능

---

## 문제 해결

### 기기가 안 보일 때

1. USB 케이블 확인 (데이터 전송 가능한 케이블인지)
2. 기기 잠금 해제
3. 기기 재시작
4. Mac 재시작
5. `flutter doctor` 실행하여 문제 확인

### iOS 서명 오류

- Xcode에서 자동 서명 설정 확인
- Apple Developer 계정 필요 (무료 계정도 가능)

### Android ADB 오류

```bash
adb kill-server
adb start-server
```

---

## 빠른 실행 명령어

```bash
# 연결된 기기 확인
flutter devices

# 첫 번째 기기로 실행
flutter run

# 특정 기기로 실행
flutter run -d <device-id>

# 릴리스 모드로 실행 (더 빠름)
flutter run --release
```
