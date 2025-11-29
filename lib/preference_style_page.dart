import 'package:flutter/material.dart';
import 'services/firestore_service.dart';
import 'main_navigation.dart';

class PreferenceStylePage extends StatefulWidget {
  const PreferenceStylePage({super.key});

  @override
  State<PreferenceStylePage> createState() => _PreferenceStylePageState();
}

class _PreferenceStylePageState extends State<PreferenceStylePage> {
  // 선호하는 외모 스타일 (최대 3개)
  final Set<String> _preferredAppearanceStyles = <String>{};
  final List<String> _appearanceStyleOptions = [
    '깔끔한',
    '힙한',
    '캐주얼',
    '스트릿',
    '시크',
    '로맨틱',
  ];

  // 선호하는 성격 (최대 3개)
  final Set<String> _preferredPersonalities = <String>{};
  final List<String> _personalityOptions = [
    '활발한',
    '차분한',
    '엉뚱한',
    '진지한',
    '유머러스한',
    '성실한',
  ];

  // 선호하는 취미/관심사 (최대 3개)
  final Set<String> _preferredHobbies = <String>{};
  final List<String> _hobbyOptions = [
    '영화',
    '음악',
    '운동',
    '독서',
    '여행',
    '요리',
  ];

  bool _isSaving = false;
  final FirestoreService _firestoreService = FirestoreService();

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
                Icons.favorite_border,
                color: Color(0xFFE94B9A),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                '선호 스타일 설정',
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
            '어떤 스타일의 사람과 만나고 싶으신가요?',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: screenSize.height * 0.03),

          // 선호하는 외모 스타일
          _buildPreferenceSection(
            title: '선호하는 외모 스타일',
            options: _appearanceStyleOptions,
            selectedOptions: _preferredAppearanceStyles,
            onOptionTapped: (option) {
              setState(() {
                if (_preferredAppearanceStyles.contains(option)) {
                  _preferredAppearanceStyles.remove(option);
                } else if (_preferredAppearanceStyles.length < 3) {
                  _preferredAppearanceStyles.add(option);
                }
              });
            },
          ),
          SizedBox(height: screenSize.height * 0.025),

          // 선호하는 성격
          _buildPreferenceSection(
            title: '선호하는 성격',
            options: _personalityOptions,
            selectedOptions: _preferredPersonalities,
            onOptionTapped: (option) {
              setState(() {
                if (_preferredPersonalities.contains(option)) {
                  _preferredPersonalities.remove(option);
                } else if (_preferredPersonalities.length < 3) {
                  _preferredPersonalities.add(option);
                }
              });
            },
          ),
          SizedBox(height: screenSize.height * 0.025),

          // 선호하는 취미/관심사
          _buildPreferenceSection(
            title: '선호하는 취미/관심사',
            options: _hobbyOptions,
            selectedOptions: _preferredHobbies,
            onOptionTapped: (option) {
              setState(() {
                if (_preferredHobbies.contains(option)) {
                  _preferredHobbies.remove(option);
                } else if (_preferredHobbies.length < 3) {
                  _preferredHobbies.add(option);
                }
              });
            },
          ),
          SizedBox(height: screenSize.height * 0.02),

          // 팁 박스
          _buildTipBox(),
          SizedBox(height: screenSize.height * 0.03),

          // Next 버튼
          _buildNextButton(context),
        ],
      ),
    );
  }

  // 선호 스타일 섹션 위젯
  Widget _buildPreferenceSection({
    required String title,
    required List<String> options,
    required Set<String> selectedOptions,
    required Function(String) onOptionTapped,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
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
          children: options.map((option) {
            final isSelected = selectedOptions.contains(option);
            final canSelect = selectedOptions.length < 3 || isSelected;

            return GestureDetector(
              onTap: canSelect ? () => onOptionTapped(option) : null,
              child: Opacity(
                opacity: canSelect ? 1.0 : 0.5,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFD6A4E0)
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
                            ? const Color(0xFFD6A4E0)
                            : const Color(0xFF666666),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        option,
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFFD6A4E0)
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
          '${selectedOptions.length}/3 선택됨',
          style: const TextStyle(
            color: Color(0xFF666666),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // 팁 박스 위젯
  Widget _buildTipBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: Color(0xFF9C27B0),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '팁: 너무 구체적으로 선택하면 매칭될 수 있는 사람이 줄어들 수 있어요. 가장 중요한 스타일들을 선택해주세요!',
              style: const TextStyle(
                color: Color(0xFF1565C0),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
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
                print('🔵 선호 스타일 Next 버튼 클릭됨');
                print('   - 선호 외모: $_preferredAppearanceStyles');
                print('   - 선호 성격: $_preferredPersonalities');
                print('   - 선호 취미: $_preferredHobbies');

                setState(() {
                  _isSaving = true;
                });

                try {
                  // Firestore에 선호 스타일 저장
                  await _firestoreService.upsertPreferenceStyles(
                    preferredAppearanceStyles: _preferredAppearanceStyles.toList(),
                    preferredPersonalities: _preferredPersonalities.toList(),
                    preferredHobbies: _preferredHobbies.toList(),
                  );

                  print('✅ 선호 스타일 저장 성공!');

                  if (!mounted) return;

                  // 메인 네비게이션으로 이동 (모든 설정 완료)
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const MainNavigation()),
                    (route) => false, // 이전 페이지들 모두 제거
                  );
                } catch (e, stackTrace) {
                  print('❌ 선호 스타일 저장 실패: $e');
                  print('❌ Stack trace: $stackTrace');

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('선호 스타일 저장 중 오류가 발생했습니다: ${e.toString()}'),
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

