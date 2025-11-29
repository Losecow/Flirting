import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firestore에 사용자 정보를 저장하는 서비스
///
/// 컬렉션 구조:
/// users/{uid} 문서에 프로필 정보를 저장한다.
class FirestoreService {
  FirestoreService();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 현재 로그인한 사용자의 uid
  String? get _userId => _auth.currentUser?.uid;

  /// 현재 사용자 문서 참조
  DocumentReference<Map<String, dynamic>> get _userDoc {
    final uid = _userId;
    if (uid == null) {
      throw Exception('로그인한 사용자가 없습니다. FirebaseAuth.currentUser가 null 입니다.');
    }
    return _db.collection('users').doc(uid);
  }

  /// 현재 사용자 정보 가져오기
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final uid = _userId;
    if (uid == null) return null;

    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      print('❌ 현재 사용자 정보 가져오기 실패: $e');
      return null;
    }
  }

  /// 특정 사용자 문서 가져오기
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDocument(String userId) async {
    return await _db.collection('users').doc(userId).get();
  }

  /// 학교 / 전공 정보 저장 (업서트)
  Future<void> upsertSchoolInfo({
    required String school,
    required String major,
  }) async {
    print('🔥 FirestoreService.upsertSchoolInfo 호출됨');
    print('   - school: $school');
    print('   - major: $major');
    
    final uid = _userId;
    print('   - currentUser.uid: $uid');
    
    if (uid == null) {
      print('❌ currentUser가 null입니다!');
      throw Exception('로그인한 사용자가 없습니다. FirebaseAuth.currentUser가 null 입니다.');
    }
    
    try {
      print('💾 Firestore에 저장 시도 중...');
      await _userDoc.set(
        {
          'school': school,
          'major': major,
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      print('✅ Firestore 저장 완료!');
    } catch (e, stackTrace) {
      print('❌ Firestore 저장 실패: $e');
      print('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// 프로필 키워드 정보 저장 (업서트)
  Future<void> upsertProfileKeywords({
    required List<String> styleKeywords,
    required List<String> personalityKeywords,
  }) async {
    await _userDoc.set(
      {
        'styleKeywords': styleKeywords,
        'personalityKeywords': personalityKeywords,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// 프로필 정보 저장 (업서트) - 이름, 나이, 자기소개, 외모 스타일
  Future<void> upsertProfileInfo({
    required String name,
    required int age,
    required String bio,
    required List<String> appearanceStyles,
  }) async {
    print('🔥 FirestoreService.upsertProfileInfo 호출됨');
    print('   - name: $name');
    print('   - age: $age');
    print('   - bio: $bio');
    print('   - appearanceStyles: $appearanceStyles');

    final uid = _userId;
    print('   - currentUser.uid: $uid');

    if (uid == null) {
      print('❌ currentUser가 null입니다!');
      throw Exception('로그인한 사용자가 없습니다. FirebaseAuth.currentUser가 null 입니다.');
    }

    try {
      print('💾 Firestore에 프로필 정보 저장 시도 중...');
      await _userDoc.set(
        {
          'name': name,
          'age': age,
          'bio': bio,
          'appearanceStyles': appearanceStyles,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      print('✅ 프로필 정보 저장 완료!');
    } catch (e, stackTrace) {
      print('❌ 프로필 정보 저장 실패: $e');
      print('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// 선호 스타일 정보 저장 (업서트) - 선호하는 외모, 성격, 취미
  Future<void> upsertPreferenceStyles({
    required List<String> preferredAppearanceStyles,
    required List<String> preferredPersonalities,
    required List<String> preferredHobbies,
  }) async {
    print('🔥 FirestoreService.upsertPreferenceStyles 호출됨');
    print('   - preferredAppearanceStyles: $preferredAppearanceStyles');
    print('   - preferredPersonalities: $preferredPersonalities');
    print('   - preferredHobbies: $preferredHobbies');

    final uid = _userId;
    print('   - currentUser.uid: $uid');

    if (uid == null) {
      print('❌ currentUser가 null입니다!');
      throw Exception('로그인한 사용자가 없습니다. FirebaseAuth.currentUser가 null 입니다.');
    }

    try {
      print('💾 Firestore에 선호 스타일 저장 시도 중...');
      await _userDoc.set(
        {
          'preferredAppearanceStyles': preferredAppearanceStyles,
          'preferredPersonalities': preferredPersonalities,
          'preferredHobbies': preferredHobbies,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      print('✅ 선호 스타일 저장 완료!');
    } catch (e, stackTrace) {
      print('❌ 선호 스타일 저장 실패: $e');
      print('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// 다른 사용자 목록 가져오기 (현재 사용자 제외)
  Future<List<Map<String, dynamic>>> getOtherUsers({
    int limit = 20,
    String? searchQuery,
    Map<String, dynamic>? filters,
  }) async {
    final uid = _userId;
    if (uid == null) {
      throw Exception('로그인한 사용자가 없습니다.');
    }

    try {
      Query<Map<String, dynamic>> query = _db.collection('users');

      // 현재 사용자 제외
      query = query.where(FieldPath.documentId, isNotEqualTo: uid);

      // 검색어가 있으면 이름, 학교, 전공에서 검색
      if (searchQuery != null && searchQuery.isNotEmpty) {
        // Firestore는 복잡한 텍스트 검색을 직접 지원하지 않으므로
        // 클라이언트 측에서 필터링하거나, 별도 검색 인덱스 사용 필요
        // 여기서는 기본적으로 모든 사용자를 가져온 후 클라이언트에서 필터링
      }

      // 필터 적용
      if (filters != null) {
        if (filters['school'] != null) {
          query = query.where('school', isEqualTo: filters['school']);
        }
        if (filters['major'] != null) {
          query = query.where('major', isEqualTo: filters['major']);
        }
        if (filters['minAge'] != null) {
          query = query.where('age', isGreaterThanOrEqualTo: filters['minAge']);
        }
        if (filters['maxAge'] != null) {
          query = query.where('age', isLessThanOrEqualTo: filters['maxAge']);
        }
      }

      query = query.limit(limit);

      final querySnapshot = await query.get();
      final users = <Map<String, dynamic>>[];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id; // 문서 ID 추가
        users.add(data);
      }

      // 검색어가 있으면 클라이언트 측에서 필터링
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerQuery = searchQuery.toLowerCase();
        return users.where((user) {
          final name = (user['name'] as String? ?? '').toLowerCase();
          final school = (user['school'] as String? ?? '').toLowerCase();
          final major = (user['major'] as String? ?? '').toLowerCase();
          final bio = (user['bio'] as String? ?? '').toLowerCase();

          return name.contains(lowerQuery) ||
              school.contains(lowerQuery) ||
              major.contains(lowerQuery) ||
              bio.contains(lowerQuery);
        }).toList();
      }

      return users;
    } catch (e) {
      print('❌ 사용자 목록 가져오기 실패: $e');
      rethrow;
    }
  }

  /// 좋아요 추가
  Future<void> addLike(String targetUserId) async {
    final uid = _userId;
    if (uid == null) {
      throw Exception('로그인한 사용자가 없습니다.');
    }

    try {
      await _db.collection('users').doc(uid).collection('likes').doc(targetUserId).set({
        'targetUserId': targetUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ 좋아요 추가 실패: $e');
      rethrow;
    }
  }

  /// 좋아요한 사용자 목록 가져오기
  Future<List<String>> getLikedUserIds() async {
    final uid = _userId;
    if (uid == null) {
      return [];
    }

    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('likes')
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('❌ 좋아요 목록 가져오기 실패: $e');
      return [];
    }
  }
}


