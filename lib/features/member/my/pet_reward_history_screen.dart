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

  Widget _buildTabBar() {
    return Row(
      children: List.generate(_tabLabels.length, (i) {
        final active = i == _tabIndex;
        return Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _switchTab(i),
            child: Container(
              alignment: Alignment.center,
              padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: active ? AppColors.textStrong : AppColors.border,
                    width: active ? 3 : 1,
                  ),
                ),
              ),
              child: Text(
                _tabLabels[i],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  color:
                      active ? AppColors.textStrong : AppColors.textSecondary,
                  letterSpacing: -0.66,
                ),
              ),
            ),
          ),
        );
      }),
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
              child: Column(
                children: [
                  _buildListHeader(0),
                  const SizedBox(height: 100),
                  const Center(
                    child: Text(
                      '리워드 내역이 없어요.',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
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
