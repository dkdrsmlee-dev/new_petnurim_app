

class NoticeFile {
  final String boardFileId;
  final String fileId;
  final String originName;
  final String fileSize;

  NoticeFile({
    required this.boardFileId,
    required this.fileId,
    required this.originName,
    required this.fileSize,
  });

  factory NoticeFile.fromJson(Map<String, dynamic> json) {
    return NoticeFile(
      boardFileId: json['boardFileId'] as String,
      fileId: json['fileId'] as String,
      originName: json['originName'] as String,
      fileSize: json['fileSize'] as String,
    );
  }
}

class NoticeItem {
  final String boardId;
  final String title;
  final String regDt;
  final String? viewCount;

  NoticeItem({
    required this.boardId,
    required this.title,
    required this.regDt,
    this.viewCount,
  });

  factory NoticeItem.fromJson(Map<String, dynamic> json) {
    return NoticeItem(
      boardId: json['boardId'] as String,
      title: json['title'] as String,
      regDt: json['regDt'] as String,
      viewCount: json['viewCount']?.toString(),
    );
  }
}

class NoticeDetail {
  final String boardId;
  final String title;
  final String content;
  final String regDt;
  final String? viewCount;
  final List<NoticeFile> files;

  NoticeDetail({
    required this.boardId,
    required this.title,
    required this.content,
    required this.regDt,
    this.viewCount,
    required this.files,
  });

  factory NoticeDetail.fromJson(Map<String, dynamic> json) {
    return NoticeDetail(
      boardId: json['boardId'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      regDt: json['regDt'] as String,
      viewCount: json['viewCount']?.toString(),
      files: (json['files'] as List<dynamic>?)
              ?.map((e) => NoticeFile.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
