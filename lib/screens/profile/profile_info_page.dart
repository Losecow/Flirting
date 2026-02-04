import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import 'profile_setting_page.dart';

class ProfileInfoPage extends StatefulWidget {
  const ProfileInfoPage({super.key});

  @override
  State<ProfileInfoPage> createState() => _ProfileInfoPageState();
}

class _ProfileInfoPageState extends State<ProfileInfoPage> {
  // 선택된 키워드들을 저장
  final Set<String> _selectedStyleKeywords = <String>{};
  final Set<String> _selectedPersonalityKeywords = <String>{};
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
          const Text(
            '프로필 정보 설정',
            style: TextStyle(
              color: Color(0xFFE94B9A),
              fontSize: 28,
              fontFamily: 'Bagel Fat One',
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: screenSize.height * 0.015),
          const Text(
            '자신을 가장 잘 나타내는 키워드를 선택해주세요',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: screenSize.height * 0.03),

          // 스타일 키워드 선택 섹션
          _buildKeywordSection(
            title: '어떤 스타일의 옷을 즐겨 입나요?',
            keywords: ['깔끔한', '힙한', '캐주얼', '스트릿', '시크', '로맨틱'],
            selectedKeywords: _selectedStyleKeywords,
            onKeywordTapped: (keyword) {
              setState(() {
                if (_selectedStyleKeywords.contains(keyword)) {
                  _selectedStyleKeywords.remove(keyword);
                } else {
                  _selectedStyleKeywords.add(keyword);
                }
              });
            },
          ),
          SizedBox(height: screenSize.height * 0.025),

          // 성격 키워드 선택 섹션
          _buildKeywordSection(
            title: '어떤 성격에 가까운가요?',
            keywords: ['활발한', '차분한', '엉뚱한', '진지한', '유머러스한', '성실한'],
            selectedKeywords: _selectedPersonalityKeywords,
            onKeywordTapped: (keyword) {
              setState(() {
                if (_selectedPersonalityKeywords.contains(keyword)) {
                  _selectedPersonalityKeywords.remove(keyword);
                } else {
                  _selectedPersonalityKeywords.add(keyword);
                }
              });
            },
          ),
          SizedBox(height: screenSize.height * 0.03),

          // 완료 버튼
          _buildCompleteButton(context),
        ],
      ),
    );
  }

  // 키워드 섹션 위젯
  Widget _buildKeywordSection({
    required String title,
    required List<String> keywords,
    required Set<String> selectedKeywords,
    required Function(String) onKeywordTapped,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFC48EC4),
            fontSize: 15,
            fontFamily: 'Bagel Fat One',
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10.0,
          runSpacing: 10.0,
          children: keywords.map((keyword) {
            final isSelected = selectedKeywords.contains(keyword);
            return GestureDetector(
              onTap: () => onKeywordTapped(keyword),
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
                child: Text(
                  keyword,
                  style: TextStyle(
                    color: isSelected 
                        ? Colors.white 
                        : const Color(0xFF666666),
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // 완료 버튼 위젯
  Widget _buildCompleteButton(BuildContext context) {
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
                setState(() {
                  _isSaving = true;
                });

                try {
                  await _firestoreService.upsertProfileKeywords(
                    styleKeywords: _selectedStyleKeywords.toList(),
                    personalityKeywords: _selectedPersonalityKeywords.toList(),
                  );

                  if (!mounted) return;

                  // ProfileSettingPage로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileSettingPage(),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('프로필 정보 저장 중 오류가 발생했습니다: $e'),
                      duration: const Duration(seconds: 3),
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
        child: const Text(
          '완료',
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



