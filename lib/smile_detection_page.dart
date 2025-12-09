import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'services/firestore_service.dart';
import 'package:flutter/services.dart';

/// 웃음 감지 카메라 페이지
/// Google ML Kit의 smilingProbability를 사용하여 웃음을 감지합니다.
/// 참고: https://developers.google.com/ml-kit/vision/face-detection/ios?hl=ko
class SmileDetectionPage extends StatefulWidget {
  final String targetUserId; // 정보를 공개할 상대방 ID

  const SmileDetectionPage({super.key, required this.targetUserId});

  @override
  State<SmileDetectionPage> createState() => _SmileDetectionPageState();
}

class _SmileDetectionPageState extends State<SmileDetectionPage> {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  final FirestoreService _firestoreService = FirestoreService();
  bool _isDetecting = false;
  double _smileProbability = 0.0;
  bool _isSmileDetected = false;
  bool _isSharing = false;
  List<Face> _faces = [];
  Size? _previewSize;

  // 웃음 감지 threshold (0.0 ~ 1.0, 1.0에 가까울수록 확실한 웃음)
  // Google ML Kit의 smilingProbability는 0.0~1.0 범위입니다 (최대 100%)
  static const double _smileThreshold = 0.95;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeFaceDetector();
  }

  Future<void> _initializeCamera() async {
    // iOS 전용: 전면 카메라만 사용
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium, // 실시간 성능을 위해 medium 사용
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.bgra8888,
    );

    await _cameraController!.initialize();

    if (mounted) {
      setState(() {
        _previewSize = _cameraController!.value.previewSize;
      });
      _startImageStream();
    }
  }

  /// Google ML Kit Face Detector 초기화
  /// 참고: https://developers.google.com/ml-kit/vision/face-detection/ios?hl=ko
  void _initializeFaceDetector() {
    final options = FaceDetectorOptions(
      enableClassification: true, // 웃음 분류 활성화 (smilingProbability 사용)
      enableLandmarks: true, // 랜드마크 활성화 (시각화용)
      enableContours: false, // 윤곽선은 비활성화 (성능 향상)
      enableTracking: false, // 실시간이므로 트래킹 비활성화
      minFaceSize: 0.1, // 최소 얼굴 크기
      performanceMode: FaceDetectorMode.fast, // 실시간 성능을 위해 fast 모드
    );
    _faceDetector = FaceDetector(options: options);
  }

  void _startImageStream() {
    _cameraController!.startImageStream((CameraImage image) {
      if (_isDetecting || _isSmileDetected || _isSharing) return;
      _processImage(image);
    });
  }

  Future<void> _processImage(CameraImage image) async {
    if (_faceDetector == null) return;

    setState(() {
      _isDetecting = true;
    });

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        setState(() {
          _isDetecting = false;
        });
        return;
      }

      final faces = await _faceDetector!.processImage(inputImage);

      if (mounted) {
        setState(() {
          _faces = faces;
          if (faces.isNotEmpty) {
            final face = faces.first;
            // Google ML Kit의 smilingProbability 사용 (0.0 ~ 1.0)
            _smileProbability = face.smilingProbability ?? 0.0;

            if (_smileProbability >= _smileThreshold && !_isSmileDetected) {
              _onSmileDetected();
            }
          } else {
            _smileProbability = 0.0;
          }
          _isDetecting = false;
        });
      }
    } catch (e) {
      print('❌ 얼굴 감지 오류: $e');
      if (mounted) {
        setState(() {
          _isDetecting = false;
        });
      }
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final rotation = InputImageRotation.rotation0deg;
    final format = InputImageFormat.bgra8888;

    final plane = image.planes[0];
    final bytes = plane.bytes;

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Future<void> _onSmileDetected() async {
    setState(() {
      _isSmileDetected = true;
      _isSharing = true;
    });

    try {
      // 현재 사용자의 연락처 정보 가져오기
      final currentUser = await _firestoreService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('사용자 정보를 가져올 수 없습니다.');
      }

      final instagramId = currentUser['instagramId'] as String? ?? '';
      final kakaoId = currentUser['kakaoId'] as String? ?? '';

      if (instagramId.isEmpty && kakaoId.isEmpty) {
        if (mounted) {
          setState(() {
            _isSharing = false;
            _isSmileDetected = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('인스타그램 또는 카카오톡 아이디를 먼저 등록해주세요.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // API 호출하여 내 정보 공개
      await _shareMyInfo();

      if (mounted) {
        // 연락처 정보 표시 모달
        _showContactInfoModal(instagramId, kakaoId);
      }
    } catch (e) {
      print('❌ 정보 공개 실패: $e');
      if (mounted) {
        setState(() {
          _isSharing = false;
          _isSmileDetected = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('정보 공개 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 나가기 확인 다이얼로그 표시
  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '나가기',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          '웃음 감지를 중단하고 나가시겠습니까?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(); // 다이얼로그 닫기
              // 다이얼로그가 완전히 닫힌 후 페이지 닫기
              Future.microtask(() {
                if (mounted) {
                  Navigator.of(context).pop(false); // 카메라 페이지 닫기
                }
              });
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('나가기'),
          ),
        ],
      ),
    );
  }

  /// 연락처 정보 표시 모달
  void _showContactInfoModal(String instagramId, String kakaoId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text(
          '연락처 정보',
          style: TextStyle(
            color: Color(0xFFE94B9A),
            fontSize: 24,
            fontFamily: 'Bagel Fat One',
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '내 정보가 공개되었습니다!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (instagramId.isNotEmpty) ...[
              _buildContactItem(
                icon: Icons.camera_alt,
                label: '인스타그램',
                value: instagramId,
                onCopy: () => _copyToClipboard(instagramId, '인스타그램'),
              ),
              const SizedBox(height: 12),
            ],
            if (kakaoId.isNotEmpty) ...[
              _buildContactItem(
                icon: Icons.chat_bubble_outline,
                label: '카카오톡',
                value: kakaoId,
                onCopy: () => _copyToClipboard(kakaoId, '카카오톡'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // 모달 닫기
              Navigator.of(context).pop(true); // 카메라 페이지 닫기
            },
            child: const Text(
              '확인',
              style: TextStyle(
                color: Color(0xFFE94B9A),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onCopy,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF6FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFE94B9A), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            color: const Color(0xFFE94B9A),
            onPressed: onCopy,
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label 아이디가 복사되었습니다: $text'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// 내 정보를 상대방에게 공개
  Future<void> _shareMyInfo() async {
    // Firestore에 정보 공개 기록 저장
    await _firestoreService.shareInfoToUser(widget.targetUserId);
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          // 오른쪽으로 스와이프 (나가기)
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 500) {
            _showExitDialog();
          }
        },
        child: Stack(
          children: [
            // 카메라 프리뷰
            Positioned.fill(child: CameraPreview(_cameraController!)),

            // 얼굴 랜드마크 오버레이
            if (_previewSize != null)
              Positioned.fill(
                child: CustomPaint(
                  painter: FaceLandmarkPainter(
                    faces: _faces,
                    previewSize: _previewSize!,
                    imageSize: Size(
                      _cameraController!.value.previewSize!.height,
                      _cameraController!.value.previewSize!.width,
                    ),
                  ),
                ),
              ),

            // 상단: Smile Probability 표시
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    if (_isSmileDetected)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '웃음 감지됨! 🎉',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Bagel Fat One',
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              '웃음 확률',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${(_smileProbability * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: _smileProbability >= _smileThreshold
                                    ? Colors.green
                                    : Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Bagel Fat One',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '목표: ${(_smileThreshold * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // 하단: 안내 문구
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 40,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      '웃으면 자동으로 정보가 공개됩니다 😊',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.swipe_right,
                          color: Colors.white70,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '오른쪽으로 스와이프하여 나가기',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 로딩 인디케이터
            if (_isSharing)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          '정보 공개 중...',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 얼굴 랜드마크를 그리는 CustomPainter
/// Google ML Kit의 랜드마크를 시각화합니다
class FaceLandmarkPainter extends CustomPainter {
  final List<Face> faces;
  final Size previewSize;
  final Size imageSize;

  FaceLandmarkPainter({
    required this.faces,
    required this.previewSize,
    required this.imageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (faces.isEmpty) return;

    // 화면 크기에 맞게 좌표 변환
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;

    for (final face in faces) {
      final landmarks = face.landmarks;

      // 입 주변 랜드마크 그리기
      final leftMouth = landmarks[FaceLandmarkType.leftMouth];
      final rightMouth = landmarks[FaceLandmarkType.rightMouth];
      final noseBase = landmarks[FaceLandmarkType.noseBase];

      final paint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.fill
        ..strokeWidth = 2;

      // 랜드마크 점 그리기
      if (leftMouth != null) {
        canvas.drawCircle(
          Offset(leftMouth.position.x * scaleX, leftMouth.position.y * scaleY),
          4,
          paint,
        );
      }

      if (rightMouth != null) {
        canvas.drawCircle(
          Offset(
            rightMouth.position.x * scaleX,
            rightMouth.position.y * scaleY,
          ),
          4,
          paint,
        );
      }

      if (noseBase != null) {
        canvas.drawCircle(
          Offset(noseBase.position.x * scaleX, noseBase.position.y * scaleY),
          4,
          paint..color = Colors.blue,
        );
      }

      // 랜드마크 연결선 그리기
      final linePaint = Paint()
        ..color = Colors.green.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      if (leftMouth != null && rightMouth != null) {
        canvas.drawLine(
          Offset(leftMouth.position.x * scaleX, leftMouth.position.y * scaleY),
          Offset(
            rightMouth.position.x * scaleX,
            rightMouth.position.y * scaleY,
          ),
          linePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(FaceLandmarkPainter oldDelegate) {
    return faces != oldDelegate.faces;
  }
}
