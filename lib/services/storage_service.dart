import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firebase Storage에 이미지를 업로드하는 서비스
class StorageService {
  StorageService();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 현재 로그인한 사용자의 uid
  String? get _userId => _auth.currentUser?.uid;

  /// 프로필 이미지 업로드
  /// 
  /// [imageFile] 업로드할 이미지 파일
  /// 반환: 업로드된 이미지의 다운로드 URL
  Future<String> uploadProfileImage(File imageFile) async {
    final uid = _userId;
    if (uid == null) {
      throw Exception('로그인한 사용자가 없습니다.');
    }

    try {
      // 파일 확장자 추출
      final extension = imageFile.path.split('.').last;
      
      // Storage 경로: profile_images/{uid}/profile.{extension}
      final ref = _storage.ref().child('profile_images').child(uid).child('profile.$extension');

      // 이미지 업로드
      print('📤 프로필 이미지 업로드 시작: ${imageFile.path}');
      await ref.putFile(imageFile);
      
      // 다운로드 URL 가져오기
      final downloadUrl = await ref.getDownloadURL();
      print('✅ 프로필 이미지 업로드 완료: $downloadUrl');
      
      return downloadUrl;
    } catch (e) {
      print('❌ 프로필 이미지 업로드 실패: $e');
      rethrow;
    }
  }

  /// 프로필 이미지 삭제
  Future<void> deleteProfileImage() async {
    final uid = _userId;
    if (uid == null) {
      throw Exception('로그인한 사용자가 없습니다.');
    }

    try {
      // profile_images/{uid} 폴더의 모든 파일 삭제
      final ref = _storage.ref().child('profile_images').child(uid);
      final listResult = await ref.listAll();
      
      for (var item in listResult.items) {
        await item.delete();
        print('🗑️ 이미지 삭제: ${item.name}');
      }
    } catch (e) {
      print('❌ 프로필 이미지 삭제 실패: $e');
      // 삭제 실패해도 계속 진행 (이미지가 없을 수도 있음)
    }
  }
}

