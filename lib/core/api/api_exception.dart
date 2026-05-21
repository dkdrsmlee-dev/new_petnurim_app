class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.code, this.data});

  final String message;
  final int? statusCode;
  final String? code;
  final Object? data;

  @override
  String toString() {
    final details = <String>[];
    if (statusCode != null) {
      details.add('HTTP $statusCode');
    }
    if (code != null && code!.isNotEmpty) {
      details.add('코드: $code');
    }
    
    if (details.isEmpty) {
      return message;
    }
    return '$message (${details.join(', ')})';
  }
}
