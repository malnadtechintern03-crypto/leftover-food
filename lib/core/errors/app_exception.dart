/// Base exception class for FoodSave
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException(this.message, {this.code, this.details});

  @override
  String toString() => 'AppException: $message (code: $code)';
}

/// Thrown when local database operations fail
class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.code, super.details});
}

/// Thrown when user input validation fails
class ValidationException extends AppException {
  const ValidationException(super.message, {super.code, super.details});
}

/// Thrown when requested entity is not found
class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.code, super.details});
}

/// Thrown when storage/file system operations fail
class StorageException extends AppException {
  const StorageException(super.message, {super.code, super.details});
}
