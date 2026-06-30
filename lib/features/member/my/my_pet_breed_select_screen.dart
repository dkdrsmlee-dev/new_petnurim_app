import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/pet_repository.dart';
import '../domain/pet_breed.dart';

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

  static const Color _primaryColor = Color(0xFF7F4FFF);
  static const Color _borderColor = Color(0xFFD6DBE4);
  static const Color _textStrongColor = Color(0xFF30343C);
  static const Color _textMutedColor = Color(0xFF51565F);
  static const Color _placeholderColor = Color(0xFFA2ADBE);
  static const Color _bgGrayColor = Color(0xFFF4F6F8);
  static const Color _dividerColor = Color(0xFFE8EBF1);

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
        preferredSize: const Size.fromHeight(106), // Status bar + page header
        child: Column(
          children: [
            // 페이지 상단 타이틀 영역
            Container(
              height: 50,
              color: Colors.white,
            ),
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
                        fontFamily: 'Pretendard',
                        fontSize: 18,
                        fontWeight: FontWeight.w700, // Bold
                        letterSpacing: -0.54,
                        color: _textStrongColor,
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
                      color: _textStrongColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 검색창 영역
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextFormField(
                controller: _searchController,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 16,
                  color: _textStrongColor,
                ),
                decoration: InputDecoration(
                  hintText: '검색어를 입력해 주세요.',
                  hintStyle: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    color: _placeholderColor,
                    letterSpacing: -0.66,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  suffixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF909AA9),
                    size: 24,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _primaryColor, width: 1.5),
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
                        color: isSelected ? _textStrongColor : _bgGrayColor,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        tabName,
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? Colors.white : const Color(0xFF909AA9),
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
                              fontFamily: 'Pretendard',
                              fontSize: 16,
                              color: _textMutedColor,
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
                                fontFamily: 'Pretendard',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
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
                                color: _placeholderColor,
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? '입력하신 검색어와 일치하는 품종이 없습니다.'
                                    : '등록된 품종 정보가 없습니다.',
                                style: const TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 16,
                                  color: _placeholderColor,
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
                              color: _dividerColor,
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
                                    color: _primaryColor,
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
                                    fontFamily: 'Pretendard',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500, // Medium
                                    color: _textMutedColor,
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
