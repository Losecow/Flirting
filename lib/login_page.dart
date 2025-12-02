import 'package:flutter/material.dart';
import 'school_info_page.dart';
import 'services/auth_service.dart';

class ResponsiveLoginPage extends StatefulWidget {
  final bool firebaseInitialized;

  const ResponsiveLoginPage({super.key, this.firebaseInitialized = false});

  @override
  State<ResponsiveLoginPage> createState() => _ResponsiveLoginPageState();
}

class _ResponsiveLoginPageState extends State<ResponsiveLoginPage> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // 구글 로그인 처리
  Future<void> _handleGoogleSignIn() async {
    // Firebase 초기화 상태 다시 확인
    final isInitialized = _authService.isFirebaseInitialized;

    if (!widget.firebaseInitialized || !isInitialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Firebase가 초기화되지 않았습니다.\n'
              'widget.firebaseInitialized: ${widget.firebaseInitialized}\n'
              'authService.isInitialized: $isInitialized\n'
              'Xcode 콘솔에서 Firebase 초기화 메시지를 확인하세요.',
            ),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('❌ Firebase 초기화 상태 확인:');
      print('   - widget.firebaseInitialized: ${widget.firebaseInitialized}');
      print('   - authService.isFirebaseInitialized: $isInitialized');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential = await _authService.signInWithGoogle();

      if (userCredential != null && mounted) {
        // 로그인 성공 시 SchoolInfoPage로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SchoolInfoPage()),
        );
      } else if (mounted) {
        // 사용자가 로그인을 취소한 경우
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('로그인이 취소되었습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그인 중 오류가 발생했습니다: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFDECF4), Color(0xFFF8D6E9)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: screenSize.width * 0.05,
              vertical: screenSize.height * 0.03,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: screenSize.height * 0.05),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB6E1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withOpacity(0.2),
                        spreadRadius: 5,
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
                SizedBox(height: screenSize.height * 0.03),
                const Text(
                  '캠퍼스 매치',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF5B3F5B),
                    fontSize: 28,
                    fontFamily: 'Bagel Fat One',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: screenSize.height * 0.04),
                _buildLoginFormCard(context, screenSize),
                SizedBox(height: screenSize.height * 0.05),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginFormCard(BuildContext context, Size screenSize) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: screenSize.width * 0.9),
      padding: EdgeInsets.symmetric(
        horizontal: screenSize.width * 0.06,
        vertical: screenSize.height * 0.03,
      ),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Login',
            style: TextStyle(
              color: Color(0xFFE94B9A),
              fontSize: 28,
              fontFamily: 'Bagel Fat One',
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: screenSize.height * 0.04),
          _buildSocialButton(
            text: 'Google 로 시작하기',
            onPressed: _isLoading ? null : _handleGoogleSignIn,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.grey[700],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.grey[300]!),
          ),
          elevation: 0,
          disabledBackgroundColor: Colors.grey[200],
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }
}
