import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io';

/// 콕 찌르기 관련 데이터를 모두 삭제하는 스크립트
/// 
/// 사용 방법:
/// dart run scripts/clear_pokes.dart
void main() async {
  try {
    // Firebase 초기화
    print('🔥 Firebase 초기화 중...');
    await Firebase.initializeApp();
    print('✅ Firebase 초기화 완료');
    
    final db = FirebaseFirestore.instance;

    print('\n🔥 콕 찌르기 데이터 삭제 시작...');
    print('⚠️  이 작업은 되돌릴 수 없습니다!\n');
    
    // 모든 사용자의 pokes 서브컬렉션 삭제
    print('📋 사용자 목록 가져오는 중...');
    final usersSnapshot = await db.collection('users').get();
    print('✅ 총 ${usersSnapshot.docs.length}명의 사용자 발견\n');
    
    int totalDeleted = 0;
    int totalUsers = 0;
    int failedDeletions = 0;
    
    for (var userDoc in usersSnapshot.docs) {
      final userId = userDoc.id;
      final userName = userDoc.data()['name'] as String? ?? userId;
      
      try {
        final pokesSnapshot = await db
            .collection('users')
            .doc(userId)
            .collection('pokes')
            .get();
        
        if (pokesSnapshot.docs.isEmpty) {
          print('⏭️  $userName: 콕 찌르기 데이터 없음 (건너뜀)');
          continue;
        }
        
        // 배치 삭제로 성능 개선
        final batch = db.batch();
        int userPokeCount = 0;
        
        for (var pokeDoc in pokesSnapshot.docs) {
          batch.delete(pokeDoc.reference);
          userPokeCount++;
        }
        
        await batch.commit();
        totalDeleted += userPokeCount;
        totalUsers++;
        
        print('✅ $userName: $userPokeCount개 문서 삭제 완료');
      } catch (e) {
        failedDeletions++;
        print('❌ $userName: 삭제 실패 - $e');
        // 개별 사용자 삭제 실패해도 계속 진행
      }
    }

    print('\n' + '=' * 50);
    print('📊 삭제 결과 요약:');
    print('  - 처리된 사용자: $totalUsers명');
    print('  - 삭제된 문서: $totalDeleted개');
    if (failedDeletions > 0) {
      print('  - 실패한 삭제: $failedDeletions건');
    }
    print('✅ 모든 콕 찌르기 데이터 삭제 완료!');
    print('=' * 50);
    
    exit(0);
  } catch (e, stackTrace) {
    print('\n❌❌❌ 스크립트 실행 실패 ❌❌❌');
    print('❌ 에러 타입: ${e.runtimeType}');
    print('❌ 에러 메시지: $e');
    print('❌ 스택 트레이스:');
    print(stackTrace);
    exit(1);
  }
}

