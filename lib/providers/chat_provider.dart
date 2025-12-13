import 'package:flutter/foundation.dart';
import '../services/firestore_service.dart';
import '../services/ai_service.dart';

// 채팅 상태 관리 Provider
class ChatProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final AIService _aiService = AIService();

  String? _currentChatUserId;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  String? _error;

  String? get currentChatUserId => _currentChatUserId;
  List<Map<String, dynamic>> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 채팅 시작
  Future<void> startChat(String targetUserId) async {
    _currentChatUserId = targetUserId;
    // 채팅방 생성 또는 가져오기
    await _firestoreService.createOrGetChatRoom(targetUserId);
    await loadMessages();
  }

  // 메시지 로드
  Future<void> loadMessages() async {
    if (_currentChatUserId == null) return;

    _setLoading(true);
    _error = null;
    try {
      _messages = await _firestoreService.getChatMessages(_currentChatUserId!);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // 메시지 전송
  Future<void> sendMessage(String text) async {
    if (_currentChatUserId == null || text.trim().isEmpty) return;

    try {
      await _firestoreService.sendChatMessage(_currentChatUserId!, text);
      await loadMessages(); // 메시지 목록 새로고침
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // AI로 말투 변환
  Future<String> convertSpeechStyle(String text, String style) async {
    try {
      return await _aiService.convertSpeechStyle(text, style);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // 채팅 종료
  void endChat() {
    _currentChatUserId = null;
    _messages = [];
    _error = null;
    notifyListeners();
  }

  // FirestoreService 직접 접근 (기존 코드 호환성)
  FirestoreService get firestoreService => _firestoreService;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
