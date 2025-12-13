import 'package:flutter/foundation.dart';
import '../services/firestore_service.dart';

// 사용자 검색 및 목록 관리 Provider
class SearchProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  String _searchQuery = '';
  bool _isLoading = false;
  String? _currentUserId = '';
  String? _error;

  List<Map<String, dynamic>> get users => _users;
  List<Map<String, dynamic>> get filteredUsers => _filteredUsers;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get currentUserId => _currentUserId;
  String? get error => _error;

  Future<void> loadUsers({int limit = 50, String? searchQuery}) async {
    _setLoading(true);
    _error = null;
    try {
      final users = await _firestoreService.getOtherUsers(
        limit: limit,
        searchQuery: searchQuery,
      );

      final currentUser = await _firestoreService.getCurrentUser();
      if (currentUser != null) {
        _currentUserId = currentUser['id'] as String;

        final currentUserDoc = await _firestoreService.getUserDocument(
          _currentUserId!,
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

        final usersWithScore = users.map((user) {
          final appearanceStyles =
              (user['appearanceStyles'] as List<dynamic>?)?.cast<String>() ??
              [];
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
              .where(
                (personality) => preferredPersonality.contains(personality),
              )
              .length;

          return {...user, 'matchScore': score};
        }).toList();

        usersWithScore.sort(
          (a, b) => (b['matchScore'] as int).compareTo(a['matchScore'] as int),
        );

        _users = usersWithScore;
        _filteredUsers = usersWithScore;
      } else {
        _users = users;
        _filteredUsers = users;
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    if (query.isEmpty) {
      _filteredUsers = _users;
    } else {
      _performSearch(query);
    }
    notifyListeners();
  }

  Future<void> _performSearch(String query) async {
    await loadUsers(limit: 100, searchQuery: query);
  }

  FirestoreService get firestoreService => _firestoreService;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
