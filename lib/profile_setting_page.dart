import 'package:flutter/material.dart';
import 'services/firestore_service.dart';
import 'preference_style_page.dart';

class ProfileSettingPage extends StatefulWidget {
  const ProfileSettingPage({super.key});

  @override
  State<ProfileSettingPage> createState() => _ProfileSettingPageState();
}

class _ProfileSettingPageState extends State<ProfileSettingPage> {
  // 입력 필드 컨트롤러
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _kakaoController = TextEditingController();

  // 외모 스타일 선택 (최대 3개)
  final Set<String> _selectedAppearanceStyles = <String>{};
  final List<String> _appearanceStyleOptions = [
    '깔끔한',
    '힙한',
    '캐주얼',
    '스트릿',
    '시크',
    '로맨틱',
  ];

  bool _isSaving = false;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    _instagramController.dispose();
    _kakaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF3EFF8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: const [],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenSize.width * 0.05,
            vertical: screenSize.height * 0.03,
          ),
          child: Center(
            child: _buildInfoCard(context, screenSize),
          ),
        ),
      ),
    );
  }

  // 정보 입력 카드 위젯
  Widget _buildInfoCard(BuildContext context, Size screenSize) {
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
          // 타이틀
          Row(
            children: [
              const Icon(
                Icons.home_outlined,
                color: Color(0xFFE94B9A),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                '프로필 설정',
                style: TextStyle(
                  color: Color(0xFFE94B9A),
                  fontSize: 28,
                  fontFamily: 'Bagel Fat One',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          SizedBox(height: screenSize.height * 0.015),
          const Text(
            '자신에 대한 정보와 스타일을 설정해주세요',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: screenSize.height * 0.03),

          // 이름과 나이 (나란히)
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: '이름',
                  controller: _nameController,
                  hint: '이름을 입력하세요',
                ),
              ),
              SizedBox(width: screenSize.width * 0.03),
              Expanded(
                child: _buildTextField(
                  label: '나이',
                  controller: _ageController,
                  hint: '나이를 입력하세요',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          SizedBox(height: screenSize.height * 0.02),

          // 자기소개
          _buildTextField(
            label: '자기소개',
            controller: _bioController,
            hint: '간단한 자기소개를 써주세요',
            maxLines: 4,
          ),
          SizedBox(height: screenSize.height * 0.02),

          // 연락처 정보
          _buildTextField(
            label: '인스타그램 아이디',
            controller: _instagramController,
            hint: '@ 없이 입력하세요 (선택사항)',
          ),
          SizedBox(height: screenSize.height * 0.02),
          _buildTextField(
            label: '카카오톡 아이디',
            controller: _kakaoController,
            hint: '카카오톡 아이디를 입력하세요 (선택사항)',
          ),
          SizedBox(height: screenSize.height * 0.025),

          // 외모 스타일 선택 섹션
          _buildAppearanceStyleSection(screenSize),
          SizedBox(height: screenSize.height * 0.03),

          // Next 버튼
          _buildNextButton(context),
        ],
      ),
    );
  }

  // 텍스트 필드 위젯
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
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
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
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

  // 외모 스타일 선택 섹션
  Widget _buildAppearanceStyleSection(Size screenSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '외모 스타일',
          style: const TextStyle(
            color: Color(0xFF666666),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10.0,
          runSpacing: 10.0,
          children: _appearanceStyleOptions.map((style) {
            final isSelected = _selectedAppearanceStyles.contains(style);
            final canSelect = _selectedAppearanceStyles.length < 3 || isSelected;

            return GestureDetector(
              onTap: canSelect
                  ? () {
                      setState(() {
                        if (isSelected) {
                          _selectedAppearanceStyles.remove(style);
                        } else {
                          _selectedAppearanceStyles.add(style);
                        }
                      });
                    }
                  : null,
              child: Opacity(
                opacity: canSelect ? 1.0 : 0.5,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFD6A4E0)
                        : const Color(0xFFFDF6FA),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFC0A0E0)
                          : const Color(0xFFE0E0E0),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? Icons.check : Icons.add,
                        size: 16,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF666666),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        style,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF666666),
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          '${_selectedAppearanceStyles.length}/3 선택됨',
          style: const TextStyle(
            color: Color(0xFF666666),
            fontSize: 13,
          ),
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
        onPressed: _isSaving
            ? null
            : () async {
                print('🔵 프로필 설정 Next 버튼 클릭됨');
                print('   - 이름: ${_nameController.text}');
                print('   - 나이: ${_ageController.text}');
                print('   - 자기소개: ${_bioController.text}');
                print('   - 선택된 외모 스타일: $_selectedAppearanceStyles');

                // 유효성 검사
                if (_nameController.text.trim().isEmpty) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('이름을 입력해주세요.'),
                        duration: Duration(seconds: 2),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                  return;
                }

                if (_ageController.text.trim().isEmpty) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('나이를 입력해주세요.'),
                        duration: Duration(seconds: 2),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                  return;
                }

                setState(() {
                  _isSaving = true;
                });

                try {
                  // Firestore에 프로필 정보 저장
                  await _firestoreService.upsertProfileInfo(
                    name: _nameController.text.trim(),
                    age: int.tryParse(_ageController.text.trim()) ?? 0,
                    bio: _bioController.text.trim(),
                    appearanceStyles: _selectedAppearanceStyles.toList(),
                  );

                  // 연락처 정보 저장
                  if (_instagramController.text.trim().isNotEmpty || 
                      _kakaoController.text.trim().isNotEmpty) {
                    await _firestoreService.upsertContactInfo(
                      instagramId: _instagramController.text.trim(),
                      kakaoId: _kakaoController.text.trim(),
                    );
                  }

                  print('✅ 프로필 정보 저장 성공!');

                  if (!mounted) return;

                  // PreferenceStylePage로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PreferenceStylePage(),
                    ),
                  );
                } catch (e, stackTrace) {
                  print('❌ 프로필 정보 저장 실패: $e');
                  print('❌ Stack trace: $stackTrace');

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('프로필 정보 저장 중 오류가 발생했습니다: ${e.toString()}'),
                      duration: const Duration(seconds: 4),
                      backgroundColor: Colors.red,
                    ),
                  );
                } finally {
                  if (mounted) {
                    setState(() {
                      _isSaving = false;
                    });
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
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
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

