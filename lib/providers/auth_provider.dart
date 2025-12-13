import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 인증 상태 관리 Provider
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _init();
  }

  void _init() {
    _currentUser = _authService.currentUser;
    _authService.authStateChanges.listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  Future<UserCredential?> signInWithGoogle() async {
    _setLoading(true);
    try {
      final credential = await _authService.signInWithGoogle();
      if (credential != null) {
        _currentUser = credential.user;
        notifyListeners();
      }
      return credential;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _currentUser = null;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
