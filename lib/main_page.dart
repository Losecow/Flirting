import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart' hide LinearGradient, Image;
import 'services/firestore_service.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController();

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;
  String _currentUserId = '';
  Timer? _searchDebounce;
  
  // 각 사용자별 Rive 애니메이션 컨트롤러 관리
  final Map<String, StateMachineController> _riveControllers = {};
  final Map<String, SMIInput<bool>?> _isLikedInputs = {};
  
  // 확장된 프로필 ID 목록 (세부사항이 보이는 프로필)
  final Set<String> _expandedProfiles = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    // 모든 Rive 컨트롤러 정리
    for (var controller in _riveControllers.values) {
      controller.dispose();
    }
    _riveControllers.clear();
    _isLikedInputs.clear();
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
    // 버튼 클릭 시 즉시 Rive 애니메이션 트리거
    print('❤️ 좋아요 버튼 클릭: $userId');
    print('🔍 Input 상태: ${_isLikedInputs[userId]?.value}');
    
    bool? currentValue;
    if (_isLikedInputs[userId] != null) {
      // toggle 방식
      currentValue = _isLikedInputs[userId]!.value;
      _isLikedInputs[userId]!.value = !currentValue;
      print('✅ Input 값 변경: $currentValue → ${!currentValue}');
    } else {
      print('⚠️ Input이 null입니다. 컨트롤러: ${_riveControllers[userId] != null}');
    }
    
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
      // 실패 시 애니메이션 되돌리기
      if (currentValue != null && _isLikedInputs[userId] != null) {
        _isLikedInputs[userId]!.value = currentValue;
      }
      
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
                : Column(
                    children: [
                      // 검색 섹션
                      _buildSearchSection(screenSize),

                      // 프로필 카드 (스와이프 가능)
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          scrollDirection: Axis.vertical,
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenSize.width * 0.05,
                        vertical: screenSize.height * 0.02,
                      ),
                              child: _buildProfileCard(
                          _filteredUsers[index],
                          screenSize,
                              ),
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
      margin: EdgeInsets.only(
        left: screenSize.width * 0.05,
        right: screenSize.width * 0.05,
        top: screenSize.height * 0.01,
        bottom: screenSize.height * 0.01,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: screenSize.width * 0.04,
        vertical: screenSize.height * 0.015,
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
            style: TextStyle(color: Colors.grey, fontSize: 11),
          ),
          const SizedBox(height: 10),
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
  Widget _buildProfileCard(
    Map<String, dynamic> user,
    Size screenSize,
  ) {
    final name = user['name'] as String? ?? '이름 없음';
    final age = user['age'] as int? ?? 0;
    final school = user['school'] as String? ?? '';
    final major = user['major'] as String? ?? '';
    final bio = user['bio'] as String? ?? '';
    final profileImageUrl = user['profileImageUrl'] as String?;
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Stack(
          fit: StackFit.expand,
        children: [
            // 프로필 이미지 배경
            profileImageUrl != null && profileImageUrl.isNotEmpty
                ? Image.network(
                    profileImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFFFDF6FA),
                        child: const Icon(
                          Icons.person,
                          size: 100,
                          color: Color(0xFFC48EC4),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                color: const Color(0xFFFDF6FA),
                        child: const Center(
                          child: CircularProgressIndicator(),
              ),
                      );
                    },
                  )
                : Container(
                    color: const Color(0xFFFDF6FA),
              child: const Icon(
                Icons.person,
                      size: 100,
                color: Color(0xFFC48EC4),
                    ),
                  ),

            // 그라데이션 오버레이 (텍스트 가독성 향상)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // 콘텐츠
            Padding(
              padding: EdgeInsets.all(screenSize.width * 0.05),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          // 기본 정보
                  Text(
              '$name, $age',
              style: const TextStyle(
                      fontSize: 24,
                fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 3,
                          color: Colors.black54,
                        ),
                      ],
            ),
          ),
          const SizedBox(height: 8),
          if (school.isNotEmpty)
            Row(
              children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.white70,
                        ),
                const SizedBox(width: 4),
                Text(
                  school,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 2,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                ),
              ],
            ),
          if (major.isNotEmpty)
            Row(
              children: [
                        const Icon(
                          Icons.school,
                          size: 16,
                          color: Colors.white70,
                        ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    major,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                  color: Colors.black54,
                                ),
                              ],
                            ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
                  const SizedBox(height: 12),

                  // 자기소개 (탭 가능)
          if (bio.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          final userId = user['id'] as String;
                          if (_expandedProfiles.contains(userId)) {
                            _expandedProfiles.remove(userId);
                          } else {
                            _expandedProfiles.add(userId);
                          }
                        });
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
              width: double.infinity,
                            constraints: const BoxConstraints(maxHeight: 80),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
              ),
                            child: Row(
                              children: [
                                Expanded(
              child: SingleChildScrollView(
                child: Text(
                  bio,
                  style: const TextStyle(
                                        color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                                        shadows: [
                                          Shadow(
                                            offset: Offset(0, 1),
                                            blurRadius: 2,
                                            color: Colors.black54,
                                          ),
                                        ],
                  ),
                  maxLines: null,
                ),
              ),
            ),
                                const SizedBox(width: 8),
                                Icon(
                                  _expandedProfiles.contains(user['id'] as String)
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),

                  // 태그들 (확장 시에만 표시)
                  if (_expandedProfiles.contains(user['id'] as String)) ...[
          if (allAppearanceStyles.isNotEmpty) ...[
                      _buildTagSectionOverlay('외모 스타일', allAppearanceStyles),
                      const SizedBox(height: 8),
                    ],
                    if (personalityKeywords.isNotEmpty) ...[
                      _buildTagSectionOverlay('성격', personalityKeywords),
            const SizedBox(height: 12),
          ],
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
            child: ElevatedButton(
              onPressed: () => _handleLike(user['id'] as String),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _handleLike(user['id'] as String),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: ClipRect(
                    child: RiveAnimation.asset(
                          'assets/rive/9864-18818-heart-like.riv',
                          fit: BoxFit.contain,
                      onInit: (artboard) {
                            print('🎬 Rive onInit 호출됨!');
                        final userId = user['id'] as String;
                            print('👤 User ID: $userId');
                            
                            // 사용 가능한 State Machine 확인
                            print('🔍 Rive State Machines: ${artboard.stateMachines.map((sm) => sm.name).toList()}');
                            print('🔍 Rive Animations: ${artboard.animations.map((a) => a.name).toList()}');
                            
                            // State Machine이 있는 경우
                            if (artboard.stateMachines.isNotEmpty) {
                              // State Machine 찾기 (여러 이름 시도)
                              StateMachineController? controller;
                              final stateMachineNames = ['State Machine 1', 'StateMachine1', 'State Machine'];
                              
                              for (final name in stateMachineNames) {
                                try {
                                  controller = StateMachineController.fromArtboard(artboard, name);
                                  if (controller != null) {
                                    print('✅ State Machine found: $name');
                                    break;
                                  }
                                } catch (e) {
                                  print('⚠️ State Machine 찾기 실패 ($name): $e');
                                }
                              }
                              
                              if (controller == null && artboard.stateMachines.isNotEmpty) {
                                // 첫 번째 State Machine 사용
                                try {
                                  final firstSMName = artboard.stateMachines.first.name;
                                  controller = StateMachineController.fromArtboard(artboard, firstSMName);
                                  print('✅ Using first State Machine: $firstSMName');
                                } catch (e) {
                                  print('❌ 첫 번째 State Machine 사용 실패: $e');
                                }
                              }
                              
                        if (controller != null) {
                          artboard.addController(controller);
                          _riveControllers[userId] = controller;
                                print('✅ Controller 추가됨: $userId');
                                
                                // 사용 가능한 모든 Input 출력
                                print('🔍 Available inputs: ${controller.inputs.map((i) => '${i.name} (${i.runtimeType})').toList()}');
                                
                                // Input 찾기 (여러 이름 시도)
                                final inputNames = ['isLiked', 'liked', 'click', 'trigger', 'pressed', 'tap'];
                                SMIInput<bool>? input;
                                
                                for (final name in inputNames) {
                                  try {
                                    input = controller.findInput<bool>(name);
                                    if (input != null) {
                                      print('✅ Input found: $name');
                                      break;
                                    }
                                  } catch (e) {
                                    // Input 타입이 다를 수 있음
                                  }
                                }
                                
                                _isLikedInputs[userId] = input;
                                
                                if (input == null) {
                                  print('⚠️ Boolean input not found. Available inputs: ${controller.inputs.map((i) => '${i.name} (${i.runtimeType})').toList()}');
                                  // 모든 Input을 확인해보기
                                  for (final inputItem in controller.inputs) {
                                    print('  - ${inputItem.name}: ${inputItem.runtimeType}');
                                  }
                                } else {
                                  print('✅ Input 설정 완료: ${input.name} = ${input.value}');
                                }
                              } else {
                                print('❌ State Machine Controller not found');
                              }
                            } else {
                              print('⚠️ State Machine이 없습니다. Animation을 사용합니다.');
                              // State Machine이 없으면 첫 번째 Animation 사용
                              if (artboard.animations.isNotEmpty) {
                                final animationName = artboard.animations.first.name;
                                print('✅ Using animation: $animationName');
                                // SimpleAnimation은 여기서는 사용하지 않고, 클릭 시 직접 제어
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '좋아요',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 태그 섹션 (오버레이용)
  Widget _buildTagSectionOverlay(String title, List<String> tags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 2,
                color: Colors.black54,
              ),
            ],
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
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Text(
                tag,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 2,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
