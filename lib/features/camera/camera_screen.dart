import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/utils/toast_util.dart';
import '../../core/widgets/camera_widgets.dart';
import 'shooting_history_screen.dart';
import '../../core/theme/app_colors.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;
  bool _isInitialized = false;

  XFile? _capturedImage;
  bool _isCaptured = false;
  bool _isPermissionDenied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isPermissionDenied) {
      // 앱으로 돌아왔을 때 권한 다시 확인
      _checkPermissionOnResume();
    }
  }

  Future<void> _checkPermissionOnResume() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      if (mounted) {
        setState(() {
          _isPermissionDenied = false;
        });
      }
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) {
        setState(() {
          _isPermissionDenied = true;
        });
      }
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _setCamera(_selectedCameraIndex);
      }
    } catch (e) {
      debugPrint("Error initializing camera: $e");
    }
  }

  Future<void> _setCamera(int index) async {
    if (_cameras == null || _cameras!.isEmpty) return;

    if (_controller != null) {
      await _controller!.dispose();
    }

    _controller = CameraController(
      _cameras![index],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _selectedCameraIndex = index;
        });
      }
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  void _flipCamera() {
    if (_cameras == null || _cameras!.length < 2) return;
    int newIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    _setCamera(newIndex);
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isTakingPicture) return;

    try {
      final XFile file = await _controller!.takePicture();
      setState(() {
        _capturedImage = file;
        _isCaptured = true;
      });
    } catch (e) {
      debugPrint("Error taking picture: $e");
    }
  }

  void _retake() {
    setState(() {
      _capturedImage = null;
      _isCaptured = false;
    });
  }

  Future<void> _savePicture() async {
    if (_capturedImage == null) return;
    
    // 임시 저장 후 홈으로 복귀. 실제 갤러리 저장 플러그인이 없으므로 로컬 저장소 시뮬레이션
    final directory = await getApplicationDocumentsDirectory();
    final String newPath = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _capturedImage!.saveTo(newPath);

    // SnackBar 대신 팝업 표시
    if (!mounted) return;
    showDialog(
      context: context,
      barrierColor: const Color(0x99000000), // bg-[var(--scrim/60,rgba(0,0,0,0.6))]
      builder: (context) => CameraRewardPopup(
        onClose: () {
          Navigator.pop(context); // 팝업 닫기
          Navigator.pop(this.context); // 화면 닫기
        },
        onViewHistory: () {
          // 촬영 완료 팝업 닫고 내역 화면으로 유도
          Navigator.pop(context); // 팝업 닫기
          Navigator.pushReplacement(
            this.context,
            MaterialPageRoute(
              builder: (_) => const ShootingHistoryScreen(),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0x99000000), // bg-[var(--scrim/60,rgba(0,0,0,0.6))]
      body: Stack(
        children: [
          // 카메라 프리뷰 영역 (가운데 554px)
          Positioned(
            top: 106,
            left: 0,
            right: 0,
            height: 554,
            child: ClipRect(
              child: _isPermissionDenied
                  ? Container(
                      color: const Color(0xFF1F2228),
                      width: double.infinity,
                      height: double.infinity,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.videocam_off, color: Colors.white54, size: 48),
                          const SizedBox(height: 16),
                          const Text(
                            '마이펫 촬영을 위해\n카메라 접근 권한이 필요해요.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () async {
                              try {
                                bool opened = await openAppSettings();
                                if (!opened && mounted) {
                                  ToastUtil.show(context, '설정 앱을 열 수 없습니다. 직접 기기 설정에서 권한을 켜주세요.');
                                }
                              } catch (e) {
                                if (mounted) {
                                  ToastUtil.show(context, '오류 발생: $e');
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: const Text(
                              '설정으로 이동',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : (_isCaptured && _capturedImage != null
                      ? Image.file(
                          File(_capturedImage!.path),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        )
                      : (_isInitialized
                          ? SizedBox(
                              width: double.infinity,
                              height: double.infinity,
                              child: FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: _controller!.value.previewSize?.height ?? 1,
                                  height: _controller!.value.previewSize?.width ?? 1,
                                  child: CameraPreview(_controller!),
                                ),
                              ),
                            )
                          : const Center(child: CircularProgressIndicator(color: Colors.white)))),
            ),
          ),

          // 가이드 텍스트 (촬영 전)
          if (!_isCaptured && !_isPermissionDenied)
            Positioned(
              top: 122,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0x4D000000), // rgba(0,0,0,0.3)
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: const Text(
                    '밝은 곳에서 선명하게 촬영해 주세요.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      letterSpacing: -0.66,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ),

          // 상단 헤더 (뒤로가기)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Status bar 
                Container(
                  height: 50,
                  color: _isCaptured ? Colors.white : const Color(0x42000000),
                ),
                // Header bar
                Container(
                  height: 56,
                  color: _isCaptured ? Colors.white : const Color(0x42000000),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.arrow_back,
                      color: _isCaptured ? Colors.black : Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 하단 컨트롤 바
          if (!_isPermissionDenied)
            Positioned(
              bottom: 34, // Indicator(34px) 공간 확보
              left: 0,
              right: 0,
              child: _isCaptured
                  ? CameraButtonBar(
                      onCancel: _retake,
                      onSave: _savePicture,
                      backgroundColor: Colors.white,
                    )
                  : CameraControlBar(
                      onCapture: _takePicture,
                      onFlipCamera: _flipCamera,
                      backgroundColor: const Color(0x42000000), // rgba(0,0,0,0.26)
                    ),
            ),

          // 하단 인디케이터 공간 (아이폰용)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 34,
            child: Container(
              color: _isCaptured ? Colors.white : const Color(0x42000000),
            ),
          ),
        ],
      ),
    );
  }
}
