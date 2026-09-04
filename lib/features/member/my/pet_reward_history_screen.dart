import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/number_format.dart';
import '../../../core/widgets/page_header.dart';
import '../data/pet_repository.dart';
import '../domain/pet_reward_history.dart';

/// 마이펫 리워드 내역 (USR-RWD-011).
/// 이용내역(historyType=ALL) / 소멸내역(EXPIRE) 탭 + 커서 무한스크롤.
class PetRewardHistoryScreen extends ConsumerStatefulWidget {
  const PetRewardHistoryScreen({super.key, required this.myPetId});

  final String myPetId;

  @override
  ConsumerState<PetRewardHistoryScreen> createState() =>
      _PetRewardHistoryScreenState();
}

/// 탭별 페이징 상태.
class _TabState {
  _TabState(this.historyType);

  final String historyType;
  final List<PetRewardHistoryItem> items = [];
  String? nextCursor;
  bool hasNext = true;
  bool isLoading = false;
  bool loadedOnce = false;
  Object? error;
}

class _PetRewardHistoryScreenState
    extends ConsumerState<PetRewardHistoryScreen> {
  static const List<String> _tabLabels = ['이용내역', '소멸내역'];
  static const List<String> _tabTypes = ['ALL', 'EXPIRE'];

  int _tabIndex = 0;
  late final List<_TabState> _states;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _states = _tabTypes.map(_TabState.new).toList();
    _scrollController.addListener(_onScroll);
    _load(0);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _load(_tabIndex);
    }
  }

  Future<void> _load(int index, {bool reset = false}) async {
    final state = _states[index];
    if (state.isLoading) return;
    if (!reset && state.loadedOnce && !state.hasNext) return;

    setState(() {
      state.isLoading = true;
      if (reset) state.error = null;
    });

    try {
      final res = await ref.read(petRepositoryProvider).getPetRewardHistory(
            myPetId: widget.myPetId,
            historyType: state.historyType,
            cursor: reset ? null : state.nextCursor,
            limit: 20,
          );
      if (!mounted) return;
      setState(() {
        if (reset) state.items.clear();
        state.items.addAll(res.items);
        state.hasNext = res.hasNext;
        state.nextCursor = res.nextCursor;
        state.loadedOnce = true;
        state.error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => state.error = e);
    } finally {
      if (mounted) setState(() => state.isLoading = false);
    }
  }

  void _switchTab(int index) {
    if (_tabIndex == index) return;
    setState(() => _tabIndex = index);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    if (!_states[index].loadedOnce) _load(index);
  }

  @override
  Widget build(BuildContext context) {
    final state = _states[_tabIndex];
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: NurimPageHeader(
        title: '리워드 내역',
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildTabBar(),
            Expanded(child: _buildBody(state)),
          ],
        ),
      ),
    );
  }

  /// 피그마 Tab base(657:9612) 활성 밑줄 색 gray/110.
  static const Color _tabActiveLine = Color(0xFF3F434A);

  Widget _buildTabBar() {
    // 예전에는 탭마다 자기 하단 보더를 그렸다(활성 3 / 비활성 1). 보더는
    // 컨테이너 안쪽에 그려져서 두 선의 두께가 다르면 위 끝이 어긋나 사이가
    // 떠 보였다. 구분선을 탭 전체 폭에 1 로 깔고 활성 표시를 그 위에 겹쳐
    // 아래 끝을 맞춘다. (검수 18행 ①)
    final n = _tabLabels.length;
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Row(
          children: List.generate(n, (i) {
            final active = i == _tabIndex;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _switchTab(i),
                child: Container(
                  alignment: Alignment.center,
                  // 피그마 Tab base: py 12 + 텍스트 22 = 46
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  child: Text(
                    _tabLabels[i],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                      height: 1.4,
                      // 피그마: 활성 text/strong, 비활성 text/subtle(#909AA9)
                      color:
                          active ? AppColors.textStrong : AppColors.textDisabled,
                      letterSpacing: -0.66,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        // 탭 전체를 가로지르는 하단 구분선
        Container(height: 1, color: AppColors.border),
        // 활성 탭 표시. 폭을 비율로 잡아 탭 수·화면 폭이 달라져도 맞는다.
        Align(
          alignment: Alignment(n > 1 ? -1 + 2 * _tabIndex / (n - 1) : 0, 1),
          child: FractionallySizedBox(
            widthFactor: 1 / n,
            child: Container(height: 3, color: _tabActiveLine),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(_TabState state) {
    if (!state.loadedOnce && state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (!state.loadedOnce && state.error != null) {
      return _buildError();
    }
    if (state.loadedOnce && state.items.isEmpty) {
      return _buildEmpty();
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _load(_tabIndex, reset: true),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: state.items.length + 2, // 헤더 + 항목들 + 푸터
        itemBuilder: (context, index) {
          if (index == 0) return _buildListHeader(state.items.length);
          if (index == state.items.length + 1) {
            return (state.isLoading && state.items.isNotEmpty)
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : const SizedBox(height: 8);
          }
          return _buildItem(state.items[index - 1]);
        },
      ),
    );
  }

  Widget _buildListHeader(int count) {
    return Container(
      width: double.infinity,
      color: AppColors.bgGray,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text(
                '전체 ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: -0.66,
                ),
              ),
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textStrong,
                  letterSpacing: -0.66,
                ),
              ),
            ],
          ),
          const Text(
            '최신 내역 순',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              letterSpacing: -0.66,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(PetRewardHistoryItem item) {
    final amountColor = item.isPlus ? AppColors.primary : AppColors.textStrong;
    final sign = item.isPlus ? '+' : '-';
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title.isEmpty ? '-' : item.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textStrong,
                    letterSpacing: -0.66,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.dateText,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    letterSpacing: -0.66,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.typeLabel,
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
          const SizedBox(width: 16),
          Text(
            '$sign${formatThousands(item.amount)}PR',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: amountColor,
              letterSpacing: -0.66,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => _load(_tabIndex, reset: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              // 스크롤뷰 안은 높이가 무한이라 Expanded 를 그냥 쓰면 렌더가
              // 죽는다. IntrinsicHeight 로 높이를 확정해 준다.
              child: IntrinsicHeight(
                child: Column(
                children: [
                  _buildListHeader(0),
                  // 고정 100 이면 화면이 길수록 위로 치우친다. 남는 공간의
                  // 가운데에 오도록 한다. (검수 18행 ②)
                  Expanded(
                    child: Center(
                    child: Text(
                      '리워드 내역이 없어요.',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    ),
                  ),
                ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '리워드 내역을 불러오지 못했습니다.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _load(_tabIndex, reset: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}
