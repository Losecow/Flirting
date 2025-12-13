import 'package:flutter/material.dart';
import 'services/firestore_service.dart';
import 'chat_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _chatRooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChatRooms();
  }

  Future<void> _loadChatRooms() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _chatRooms = await _firestoreService.getChatRooms();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('❌ 채팅방 목록 로드 실패: $e');
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
      appBar: AppBar(
        title: const Text(
          '채팅',
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
        iconTheme: const IconThemeData(color: Color(0xFFE94B9A)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chatRooms.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '아직 채팅방이 없습니다',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '지도 탭에서 채팅을 시작해보세요!',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadChatRooms,
              child: ListView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: screenSize.width * 0.05,
                  vertical: 16,
                ),
                itemCount: _chatRooms.length,
                itemBuilder: (context, index) {
                  return _buildChatRoomCard(_chatRooms[index], screenSize);
                },
              ),
            ),
    );
  }

  Widget _buildChatRoomCard(Map<String, dynamic> chatRoom, Size screenSize) {
    final otherUser = chatRoom['otherUser'] as Map<String, dynamic>?;
    final lastMessage = chatRoom['lastMessage'] as String? ?? '';
    final unreadCount = chatRoom['unreadCount'] as int? ?? 0;

    if (otherUser == null) {
      return const SizedBox.shrink();
    }

    final name = otherUser['name'] as String? ?? '이름 없음';
    final profileImageUrl = otherUser['profileImageUrl'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFFFDF6FA),
          backgroundImage: profileImageUrl != null
              ? NetworkImage(profileImageUrl)
              : null,
          child: profileImageUrl == null
              ? const Icon(Icons.person, color: Color(0xFFC48EC4), size: 28)
              : null,
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          lastMessage,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: unreadCount > 0
            ? Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFE94B9A),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : null,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPage(
                targetUserId: otherUser['id'] as String,
                targetUserName: name,
                targetUserImageUrl: profileImageUrl,
              ),
            ),
          ).then((_) {
            // 채팅 페이지에서 돌아오면 목록 새로고침
            _loadChatRooms();
          });
        },
      ),
    );
  }
}
