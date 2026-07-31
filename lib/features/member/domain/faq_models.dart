// 자주 묻는 질문(FAQ) 도메인 모델.
//
// 백엔드 board/faqs 는 공지사항과 동일한 커서 페이징 구조로,
// 목록(FaqItem)에는 제목만 있고 답변 본문(content)은 상세(FaqDetail)에서 내려온다.

class FaqItem {
  final String boardId;
  final String title;
  final String? categoryCode;
  final String? regDt;
  final String? viewCount;

  FaqItem({
    required this.boardId,
    required this.title,
    this.categoryCode,
    this.regDt,
    this.viewCount,
  });

  factory FaqItem.fromJson(Map<String, dynamic> json) {
    return FaqItem(
      boardId: json['boardId'].toString(),
      title: (json['title'] ?? '') as String,
      categoryCode: json['categoryCode']?.toString(),
      regDt: json['regDt']?.toString(),
      viewCount: json['viewCount']?.toString(),
    );
  }
}

class FaqDetail {
  final String boardId;
  final String title;
  final String content;
  final String? regDt;

  FaqDetail({
    required this.boardId,
    required this.title,
    required this.content,
    this.regDt,
  });

  factory FaqDetail.fromJson(Map<String, dynamic> json) {
    return FaqDetail(
      boardId: json['boardId'].toString(),
      title: (json['title'] ?? '') as String,
      content: (json['content'] ?? '') as String,
      regDt: json['regDt']?.toString(),
    );
  }
}
