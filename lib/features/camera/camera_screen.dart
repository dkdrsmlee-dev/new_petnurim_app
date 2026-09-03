import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/api/api_exception.dart';
import '../../core/utils/toast_util.dart';
import '../../core/widgets/camera_widgets.dart';
import '../../core/widgets/edge_button_dialog.dart';
import '../member/data/file_repository.dart';
import 'data/photo_event_repository.dart';
import '../event/data/mission_refresh_providers.dart';
import '../../core/widgets/pet_select_card.dart';
import 'shooting_history_screen.dart';
import '../../core/theme/app_colors.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({
    Key? key,
    this.eventMasterId,
    this.petId,
    this.rewardValueHint,
    this.petData,
  }) : super(key: key);

  /// 촬영 참여 API 호출에 사용할 이벤트 식별자. null이면 백엔드 연동 없이 기존 동작.
  final String? eventMasterId;

  /// 촬영 참여 대상 펫 식별자
  final String? petId;

  /// 참여 결과에 리워드가 없을 때 팝업에 표시할 예비 리워드 값
  final int? rewardValueHint;

  /// 촬영 내역 화면 요약 카드에 표시할 펫 정보(품종·나이·성별 등).
  /// 백엔드 내역 응답에는 이 정보가 없어 화면 간 전달이 필요하다.
  final PetSelectCardData? petData;

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;
  bool _isInitialized = false;

  XFile? _capturedImage;
  bool _isCaptured = false;
  bool _isPermissionDenied = false;
  bool _isSaving = false;
  // 촬영 중단 확인 팝업을 거친 뒤에만 실제로 화면을 pop 하기 위한 플래그
  bool _canPop = false;

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
    if (_capturedImage == null || _isSaving) return;

    final eventMasterId = widget.eventMasterId;
    final petId = widget.petId;

    // 이벤트/펫 정보가 없으면 (예: 촬영 내역 화면에서 진입) 백엔드 연동 없이 팝업만 표시
    if (eventMasterId == null ||
        eventMasterId.isEmpty ||
        petId == null ||
        petId.isEmpty) {
      _showRewardPopup(widget.rewardValueHint ?? 100);
      return;
    }

    setState(() => _isSaving = true);
    try {
      // 1) 촬영 이미지를 파일 서버에 업로드
      final bytes = await _capturedImage!.readAsBytes();
      final filename =
          _capturedImage!.name.isNotEmpty ? _capturedImage!.name : 'pet.jpg';
      final uploadResult = await ref
          .read(fileRepositoryProvider)
          .uploadFile(fileBytes: bytes, filename: filename);
      final fileId = uploadResult['fileId']?.toString();
      if (fileId == null || fileId.isEmpty) {
        throw const FormatException('파일 ID를 확인할 수 없습니다.');
      }

      // 2) 업로드한 파일로 촬영 미션 참여
      final result = await ref.read(photoEventRepositoryProvider).participate(
            eventMasterId: eventMasterId,
            petId: petId,
            fileId: fileId,
          );

      if (!mounted) return;
      setState(() => _isSaving = false);

      // 홈 "주간 참여"를 즉시 +1 낙관 갱신하기 위한 참여 성공 신호(①/②).
      // /events/templates 집계 반영 지연을 우회한다(홈이 소비 후 리셋).
      ref.read(photoParticipatedProvider.notifier).set(petId);

      final reward =
          result.rewardValue > 0 ? result.rewardValue : (widget.rewardValueHint ?? 0);
      _showRewardPopup(reward);
    } catch (e) {
      debugPrint('Participate error: $e');
      if (!mounted) return;
      setState(() => _isSaving = false);
      // 이미 참여한 경우(1일 1회 제한)는 전용 안내 메시지로 분기
      final alreadyParticipated =
          e is ApiException && e.code == 'EVENT.ALREADY_PARTICIPATED';
      ToastUtil.show(
        context,
        alreadyParticipated
            ? '오늘은 이미 참여했어요.'
            : '사진 저장에 실패했습니다. 다시 시도해 주세요.',
      );
    }
  }

  void _showRewardPopup(int rewardValue) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierColor: const Color(0x99000000), // bg-[var(--scrim/60,rgba(0,0,0,0.6))]
      builder: (dialogContext) => CameraRewardPopup(
        rewardValue: rewardValue,
        onClose: () {
          Navigator.pop(dialogContext); // 팝업 닫기
          _exit(); // 화면 닫기 (PopScope 우회)
        },
        onViewHistory: () {
          // 촬영 완료 팝업 닫고 내역 화면으로 유도 (이벤트/펫 식별자 전달)
          Navigator.pop(dialogContext); // 팝업 닫기
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ShootingHistoryScreen(
                eventMasterId: widget.eventMasterId,
                petId: widget.petId,
                petData: widget.petData,
              ),
            ),
          );
        },
      ),
    );
  }

  /// 촬영 중단 확인 팝업. "중단하기" 선택 시에만 화면을 종료한다.
  void _confirmExit() {
    if (_isSaving) return;
    showDialog(
      context: context,
      builder: (dialogContext) => EdgeButtonDialog(
        title: '촬영을 중단하시겠어요?',
        content: '지금 나가면 촬영이 취소돼요.',
        cancelText: '중단하기',
        confirmText: '계속 참여하기',
        onCancel: () {
          Navigator.of(dialogContext).pop(); // 팝업 닫기
          _exit(); // 카메라 화면 종료
        },
        onConfirm: () {}, // 계속 참여: 팝업만 닫힘(EdgeButtonDialog가 자동 pop)
      ),
    );
  }

  /// PopScope(canPop:false)를 우회해 실제로 화면을 pop 한다.
  void _exit() {
    if (!mounted) return;
    setState(() => _canPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _confirmExit();
      },
      child: Scaffold(
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
                    onTap: _confirmExit,
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
                      onRetake: _retake,
                      onSave: _savePicture,
                      backgroundColor: Colors.white,
                    )
                  : CameraControlBar(
                      onCapture: _takePicture,
                      onFlipCamera: _flipCamera,
                      backgroundColor: const Color(0x66000000), // Figma rgba(0,0,0,0.4)
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

          // 업로드/참여 진행 중 로딩 오버레이
          if (_isSaving)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x99000000),
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    ),
    );
  }
}
