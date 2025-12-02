import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'services/firestore_service.dart';

class LikesPage extends StatefulWidget {
  const LikesPage({super.key});

  @override
  State<LikesPage> createState() => _LikesPageState();
}

class _LikesPageState extends State<LikesPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final Map<String, Marker> _markers = {};
  GoogleMapController? _mapController;

  Future<void> _loadLikedUsers() async {
    try {
      // 좋아요한 사용자 ID 목록 가져오기
      final likedUserIds = await _firestoreService.getLikedUserIds();

      if (likedUserIds.isEmpty) {
        setState(() {
          _markers.clear();
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

      // 지도에 마커 추가
      if (mounted) {
        setState(() {
          _markers.clear();
          
          for (final user in likedUsers) {
            final name = user['name'] as String? ?? '이름 없음';
            final latitude = user['latitude'] as double?;
            final longitude = user['longitude'] as double?;

            // 위치 정보가 있는 경우에만 마커 추가
            if (latitude != null && longitude != null) {
              final marker = Marker(
                markerId: MarkerId(user['id'] as String),
                position: LatLng(latitude, longitude),
                infoWindow: InfoWindow(
                  title: name,
                  snippet: user['school'] as String? ?? '',
                ),
              );
              _markers[user['id'] as String] = marker;
            }
          }
        });
      }
    } catch (e) {
      print('❌ 좋아요 목록 불러오기 실패: $e');
      // 에러가 발생해도 지도는 계속 표시됨
    }
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
    
    // 현재 사용자 위치 가져오기
    final currentUser = await _firestoreService.getCurrentUser();
    LatLng? currentUserLocation;

    if (currentUser != null) {
      final latitude = currentUser['latitude'] as double?;
      final longitude = currentUser['longitude'] as double?;
      if (latitude != null && longitude != null) {
        currentUserLocation = LatLng(latitude, longitude);
      }
    }

    // 현재 사용자 위치로 지도 중앙 설정
    if (currentUserLocation != null) {
      _updateCameraPosition(currentUserLocation);
    } else {
      // 위치 정보가 없으면 기본 위치(서울)로 설정
      _updateCameraPosition(null);
    }

    // 좋아요한 사용자 정보 불러오기
    _loadLikedUsers();
  }

  Widget _buildMap() {
    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: const CameraPosition(
        target: LatLng(37.5665, 126.9780),
        zoom: 12,
      ),
      markers: _markers.values.toSet(),
      myLocationButtonEnabled: true,
      myLocationEnabled: true,
      mapType: MapType.normal,
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '좋아요',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _buildMap(),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
