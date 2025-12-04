import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'services/firestore_service.dart';
import 'smile_detection_page.dart';

class LikesPage extends StatefulWidget {
  const LikesPage({super.key});

  @override
  State<LikesPage> createState() => _LikesPageState();
}

class _LikesPageState extends State<LikesPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final Map<String, Marker> _markers = {};
  final Map<String, Circle> _circles = {};
  final Map<String, Map<String, dynamic>> _likedUsersData = {};
  GoogleMapController? _mapController;
  LatLng? _currentUserLocation;

  // 반경 1km (미터 단위)
  static const double _radiusInMeters = 1000.0;

  /// 두 지점 간의 거리 계산 (미터 단위, Haversine 공식)
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // 지구 반경 (미터)

    final double lat1Rad = point1.latitude * pi / 180;
    final double lat2Rad = point2.latitude * pi / 180;
    final double deltaLatRad = (point2.latitude - point1.latitude) * pi / 180;
    final double deltaLngRad = (point2.longitude - point1.longitude) * pi / 180;

    final double a =
        sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) *
            cos(lat2Rad) *
            sin(deltaLngRad / 2) *
            sin(deltaLngRad / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// 반경 1km 안에 있는 사용자인지 확인
  bool _isWithinRadius(LatLng userLocation, LatLng targetLocation) {
    final distance = _calculateDistance(userLocation, targetLocation);
    return distance <= _radiusInMeters;
  }

  Future<void> _loadLikedUsers() async {
    try {
      // 현재 사용자 위치 가져오기
      final currentUser = await _firestoreService.getCurrentUser();
      if (currentUser == null) {
        setState(() {
          _markers.clear();
          _circles.clear();
        });
        return;
      }

      final currentLat = currentUser['latitude'] as double?;
      final currentLng = currentUser['longitude'] as double?;

      if (currentLat == null || currentLng == null) {
        setState(() {
          _markers.clear();
          _circles.clear();
        });
        return;
      }

      _currentUserLocation = LatLng(currentLat, currentLng);

      // 좋아요한 사용자 ID 목록 가져오기
      final likedUserIds = await _firestoreService.getLikedUserIds();

      if (likedUserIds.isEmpty) {
        setState(() {
          _markers.clear();
          _circles.clear();
        });
        return;
      }

      // 좋아요한 사용자들의 정보 가져오기
      final likedUsers = <Map<String, dynamic>>[];
      for (final userId in likedUserIds) {
        try {
          final userDoc = await _firestoreService.getUserDocument(userId);
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            userData['id'] = userDoc.id;
            likedUsers.add(userData);
          }
        } catch (e) {
          print('❌ 사용자 정보 가져오기 실패 ($userId): $e');
        }
      }

      // 지도에 마커 추가 (반경 1km 안에 있는 사용자만)
      if (mounted) {
        setState(() {
          _markers.clear();
          _likedUsersData.clear();

          for (final user in likedUsers) {
            final name = user['name'] as String? ?? '이름 없음';
            final latitude = user['latitude'] as double?;
            final longitude = user['longitude'] as double?;

            // 위치 정보가 있는 경우에만 처리
            if (latitude != null && longitude != null) {
              final userLocation = LatLng(latitude, longitude);

              // 반경 1km 안에 있는 사용자만 마커 추가
              if (_isWithinRadius(_currentUserLocation!, userLocation)) {
                final userId = user['id'] as String;

                // 사용자 데이터 저장 (모달에서 사용)
                _likedUsersData[userId] = user;

                final marker = Marker(
                  markerId: MarkerId(userId),
                  position: userLocation,
                  infoWindow: InfoWindow(
                    title: name,
                    snippet: user['school'] as String? ?? '',
                  ),
                  onTap: () => _showProfileModal(user),
                );
                _markers[userId] = marker;
              }
            }
          }

          // 반경 1km 원 추가
          _circles['radius'] = Circle(
            circleId: const CircleId('radius'),
            center: _currentUserLocation!,
            radius: _radiusInMeters,
            fillColor: const Color(0xFFE94B9A).withOpacity(0.1),
            strokeColor: const Color(0xFFE94B9A),
            strokeWidth: 2,
          );
        });
      }
    } catch (e) {
      print('❌ 좋아요 목록 불러오기 실패: $e');
      // 에러가 발생해도 지도는 계속 표시됨
    }
  }

  /// 프로필 모달 표시
  void _showProfileModal(Map<String, dynamic> userData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.3), // 반투명 배경으로 지도가 살짝 보이도록
      builder: (context) => _ProfileModal(userData: userData),
    );
  }

  void _updateCameraPosition(LatLng? currentUserLocation) {
    if (_mapController == null) return;

    try {
      if (currentUserLocation != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(currentUserLocation, 12),
        );
      } else if (_markers.isNotEmpty) {
        final firstMarker = _markers.values.first;
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(firstMarker.position, 12),
        );
      } else {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(const LatLng(37.5665, 126.9780), 12),
        );
      }
    } catch (e) {
      print('❌ 카메라 위치 업데이트 실패: $e');
    }
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;

    // 좋아요한 사용자 정보 불러오기 (내부에서 현재 사용자 위치도 가져옴)
    await _loadLikedUsers();

    // 현재 사용자 위치로 지도 중앙 설정
    if (_currentUserLocation != null) {
      _updateCameraPosition(_currentUserLocation);
    } else {
      // 위치 정보가 없으면 기본 위치(서울)로 설정
      _updateCameraPosition(null);
    }
  }

  Widget _buildMap() {
    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: const CameraPosition(
        target: LatLng(37.5665, 126.9780),
        zoom: 12,
      ),
      markers: _markers.values.toSet(),
      circles: _circles.values.toSet(),
      myLocationButtonEnabled: true,
      myLocationEnabled: true,
      mapType: MapType.normal,
      onTap: (LatLng position) {
        // 지도 탭 시 모달 닫기 (필요시)
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3EFF8),
      appBar: AppBar(
        title: const Text(
          '좋아요',
          style: TextStyle(
            color: Color(0xFFE94B9A),
            fontSize: 24,
            fontFamily: 'Bagel Fat One',
            fontWeight: FontWeight.w400,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(child: _buildMap()),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

/// 프로필 모달 위젯
class _ProfileModal extends StatefulWidget {
  final Map<String, dynamic> userData;

  const _ProfileModal({required this.userData});

  @override
  State<_ProfileModal> createState() => _ProfileModalState();
}

class _ProfileModalState extends State<_ProfileModal> {
  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final name = widget.userData['name'] as String? ?? '이름 없음';
    final age = widget.userData['age'] as int? ?? 0;
    final school = widget.userData['school'] as String? ?? '';
    final major = widget.userData['major'] as String? ?? '';
    final bio = widget.userData['bio'] as String? ?? '';
    final hasProfileImage = widget.userData['profileImageUrl'] != null;
    final appearanceStyles =
        (widget.userData['appearanceStyles'] as List<dynamic>?)
            ?.cast<String>() ??
        [];
    final styleKeywords =
        (widget.userData['styleKeywords'] as List<dynamic>?)?.cast<String>() ??
        [];
    final personalityKeywords =
        (widget.userData['personalityKeywords'] as List<dynamic>?)
            ?.cast<String>() ??
        [];
    final hobbyOptions =
        (widget.userData['hobbyOptions'] as List<dynamic>?)?.cast<String>() ??
        [];

    // 외모 스타일 표시
    final displayAppearanceStyles = appearanceStyles.isNotEmpty
        ? appearanceStyles
        : styleKeywords;

    return DraggableScrollableSheet(
      initialChildSize: 0.55, // 화면의 55% 정도로 줄임 (지도가 보이도록)
      minChildSize: 0.3, // 최소 크기
      maxChildSize: 0.85, // 최대 크기
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // 드래그 핸들
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 프로필 내용
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(
                    horizontal: screenSize.width * 0.05,
                    vertical: screenSize.height * 0.02,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 프로필 이미지 + 기본 정보
                      Row(
                        children: [
                          // 프로필 이미지
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: hasProfileImage
                                  ? Colors.transparent
                                  : const Color(0xFFFDF6FA),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFE0E0E0),
                                width: 2,
                              ),
                              image: hasProfileImage
                                  ? DecorationImage(
                                      image: NetworkImage(
                                        widget.userData['profileImageUrl']
                                            as String,
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: hasProfileImage
                                ? null
                                : const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Color(0xFFC48EC4),
                                  ),
                          ),
                          SizedBox(width: screenSize.width * 0.04),

                          // 기본 정보
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$name, $age',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (school.isNotEmpty)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          school,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (major.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.school,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          major,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 자기소개
                      if (bio.isNotEmpty) ...[
                        const Text(
                          '자기소개',
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          bio,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // 외모 스타일
                      if (displayAppearanceStyles.isNotEmpty) ...[
                        _buildTagSection('외모 스타일', displayAppearanceStyles),
                        const SizedBox(height: 20),
                      ],

                      // 성격
                      if (personalityKeywords.isNotEmpty) ...[
                        _buildTagSection('성격', personalityKeywords),
                        const SizedBox(height: 20),
                      ],

                      // 취미/관심사
                      if (hobbyOptions.isNotEmpty) ...[
                        _buildTagSection('취미/관심사', hobbyOptions),
                        const SizedBox(height: 20),
                      ],

                      const SizedBox(height: 20),

                      // 내 정보 공개하기 버튼
                      _buildShareInfoButton(screenSize),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShareInfoButton(Size screenSize) {
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
        onPressed: () {
          // 웃음 감지 카메라 페이지로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SmileDetectionPage(
                targetUserId: widget.userData['id'] as String? ?? '',
              ),
            ),
          ).then((success) {
            if (success == true && mounted) {
              // 정보 공개 성공 시 모달 닫기
              Navigator.of(context).pop();
            }
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: const Text(
          '내 정보 공개하기',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Bagel Fat One',
          ),
        ),
      ),
    );
  }

  Widget _buildTagSection(String title, List<String> tags) {
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
          spacing: 8,
          runSpacing: 8,
          children: tags.map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFD6A4E0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tag,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
