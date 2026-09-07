import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/toast_util.dart';
import '../../../core/widgets/edge_button_dialog.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/selection_control.dart';
import '../../auth/domain/readable_auth_error.dart';
import '../data/membership_repository.dart';
import '../domain/membership_models.dart';
import '../widgets/membership_benefit_list.dart';
import 'membership_benefits_screen.dart';
import 'membership_cancel_complete_screen.dart';

/// 멤버십 해지 화면 (USR-MBS, Figma 547:14070).
///
/// 구독중 혜택 화면의 "멤버십 해지하기"에서 진입. `GET /cancel-info`로 남은 일수·
/// 이용 종료일·해지 사유 목록(공통코드)을 받아 렌더하고, 유의사항 동의 + 사유 선택 후
/// "멤버십 해지하기" → 확인 다이얼로그(593:11560) → `POST /cancel`(사유코드+동의 전송)
/// → 해지 신청 완료 화면(615:10503). "멤버십 유지하기"는 이전 화면으로 복귀.
class MembershipCancelScreen extends ConsumerStatefulWidget {
  const MembershipCancelScreen({
    super.key,
    required this.myPetId,
    required this.membershipId,
  });

  final String myPetId;
  final int membershipId;

  @override
  ConsumerState<MembershipCancelScreen> createState() =>
      _MembershipCancelScreenState();
}

class _MembershipCancelScreenState extends ConsumerState<MembershipCancelScreen> {
  String? _selectedCode; // 선택된 해지 사유 코드
  bool _selectedIsEtc = false;
  final TextEditingController _directController = TextEditingController();
  bool _agreed = false;
  bool _submitting = false;

  @override
  void dispose() {
    _directController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final infoAsync = ref.watch(membershipCancelInfoProvider(widget.membershipId));
    final guide = ref.watch(membershipGuideProvider).asData?.value;
    final benefits = (guide != null && guide.isNotEmpty)
        ? guide.first.benefits
        : const <MembershipBenefit>[];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: NurimPageHeader(
        title: '멤버십 해지',
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      body: infoAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, _) => const Center(
          child: Text(
            '해지 정보를 불러오지 못했습니다.',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
        ),
        data: (info) => _buildBody(context, info, benefits),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    MembershipCancelInfo info,
    List<MembershipBenefit> benefits,
  ) {
    final endDot = _dot(info.benefitEndDate);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 24, 16, 24 + bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RemainHeadline(days: info.benefitRemainingDays),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgGray,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  info.membershipName.isEmpty ? '멤버십' : info.membershipName,
                  // Figma Membership text info box_1(590:7909)
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textStrong,
                    letterSpacing: -0.66,
                    height: 1.4,
                  ),
                ),
                Text(
                  '$endDot까지',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    letterSpacing: -0.66,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Image.asset(
              'assets/images/membership/sad_pet.png',
              width: 100,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '해지하면 아래의 혜택을 모두 잃게 돼요!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textStrong,
              letterSpacing: -0.66,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          MembershipBenefitList(benefits: benefits),
          const SizedBox(height: 32),
          // 디자인 문구는 "(선택)" 이지만 백엔드가 cancelReasonCodes 를
          // required(최소 1개)로 받는다. 백엔드 스펙에 맞추기로 해 "(필수)" 로 쓴다.
          // 해지 버튼 활성 조건(_canCancel)도 사유 선택을 요구하므로 문구와 일치한다.
          const Text(
            '해지 사유를 알려주세요.(필수)',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textStrong,
              letterSpacing: -0.66,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          for (final reason in info.cancelReasons) ...[
            _reasonRow(reason),
            // 직접 입력(ETC) 라디오를 선택했을 때만 입력 칸 노출.
            if (reason.isEtc && _selectedCode == reason.code) ...[
              const SizedBox(height: 12),
              _directInput(context),
            ],
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 8),
          const Divider(height: 1, thickness: 1, color: AppColors.bgGray),
          const SizedBox(height: 24),
          _agreementCheck(),
          const SizedBox(height: 24),
          _keepButton(),
          const SizedBox(height: 12),
          _cancelButton(),
        ],
      ),
    );
  }

  /// 도넛형 라디오 + 라벨(공통코드 사유).
  Widget _reasonRow(CancelReasonItem reason) {
    final selected = _selectedCode == reason.code;
    return InkWell(
      onTap: () => setState(() {
        _selectedCode = reason.code;
        _selectedIsEtc = reason.isEtc;
      }),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 21,
            height: 21,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.borderLight,
                width: 6.3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              reason.name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? AppColors.textStrong : AppColors.textSecondary,
                letterSpacing: -0.66,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 직접 입력 텍스트영역.
  ///
  /// 피그마 Textarea field base(593:9313) 실측: 박스 343x138 =
  /// 패딩 16 + 본문 80 + 간격 8 + 카운터 18 + 패딩 16.
  /// 카운터(0/100)는 테두리 "안쪽" 우하단이다(검수 20행 ①).
  /// Flutter 기본 counter 는 입력창 바깥에 그려지므로 끄고 직접 배치한다.
  ///
  /// 본문 80 은 16px·행간 1.4(=22.4) 기준 3.57줄이라 maxLines 로는 못 맞춘다.
  /// expands 로 높이를 직접 주되, 글자 배율이 커지면 같이 늘어나도록
  /// 본문·카운터 높이에 배율을 곱한다(고정 80 이면 큰 글자에서 잘린다).
  Widget _directInput(BuildContext context) {
    final scale = MediaQuery.of(context).textScaler.scale(16) / 16;
    final counterHeight = 13 * 1.4 * scale;
    final bottomPadding = 16 + 8 + counterHeight;

    return Stack(
      children: [
        SizedBox(
          height: 16 + 80 * scale + bottomPadding,
          child: TextField(
            controller: _directController,
            maxLength: 100,
            expands: true,
            maxLines: null,
            minLines: null,
            textAlignVertical: TextAlignVertical.top,
            // 기본 카운터는 입력창 바깥에 그려져서 끄고 아래에서 직접 배치한다.
            buildCounter: (
              _, {
              required int currentLength,
              required bool isFocused,
              int? maxLength,
            }) =>
                null,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
              letterSpacing: -0.66,
              height: 1.4,
            ),
            decoration: InputDecoration(
              hintText: '해지 사유를 자유롭게 입력해 주세요.',
              hintStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.placeholder,
                letterSpacing: -0.66,
                height: 1.4,
              ),
              filled: true,
              fillColor: Colors.white,
              // 아래는 카운터 자리(패딩 16 + 간격 8 + 줄높이)를 비워 둔다.
              contentPadding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _directController,
            builder: (context, value, _) => Text(
              '${value.text.characters.length}/100',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.dot, // #B4C0D3
                letterSpacing: -0.66,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 유의사항 동의 체크.
  ///
  /// 자체 구현이라 미체크 상태에서도 굵은 글씨였고(검수 20행 ②) 체크박스도
  /// 빈 사각형이라 디자인(135:13273 = 연회색 채움 + 흰 체크)과 달랐다.
  /// 회원탈퇴 화면과 같은 공용 위젯을 쓰도록 바꾼다.
  /// 이 화면 디자인(593:9314)의 체크 줄은 상하 패딩 없이 높이 22 라
  /// 패딩을 0 으로 넘긴다(공용 기본값은 그대로 둬서 다른 화면 영향 없음).
  Widget _agreementCheck() {
    return SelectionControl<bool>(
      style: SelectionControlStyle.checkbox,
      text: '유의사항을 모두 확인하였으며, 이에 동의합니다.',
      value: _agreed,
      padding: EdgeInsets.zero,
      onChanged: (val) => setState(() => _agreed = val ?? false),
    );
  }

  Widget _keepButton() {
    return SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: _submitting ? null : () => Navigator.of(context).pop(),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text(
          '멤버십 유지하기',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: -0.66,
          ),
        ),
      ),
    );
  }

  /// 사유 1개 이상 선택 + 유의사항 동의(ETC면 직접입력 필수) 시 활성.
  bool get _canCancel {
    if (!_agreed || _selectedCode == null || _submitting) return false;
    if (_selectedIsEtc && _directController.text.trim().isEmpty) return false;
    return true;
  }

  Widget _cancelButton() {
    final enabled = _canCancel;
    return SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: enabled ? _confirmCancel : null,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFF7F6FF), // violet/10
          disabledBackgroundColor: const Color(0xFFF7F6FF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _submitting
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              )
            : Text(
                '멤버십 해지하기',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: enabled ? AppColors.primary : AppColors.primarySoft,
                  letterSpacing: -0.66,
                ),
              ),
      ),
    );
  }

  /// 해지 확인 다이얼로그(593:11560).
  void _confirmCancel() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => EdgeButtonDialog(
        title: '정말 해지하시겠어요?',
        content: '멤버십 해지 시 혜택 및\n모든 데이터는 복구되지 않아요.',
        cancelText: '취소',
        confirmText: '해지하기',
        onConfirm: _doCancel,
      ),
    );
  }

  Future<void> _doCancel() async {
    final code = _selectedCode;
    if (code == null) return;
    setState(() => _submitting = true);
    try {
      final result = await ref.read(membershipRepositoryProvider).cancelMembership(
            widget.membershipId,
            cancelReasonCodes: [code],
            cancelReasonText: _selectedIsEtc ? _directController.text : null,
            noticeAgreed: true,
          );
      if (!mounted) return;
      // 상세·해지정보·마이펫 상태 캐시 무효화(해지 신청 반영).
      ref.invalidate(membershipDetailProvider(widget.membershipId));
      ref.invalidate(membershipCancelInfoProvider(widget.membershipId));
      ref.invalidate(petMembershipProvider(widget.myPetId));
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MembershipCancelCompleteScreen(
            applyDate: _dot(result.cancelRequestDate),
            endDate: _dot(result.benefitEndDate),
          ),
        ),
      );
      if (!mounted) return;
      // 구독 플로우(해지→혜택)를 걷어내고 마이펫 상세로 복귀.
      Navigator.of(context).popUntil(
        (route) => route.settings.name == MembershipBenefitsScreen.routeName,
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ToastUtil.show(context, readAuthErrorMessage(error, '멤버십 해지에 실패했습니다.'));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// yyyy-MM-dd → yyyy.MM.dd.
  String _dot(String s) =>
      (s.length >= 10 ? s.substring(0, 10) : s).replaceAll('-', '.');
}

/// "아직 멤버십 혜택이 {N일} 남았어요!" — N일만 빨강 강조.
class _RemainHeadline extends StatelessWidget {
  const _RemainHeadline({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: AppColors.textStrong,
      letterSpacing: -0.66,
      height: 1.4,
    );
    return RichText(
      text: TextSpan(
        style: base,
        children: [
          const TextSpan(text: '아직 멤버십 혜택이 '),
          TextSpan(text: '$days일', style: base.copyWith(color: const Color(0xFFFF5F5F))),
          const TextSpan(text: ' 남았어요!'),
        ],
      ),
    );
  }
}
