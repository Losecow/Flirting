import 'dart:async';
import 'package:geolocator/geolocator.dart';

/// 위치 정보를 수집하는 서비스
class LocationService {
  LocationService();

  /// 위치 권한 확인 및 요청
  Future<bool> requestLocationPermission() async {
    try {
      // 위치 서비스가 활성화되어 있는지 확인
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ 위치 서비스가 비활성화되어 있습니다.');
        return false;
      }

      // 위치 권한 상태 확인
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        // 권한 요청
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('❌ 위치 권한이 거부되었습니다.');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print(
            '❌ 위치 권한이 영구적으로 거부되었습니다. 설정에서 권한을 허용해주세요.');
        return false;
      }

      print('✅ 위치 권한이 허용되었습니다.');
      return true;
    } catch (e) {
      print('❌ 위치 권한 확인 중 오류: $e');
      return false;
    }
  }

  /// 현재 위치 가져오기
  Future<Position?> getCurrentLocation() async {
    try {
      // 권한 확인
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        return null;
      }

      // 현재 위치 가져오기 (에러 발생 시 안전하게 처리)
      print('📍 현재 위치 수집 중...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // high에서 medium으로 변경 (더 안정적)
        timeLimit: const Duration(seconds: 15),
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          print('⚠️ 위치 수집 타임아웃');
          throw TimeoutException('위치 수집 타임아웃', const Duration(seconds: 20));
        },
      );

      print('✅ 위치 수집 완료: ${position.latitude}, ${position.longitude}');
      return position;
    } on TimeoutException {
      print('❌ 위치 수집 타임아웃');
      return null;
    } catch (e) {
      print('❌ 위치 수집 실패: $e');
      return null;
    }
  }

  /// 위치 업데이트 리스너 (선택사항)
  Stream<Position>? getPositionStream() {
    try {
      return Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 100, // 100m 이동 시 업데이트
        ),
      );
    } catch (e) {
      print('❌ 위치 스트림 생성 실패: $e');
      return null;
    }
  }
}

