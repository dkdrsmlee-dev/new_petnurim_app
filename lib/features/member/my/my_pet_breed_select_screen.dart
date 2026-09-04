import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../data/pet_repository.dart';
import '../domain/pet_breed.dart';
import '../../../core/theme/app_colors.dart';

class MyPetBreedSelectScreen extends ConsumerStatefulWidget {
  final String petType; // 'DOG' 또는 'CAT'

  const MyPetBreedSelectScreen({
    super.key,
    required this.petType,
  });

  @override
  ConsumerState<MyPetBreedSelectScreen> createState() => _MyPetBreedSelectScreenState();
}

class _MyPetBreedSelectScreenState extends ConsumerState<MyPetBreedSelectScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String _searchQuery = '';
  String _selectedTab = '전체'; // '전체', 'ㄱ~ㄴ', 'ㄷ~ㅂ', 'ㅅ~ㅊ', 'ㅋ~ㅎ'
  
  List<PetBreed> _breeds = [];
  bool _isLoading = false;
  bool _hasNext = true;
  String? _nextCursor;
  String? _errorMessage;
  Timer? _debounce;


  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    Future.microtask(() => _fetchBreeds(reset: true));
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final query = _searchController.text.trim();
      if (query != _searchQuery) {
        setState(() {
          _searchQuery = query;
        });
        _fetchBreeds(reset: true);
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _fetchBreeds();
    }
  }

  Future<void> _fetchBreeds({bool reset = false}) async {
    if (_isLoading) return;
    if (!reset && !_hasNext) return;

    setState(() {
      _isLoading = true;
      if (reset) {
        _breeds = [];
        _hasNext = true;
        _nextCursor = null;
        _errorMessage = null;
      }
    });

    try {
      final choseongCodeMap = {
        '전체': 'ALL',
        'ㄱ~ㄴ': 'GN',
        'ㄷ~ㅂ': 'DB',
        'ㅅ~ㅊ': 'SC',
        'ㅋ~ㅎ': 'KH',
      };
      final choseong = choseongCodeMap[_selectedTab] ?? 'ALL';

      final repository = ref.read(petRepositoryProvider);
      final response = await repository.searchBreeds(
        petTypeCode: widget.petType,
        choseongCode: choseong,
        keyword: _searchQuery.isEmpty ? null : _searchQuery,
        cursor: _nextCursor,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          _breeds.addAll(response.items);
          _hasNext = response.hasNext;
          _nextCursor = response.nextCursor;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint('Breed API failed: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (reset) {
            final errStr = e.toString();
            if (errStr.contains('로그인 정보')) {
              _errorMessage = '로그인 정보가 유효하지 않습니다.\n다시 로그인해 주세요.';
            } else {
              _errorMessage = '품종 목록을 불러오지 못했습니다.\n네트워크 연결 상태를 확인해 주세요.';
            }
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final listCount = _breeds.length + (_isLoading ? 1 : 0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        // 상태바 자리를 50 으로 고정해 그리면 기기마다 어긋난다(실제 26.7).
        // Scaffold 가 primary 일 때 appBar 높이에 상태바를 자동으로 더하므로
        // 여기서는 피그마 Popup_header 높이 56 만 준다(더하면 이중 계산).
        // 상태바만큼 아래로 미는 건 아래 SafeArea 가 한다. (검수 17행 ①)
        preferredSize: const Size.fromHeight(56),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.white,
              child: Row(
                children: [
                  const SizedBox(width: 24), // 좌측 화살표 없는 대칭 여백 확보
                  Expanded(
                    child: Text(
                      '품종 선택',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700, // Bold
                        letterSpacing: -0.54,
                        color: AppColors.textStrong,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      context.pop();
                    },
                    child: const Icon(
                      Icons.close,
                      size: 24,
                      color: AppColors.textStrong,
                    ),
                  ),
                ],
              ),
            ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        // appBar 가 이미 상단 안전영역을 차지하므로 여기서 또 더하면
        // 헤더와 검색창 사이가 상태바 높이만큼 벌어진다.
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 검색창 영역
            Padding(
              // 피그마: 헤더 아래 16, 검색창 아래 16
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: TextFormField(
                controller: _searchController,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textStrong,
                ),
                decoration: InputDecoration(
                  hintText: '검색어를 입력해 주세요.',
                  hintStyle: const TextStyle(
                    fontSize: 16,
                    color: AppColors.placeholder,
                    letterSpacing: -0.66,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  // 피그마 Icon/Serach/24(624:11933): 원 r6.93 + 손잡이,
                  // stroke 2, #51565F. Material 아이콘과 형태가 달랐다. (검수 17행 ②)
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: SvgPicture.asset(
                      'assets/images/ic_search_24.svg',
                      width: 24,
                      height: 24,
                    ),
                  ),
                  suffixIconConstraints: const BoxConstraints(
                    minWidth: 24 + 16,
                    minHeight: 24,
                  ),
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
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            // 2. 초성 필터 탭 영역 (가로 스크롤 가능)
            Container(
              height: 40,
              margin: const EdgeInsets.only(bottom: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: ['전체', 'ㄱ~ㄴ', 'ㄷ~ㅂ', 'ㅅ~ㅊ', 'ㅋ~ㅎ'].map((tabName) {
                  final isSelected = _selectedTab == tabName;
                  return GestureDetector(
                    onTap: () {
                      if (_selectedTab != tabName) {
                        setState(() {
                          _selectedTab = tabName;
                        });
                        _fetchBreeds(reset: true);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.textStrong : AppColors.bgGray,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        tabName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textDisabled,
                          letterSpacing: -0.66,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            // 3. 품종 리스트 영역
            Expanded(
              child: _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Color(0xFFFA6262),
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _fetchBreeds(reset: true),
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text(
                              '다시 시도',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : _breeds.isEmpty && !_isLoading
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.search_off,
                                color: AppColors.placeholder,
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? '입력하신 검색어와 일치하는 품종이 없습니다.'
                                    : '등록된 품종 정보가 없습니다.',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.placeholder,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: listCount,
                          separatorBuilder: (context, index) {
                            if (index == _breeds.length - 1 && _isLoading) {
                              return const SizedBox.shrink();
                            }
                            return const Divider(
                              color: AppColors.borderLight,
                              height: 1,
                              thickness: 1,
                            );
                          },
                          itemBuilder: (context, index) {
                            if (index == _breeds.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                  ),
                                ),
                              );
                            }

                            final breed = _breeds[index];
                            return GestureDetector(
                              onTap: () {
                                context.pop(breed); // 선택 품종 객체를 넘겨주며 뒤로가기
                              },
                              child: Container(
                                height: 54,
                                alignment: Alignment.centerLeft,
                                color: Colors.transparent,
                                child: Text(
                                  breed.breedNameKor,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500, // Medium
                                    color: AppColors.textMuted,
                                    letterSpacing: -0.66,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
