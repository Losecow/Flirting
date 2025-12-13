import 'package:flutter/foundation.dart';
import '../services/firestore_service.dart';

// 좋아요 관련 상태 관리 Provider
class LikesProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<String> _likedUserIds = [];
  List<Map<String, dynamic>> _receivedLikes = [];
  bool _isLoading = false;
  String? _error;

  List<String> get likedUserIds => _likedUserIds;
  List<Map<String, dynamic>> get receivedLikes => _receivedLikes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadLikedUserIds() async {
    _setLoading(true);
    _error = null;
    try {
      _likedUserIds = await _firestoreService.getLikedUserIds();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadReceivedLikes() async {
    _setLoading(true);
    _error = null;
    try {
      _receivedLikes = await _firestoreService.getReceivedLikes();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addLike(String targetUserId) async {
    try {
      await _firestoreService.addLike(targetUserId);
      _likedUserIds.add(targetUserId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  FirestoreService get firestoreService => _firestoreService;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
