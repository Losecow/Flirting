import 'package:flutter/material.dart';
import 'main_page.dart';
import 'profile_page.dart';
import 'likes_page.dart';
import 'services/location_service.dart';
import 'services/firestore_service.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 1; // 기본값은 검색 페이지
  final LocationService _locationService = LocationService();
  final FirestoreService _firestoreService = FirestoreService();
  bool _hasCollectedLocation = false;

  // LikesPage는 지연 생성 (Google Maps 초기화 충돌 방지)
  Widget? _likesPage;

  @override
  void initState() {
    super.initState();
    // 앱이 완전히 로드된 후 위치 수집 (Google Maps 초기화 충돌 방지)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 1), () {
        _collectAndSaveLocation();
      });
    });
  }

  /// 위치 수집 및 저장
  Future<void> _collectAndSaveLocation() async {
    // 이미 수집했으면 다시 수집하지 않음
    if (_hasCollectedLocation) return;

    try {
      // 위치 수집 시도 (에러가 발생해도 앱이 멈추지 않도록)
      final position = await _locationService.getCurrentLocation().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('⚠️ 위치 수집 타임아웃');
          return null;
        },
      );

      if (position != null && mounted) {
        await _firestoreService.upsertLocation(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        _hasCollectedLocation = true;
        print('✅ 위치 수집 및 저장 완료');
      } else {
        print('⚠️ 위치 수집 실패 또는 권한 거부');
      }
    } catch (e, stackTrace) {
      print('❌ 위치 수집 및 저장 중 오류: $e');
      print('❌ Stack trace: $stackTrace');
      // 에러가 발생해도 앱은 계속 실행되도록 함
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return const ProfilePage();
      case 1:
        return const MainPage();
      case 2:
        // LikesPage는 처음 접근할 때만 생성 (Google Maps 초기화 충돌 방지)
        _likesPage ??= const LikesPage();
        return _likesPage!;
      default:
        return const MainPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getPage(_currentIndex), // 지연 생성된 페이지 표시
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.person, '프로필', 0),
            _buildNavItem(Icons.search, '검색', 1),
            _buildNavItem(Icons.favorite_border, '좋아요', 2),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFFE94B9A) : Colors.grey,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFFE94B9A) : Colors.grey,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
