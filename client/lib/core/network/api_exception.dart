class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  ApiException({required this.message, this.statusCode, this.code});

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';

  // Parse error from our standard API response envelope
  // { success: false, error: { code: '...', message: '...' } }
  factory ApiException.fromResponse(
    Map<String, dynamic> data,
    int? statusCode,
  ) {
    final error = data['error'] as Map<String, dynamic>?;
    return ApiException(
      message: error?['message'] ?? 'An unexpected error occurred',
      code: error?['code'],
      statusCode: statusCode,
    );
  }

  factory ApiException.networkError() {
    return ApiException(
      message: 'Network error. Please check your connection.',
      statusCode: null,
    );
  }

  factory ApiException.timeoutError() {
    return ApiException(
      message: 'Request timed out. Please try again.',
      statusCode: null,
    );
  }
}
