import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/firestore_service.dart';

/// 받은 좋아요 목록 페이지
class ReceivedLikesPage extends StatefulWidget {
  const ReceivedLikesPage({super.key});

  @override
  State<ReceivedLikesPage> createState() => _ReceivedLikesPageState();
}

class _ReceivedLikesPageState extends State<ReceivedLikesPage> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _receivedLikes = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _loadReceivedLikes();
  }

  Future<void> _loadCurrentUserId() async {
    final currentUser = await _firestoreService.getCurrentUser();
    if (currentUser != null) {
      setState(() {
        _currentUserId = currentUser['id'] as String;
      });
    }
  }

  Future<void> _loadReceivedLikes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final likes = await _firestoreService.getReceivedLikes();
      setState(() {
        _receivedLikes = likes;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ 받은 좋아요 목록 로드 실패: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label 아이디가 복사되었습니다: $text'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _handlePoke(String targetUserId) async {
    // Optimistic Update: 즉시 UI 업데이트
    setState(() {
      final userIndex = _receivedLikes.indexWhere((user) => user['id'] == targetUserId);
      if (userIndex != -1) {
        // 해당 사용자의 상태를 즉시 업데이트
        _receivedLikes[userIndex]['hasPokedByMe'] = true;
        _receivedLikes[userIndex]['canPoke'] = false; // 내가 마지막으로 찔렀으므로 비활성화
        final currentCount = (_receivedLikes[userIndex]['pokedByMeCount'] as int? ?? 0) + 1;
        _receivedLikes[userIndex]['pokedByMeCount'] = currentCount;
        if (_currentUserId != null) {
          _receivedLikes[userIndex]['lastPokedByMe'] = _currentUserId;
        }
        
        // 총 횟수 업데이트
        final pokedMeCount = _receivedLikes[userIndex]['pokedMeCount'] as int? ?? 0;
        _receivedLikes[userIndex]['totalPokeCount'] = currentCount + pokedMeCount;
      }
    });

    try {
      await _firestoreService.pokeUser(targetUserId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('콕 찌르기를 보냈습니다!'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
        // 백그라운드에서 목록 새로고침 (사용자 경험 개선)
        _loadReceivedLikes();
      }
    } catch (e) {
      // 실패 시 롤백
      if (mounted) {
        _loadReceivedLikes(); // 원래 상태로 복구
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('콕 찌르기 실패: $e'),
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
      appBar: AppBar(
        title: const Text(
          '받은 좋아요',
          style: TextStyle(
            color: Color(0xFFE94B9A),
            fontSize: 24,
            fontFamily: 'Bagel Fat One',
            fontWeight: FontWeight.w400,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _receivedLikes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.favorite_border,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '아직 받은 좋아요가 없습니다',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadReceivedLikes,
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenSize.width * 0.05,
                        vertical: screenSize.height * 0.02,
                      ),
                      itemCount: _receivedLikes.length,
                      itemBuilder: (context, index) {
                        final user = _receivedLikes[index];
                        return _buildUserCard(user, screenSize);
                      },
                    ),
                  ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, Size screenSize) {
    final name = user['name'] as String? ?? '이름 없음';
    final age = user['age'] as int? ?? 0;
    final school = user['school'] as String? ?? '';
    final major = user['major'] as String? ?? '';
    final userId = user['id'] as String;
    final hasProfileImage = user['profileImageUrl'] != null;
    final hasSharedInfo = user['hasSharedInfo'] as bool? ?? false;
    final hasPokedMe = user['hasPokedMe'] as bool? ?? false;
    final pokedByMeCount = user['pokedByMeCount'] as int? ?? 0;
    final pokedMeCount = user['pokedMeCount'] as int? ?? 0;
    final totalPokeCount = pokedByMeCount + pokedMeCount;
    final canPoke = user['canPoke'] as bool? ?? true; // 찌를 수 있는지 여부
    // 정보를 공개한 사용자의 연락처 정보 (sharedInstagramId, sharedKakaoId 사용)
    final instagramId = user['sharedInstagramId'] as String? ?? '';
    final kakaoId = user['sharedKakaoId'] as String? ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: screenSize.height * 0.02),
      padding: EdgeInsets.all(screenSize.width * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          // 프로필 헤더
          Row(
            children: [
              // 프로필 이미지
              Container(
                width: 60,
                height: 60,
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
                          image: NetworkImage(user['profileImageUrl'] as String),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: hasProfileImage
                    ? null
                    : const Icon(
                        Icons.person,
                        size: 30,
                        color: Color(0xFFC48EC4),
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (school.isNotEmpty)
                      Text(
                        school,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    if (major.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        major,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          
          // 콕 찌르기 표시 (상대방이 찔렀고, 내가 아직 다시 찌르지 않았을 때만)
          if (hasPokedMe && canPoke) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE94B9A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE94B9A).withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.touch_app,
                    color: Color(0xFFE94B9A),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$name님이 나를 콕 찔렀습니다',
                      style: const TextStyle(
                        color: Color(0xFFE94B9A),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 콕 찌르기 횟수 표시 (임시 - 나중에 Rive로 대체)
          if (totalPokeCount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFD6A4E0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFD6A4E0).withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.touch_app,
                    color: Color(0xFFD6A4E0),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '서로 콕 찌르기 $totalPokeCount회',
                    style: const TextStyle(
                      color: Color(0xFFD6A4E0),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 콕 찌르기 버튼
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: canPoke ? () => _handlePoke(userId) : null,
              icon: Icon(
                canPoke ? Icons.touch_app : Icons.check_circle,
                size: 18,
              ),
              label: Text(canPoke ? '콕 찌르기' : '콕 찔렀습니다'),
              style: ElevatedButton.styleFrom(
                backgroundColor: canPoke
                    ? const Color(0xFFD6A4E0)
                    : Colors.grey[300],
                foregroundColor: canPoke
                    ? Colors.white
                    : Colors.grey[600],
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey[300],
                disabledForegroundColor: Colors.grey[600],
              ),
            ),
          ),

          // 정보 공개 여부에 따른 연락처 표시
          if (hasSharedInfo) ...[
            const SizedBox(height: 12),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF6FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE94B9A).withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.verified,
                        color: Color(0xFFE94B9A),
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '정보 공개됨',
                        style: TextStyle(
                          color: Color(0xFFE94B9A),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (instagramId.isNotEmpty) ...[
                    _buildContactItem(
                      icon: Icons.camera_alt,
                      label: '인스타그램',
                      value: instagramId,
                      onCopy: () => _copyToClipboard(instagramId, '인스타그램'),
                    ),
                    if (kakaoId.isNotEmpty) const SizedBox(height: 8),
                  ],
                  if (kakaoId.isNotEmpty) ...[
                    _buildContactItem(
                      icon: Icons.chat_bubble_outline,
                      label: '카카오톡',
                      value: kakaoId,
                      onCopy: () => _copyToClipboard(kakaoId, '카카오톡'),
                    ),
                  ],
                  if (instagramId.isEmpty && kakaoId.isEmpty)
                    const Text(
                      '연락처 정보가 없습니다',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: Colors.grey,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '아직 정보가 공개되지 않았습니다',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onCopy,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFE94B9A), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            color: const Color(0xFFE94B9A),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onCopy,
          ),
        ],
      ),
    );
  }
}

