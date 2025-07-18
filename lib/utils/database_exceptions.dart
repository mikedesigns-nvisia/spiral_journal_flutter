/// Custom database exception for better error handling
class DatabaseTransactionException implements Exception {
  final String message;
  final String? operation;
  final dynamic originalError;

  const DatabaseTransactionException(
    this.message, {
    this.operation,
    this.originalError,
  });

  @override
  String toString() {
    if (operation != null) {
      return 'DatabaseTransactionException in $operation: $message';
    }
    return 'DatabaseTransactionException: $message';
  }
}

/// Custom validation exception for database operations
class DatabaseValidationException implements Exception {
  final String message;
  final String? field;

  const DatabaseValidationException(
    this.message, {
    this.field,
  });

  @override
  String toString() {
    if (field != null) {
      return 'DatabaseValidationException for field $field: $message';
    }
    return 'DatabaseValidationException: $message';
  }
}

/// Exception for database initialization failures
class DatabaseInitializationException implements Exception {
  final String message;
  final dynamic originalError;

  const DatabaseInitializationException(
    this.message, {
    this.originalError,
  });

  @override
  String toString() {
    return 'DatabaseInitializationException: $message';
  }
}

/// Exception for database security-related failures
class DatabaseSecurityException implements Exception {
  final String message;
  final dynamic originalError;

  const DatabaseSecurityException(
    this.message, {
    this.originalError,
  });

  @override
  String toString() {
    return 'DatabaseSecurityException: $message';
  }
}

/// Exception for database export/import operations
class DatabaseExportException implements Exception {
  final String message;
  final dynamic originalError;

  const DatabaseExportException(
    this.message, {
    this.originalError,
  });

  @override
  String toString() {
    return 'DatabaseExportException: $message';
  }
}

/// Exception for general database operations
class DatabaseOperationException implements Exception {
  final String message;
  final String? operation;
  final dynamic originalError;

  const DatabaseOperationException(
    this.message, {
    this.operation,
    this.originalError,
  });

  @override
  String toString() {
    if (operation != null) {
      return 'DatabaseOperationException in $operation: $message';
    }
    return 'DatabaseOperationException: $message';
  }
}