import 'package:flutter/foundation.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

// 프로필 정보 관리 Provider
class ProfileProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  Map<String, dynamic>? _currentUserData;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  String? _error;

  Map<String, dynamic>? get currentUserData => _currentUserData;
  bool get isLoading => _isLoading;
  bool get isUploadingImage => _isUploadingImage;
  String? get error => _error;

  Future<void> loadProfile() async {
    _setLoading(true);
    _error = null;
    try {
      _currentUserData = await _firestoreService.getCurrentUser();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> uploadProfileImage(dynamic imageFile) async {
    _setUploadingImage(true);
    _error = null;
    try {
      final imageUrl = await _storageService.uploadProfileImage(imageFile);
      await _firestoreService.upsertProfileImageUrl(imageUrl);
      await loadProfile();
      return imageUrl;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    } finally {
      _setUploadingImage(false);
    }
  }

  FirestoreService get firestoreService => _firestoreService;
  StorageService get storageService => _storageService;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setUploadingImage(bool value) {
    _isUploadingImage = value;
    notifyListeners();
  }
}
