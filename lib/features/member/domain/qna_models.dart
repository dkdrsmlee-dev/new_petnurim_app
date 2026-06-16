class QnaFile {
  final String boardFileId;
  final String fileId;
  final String originName;
  final String fileSize;

  QnaFile({
    required this.boardFileId,
    required this.fileId,
    required this.originName,
    required this.fileSize,
  });

  factory QnaFile.fromJson(Map<String, dynamic> json) {
    return QnaFile(
      boardFileId: json['boardFileId'] as String,
      fileId: json['fileId'] as String,
      originName: json['originName'] as String,
      fileSize: json['fileSize'] as String,
    );
  }
}

class QnaAnswer {
  final String boardQnaAnswerId;
  final String boardQnaId;
  final String content;
  final String regDt;
  final List<QnaFile> files;

  QnaAnswer({
    required this.boardQnaAnswerId,
    required this.boardQnaId,
    required this.content,
    required this.regDt,
    required this.files,
  });

  factory QnaAnswer.fromJson(Map<String, dynamic> json) {
    return QnaAnswer(
      boardQnaAnswerId: json['boardQnaAnswerId'] as String,
      boardQnaId: json['boardQnaId'] as String,
      content: json['content'] as String,
      regDt: json['regDt'] as String,
      files: (json['files'] as List<dynamic>)
          .map((e) => QnaFile.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class QnaItem {
  final String boardQnaId;
  final String qnaTypeCode;
  final String title;
  final String processStatusCode;
  final String regDt;

  QnaItem({
    required this.boardQnaId,
    required this.qnaTypeCode,
    required this.title,
    required this.processStatusCode,
    required this.regDt,
  });

  factory QnaItem.fromJson(Map<String, dynamic> json) {
    return QnaItem(
      boardQnaId: json['boardQnaId'] as String,
      qnaTypeCode: json['qnaTypeCode'] as String,
      title: json['title'] as String,
      processStatusCode: json['processStatusCode'] as String,
      regDt: json['regDt'] as String,
    );
  }
}

class QnaDetail {
  final String boardQnaId;
  final String qnaTypeCode;
  final String title;
  final String content;
  final String processStatusCode;
  final String regDt;
  final List<QnaFile> files;
  final QnaAnswer? answer;

  QnaDetail({
    required this.boardQnaId,
    required this.qnaTypeCode,
    required this.title,
    required this.content,
    required this.processStatusCode,
    required this.regDt,
    required this.files,
    this.answer,
  });

  factory QnaDetail.fromJson(Map<String, dynamic> json) {
    return QnaDetail(
      boardQnaId: json['boardQnaId'] as String,
      qnaTypeCode: json['qnaTypeCode'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      processStatusCode: json['processStatusCode'] as String,
      regDt: json['regDt'] as String,
      files: (json['files'] as List<dynamic>)
          .map((e) => QnaFile.fromJson(e as Map<String, dynamic>))
          .toList(),
      answer: json['answer'] != null
          ? QnaAnswer.fromJson(json['answer'] as Map<String, dynamic>)
          : null,
    );
  }
}

class CursorPaginationResponse<T> {
  final List<T> items;
  final bool hasNext;
  final String? nextCursor;

  CursorPaginationResponse({
    required this.items,
    required this.hasNext,
    this.nextCursor,
  });

  factory CursorPaginationResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) fromJsonT,
  ) {
    return CursorPaginationResponse(
      items: (json['items'] as List<dynamic>)
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
      hasNext: json['hasNext'] as bool,
      nextCursor: json['nextCursor']?.toString(),
    );
  }
}
