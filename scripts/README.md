# 학교 및 전공 데이터 초기화 가이드

## 방법 1: Firebase 콘솔에서 직접 입력 (가장 간단)

1. Firebase Console (https://console.firebase.google.com) 접속
2. 프로젝트 선택
3. Firestore Database로 이동
4. `schools` 컬렉션 생성 후 다음 데이터 추가:

```
문서 ID: 자동 생성
필드:
  - name: "서울대학교" (타입: string)
  - createdAt: (타입: timestamp, 현재 시간)
```

각 학교마다 문서를 추가하세요:
- 서울대학교
- 연세대학교
- 고려대학교
- 한국과학기술원(KAIST)
- 포스텍(포항공과대학교)
- 성균관대학교
- 한양대학교
- 중앙대학교
- 경희대학교
- 이화여자대학교

5. `majors` 컬렉션 생성 후 다음 데이터 추가:

각 전공마다 문서를 추가하세요:
- 컴퓨터공학
- 경영학
- 심리학
- 경제학
- 영어영문학
- 의학
- 법학
- 건축학
- 디자인
- 음악

## 방법 2: 스크립트 실행

```bash
# Flutter 앱이 실행 중이어야 합니다
flutter run -d chrome --target scripts/init_school_major_data.dart
```

또는 Firebase CLI를 사용하여 JSON 데이터를 import할 수 있습니다.

## 데이터 구조

### schools 컬렉션
```
{
  name: string,
  createdAt: timestamp
}
```

### majors 컬렉션
```
{
  name: string,
  createdAt: timestamp
}
```

