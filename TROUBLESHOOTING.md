# 기기 연결 오류 해결 방법

## "Device is busy" 오류 해결

### 1. 기기 재연결

1. iPhone에서 USB 케이블을 뽑았다가 다시 연결
2. 기기 잠금 해제
3. "이 컴퓨터를 신뢰하시겠습니까?" → **신뢰** 선택

### 2. Xcode에서 기기 신뢰 확인

1. Xcode 열기
2. **Window > Devices and Simulators** (또는 `Cmd + Shift + 2`)
3. 왼쪽에서 기기 선택
4. "Use for Development" 버튼 클릭 (또는 기기 이름 옆의 신뢰 버튼)
5. 기기에서 "신뢰" 선택

### 3. 개발자 모드 확인 (iOS 16 이상)

1. iPhone 설정 > 개인정보 보호 및 보안 > 개발자 모드
2. 개발자 모드가 **켜져 있는지** 확인
3. 꺼져 있으면 켜고 기기 재시작

### 4. Xcode 프로젝트 정리

터미널에서 실행:

```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
```

### 5. Flutter 클린 빌드

```bash
flutter clean
flutter pub get
cd ios
pod install
cd ..
```

### 6. 다시 실행

```bash
flutter devices
flutter run
```

---

## 추가 해결 방법

### 방법 1: Xcode에서 직접 빌드

1. Xcode 열기: `open ios/Runner.xcworkspace`
2. 상단에서 기기 선택 (losecow🐮)
3. Product > Run (또는 `Cmd + R`)

### 방법 2: 기기 재시작

1. iPhone 완전히 재시작
2. Mac 재시작 (필요시)
3. 다시 연결

### 방법 3: 다른 USB 포트/케이블 사용

- 다른 USB 포트에 연결 시도
- 다른 케이블 사용 (데이터 전송 가능한 케이블인지 확인)

---

## 빠른 해결 체크리스트

- [ ] 기기 잠금 해제
- [ ] USB 케이블 제대로 연결
- [ ] "이 컴퓨터를 신뢰" 선택
- [ ] 개발자 모드 켜기 (iOS 16+)
- [ ] Xcode에서 기기 신뢰
- [ ] `flutter clean` 실행
- [ ] 기기 재시작
