import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/number_format.dart';
import '../../../core/utils/toast_util.dart';
import '../../../core/widgets/bullit_text.dart';
import '../../../core/widgets/edge_button_dialog.dart';
import '../../../core/widgets/page_header.dart';
import '../../auth/domain/readable_auth_error.dart';
import '../data/membership_repository.dart';
import '../domain/membership_models.dart';
import '../widgets/membership_benefit_list.dart';
import 'membership_cancel_screen.dart';
import 'membership_terms_agreement_screen.dart';

/// 별 SVG를 흰색으로 강제 렌더(디자인 원본 fill이 flutter_svg에서 불안정).
const ColorFilter _kWhiteFilter =
    ColorFilter.mode(Colors.white, BlendMode.srcIn);

/// 멤버십 혜택 화면 (USR-MBS-010, 멤버십 미이용 상태).
/// 마이펫 상세의 "멤버십 혜택 보기"에서 진입. 대부분 정적 콘텐츠.
///
/// 가격·상품명은 `GET /memberships/guide`(membershipGuideProvider)에서 받아 바인딩,
/// "멤버십 즉시 구독하기"는 약관 동의 화면으로 이동한다. 멤버십은 펫별이라
/// [myPetId]를 구독 플로우 전체(약관→카드→가입)에 관통시킨다.
class MembershipBenefitsScreen extends ConsumerWidget {
  const MembershipBenefitsScreen({super.key, required this.myPetId});

  /// 가입 대상 마이펫 ID.
  final int myPetId;

  /// 구독 플로우(약관→카드 등록) 완료 시 이 화면까지 popUntil로 되돌아오기 위한
  /// route 이름. 마이펫 상세에서 push할 때 RouteSettings.name으로 지정한다.
  static const String routeName = 'membership_benefits';

  // 이 화면 전용(브랜드/1회성) 색상
  static const Color _gradTop = Color(0xFF5F78F2);
  static const Color _gradBottom = Color(0xFF7266DF);
  static const Color _heroYellow = Color(0xFFFFF945);
  static const Color _priceCardBorder = Color(0xFF7788D9);
  static const Color _crownBg = Color(0xFFFFF7D7);
  static const Color _crownBorder = Color(0xFFFFEFC2);
  static const Color _crownIcon = Color(0xFFF8B600); // 디자인 크라운 금색
  static const Color _benefitBadge = Color(0xFF4F23A6);
  static const Color _green = Color(0xFF24CE82);
  static const Color _priceUnit = Color(0xFF909AA9);
  static const Color _badgeText = Color(0xFF6C737F);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petMem = ref.watch(petMembershipProvider(myPetId.toString()));
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: NurimPageHeader(
        title: '멤버십 혜택',
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      body: petMem.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        // 상태 조회 실패 시 가입 안내(미가입 뷰)로 폴백.
        error: (_, _) => _unsubscribedBody(context, ref),
        data: (status) {
          final membership = status.membership;
          return membership != null
              ? _subscribedBody(context, ref, membership)
              : _unsubscribedBody(context, ref);
        },
      ),
    );
  }

  /// 미가입 상태(263:9035) — 데코 히어로 + 가격 + "즉시 구독하기".
  Widget _unsubscribedBody(BuildContext context, WidgetRef ref) {
    final list = ref.watch(membershipGuideProvider).asData?.value;
    final item = (list != null && list.isNotEmpty) ? list.first : null;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHero(context, item),
          _buildNotice(context),
        ],
      ),
    );
  }

  /// 구독 중 상태(547:12592) — 구독 정보 + 혜택 + 유의사항 + 해지 버튼.
  Widget _subscribedBody(
    BuildContext context,
    WidgetRef ref,
    MembershipInfo membership,
  ) {
    final detailAsync = ref.watch(membershipDetailProvider(membership.membershipId));
    final guide = ref.watch(membershipGuideProvider).asData?.value;
    final benefits = (guide != null && guide.isNotEmpty)
        ? guide.first.benefits
        : const <MembershipBenefit>[];
    return detailAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (_, _) => const Center(
        child: Text(
          '멤버십 정보를 불러오지 못했습니다.',
          style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
        ),
      ),
      data: (detail) => _SubscribedView(
        myPetId: myPetId,
        detail: detail,
        benefits: benefits,
      ),
    );
  }

  Widget _buildHero(BuildContext context, MembershipGuideItem? item) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_gradTop, _gradBottom],
        ),
      ),
      child: Stack(
        children: [
          // 배경 글로우 — 콘텐츠 뒤(탭 통과)
          const Positioned.fill(
            child: IgnorePointer(child: _HeroDecorations(front: false)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 32),
            child: Column(
              children: [
                // 히어로 타이틀
                const Text('멤버십으로',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Gmarket Sans',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.4,
                      letterSpacing: -0.66,
                    )),
                const Text('더 크게 돌려받는',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Gmarket Sans',
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.4,
                      letterSpacing: -1,
                    )),
                const Text('리워드 혜택',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Gmarket Sans',
                      fontSize: 35,
                      fontWeight: FontWeight.w700,
                      color: _heroYellow,
                      height: 1.3,
                      letterSpacing: -1,
                    )),
                const SizedBox(height: 28),
                _buildPriceCard(context, item),
                const SizedBox(height: 28),
                _buildBenefitBadge(),
                const SizedBox(height: 16),
                _buildBenefitBox(),
                const SizedBox(height: 32),
                _buildSubscribeButton(context, item),
              ],
            ),
          ),
          // 코인·별 — 콘텐츠 위(coin4가 가격카드 위로 겹침). 탭 통과
          const Positioned.fill(
            child: IgnorePointer(child: _HeroDecorations(front: true)),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(BuildContext context, MembershipGuideItem? item) {
    final f = MediaQuery.of(context).size.width / 375; // 디자인 프레임 폭
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _priceCardBorder, width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x33291D55), blurRadius: 4),
        ],
      ),
      child: Column(
        children: [
          // 크라운 + 등급명
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _crownBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: _crownBorder, width: 1.33),
                ),
                child: SvgPicture.asset(
                  'assets/images/membership/crown.svg',
                  width: 13.33,
                  height: 12,
                  colorFilter: const ColorFilter.mode(
                      _crownIcon, BlendMode.srcIn),
                ),
              ),
              const SizedBox(width: 6),
              Text(item?.membershipName ?? '브론즈 멤버십',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textStrong,
                    letterSpacing: -0.66,
                  )),
            ],
          ),
          const SizedBox(height: 4),
          // 가격
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(item != null ? formatThousands(item.monthlyFee) : '10,000',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textStrong,
                    letterSpacing: -0.66,
                    height: 1.4,
                  )),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('원/월',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _priceUnit,
                      letterSpacing: -0.66,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // 배지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.bgGray,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('매월 신용카드 자동결제',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _badgeText,
                  letterSpacing: -0.66,
                )),
          ),
        ],
      ),
    );

    // coin4: 가격카드 좌하단 모서리에 겹쳐 그림(28.83° 기울임, 절반은 카드 아래로).
    // 카드에 직접 고정해 콘텐츠 레이아웃과 어긋나지 않게 한다.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        Positioned(
          left: 31.86 * f,
          bottom: -23.8 * f,
          width: 42.288 * f,
          height: 47.595 * f,
          child: IgnorePointer(
            child: Transform.rotate(
              angle: 28.83 * math.pi / 180,
              child: Image.asset(
                'assets/images/membership/coin4.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        // Star 9: 카드 우하단 바로 아래(보라 배경 위)의 흰 별.
        // 절대좌표(y324)는 카드 위에 얹혀 흰색+흰색으로 사라지므로 카드에 고정.
        Positioned(
          right: 25.53 * f,
          bottom: -24.07 * f,
          width: 13.337 * f,
          height: 13.337 * f,
          child: IgnorePointer(
            child: SvgPicture.asset(
              'assets/images/membership/star_a.svg',
              colorFilter: _kWhiteFilter,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _benefitBadge,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: const Text('멤버십 혜택',
          style: TextStyle(
            fontFamily: 'Gmarket Sans',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.66,
          )),
    );
  }

  Widget _buildBenefitBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          _BenefitRow(no: '01', text: '결제 금액의 1% 기본 적립'),
          SizedBox(height: 12),
          _BenefitRow(no: '02', text: '가입 즉시 10,000PR 지급'),
          SizedBox(height: 12),
          _BenefitRow(no: '03', text: '기본 서비스 이용'),
        ],
      ),
    );
  }

  Widget _buildSubscribeButton(BuildContext context, MembershipGuideItem? item) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: TextButton(
        // guide 미로딩(item==null) 시 비활성. 로딩되면 약관 동의로 이동.
        onPressed: item == null
            ? null
            : () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MembershipTermsAgreementScreen(
                      myPetId: myPetId,
                      membershipMasterId: item.membershipMasterId,
                    ),
                  ),
                );
              },
        style: TextButton.styleFrom(
          backgroundColor: AppColors.textStrong,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('멤버십 즉시 구독하기',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.66,
                )),
            SizedBox(width: 4),
            // 화살표는 디자인상 회색(Color/Gray/90 #6C737F)
            Icon(Icons.chevron_right, color: Color(0xFF6C737F), size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildNotice(BuildContext context) {
    // 시스템 내비게이션 바에 마지막 문구가 가리지 않도록 하단 인셋 + 여유 여백.
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      width: double.infinity,
      color: AppColors.bgGray,
      padding: EdgeInsets.fromLTRB(16, 32, 16, 40 + bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('가입 시 안내사항',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                letterSpacing: -0.66,
              )),
          SizedBox(height: 12),
          BullitText(text: '리워드는 결제일에 자동으로 리워드 지갑에 적립됩니다.'),
          SizedBox(height: 8),
          BullitText(
              text: '결제는 카드 결제만 가능하며, 멤버십 가입일 기준으로 월 단위 선납 방식으로 진행됩니다.'),
          SizedBox(height: 8),
          BullitText(text: '회원탈퇴 시 잔여 기간을 모두 사용 후 멤버십 탈퇴가 가능합니다.'),
        ],
      ),
    );
  }
}

/// 혜택 목록 한 줄 (초록 번호 + 텍스트)
class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.no, required this.text});

  final String no;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: MembershipBenefitsScreen._green,
            shape: BoxShape.circle,
          ),
          child: Text(no,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: -0.66,
              )),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: -0.66,
                height: 1.4,
              )),
        ),
      ],
    );
  }
}

/// 히어로 데코(배경 글로우 원 + 코인 + 별). Figma(263:9035) 정확 반영.
/// 디자인 프레임 폭 375 기준 좌표를 실제 폭에 비례 스케일한다.
///
/// z-순서상 배경 글로우는 콘텐츠 뒤, 코인·별은 콘텐츠 위에 그린다
/// (디자인에서 coin4가 가격카드 위로 겹침). [front]로 두 층을 구분한다.
class _HeroDecorations extends StatelessWidget {
  const _HeroDecorations({required this.front});

  /// true면 코인·별(콘텐츠 위), false면 배경 글로우(콘텐츠 뒤).
  final bool front;

  static const double _dw = 375; // 디자인 프레임 폭
  static const String _p = 'assets/images/membership';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final f = constraints.maxWidth / _dw;

        Positioned at(double x, double y, double w, double h, Widget child) {
          return Positioned(
            left: x * f,
            top: y * f,
            width: w * f,
            height: h * f,
            child: child,
          );
        }

        // 중심(cx,cy)에 원본 w×h를 두고 deg만큼(시계방향) 회전 배치.
        Positioned atRot(
            double cx, double cy, double w, double h, double deg, Widget child) {
          return Positioned(
            left: (cx - w / 2) * f,
            top: (cy - h / 2) * f,
            width: w * f,
            height: h * f,
            child: Transform.rotate(
              angle: deg * math.pi / 180,
              child: child,
            ),
          );
        }

        // 배경 글로우 원(Ellipse 349/350) — #6960EB 20%, 블러 37
        Positioned glow(double x, double y, double d) {
          return Positioned(
            left: x * f,
            top: y * f,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 37 * f, sigmaY: 37 * f),
              child: Container(
                width: d * f,
                height: d * f,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6960EB).withValues(alpha: 0.2),
                ),
              ),
            ),
          );
        }

        if (!front) {
          // 배경 글로우(콘텐츠 뒤)
          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              glow(-119.92, -135.68, 249.46),
              glow(186.00, 192.04, 278.01),
            ],
          );
        }

        // 코인·별(콘텐츠 위)
        return Stack(
          clipBehavior: Clip.none,
          children: [
            at(74.33, -8, 41.23, 41.48,
                Image.asset('$_p/coin2.png', fit: BoxFit.contain)),
            at(308.76, 113.81, 29.05, 29.05,
                Image.asset('$_p/coin1.png', fit: BoxFit.contain)),
            // coin3(옆면 코인)은 디자인에서 42.89° 기울어져 있다.
            // (coin4는 가격카드에 직접 고정 — _buildPriceCard 참고)
            atRot(308.89, 171.66, 6.512, 26, 42.89,
                Image.asset('$_p/coin3.png', fit: BoxFit.contain)),
            // 별 Star 8(좌상단) / Star 10(좌하단) — 흰색 강제(colorFilter).
            // (Star 9는 가격카드 우하단에 직접 고정 — _buildPriceCard 참고)
            at(60.99, 33.48, 13.34, 13.34,
                SvgPicture.asset('$_p/star_a.svg', colorFilter: _kWhiteFilter)),
            at(46.83, 391.04, 11.00, 11.00,
                SvgPicture.asset('$_p/star_b.svg', colorFilter: _kWhiteFilter)),
          ],
        );
      },
    );
  }
}

/// 멤버십 혜택 화면 "구독 중" 상태 본문 (Figma 547:12592).
/// 구독 정보·혜택·유의사항(접이식)·해지 버튼. 유의사항 토글 상태를 위해 Stateful.
class _SubscribedView extends ConsumerStatefulWidget {
  const _SubscribedView({
    required this.myPetId,
    required this.detail,
    required this.benefits,
  });

  final int myPetId;
  final MembershipDetail detail;
  final List<MembershipBenefit> benefits;

  @override
  ConsumerState<_SubscribedView> createState() => _SubscribedViewState();
}

class _SubscribedViewState extends ConsumerState<_SubscribedView> {
  bool _noticeExpanded = true;
  bool _resubmitting = false;

  static const Color _crownBg = Color(0xFFF2EFFF); // violet/20
  static const Color _crownBorder = Color(0xFFDBD4FF); // violet/40
  static const Color _crownIcon = Color(0xFF7025FF); // violet/100
  static const Color _subtle = Color(0xFF909AA9); // text/subtle

  @override
  Widget build(BuildContext context) {
    final d = widget.detail;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          // 크라운 + 상품명 + 자동결제 안내
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _crownBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: _crownBorder, width: 1),
                  ),
                  child: SvgPicture.asset(
                    'assets/images/membership/crown.svg',
                    width: 17,
                    height: 15,
                    colorFilter: const ColorFilter.mode(_crownIcon, BlendMode.srcIn),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  d.membershipName.isEmpty ? '멤버십' : d.membershipName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textStrong,
                    letterSpacing: -0.66,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_billingDateKor(d.nextBillingDt)}에\n등록한 신용카드로 자동 결제 됩니다.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    letterSpacing: -0.66,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // 구독 정보 박스
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgGray,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _infoRow(
                    '구독 금액',
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatThousands(d.paymentAmount),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textStrong,
                            letterSpacing: -0.66,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Text(
                            '원/월',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _subtle,
                              letterSpacing: -0.66,
                            ),
                          ),
                        ),
                      ],
                    ),
                    labelColor: _subtle,
                  ),
                  const SizedBox(height: 10),
                  _infoRow('구독 방식', _value(d.paymentCycleLabel)),
                  const SizedBox(height: 10),
                  _infoRow('이용 기간', _value(_periodText(d))),
                  const SizedBox(height: 10),
                  _infoRow('결제 수단', _value(d.cardLabel)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(height: 6, color: AppColors.bgGray),
          const SizedBox(height: 24),
          // 멤버십 혜택
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '멤버십 혜택',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: -0.66,
                  ),
                ),
                const SizedBox(height: 12),
                MembershipBenefitList(benefits: widget.benefits),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // 유의사항(접이식)
          Container(height: 6, color: AppColors.bgGray),
          InkWell(
            onTap: () => setState(() => _noticeExpanded = !_noticeExpanded),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '유의사항',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                        letterSpacing: -0.66,
                      ),
                    ),
                  ),
                  Icon(
                    _noticeExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 24,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          Container(height: 6, color: AppColors.bgGray),
          if (_noticeExpanded)
            Container(
              width: double.infinity,
              color: AppColors.bgGray,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '가입 시 안내사항',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      letterSpacing: -0.66,
                    ),
                  ),
                  SizedBox(height: 12),
                  BullitText(text: '리워드는 결제일에 자동으로 리워드 지갑에 적립됩니다.'),
                  SizedBox(height: 8),
                  BullitText(
                      text: '결제는 카드 결제만 가능하며, 멤버십 가입일 기준으로 월 단위 선납 방식으로 진행됩니다.'),
                  SizedBox(height: 8),
                  BullitText(text: '회원탈퇴 시 잔여 기간을 모두 사용 후 멤버십 탈퇴가 가능합니다.'),
                ],
              ),
            ),
          const SizedBox(height: 24),
          // 해지 / 해지 취소 버튼
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 24 + bottomInset),
            child: _actionButton(context),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(BuildContext context) {
    final cancelScheduled = widget.detail.isCancelScheduled;
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: _resubmitting
            ? null
            : () {
                if (cancelScheduled) {
                  // 해지 신청 상태 → 재구독(해지 취소).
                  _confirmResubscribe();
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MembershipCancelScreen(
                      myPetId: widget.myPetId.toString(),
                      membershipId: widget.detail.membershipId,
                    ),
                  ),
                );
              },
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: _resubmitting
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              )
            : Text(
                cancelScheduled ? '해지 취소하기' : '멤버십 해지하기',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: -0.66,
                ),
              ),
      ),
    );
  }

  /// 재구독(해지 취소) 확인 다이얼로그(Figma 900:39130).
  void _confirmResubscribe() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => EdgeButtonDialog(
        title: '멤버십 해지를 취소하시겠어요?',
        content: '해지를 취소하면 멤버십이 유지되고\n자동 결제가 재개됩니다.',
        cancelText: '닫기',
        confirmText: '해지 취소하기',
        onCancel: () {},
        onConfirm: _doResubscribe,
      ),
    );
  }

  /// 재구독(`POST /memberships` 최소 payload — 기존 billingKey 재사용).
  /// 성공 시 완료 토스트(900:39304) + 상태 캐시 무효화로 ACTIVE 자동 갱신.
  Future<void> _doResubscribe() async {
    setState(() => _resubmitting = true);
    try {
      await ref.read(membershipRepositoryProvider).resubscribe(
            myPetId: widget.myPetId,
            membershipMasterId: widget.detail.membershipMasterId,
          );
      if (!mounted) return;
      ToastUtil.show(context, '멤버십 해지가 취소되었습니다.\n멤버십이 계속 유지됩니다.');
      ref.invalidate(membershipDetailProvider(widget.detail.membershipId));
      ref.invalidate(petMembershipProvider(widget.myPetId.toString()));
    } catch (error) {
      if (!mounted) return;
      ToastUtil.show(context, readAuthErrorMessage(error, '재구독에 실패했습니다.'));
    } finally {
      if (mounted) setState(() => _resubmitting = false);
    }
  }

  Widget _infoRow(String label, Widget value, {Color labelColor = AppColors.textSecondary}) {
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: labelColor,
                letterSpacing: -0.66,
              ),
            ),
          ),
          value,
        ],
      ),
    );
  }

  Widget _value(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
          letterSpacing: -0.66,
        ),
      );

  /// yyyy-MM-dd → "yyyy년 M월 dd일".
  String _billingDateKor(String ymd) {
    final s = ymd.length >= 10 ? ymd.substring(0, 10) : ymd;
    final parts = s.split('-');
    if (parts.length != 3) return s;
    final m = int.tryParse(parts[1]) ?? parts[1];
    return '${parts[0]}년 $m월 ${parts[2]}일';
  }

  /// 이용 기간 "yyyy.MM.dd~yyyy.MM.dd".
  String _periodText(MembershipDetail d) {
    String dot(String s) =>
        (s.length >= 10 ? s.substring(0, 10) : s).replaceAll('-', '.');
    if (d.periodStartDt.isEmpty && d.periodEndDt.isEmpty) return '-';
    return '${dot(d.periodStartDt)}~${dot(d.periodEndDt)}';
  }
}
