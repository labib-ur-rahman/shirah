/// Custom exception class to handle Firebase Cloud Functions errors
class SLFirebaseFunctionsException implements Exception {
  /// The Firebase Cloud Functions error code associated with the exception
  final String code;

  /// Optional error message from the function
  final String? message;

  /// Default constructor
  SLFirebaseFunctionsException(this.code, {this.message});

  /// Get user-friendly error message based on error code
  String get formattedMessage {
    switch (code) {
      // Invalid Argument Errors
      case 'invalid-argument':
        return 'Invalid argument provided to the function. Please check your input.';

      // Authentication & Permission Errors
      case 'unauthenticated':
        return 'Authentication required. Please login to continue.';
      case 'permission-denied':
        return 'You do not have permission to perform this action.';

      // Resource Errors
      case 'not-found':
        return 'The requested resource was not found.';
      case 'already-exists':
        return 'The resource already exists. Please use a different identifier.';
      case 'resource-exhausted':
        return 'Resource quota exceeded. Please try again later.';
      case 'conflict':
        return 'Operation conflicts with existing data. Please resolve and try again.';

      // Operation Errors
      case 'aborted':
        return 'Operation was aborted. Please try again.';
      case 'cancelled':
        return 'Operation was cancelled.';
      case 'deadline-exceeded':
        return 'Operation timed out. Please try again.';

      // Precondition Errors
      case 'failed-precondition':
        return 'Operation precondition was not met. Please check your request.';
      case 'out-of-range':
        return 'Operation argument is out of range. Please verify your input.';

      // Data Errors
      case 'data-loss':
        return 'Unrecoverable data loss occurred. Please contact support.';
      case 'invalid-data-format':
        return 'Invalid data format received from the server.';

      // Server Errors
      case 'internal':
        return 'Internal server error. Please try again later.';
      case 'unavailable':
        return 'The service is currently unavailable. Please try again later.';
      case 'unimplemented':
        return 'This feature is not yet implemented.';
      case 'unknown':
        return 'An unknown error occurred in the cloud function.';

      // Network Errors
      case 'network-request-failed':
        return 'Network request failed. Please check your internet connection.';

      // Custom SHIRAH specific errors
      case 'invalid-invite-code':
        return 'The invite code is invalid or has expired.';
      case 'invite-code-already-used':
        return 'This invite code has already been used.';
      case 'insufficient-balance':
        return 'Insufficient wallet balance to complete this operation.';
      case 'transaction-failed':
        return 'Transaction failed. Please try again.';
      case 'user-limit-exceeded':
        return 'User limit exceeded. Please contact support.';
      case 'verification-failed':
        return 'Verification failed. Please try again.';
      case 'referral-limit-exceeds':
        return 'Referral limit has been exceeded.';
      case 'invalid-amount':
        return 'Invalid amount provided. Please check and try again.';
      case 'withdrawal-not-allowed':
        return 'Withdrawal is not allowed at this time.';
      case 'duplicate-transaction':
        return 'This transaction has already been processed.';

      // Default case for unknown errors
      default:
        return message ??
            'Cloud function error occurred. Code: $code. Please contact support if the issue persists.';
    }
  }
}
