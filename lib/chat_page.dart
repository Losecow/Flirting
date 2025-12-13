import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'providers/chat_provider.dart';
import 'providers/speech_style_provider.dart';

class ChatPage extends StatefulWidget {
  final String targetUserId;
  final String targetUserName;
  final String? targetUserImageUrl;

  const ChatPage({
    super.key,
    required this.targetUserId,
    required this.targetUserName,
    this.targetUserImageUrl,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isConverting = false;
  bool _showConversionSuccess = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.startChat(widget.targetUserId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await chatProvider.sendMessage(text);

    _messageController.clear();
    _scrollToBottom();
  }

  Future<void> _convertAndSend() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isConverting = true;
    });

    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final speechStyleProvider = Provider.of<SpeechStyleProvider>(
        context,
        listen: false,
      );

      // AI로 말투 변환
      final convertedText = await chatProvider.convertSpeechStyle(
        text,
        speechStyleProvider.selectedStyle,
      );

      // 변환된 텍스트를 입력 필드에 표시 (사용자가 확인 후 전송 가능)
      _messageController.text = convertedText;

      // 커서를 텍스트 끝으로 이동
      _messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: convertedText.length),
      );

      if (mounted) {
        setState(() {
          _showConversionSuccess = true;
        });
        // 2초 후 자동으로 숨김
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _showConversionSuccess = false;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('말투 변환 실패: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConverting = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF3EFF8),
      appBar: AppBar(
        title: Row(
          children: [
            if (widget.targetUserImageUrl != null)
              CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(widget.targetUserImageUrl!),
              )
            else
              const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFFDF6FA),
                child: Icon(Icons.person, color: Color(0xFFC48EC4)),
              ),
            const SizedBox(width: 12),
            Text(
              widget.targetUserName,
              style: const TextStyle(
                color: Color(0xFFE94B9A),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFE94B9A)),
      ),
      body: Column(
        children: [
          // 말투 선택 바
          _buildSpeechStyleBar(),

          // 메시지 목록
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                if (chatProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (chatProvider.messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${widget.targetUserName}님과의 대화를 시작해보세요!',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(
                    horizontal: screenSize.width * 0.05,
                    vertical: 16,
                  ),
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (context, index) {
                    final message = chatProvider.messages[index];
                    return _buildMessageBubble(message, screenSize);
                  },
                );
              },
            ),
          ),

          // 메시지 입력 바
          Stack(
            children: [
              _buildMessageInputBar(screenSize),
              // 변환 완료 스낵바 (입력창 위)
              if (_showConversionSuccess)
                Positioned(
                  bottom: 80, // 입력창 높이 + 여유 공간
                  left: screenSize.width * 0.05,
                  right: screenSize.width * 0.05,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '말투가 변환되었습니다. 확인 후 전송 버튼을 눌러주세요.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpeechStyleBar() {
    return Consumer<SpeechStyleProvider>(
      builder: (context, speechStyleProvider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: Row(
            children: [
              const Icon(Icons.brush, size: 18, color: Color(0xFFE94B9A)),
              const SizedBox(width: 8),
              const Text(
                '말투:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: speechStyleProvider.availableStyles.map((style) {
                      final isSelected =
                          style == speechStyleProvider.selectedStyle;
                      return GestureDetector(
                        onTap: () {
                          speechStyleProvider.selectStyle(style);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFE94B9A)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            style,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, Size screenSize) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isMe = message['senderId'] == currentUserId;
    final text = message['text'] as String? ?? '';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: screenSize.width * 0.7),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFE94B9A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 15,
            color: isMe ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInputBar(Size screenSize) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenSize.width * 0.05,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: '메시지를 입력하세요...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFFDF6FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          // 수정 버튼 (텍스트가 있을 때만 표시)
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _messageController,
            builder: (context, value, child) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                onPressed: _isConverting ? null : _convertAndSend,
                icon: _isConverting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_fix_high, color: Color(0xFFE94B9A)),
                tooltip: 'AI로 말투 변환',
              );
            },
          ),
          // 전송 버튼
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE94B9A),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
