import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';

class AuthService {
  GoogleSignIn _googleSignIn = GoogleSignIn();

  // Firebase가 초기화되었는지 확인
  bool get isFirebaseInitialized {
    try {
      Firebase.app();
      return true;
    } catch (e) {
      return false;
    }
  }

  // FirebaseAuth 인스턴스 가져오기 (초기화 확인 후)
  FirebaseAuth get _auth {
    if (!isFirebaseInitialized) {
      throw Exception('Firebase가 초기화되지 않았습니다. Firebase.initializeApp()을 먼저 호출하세요.');
    }
    return FirebaseAuth.instance;
  }

  // 현재 사용자 가져오기
  User? get currentUser {
    if (!isFirebaseInitialized) return null;
    return _auth.currentUser;
  }

  // 인증 상태 스트림
  Stream<User?> get authStateChanges {
    if (!isFirebaseInitialized) {
      return Stream.value(null);
    }
    return _auth.authStateChanges();
  }

  // 구글 로그인
  Future<UserCredential?> signInWithGoogle() async {
    if (!isFirebaseInitialized) {
      throw Exception('Firebase가 초기화되지 않았습니다. 앱을 다시 시작해주세요.');
    }

    try {
      // 구글 로그인 플로우 시작
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // 사용자가 로그인을 취소한 경우
        return null;
      }

      // 인증 정보 가져오기
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Firebase 인증을 위한 크리덴셜 생성
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase에 로그인
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('구글 로그인 오류: $e');
      rethrow;
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    final futures = <Future<void>>[];
    
    if (isFirebaseInitialized) {
      futures.add(_auth.signOut());
    }
    futures.add(_googleSignIn.signOut());
    
    await Future.wait(futures);
  }
}

