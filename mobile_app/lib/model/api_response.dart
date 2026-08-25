/// Generic API response wrapper used across the mobile app services.
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;

  ApiResponse({required this.success, this.data, this.message});

  factory ApiResponse.error(String message) =>
      ApiResponse(success: false, message: message);

  @override
  String toString() => 'ApiResponse(success: $success, message: $message)';
}
