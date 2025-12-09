import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

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
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDocument(
    String userId,
  ) async {
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
      await _userDoc.set({
        'school': school,
        'major': major,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
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
    await _userDoc.set({
      'styleKeywords': styleKeywords,
      'personalityKeywords': personalityKeywords,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 취미 정보 저장 (업서트)
  Future<void> upsertHobbyOptions(List<String> hobbyOptions) async {
    await _userDoc.set({
      'hobbyOptions': hobbyOptions,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 연락처 정보 저장 (업서트) - 인스타그램, 카카오톡 아이디
  Future<void> upsertContactInfo({
    required String instagramId,
    required String kakaoId,
  }) async {
    final uid = _userId;
    if (uid == null) {
      throw Exception('로그인한 사용자가 없습니다.');
    }

    try {
      await _userDoc.set({
        'instagramId': instagramId.isEmpty ? null : instagramId,
        'kakaoId': kakaoId.isEmpty ? null : kakaoId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print('✅ 연락처 정보 저장 완료!');
    } catch (e) {
      print('❌ 연락처 정보 저장 실패: $e');
      rethrow;
    }
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
      await _userDoc.set({
        'name': name,
        'age': age,
        'bio': bio,
        'appearanceStyles': appearanceStyles,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print('✅ 프로필 정보 저장 완료!');
    } catch (e, stackTrace) {
      print('❌ 프로필 정보 저장 실패: $e');
      print('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// 프로필 이미지 URL 저장 (업서트)
  Future<void> upsertProfileImageUrl(String imageUrl) async {
    final uid = _userId;
    if (uid == null) {
      throw Exception('로그인한 사용자가 없습니다.');
    }

    try {
      await _userDoc.set({
        'profileImageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print('✅ 프로필 이미지 URL 저장 완료: $imageUrl');
    } catch (e) {
      print('❌ 프로필 이미지 URL 저장 실패: $e');
      rethrow;
    }
  }

  /// 위치 정보 저장 (업서트)
  Future<void> upsertLocation({
    required double latitude,
    required double longitude,
  }) async {
    final uid = _userId;
    if (uid == null) {
      throw Exception('로그인한 사용자가 없습니다.');
    }

    try {
      await _userDoc.set({
        'latitude': latitude,
        'longitude': longitude,
        'locationUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print('✅ 위치 정보 저장 완료: $latitude, $longitude');
    } catch (e) {
      print('❌ 위치 정보 저장 실패: $e');
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
      await _userDoc.set({
        'preferredAppearanceStyles': preferredAppearanceStyles,
        'preferredPersonalities': preferredPersonalities,
        'preferredHobbies': preferredHobbies,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
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
      await _db
          .collection('users')
          .doc(uid)
          .collection('likes')
          .doc(targetUserId)
          .set({
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

  /// 나를 좋아요한 사용자 목록 가져오기
  Future<List<Map<String, dynamic>>> getReceivedLikes() async {
    final uid = _userId;
    if (uid == null) {
      return [];
    }

    try {
      // 모든 사용자의 likes 서브컬렉션에서 현재 사용자 ID를 찾기
      final allUsersSnapshot = await _db.collection('users').get();
      final receivedLikes = <Map<String, dynamic>>[];

      for (final userDoc in allUsersSnapshot.docs) {
        final userId = userDoc.id;
        if (userId == uid) continue; // 자기 자신은 제외

        // 해당 사용자의 likes 서브컬렉션에서 현재 사용자 확인
        final likeDoc = await _db
            .collection('users')
            .doc(userId)
            .collection('likes')
            .doc(uid)
            .get();

        if (likeDoc.exists) {
          // 사용자 정보 가져오기
          final userData = userDoc.data();
          userData['id'] = userId;

          // 정보 공개 여부 확인 (sharedInfo 컬렉션에서 확인)
          // userId가 나에게 정보를 공개했는지 확인
          final sharedInfoDoc = await _db
              .collection('users')
              .doc(uid) // 현재 사용자(받은 좋아요를 본 사람)
              .collection('sharedInfo')
              .doc(userId) // 좋아요를 보낸 사용자가 공개한 정보
              .get();

          if (sharedInfoDoc.exists) {
            userData['hasSharedInfo'] = true;
            userData['sharedAt'] = sharedInfoDoc.data()?['sharedAt'];

            // 정보를 공개한 사용자(userId)의 실제 연락처 정보 가져오기
            final sharedUserDoc = await _db
                .collection('users')
                .doc(userId)
                .get();

            if (sharedUserDoc.exists) {
              final sharedUserData = sharedUserDoc.data()!;
              userData['sharedInstagramId'] =
                  sharedUserData['instagramId'] as String? ?? '';
              userData['sharedKakaoId'] =
                  sharedUserData['kakaoId'] as String? ?? '';
            }
          } else {
            userData['hasSharedInfo'] = false;
            userData['sharedInstagramId'] = '';
            userData['sharedKakaoId'] = '';
          }

          // 콕 찌르기 여부 확인 (userId가 나를 콕 찔렀는지)
          final pokeDoc = await _db
              .collection('users')
              .doc(uid)
              .collection('pokes')
              .doc(userId)
              .get();

          userData['hasPokedMe'] = pokeDoc.exists;
          if (pokeDoc.exists) {
            userData['pokedAt'] = pokeDoc.data()?['pokedAt'];
          }

          // 내가 이 사용자를 콕 찔렀는지 확인 및 횟수
          // 상대방의 pokes 컬렉션에서 내가 찔렀는지 확인
          final myPokeDoc = await _db
              .collection('users')
              .doc(userId)
              .collection('pokes')
              .doc(uid)
              .get();

          userData['hasPokedByMe'] = myPokeDoc.exists;
          String? lastPokedByMe;
          if (myPokeDoc.exists) {
            userData['pokedByMeAt'] = myPokeDoc.data()?['pokedAt'];
            userData['pokedByMeCount'] = myPokeDoc.data()?['count'] as int? ?? 0;
            lastPokedByMe = myPokeDoc.data()?['lastPokedBy'] as String?;
            userData['lastPokedByMe'] = lastPokedByMe;
          } else {
            userData['pokedByMeCount'] = 0;
            userData['lastPokedByMe'] = null;
          }

          // 상대방이 나를 콕 찔렀는지 확인 및 횟수
          // 내 pokes 컬렉션에서 상대방이 찔렀는지 확인
          String? lastPokedMe;
          if (pokeDoc.exists) {
            userData['pokedMeCount'] = pokeDoc.data()?['count'] as int? ?? 0;
            lastPokedMe = pokeDoc.data()?['lastPokedBy'] as String?;
            userData['lastPokedMe'] = lastPokedMe;
          } else {
            userData['pokedMeCount'] = 0;
            userData['lastPokedMe'] = null;
          }

          // 찌를 수 있는지 확인
          // 1. 아무도 찌르지 않았으면 찌를 수 있음
          // 2. 상대방이 마지막으로 찔렀으면 찌를 수 있음 (lastPokedMe == userId)
          // 3. 내가 마지막으로 찔렀으면 찌를 수 없음 (lastPokedByMe == uid)
          bool canPoke;
          if (lastPokedByMe == null && lastPokedMe == null) {
            // 아무도 찌르지 않음
            canPoke = true;
          } else if (lastPokedByMe == uid) {
            // 내가 마지막으로 찔렀음
            canPoke = false;
          } else if (lastPokedMe == userId) {
            // 상대방이 마지막으로 찔렀음
            canPoke = true;
          } else {
            // 기본적으로 찌를 수 있음
            canPoke = true;
          }
          
          userData['canPoke'] = canPoke;

          receivedLikes.add(userData);
        }
      }

      return receivedLikes;
    } catch (e) {
      print('❌ 받은 좋아요 목록 가져오기 실패: $e');
      return [];
    }
  }

  /// 특정 사용자에게 내 정보 공개 (웃음 인증 후)
  Future<void> shareInfoToUser(String targetUserId) async {
    final uid = _userId;
    if (uid == null) {
      throw Exception('로그인한 사용자가 없습니다.');
    }

    try {
      // 상대방의 sharedInfo 컬렉션에 내 정보 추가
      await _db
          .collection('users')
          .doc(targetUserId)
          .collection('sharedInfo')
          .doc(uid)
          .set({'sharedUserId': uid, 'sharedAt': FieldValue.serverTimestamp()});

      print('✅ 정보 공개 완료: $targetUserId에게 내 정보 공개');
    } catch (e) {
      print('❌ 정보 공개 실패: $e');
      rethrow;
    }
  }

  /// 상대방을 콕 찌르기
  Future<void> pokeUser(String targetUserId) async {
    final uid = _userId;
    if (uid == null) {
      throw Exception('로그인한 사용자가 없습니다.');
    }

    try {
      // 상대방의 pokes 컬렉션에 콕 찌르기 정보 추가 (횟수 증가)
      final pokeRef = _db
          .collection('users')
          .doc(targetUserId)
          .collection('pokes')
          .doc(uid);

      final pokeDoc = await pokeRef.get();
      
      if (pokeDoc.exists) {
        // 이미 존재하면 횟수 증가
        final currentCount = (pokeDoc.data()?['count'] as int? ?? 0) + 1;
        await pokeRef.update({
          'pokedBy': uid,
          'lastPokedBy': uid, // 마지막으로 찌른 사람
          'pokedAt': FieldValue.serverTimestamp(),
          'count': currentCount,
        });
      } else {
        // 처음 콕 찌르기면 생성
        await pokeRef.set({
          'pokedBy': uid,
          'lastPokedBy': uid, // 마지막으로 찌른 사람
          'pokedAt': FieldValue.serverTimestamp(),
          'count': 1,
        });
      }

      print('✅ 콕 찌르기 완료: $targetUserId를 콕 찔렀습니다');
    } catch (e) {
      print('❌ 콕 찌르기 실패: $e');
      rethrow;
    }
  }

  /// 나를 콕 찌른 사용자 목록 가져오기
  Future<List<String>> getPokedByUsers() async {
    final uid = _userId;
    if (uid == null) {
      return [];
    }

    try {
      final pokesSnapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('pokes')
          .get();

      return pokesSnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('❌ 콕 찌르기 목록 가져오기 실패: $e');
      return [];
    }
  }

  /// 모든 콕 찌르기 데이터 삭제 (개발/테스트용)
  Future<void> clearAllPokes() async {
    try {
      print('🔥 콕 찌르기 데이터 삭제 시작...');
      
      // 모든 사용자의 pokes 서브컬렉션 삭제
      final usersSnapshot = await _db.collection('users').get();
      
      int totalDeleted = 0;
      
      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        final pokesSnapshot = await _db
            .collection('users')
            .doc(userId)
            .collection('pokes')
            .get();
        
        for (var pokeDoc in pokesSnapshot.docs) {
          await pokeDoc.reference.delete();
          totalDeleted++;
        }
      }

      print('✅ 모든 콕 찌르기 데이터 삭제 완료! (총 $totalDeleted개 문서 삭제)');
    } catch (e) {
      print('❌ 콕 찌르기 데이터 삭제 실패: $e');
      rethrow;
    }
  }

  /// 학교 목록 가져오기
  Future<List<String>> getSchools() async {
    try {
      final snapshot = await _db.collection('schools').orderBy('name').get();

      final schools = snapshot.docs
          .map((doc) => doc.data()['name'] as String)
          .toList();

      // 데이터가 없으면 자동으로 초기화
      if (schools.isEmpty) {
        print('⚠️ 학교 데이터가 없습니다. 자동 초기화를 시작합니다...');
        await initializeSchoolAndMajorData();
        // 초기화 후 다시 가져오기
        final newSnapshot = await _db
            .collection('schools')
            .orderBy('name')
            .get();
        return newSnapshot.docs
            .map((doc) => doc.data()['name'] as String)
            .toList();
      }

      return schools;
    } catch (e) {
      print('❌ 학교 목록 가져오기 실패: $e');
      return [];
    }
  }

  /// 전공 목록 가져오기
  Future<List<String>> getMajors() async {
    try {
      final snapshot = await _db.collection('majors').orderBy('name').get();

      final majors = snapshot.docs
          .map((doc) => doc.data()['name'] as String)
          .toList();

      // 데이터가 없으면 자동으로 초기화
      if (majors.isEmpty) {
        print('⚠️ 전공 데이터가 없습니다. 자동 초기화를 시작합니다...');
        await initializeSchoolAndMajorData();
        // 초기화 후 다시 가져오기
        final newSnapshot = await _db
            .collection('majors')
            .orderBy('name')
            .get();
        return newSnapshot.docs
            .map((doc) => doc.data()['name'] as String)
            .toList();
      }

      return majors;
    } catch (e) {
      print('❌ 전공 목록 가져오기 실패: $e');
      return [];
    }
  }

  /// 학교 및 전공 데이터 초기화 (데이터가 없을 때만 실행)
  Future<void> initializeSchoolAndMajorData() async {
    try {
      // 이미 데이터가 있는지 확인
      final schoolsSnapshot = await _db.collection('schools').limit(1).get();
      final majorsSnapshot = await _db.collection('majors').limit(1).get();

      if (schoolsSnapshot.docs.isNotEmpty && majorsSnapshot.docs.isNotEmpty) {
        print('✅ 학교 및 전공 데이터가 이미 존재합니다.');
        return;
      }

      print('🔥 학교 및 전공 데이터 초기화 시작...');

      // JSON 파일에서 데이터 로드
      List<String> schools;
      List<String> majors;

      try {
        final String jsonString = await rootBundle.loadString(
          'assets/data/school_major_data.json',
        );
        final Map<String, dynamic> jsonData = json.decode(jsonString);
        schools = List<String>.from(jsonData['schools'] ?? []);
        majors = List<String>.from(jsonData['majors'] ?? []);
        print('✅ JSON 파일에서 데이터 로드 성공');
      } catch (e) {
        print('⚠️ JSON 파일 로드 실패, 기본 데이터 사용: $e');
        // JSON 파일을 읽을 수 없으면 기본 데이터 사용
        schools = [
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
        majors = [
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
      }

      // 학교 데이터 저장 (중복 방지)
      if (schoolsSnapshot.docs.isEmpty) {
        for (var school in schools) {
          // 중복 체크
          final existing = await _db
              .collection('schools')
              .where('name', isEqualTo: school)
              .limit(1)
              .get();

          if (existing.docs.isEmpty) {
            await _db.collection('schools').add({
              'name': school,
              'createdAt': FieldValue.serverTimestamp(),
            });
            print('✅ 학교 추가: $school');
          }
        }
      }

      // 전공 데이터 저장 (중복 방지)
      if (majorsSnapshot.docs.isEmpty) {
        for (var major in majors) {
          // 중복 체크
          final existing = await _db
              .collection('majors')
              .where('name', isEqualTo: major)
              .limit(1)
              .get();

          if (existing.docs.isEmpty) {
            await _db.collection('majors').add({
              'name': major,
              'createdAt': FieldValue.serverTimestamp(),
            });
            print('✅ 전공 추가: $major');
          }
        }
      }

      print('✅ 학교 및 전공 데이터 초기화 완료!');
    } catch (e) {
      print('❌ 학교 및 전공 데이터 초기화 실패: $e');
      rethrow;
    }
  }
}
