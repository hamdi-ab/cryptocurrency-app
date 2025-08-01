
// A base class for all API-related exceptions
abstract class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

// Thrown when the server returns a non-200 status code.
class ServerException extends ApiException {
  ServerException(String message) : super('Server Error: $message');
}

// Thrown when the API rate limit is exceeded (HTTP 429).
class TooManyRequestsException extends ApiException {
  TooManyRequestsException() : super('Too many requests. Please try again later.');
}

// Thrown when there is a network connectivity issue.
class NetworkException extends ApiException {
  NetworkException() : super('Network Error: Please check your internet connection.');
}
