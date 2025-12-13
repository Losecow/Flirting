import 'package:flutter/foundation.dart';
import '../services/firestore_service.dart';

// 말투 스타일 관리 Provider
class SpeechStyleProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  String _selectedStyle = '친근한 말투';
  List<String> _availableStyles = [
    '친근한 말투',
    '존댓말',
    '반말',
    '귀여운 말투',
    '차분한 말투',
    '밝은 말투',
  ];

  String get selectedStyle => _selectedStyle;
  List<String> get availableStyles => _availableStyles;

  SpeechStyleProvider() {
    _loadStyle();
  }

  // 저장된 말투 스타일 로드
  Future<void> _loadStyle() async {
    try {
      final user = await _firestoreService.getCurrentUser();
      if (user != null && user['speechStyle'] != null) {
        _selectedStyle = user['speechStyle'] as String;
        notifyListeners();
      }
    } catch (e) {
      print('❌ 말투 스타일 로드 실패: $e');
    }
  }

  // 말투 스타일 선택
  Future<void> selectStyle(String style) async {
    if (!_availableStyles.contains(style)) return;

    _selectedStyle = style;
    notifyListeners();

    // Firestore에 저장
    try {
      final uid = await _firestoreService.getCurrentUser();
      if (uid != null) {
        await _firestoreService.upsertSpeechStyle(style);
      }
    } catch (e) {
      print('❌ 말투 스타일 저장 실패: $e');
    }
  }
}
