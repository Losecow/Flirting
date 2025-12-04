import 'package:flutter/material.dart';
import 'services/firestore_service.dart';

class ProfileEditPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ProfileEditPage({super.key, required this.userData});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final FirestoreService _firestoreService = FirestoreService();
  
  // 입력 필드 컨트롤러
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _bioController;
  late TextEditingController _instagramController;
  late TextEditingController _kakaoController;
  
  // 선택된 값들
  String? _selectedSchool;
  String? _selectedMajor;
  final Set<String> _selectedAppearanceStyles = <String>{};
  final Set<String> _selectedStyleKeywords = <String>{};
  final Set<String> _selectedPersonalityKeywords = <String>{};
  final Set<String> _selectedHobbyOptions = <String>{};
  
  // 옵션 리스트
  List<String> _schoolOptions = [];
  List<String> _majorOptions = [];
  bool _isLoadingOptions = true;
  final List<String> _appearanceStyleOptions = [
    '깔끔한',
    '힙한',
    '캐주얼',
    '스트릿',
    '시크',
    '로맨틱',
  ];
  final List<String> _styleKeywordOptions = [
    '깔끔한',
    '힙한',
    '캐주얼',
    '스트릿',
    '시크',
    '로맨틱',
  ];
  final List<String> _personalityKeywordOptions = [
    '활발한',
    '차분한',
    '엉뚱한',
    '진지한',
    '유머러스한',
    '성실한',
  ];
  final List<String> _hobbyOptions = [
    '영화',
    '음악',
    '운동',
    '독서',
    '여행',
    '요리',
  ];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeFromUserData();
    _loadSchoolAndMajorData();
  }

  /// Firestore에서 학교 및 전공 목록 가져오기
  Future<void> _loadSchoolAndMajorData() async {
    try {
      final schools = await _firestoreService.getSchools();
      final majors = await _firestoreService.getMajors();
      
      if (mounted) {
        setState(() {
          _schoolOptions = schools;
          _majorOptions = majors;
          _isLoadingOptions = false;
          
          // 기존 선택된 값이 실제 목록에 있는지 확인
          // 없으면 null로 설정하여 오류 방지
          if (_selectedSchool != null && !schools.contains(_selectedSchool)) {
            print('⚠️ 선택된 학교 "${_selectedSchool}"가 목록에 없습니다. null로 설정합니다.');
            _selectedSchool = null;
          }
          if (_selectedMajor != null && !majors.contains(_selectedMajor)) {
            print('⚠️ 선택된 전공 "${_selectedMajor}"가 목록에 없습니다. null로 설정합니다.');
            _selectedMajor = null;
          }
        });
      }
    } catch (e) {
      print('❌ 학교/전공 데이터 로드 실패: $e');
      if (mounted) {
        setState(() {
          _isLoadingOptions = false;
        });
      }
    }
  }

  void _initializeFromUserData() {
    // 기존 데이터로 초기화
    _nameController = TextEditingController(text: widget.userData['name'] as String? ?? '');
    _ageController = TextEditingController(text: widget.userData['age']?.toString() ?? '');
    _bioController = TextEditingController(text: widget.userData['bio'] as String? ?? '');
    _instagramController = TextEditingController(text: widget.userData['instagramId'] as String? ?? '');
    _kakaoController = TextEditingController(text: widget.userData['kakaoId'] as String? ?? '');
    
    // 학교와 전공은 Firestore에서 로드한 후에 검증하므로 여기서는 임시로 설정
    _selectedSchool = widget.userData['school'] as String?;
    _selectedMajor = widget.userData['major'] as String?;
    
    final appearanceStyles = (widget.userData['appearanceStyles'] as List<dynamic>?)?.cast<String>() ?? [];
    final styleKeywords = (widget.userData['styleKeywords'] as List<dynamic>?)?.cast<String>() ?? [];
    final personalityKeywords = (widget.userData['personalityKeywords'] as List<dynamic>?)?.cast<String>() ?? [];
    final hobbyOptions = (widget.userData['hobbyOptions'] as List<dynamic>?)?.cast<String>() ?? [];
    
    _selectedAppearanceStyles.addAll(appearanceStyles);
    _selectedStyleKeywords.addAll(styleKeywords);
    _selectedPersonalityKeywords.addAll(personalityKeywords);
    _selectedHobbyOptions.addAll(hobbyOptions);
  }

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
        title: const Text(
          '프로필 수정',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenSize.width * 0.05,
            vertical: screenSize.height * 0.02,
          ),
          child: Column(
            children: [
              _buildSection(
                title: '기본 정보',
                children: [
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
                  _buildTextField(
                    label: '자기소개',
                    controller: _bioController,
                    hint: '간단한 자기소개를 써주세요',
                    maxLines: 4,
                  ),
                  SizedBox(height: screenSize.height * 0.02),
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
                ],
              ),
              SizedBox(height: screenSize.height * 0.02),
              _buildSection(
                title: '학교 정보',
                children: [
                  _buildDropdownField(
                    label: '학교',
                    hint: _isLoadingOptions ? '로딩 중...' : '학교를 선택하세요',
                    value: _selectedSchool,
                    items: _schoolOptions,
                    onChanged: _isLoadingOptions ? null : (value) {
                      setState(() {
                        _selectedSchool = value;
                      });
                    },
                  ),
                  SizedBox(height: screenSize.height * 0.02),
                  _buildDropdownField(
                    label: '전공',
                    hint: _isLoadingOptions ? '로딩 중...' : '전공을 선택하세요',
                    value: _selectedMajor,
                    items: _majorOptions,
                    onChanged: _isLoadingOptions ? null : (value) {
                      setState(() {
                        _selectedMajor = value;
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: screenSize.height * 0.02),
              _buildSection(
                title: '외모 스타일',
                children: [
                  _buildKeywordSelector(
                    options: _appearanceStyleOptions,
                    selectedOptions: _selectedAppearanceStyles,
                    maxSelections: 3,
                    onOptionTapped: (option) {
                      setState(() {
                        if (_selectedAppearanceStyles.contains(option)) {
                          _selectedAppearanceStyles.remove(option);
                        } else if (_selectedAppearanceStyles.length < 3) {
                          _selectedAppearanceStyles.add(option);
                        }
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: screenSize.height * 0.02),
              _buildSection(
                title: '스타일 키워드',
                children: [
                  _buildKeywordSelector(
                    options: _styleKeywordOptions,
                    selectedOptions: _selectedStyleKeywords,
                    maxSelections: null,
                    onOptionTapped: (option) {
                      setState(() {
                        if (_selectedStyleKeywords.contains(option)) {
                          _selectedStyleKeywords.remove(option);
                        } else {
                          _selectedStyleKeywords.add(option);
                        }
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: screenSize.height * 0.02),
              _buildSection(
                title: '성격',
                children: [
                  _buildKeywordSelector(
                    options: _personalityKeywordOptions,
                    selectedOptions: _selectedPersonalityKeywords,
                    maxSelections: null,
                    onOptionTapped: (option) {
                      setState(() {
                        if (_selectedPersonalityKeywords.contains(option)) {
                          _selectedPersonalityKeywords.remove(option);
                        } else {
                          _selectedPersonalityKeywords.add(option);
                        }
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: screenSize.height * 0.02),
              _buildSection(
                title: '취미/관심사',
                children: [
                  _buildKeywordSelector(
                    options: _hobbyOptions,
                    selectedOptions: _selectedHobbyOptions,
                    maxSelections: null,
                    onOptionTapped: (option) {
                      setState(() {
                        if (_selectedHobbyOptions.contains(option)) {
                          _selectedHobbyOptions.remove(option);
                        } else {
                          _selectedHobbyOptions.add(option);
                        }
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: screenSize.height * 0.03),
              _buildSaveButton(),
              SizedBox(height: screenSize.height * 0.02),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFE94B9A),
              fontSize: 20,
              fontFamily: 'Bagel Fat One',
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

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

  Widget _buildDropdownField({
    required String label,
    required String? hint,
    required String? value,
    required List<String> items,
    ValueChanged<String?>? onChanged,
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
          hint: hint != null ? Text(hint, style: const TextStyle(color: Colors.grey, fontSize: 13)) : null,
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

  Widget _buildKeywordSelector({
    required List<String> options,
    required Set<String> selectedOptions,
    int? maxSelections,
    required Function(String) onOptionTapped,
  }) {
    return Wrap(
      spacing: 10.0,
      runSpacing: 10.0,
      children: options.map((option) {
        final isSelected = selectedOptions.contains(option);
        final canSelect = maxSelections == null || selectedOptions.length < maxSelections || isSelected;

        return GestureDetector(
          onTap: canSelect ? () => onOptionTapped(option) : null,
          child: Opacity(
            opacity: canSelect ? 1.0 : 0.5,
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 40,
              ),
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
                mainAxisAlignment: MainAxisAlignment.center,
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
                    option,
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
    );
  }

  Widget _buildSaveButton() {
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
        onPressed: _isSaving ? null : _handleSave,
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
                '저장',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: 'Bagel Fat One',
                ),
              ),
      ),
    );
  }

  Future<void> _handleSave() async {
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
      // 학교 정보 저장
      if (_selectedSchool != null && _selectedMajor != null) {
        await _firestoreService.upsertSchoolInfo(
          school: _selectedSchool!,
          major: _selectedMajor!,
        );
      } else if (_selectedSchool != null || _selectedMajor != null) {
        // 둘 중 하나만 선택된 경우
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('학교와 전공을 모두 선택해주세요.'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() {
          _isSaving = false;
        });
        return;
      }

      // 프로필 정보 저장
      await _firestoreService.upsertProfileInfo(
        name: _nameController.text.trim(),
        age: int.tryParse(_ageController.text.trim()) ?? 0,
        bio: _bioController.text.trim(),
        appearanceStyles: _selectedAppearanceStyles.toList(),
      );

      // 연락처 정보 저장
      await _firestoreService.upsertContactInfo(
        instagramId: _instagramController.text.trim(),
        kakaoId: _kakaoController.text.trim(),
      );

      // 키워드 정보 저장
      await _firestoreService.upsertProfileKeywords(
        styleKeywords: _selectedStyleKeywords.toList(),
        personalityKeywords: _selectedPersonalityKeywords.toList(),
      );

      // 취미 정보 저장
      if (_selectedHobbyOptions.isNotEmpty) {
        await _firestoreService.upsertHobbyOptions(_selectedHobbyOptions.toList());
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('프로필이 수정되었습니다.'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('프로필 수정 중 오류가 발생했습니다: ${e.toString()}'),
          duration: const Duration(seconds: 3),
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
  }
}

