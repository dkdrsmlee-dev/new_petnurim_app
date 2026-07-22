import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'toast_util.dart';

/// 이미지 소스([ImageSource.camera] 또는 [ImageSource.gallery])에서 이미지를
/// 선택해 로컬 파일 경로를 반환한다.
///
/// 여러 화면(마이펫 등록/수정)에 중복돼 있던 이미지 선택 로직을 공통화한 것.
/// - 선택 취소 시 null 반환
/// - 실패 시 스낵바 안내 후 null 반환
///
/// 마이펫 프로필 규격에 맞춰 최대 500x500, 품질 85로 리사이즈한다.
Future<String?> pickImagePath(BuildContext context, ImageSource source) async {
  try {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 500,
      maxHeight: 500,
      imageQuality: 85,
    );
    return pickedFile?.path;
  } catch (_) {
    if (context.mounted) {
      ToastUtil.show(context, '이미지를 가져오지 못했습니다.');
    }
    return null;
  }
}
