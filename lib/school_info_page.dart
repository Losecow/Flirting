import 'package:flutter/material.dart';
import 'profile_setting_page.dart';
import 'services/firestore_service.dart';
import 'main_navigation.dart';

class SchoolInfoPage extends StatefulWidget {
  const SchoolInfoPage({super.key});

  @override
  State<SchoolInfoPage> createState() => _SchoolInfoPageState();
}

class _SchoolInfoPageState extends State<SchoolInfoPage> {
  // 드롭다운 메뉴에서 선택된 값을 저장하기 위한 변수
  String? _selectedSchool;
  String? _selectedMajor;
  bool _isSaving = false;
  bool _isCheckingUser = true;

  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _checkExistingUser();
  }

  /// 기존 사용자 정보 확인
  Future<void> _checkExistingUser() async {
    try {
      final user = await _firestoreService.getCurrentUser();
      
      if (user != null && mounted) {
        // 사용자 정보가 있으면 MainNavigation으로 바로 이동
        final hasName = user['name'] != null && (user['name'] as String).isNotEmpty;
        final hasSchool = user['school'] != null && (user['school'] as String).isNotEmpty;
        
        if (hasName && hasSchool) {
          // 프로필이 완성된 사용자
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainNavigation()),
          );
          return;
        }
      }
    } catch (e) {
      print('❌ 사용자 정보 확인 실패: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingUser = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    
    if (_isCheckingUser) {
      return Scaffold(
        backgroundColor: const Color(0xFFF3EFF8),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFFF3EFF8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.of(context).pop(), // 뒤로가기 기능
        ),
        actions: const [], // 카메라 아이콘 제거
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenSize.width * 0.05,
            vertical: screenSize.height * 0.03,
          ),
          child: Center(
            child: _buildInfoCard(context),
          ),
        ),
      ),
    );
  }

  // 정보 입력 카드 위젯
  Widget _buildInfoCard(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    
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
            '학교 정보 설정',
            style: TextStyle(
              color: Color(0xFFE94B9A),
              fontSize: 28,
              fontFamily: 'Bagel Fat One',
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: screenSize.height * 0.015),
          const Text(
            '소속 학교와 전공을 선택해주세요',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
          SizedBox(height: screenSize.height * 0.03),

          // 학교 선택 드롭다운 메뉴
          _buildDropdownField(
            label: '학교',
            hint: '학교를 선택하세요',
            value: _selectedSchool,
            items: ['학교 A', '학교 B', '학교 C'], // 임시 데이터
            onChanged: (value) {
              setState(() {
                _selectedSchool = value;
              });
            },
          ),
          SizedBox(height: screenSize.height * 0.02),

          // 전공 선택 드롭다운 메뉴
          _buildDropdownField(
            label: '전공',
            hint: '전공을 선택하세요',
            value: _selectedMajor,
            items: ['전공 A', '전공 B', '전공 C'], // 임시 데이터
            onChanged: (value) {
              setState(() {
                _selectedMajor = value;
              });
            },
          ),
          SizedBox(height: screenSize.height * 0.03),

          // Next 버튼
          _buildNextButton(context),
        ],
      ),
    );
  }

  // 드롭다운 필드 위젯
  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
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
        DropdownButtonFormField<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          isExpanded: true,
          decoration: InputDecoration(
            fillColor: const Color(0xFFFDF6FA),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  // Next 버튼 위젯
  Widget _buildNextButton(BuildContext context) {
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
        // 학교 / 전공 정보 저장 후 다음 페이지로 이동
        onPressed: _isSaving
            ? null
            : () async {
                print('🔵 Next 버튼 클릭됨');
                print('   - 선택된 학교: $_selectedSchool');
                print('   - 선택된 전공: $_selectedMajor');
                
                if (_selectedSchool == null || _selectedMajor == null) {
                  print('⚠️ 학교 또는 전공이 선택되지 않음');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('학교와 전공을 모두 선택해주세요.'),
                        duration: Duration(seconds: 2),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                  return;
                }

                print('💾 Firestore 저장 시작...');
                setState(() {
                  _isSaving = true;
                });

                try {
                  await _firestoreService.upsertSchoolInfo(
                    school: _selectedSchool!,
                    major: _selectedMajor!,
                  );

                  print('✅ Firestore 저장 성공!');
                  
                  if (!mounted) {
                    print('⚠️ 위젯이 unmount됨');
                    return;
                  }

                  print('➡️ ProfileInfoPage로 이동');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileSettingPage(),
                    ),
                  );
                } catch (e, stackTrace) {
                  print('❌ Firestore 저장 실패: $e');
                  print('❌ Stack trace: $stackTrace');
                  
                  if (!mounted) return;
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('학교 정보 저장 중 오류가 발생했습니다: ${e.toString()}'),
                      duration: const Duration(seconds: 4),
                      backgroundColor: Colors.red,
                    ),
                  );
                } finally {
                  if (mounted) {
                    setState(() {
                      _isSaving = false;
                    });
                    print('🔄 _isSaving을 false로 설정');
                  }
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: const Text(
          'Next',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontFamily: 'Bagel Fat One',
          ),
        ),
      ),
    );
  }
}