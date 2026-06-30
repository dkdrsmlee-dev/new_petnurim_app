import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  String _searchQuery = '';
  String _selectedTab = '전체'; // '전체', 'ㄱ~ㄴ', 'ㄷ~ㅂ', 'ㅅ~ㅊ', 'ㅋ~ㅎ'

  static const Color _primaryColor = Color(0xFF7F4FFF);
  static const Color _borderColor = Color(0xFFD6DBE4);
  static const Color _textStrongColor = Color(0xFF30343C);
  static const Color _textMutedColor = Color(0xFF51565F);
  static const Color _placeholderColor = Color(0xFFA2ADBE);
  static const Color _bgGrayColor = Color(0xFFF4F6F8);
  static const Color _dividerColor = Color(0xFFE8EBF1);

  // 품종 데이터 마스터 리스트
  static const List<String> _dogBreeds = [
    '믹스견 [Mix]',
    '골든 리트리버 [Golden Retriever]',
    '그레이 하운드 [Grey Hound]',
    '그레이트 데인 [Great Dane]',
    '그레이트 피레니즈 [Great Pyrenees]',
    '기슈 이누 [Kishu Inu]',
    '노르웨이언 엘크하운드 [Norwegian Elkhound]',
    '노리치 테리어 [Norwich Terrier]',
    '노르포크 테리어 [Norfolk Terrier]',
    '뉴펀들랜드 [Newfoundland]',
    '닥스훈트 [Dachshund]',
    '도베르만 [Doberman]',
    '말티즈 [Maltese]',
    '미니어처 핀셔 [Miniature Pinscher]',
    '바셋 하운드 [Basset Hound]',
    '베들링턴 테리어 [Bedlington Terrier]',
    '보스턴 테리어 [Boston Terrier]',
    '보더 콜리 [Border Collie]',
    '비숑 프리제 [Bichon Frise]',
    '사모예드 [Samoyed]',
    '샤페이 [Shar Pei]',
    '시바견 [Shiba Inu]',
    '시베리안 허스키 [Siberian Husky]',
    '시츄 [Shih Tzu]',
    '아프간 하운드 [Afghan Hound]',
    '웰시 코기 [Welsh Corgi]',
    '진돗개 [Jindo Dog]',
    '치와와 [Chihuahua]',
    '코카 스파니엘 [Cocker Spaniel]',
    '콜리 [Collie]',
    '퍼그 [Pug]',
    '페키니즈 [Pekingese]',
    '포메라니안 [Pomeranian]',
    '푸들 [Poodle]',
    '풍산개 [Poongsan Dog]',
    '프렌치 불독 [French Bulldog]',
    '화이트 테리어 [White Terrier]'
  ];

  static const List<String> _catBreeds = [
    '믹스묘 [Mix]',
    '네벨룽 [Nebelung]',
    '노르웨이 숲 [Norwegian Forest Cat]',
    '데본렉스 [Devon Rex]',
    '라가머핀 [Ragamuffin]',
    '러시안 블루 [Russian Blue]',
    '렉돌 [Ragdoll]',
    '맹크스 [Manx]',
    '메인쿤 [Maine Coon]',
    '발리네즈 [Balinese]',
    '버만 [Birman]',
    '버미즈 [Burmese]',
    '뱅갈 [Bengal]',
    '봄베이 [Bombay]',
    '브리티시 숏헤어 [British Shorthair]',
    '사바나캣 [Savannah Cat]',
    '샤트룩스 [Chartreux]',
    '샴 [Siamese]',
    '셀커크 렉스 [Selkirk Rex]',
    '소말리 [Somali]',
    '스코티시 폴드 [Scottish Fold]',
    '스노우슈 [Snowshoe]',
    '스핑크스 [Sphynx]',
    '싱가퓨라 [Singapura]',
    '아메리칸 숏헤어 [American Shorthair]',
    '아메리칸 와이어헤어 [American Wirehair]',
    '아메리칸 컬 [American Curl]',
    '아비시니안 [Abyssinian]',
    '오시캣 [Ocicat]',
    '요크 초콜릿 [York Chocolate]',
    '재패니즈 밥테일 [Japanese Bobtail]',
    '터키시 앙고라 [Turkish Angora]',
    '터키시 반 [Turkish Van]',
    '토이거 [Toyger]',
    '페르시안 [Persian]',
    '하바나 브라운 [Havana Brown]'
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
  }

  // 한글 한 글자의 초성 추출 도우미 함수
  String _getInitialConsonant(String text) {
    if (text.isEmpty) return '';
    final firstCode = text.codeUnitAt(0);
    // 한글 음절 범위 (가 ~ 힣: 0xAC00 ~ 0xD7A3)
    if (firstCode >= 0xAC00 && firstCode <= 0xD7A3) {
      final index = (firstCode - 0xAC00) ~/ 588;
      const consonants = [
        'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ',
        'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ'
      ];
      return consonants[index];
    }
    return text[0];
  }

  // 초성 그룹 탭 매칭 검증
  bool _matchesTabGroup(String breedName) {
    if (_selectedTab == '전체') return true;

    final initial = _getInitialConsonant(breedName);
    if (initial.isEmpty) return false;

    if (_selectedTab == 'ㄱ~ㄴ') {
      return const ['ㄱ', 'ㄲ', 'ㄴ'].contains(initial);
    } else if (_selectedTab == 'ㄷ~ㅂ') {
      return const ['ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ'].contains(initial);
    } else if (_selectedTab == 'ㅅ~ㅊ') {
      return const ['ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ'].contains(initial);
    } else if (_selectedTab == 'ㅋ~ㅎ') {
      return const ['ㅋ', 'ㅌ', 'ㅍ', 'ㅎ'].contains(initial);
    }
    return false;
  }

  // 검색어 매칭 검증
  bool _matchesSearch(String breedName) {
    if (_searchQuery.isEmpty) return true;
    final normalizedSearch = _searchQuery.toLowerCase();
    final normalizedBreed = breedName.toLowerCase();
    return normalizedBreed.contains(normalizedSearch);
  }

  @override
  Widget build(BuildContext context) {
    final breeds = widget.petType == 'DOG' ? _dogBreeds : _catBreeds;
    // 필터링 적용 리스트
    final filteredBreeds = breeds.where((breed) {
      return _matchesTabGroup(breed) && _matchesSearch(breed);
    }).toList();

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
                      setState(() {
                        _selectedTab = tabName;
                      });
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
              child: filteredBreeds.isEmpty
                  ? const Center(
                      child: Text(
                        '검색 결과에 맞는 품종이 없습니다.',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 16,
                          color: _placeholderColor,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredBreeds.length,
                      separatorBuilder: (context, index) => const Divider(
                        color: _dividerColor,
                        height: 1,
                        thickness: 1,
                      ),
                      itemBuilder: (context, index) {
                        final breed = filteredBreeds[index];
                        return GestureDetector(
                          onTap: () {
                            context.pop(breed); // 선택값을 넘겨주며 뒤로가기
                          },
                          child: Container(
                            height: 54,
                            alignment: Alignment.centerLeft,
                            color: Colors.transparent,
                            child: Text(
                              breed,
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
