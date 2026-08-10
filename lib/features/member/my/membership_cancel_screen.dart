import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/toast_util.dart';
import '../../../core/widgets/edge_button_dialog.dart';
import '../../../core/widgets/page_header.dart';
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textStrong,
                    letterSpacing: -0.66,
                  ),
                ),
                Text(
                  '$endDot까지',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    letterSpacing: -0.66,
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
          const Text(
            '해지 사유를 알려주세요.(선택)',
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
              _directInput(),
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

  Widget _directInput() {
    return TextField(
      controller: _directController,
      maxLength: 100,
      maxLines: 3,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
        letterSpacing: -0.66,
      ),
      decoration: InputDecoration(
        hintText: '해지 사유를 자유롭게 입력해 주세요.',
        hintStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.placeholder,
          letterSpacing: -0.66,
        ),
        counterStyle: const TextStyle(fontSize: 13, color: Color(0xFFB4C0D3)),
        contentPadding: const EdgeInsets.all(16),
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
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _agreementCheck() {
    return InkWell(
      onTap: () => setState(() => _agreed = !_agreed),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: _agreed ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _agreed ? AppColors.primary : AppColors.border,
                width: 1.5,
              ),
            ),
            child: _agreed
                ? const Icon(Icons.check, size: 15, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '유의사항을 모두 확인하였으며, 이에 동의합니다.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textStrong,
                letterSpacing: -0.66,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
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
        onCancel: () {},
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
