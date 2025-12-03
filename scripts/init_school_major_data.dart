import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../lib/main.dart' as app;

/// 학교와 전공 데이터를 Firestore에 초기화하는 스크립트
/// 
/// 사용 방법:
/// 1. Firebase 프로젝트가 설정되어 있어야 합니다
/// 2. flutter run -d chrome --target scripts/init_school_major_data.dart
///    또는
///    dart run scripts/init_school_major_data.dart
void main() async {
  // Firebase 초기화
  await Firebase.initializeApp();
  
  final db = FirebaseFirestore.instance;

  // 학교 데이터 (10개)
  final schools = [
    '서울대학교',
    '연세대학교',
    '고려대학교',
    '한국과학기술원(KAIST)',
    '포스텍(포항공과대학교)',
    '성균관대학교',
    '한양대학교',
    '중앙대학교',
    '경희대학교',
    '이화여자대학교',
  ];

  // 전공 데이터 (10개)
  final majors = [
    '컴퓨터공학',
    '경영학',
    '심리학',
    '경제학',
    '영어영문학',
    '의학',
    '법학',
    '건축학',
    '디자인',
    '음악',
  ];

  try {
    print('🔥 학교 데이터 초기화 시작...');
    
    // 학교 데이터 저장
    for (var school in schools) {
      await db.collection('schools').add({
        'name': school,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('✅ 학교 추가: $school');
    }

    print('\n🔥 전공 데이터 초기화 시작...');
    
    // 전공 데이터 저장
    for (var major in majors) {
      await db.collection('majors').add({
        'name': major,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('✅ 전공 추가: $major');
    }

    print('\n✅ 모든 데이터 초기화 완료!');
  } catch (e) {
    print('❌ 데이터 초기화 실패: $e');
  }
}

