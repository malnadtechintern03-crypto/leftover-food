/// Base failure class for domain layer error representation
abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code;

  @override
  int get hashCode => message.hashCode ^ code.hashCode;

  @override
  String toString() => '$runtimeType: $message';
}

/// Represents failure during database operations
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, {super.code});
}

/// Represents user input or business validation failure
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}

/// Represents not found failure
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, {super.code});
}

/// Represents file system/storage failure
class StorageFailure extends Failure {
  const StorageFailure(super.message, {super.code});
}

/// Unexpected general failure
class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unexpected error occurred.']);
}
