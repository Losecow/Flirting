import 'dart:async';
import 'package:flutter/material.dart';
import 'services/firestore_service.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;
  String _currentUserId = '';
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _firestoreService.getOtherUsers(limit: 50);

      // 현재 사용자 ID 가져오기
      final currentUser = await _firestoreService.getCurrentUser();
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      _currentUserId = currentUser['id'] as String;

      // 현재 사용자의 선호도 정보 가져오기
      final currentUserDoc = await _firestoreService.getUserDocument(
        _currentUserId,
      );

      final currentUserData = currentUserDoc.data();
      final preferredAppearance =
          (currentUserData?['preferredAppearanceStyles'] as List<dynamic>?)
              ?.cast<String>() ??
          [];
      final preferredPersonality =
          (currentUserData?['preferredPersonalities'] as List<dynamic>?)
              ?.cast<String>() ??
          [];
      // final preferredHobbies = (currentUserData?['preferredHobbies'] as List<dynamic>?)?.cast<String>() ?? [];

      // 유사도 점수 계산 및 정렬
      final usersWithScore = users.map((user) {
        // 다른 사용자의 프로필 정보
        final appearanceStyles =
            (user['appearanceStyles'] as List<dynamic>?)?.cast<String>() ?? [];
        final styleKeywords =
            (user['styleKeywords'] as List<dynamic>?)?.cast<String>() ?? [];
        final personalityKeywords =
            (user['personalityKeywords'] as List<dynamic>?)?.cast<String>() ??
            [];

        // appearanceStyles와 styleKeywords를 합쳐서 외모 스타일로 사용
        final allAppearanceStyles = {
          ...appearanceStyles,
          ...styleKeywords,
        }.toList();

        int score = 0;
        // 선호 외모 스타일과 일치하는 개수
        score += allAppearanceStyles
            .where((style) => preferredAppearance.contains(style))
            .length;
        // 선호 성격과 일치하는 개수
        score += personalityKeywords
            .where((personality) => preferredPersonality.contains(personality))
            .length;
        // 취미는 아직 저장되지 않았으므로 일단 제외

        return {...user, 'matchScore': score};
      }).toList();

      // 점수 높은 순으로 정렬
      usersWithScore.sort(
        (a, b) => (b['matchScore'] as int).compareTo(a['matchScore'] as int),
      );

      setState(() {
        _users = usersWithScore;
        _filteredUsers = usersWithScore;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ 사용자 목록 로드 실패: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    // 이전 타이머 취소
    _searchDebounce?.cancel();

    // 검색어가 비어있으면 이미 로드된 전체 사용자 표시
    if (query.isEmpty) {
      setState(() {
        _filteredUsers = _users;
      });
      return;
    }

    // 500ms 후에 검색 실행 (debounce)
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Firestore에서 검색어로 검색
      final users = await _firestoreService.getOtherUsers(
        limit: 100,
        searchQuery: query,
      );

      // 현재 사용자 ID 가져오기
      final currentUser = await _firestoreService.getCurrentUser();
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      _currentUserId = currentUser['id'] as String;

      // 현재 사용자의 선호도 정보 가져오기
      final currentUserDoc = await _firestoreService.getUserDocument(
        _currentUserId,
      );
      final currentUserData = currentUserDoc.data();
      final preferredAppearance =
          (currentUserData?['preferredAppearanceStyles'] as List<dynamic>?)
              ?.cast<String>() ??
          [];
      final preferredPersonality =
          (currentUserData?['preferredPersonalities'] as List<dynamic>?)
              ?.cast<String>() ??
          [];

      // 유사도 점수 계산 및 정렬
      final usersWithScore = users.map((user) {
        final appearanceStyles =
            (user['appearanceStyles'] as List<dynamic>?)?.cast<String>() ?? [];
        final styleKeywords =
            (user['styleKeywords'] as List<dynamic>?)?.cast<String>() ?? [];
        final personalityKeywords =
            (user['personalityKeywords'] as List<dynamic>?)?.cast<String>() ??
            [];
        final allAppearanceStyles = {
          ...appearanceStyles,
          ...styleKeywords,
        }.toList();

        int score = 0;
        score += allAppearanceStyles
            .where((style) => preferredAppearance.contains(style))
            .length;
        score += personalityKeywords
            .where((personality) => preferredPersonality.contains(personality))
            .length;

        return {...user, 'matchScore': score};
      }).toList();

      usersWithScore.sort(
        (a, b) => (b['matchScore'] as int).compareTo(a['matchScore'] as int),
      );

      setState(() {
        _users = usersWithScore;
        _filteredUsers = usersWithScore;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ 검색 실패: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLike(String userId) async {
    try {
      await _firestoreService.addLike(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('좋아요를 보냈습니다!'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('좋아요 전송 실패: $e'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF3EFF8),
      body: SafeArea(
        child: Column(
          children: [
            // 상단 검색 영역
            _buildSearchSection(screenSize),

            // 중앙 프로필 카드 리스트
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '검색 결과가 없습니다',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenSize.width * 0.05,
                        vertical: screenSize.height * 0.02,
                      ),
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        return _buildProfileCard(
                          _filteredUsers[index],
                          screenSize,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // 검색 섹션
  Widget _buildSearchSection(Size screenSize) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenSize.width * 0.05,
        vertical: screenSize.height * 0.02,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: screenSize.width * 0.04,
        vertical: screenSize.height * 0.02,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '사람 찾기',
            style: TextStyle(
              color: Color(0xFFE94B9A),
              fontSize: 24,
              fontFamily: 'Bagel Fat One',
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '이름, 전공, 학교, 관심사로 검색해보세요',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: '이름, 전공, 학교, 취미 검색',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFFDF6FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: Colors.grey,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 프로필 카드
  Widget _buildProfileCard(Map<String, dynamic> user, Size screenSize) {
    final name = user['name'] as String? ?? '이름 없음';
    final age = user['age'] as int? ?? 0;
    final school = user['school'] as String? ?? '';
    final major = user['major'] as String? ?? '';
    final bio = user['bio'] as String? ?? '';
    final appearanceStyles =
        (user['appearanceStyles'] as List<dynamic>?)?.cast<String>() ?? [];
    final styleKeywords =
        (user['styleKeywords'] as List<dynamic>?)?.cast<String>() ?? [];
    final personalityKeywords =
        (user['personalityKeywords'] as List<dynamic>?)?.cast<String>() ?? [];

    // appearanceStyles와 styleKeywords를 합쳐서 표시
    final allAppearanceStyles = {
      ...appearanceStyles,
      ...styleKeywords,
    }.toList();

    return Container(
      margin: EdgeInsets.only(bottom: screenSize.height * 0.02),
      padding: EdgeInsets.all(screenSize.width * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 프로필 이미지 (임시 아이콘)
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFFDF6FA),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE0E0E0), width: 2),
              ),
              child: const Icon(
                Icons.person,
                size: 60,
                color: Color(0xFFC48EC4),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 기본 정보
          Center(
            child: Text(
              '$name, $age',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (school.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  school,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          if (major.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.school, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    major,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),

          // 자기소개
          if (bio.isNotEmpty)
            Container(
              width: double.infinity,
              height: 80,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF6FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: Text(
                  bio,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    height: 1.4,
                  ),
                  maxLines: null,
                ),
              ),
            ),
          const SizedBox(height: 16),

          // 태그들
          if (allAppearanceStyles.isNotEmpty) ...[
            _buildTagSection('외모 스타일', allAppearanceStyles),
            const SizedBox(height: 12),
          ],
          if (personalityKeywords.isNotEmpty) ...[
            _buildTagSection('성격', personalityKeywords),
            const SizedBox(height: 16),
          ],

          // 액션 버튼
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: const LinearGradient(
                colors: [Color(0xFFD6A4E0), Color(0xFFC0A0E0)],
              ),
            ),
            child: ElevatedButton.icon(
              onPressed: () => _handleLike(user['id'] as String),
              icon: const Icon(Icons.favorite_border, color: Colors.white),
              label: const Text(
                '좋아요',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 태그 섹션
  Widget _buildTagSection(String title, List<String> tags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF666666),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: tags.map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFD6A4E0),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                tag,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
