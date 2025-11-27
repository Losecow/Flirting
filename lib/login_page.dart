import 'package:flutter/material.dart';
import 'info_page.dart'; // 1. 새로 만든 페이지 import

class ResponsiveLoginPage extends StatelessWidget {
  const ResponsiveLoginPage({super.key});

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

  // 3. context를 매개변수로 받도록 수정
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
          SizedBox(height: screenSize.height * 0.01),
          // Text(
          //   'login ha sem mosol dlc a.',
          //   style: TextStyle(
          //     color: const Color(0xFFE94B9A).withOpacity(0.7),
          //     fontSize: 13,
          //   ),
          // ),
          SizedBox(height: screenSize.height * 0.025),
          _buildTextField(label: 'ID', hint: 'ID를 입력하세요'),
          SizedBox(height: screenSize.height * 0.02),
          // obscureText: true 추가
          _buildTextField(label: 'PW', hint: 'PW를 입력하세요', obscureText: true),
          SizedBox(height: screenSize.height * 0.025),
          // 4. context를 _buildLoginButton에 전달
          _buildLoginButton(context),
          SizedBox(height: screenSize.height * 0.02),
          _buildSocialButton(text: 'Google 로 시작하기'),
          SizedBox(height: screenSize.height * 0.015),
          _buildSocialButton(text: '카카오로 시작하기'),
        ],
      ),
    );
  }

  // obscureText 파라미터 추가
  Widget _buildTextField({
    required String label,
    required String hint,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFC48EC4),
            fontSize: 15,
            fontFamily: 'Bagel Fat One',
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          obscureText: obscureText, // 비밀번호 필드를 위해 추가
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFFDF6FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  // 5. context를 매개변수로 받도록 수정
  Widget _buildLoginButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(
          colors: [Color(0xFFD6A4E0), Color(0xFFC0A0E0)],
        ),
      ),
      child: ElevatedButton(
        // 6. onPressed 이벤트에 페이지 이동 코드 추가
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const InfoPage()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: const Text(
          'Login',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontFamily: 'Bagel Fat One',
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({required String text}) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.grey[700],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.grey[300]!),
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }
}
