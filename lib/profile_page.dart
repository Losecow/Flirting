import 'package:flutter/material.dart';
import 'services/firestore_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirestoreService _firestoreService = FirestoreService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _firestoreService.getCurrentUser();
      setState(() {
        _userData = user;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ 프로필 로드 실패: $e');
      setState(() {
        _isLoading = false;
      });
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
            : _userData == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          '프로필 정보를 불러올 수 없습니다',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadProfile,
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenSize.width * 0.05,
                      vertical: screenSize.height * 0.02,
                    ),
                    child: Column(
                      children: [
                        // 프로필 헤더 + 상세 정보 (하나의 카드)
                        _buildProfileCard(screenSize),
                      ],
                    ),
                  ),
      ),
    );
  }

  // 프로필 카드 (헤더 + 상세 정보 통합)
  Widget _buildProfileCard(Size screenSize) {
    final name = _userData!['name'] as String? ?? '이름 없음';
    final age = _userData!['age'] as int? ?? 0;
    final school = _userData!['school'] as String? ?? '';
    final major = _userData!['major'] as String? ?? '';
    final hasProfileImage = _userData!['profileImageUrl'] != null;
    final appearanceStyles = (_userData!['appearanceStyles'] as List<dynamic>?)?.cast<String>() ?? [];
    final styleKeywords = (_userData!['styleKeywords'] as List<dynamic>?)?.cast<String>() ?? [];
    final personalityKeywords = (_userData!['personalityKeywords'] as List<dynamic>?)?.cast<String>() ?? [];
    final hobbyOptions = (_userData!['hobbyOptions'] as List<dynamic>?)?.cast<String>() ?? [];

    // appearanceStyles와 styleKeywords를 합쳐서 외모 스타일로 사용
    final allAppearanceStyles = {...appearanceStyles, ...styleKeywords}.toList();

    return Container(
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
          // 타이틀
          const Text(
            '내 프로필',
            style: TextStyle(
              color: Color(0xFFE94B9A),
              fontSize: 28,
              fontFamily: 'Bagel Fat One',
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 20),

          // 프로필 이미지 + 기본 정보
          Row(
            children: [
              // 프로필 이미지
              GestureDetector(
                onTap: () {
                  // TODO: 프로필 이미지 업로드 기능
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('프로필 이미지 업로드 기능은 준비 중입니다.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: hasProfileImage
                            ? Colors.transparent
                            : const Color(0xFFFDF6FA),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFE0E0E0),
                          width: 2,
                        ),
                        image: hasProfileImage
                            ? DecorationImage(
                                image: NetworkImage(_userData!['profileImageUrl'] as String),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: hasProfileImage
                          ? null
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.camera_alt,
                                  size: 30,
                                  color: Color(0xFFC48EC4),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '이미지\n등록',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: const Color(0xFFC48EC4),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    if (!hasProfileImage)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE94B9A),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: screenSize.width * 0.04),

              // 기본 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$name, $age',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (school.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              school,
                              style: const TextStyle(color: Colors.grey, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    if (major.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
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
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 프로필 상세 정보 (태그들)
          if (allAppearanceStyles.isNotEmpty) ...[
            _buildTagSection('외모 스타일', allAppearanceStyles),
            const SizedBox(height: 20),
          ],
          if (personalityKeywords.isNotEmpty) ...[
            _buildTagSection('성격', personalityKeywords),
            const SizedBox(height: 20),
          ],
          if (hobbyOptions.isNotEmpty) ...[
            _buildTagSection('취미/관심사', hobbyOptions),
          ],
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
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFD6A4E0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tag,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
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

