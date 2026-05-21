class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.code, this.data});

  final String message;
  final int? statusCode;
  final String? code;
  final Object? data;

  @override
  String toString() {
    if (statusCode == null) {
      return message;
    }

    return '$message (HTTP $statusCode)';
  }
}
