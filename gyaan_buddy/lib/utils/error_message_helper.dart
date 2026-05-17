import '../services/api_service.dart';

/// Helper class to convert exceptions and error codes to user-friendly messages
class ErrorMessageHelper {
  /// Convert an exception to a user-friendly error message
  static String getErrorMessage(dynamic error) {
    if (error == null) {
      return 'An unexpected error occurred. Please try again.';
    }

    // Handle custom exceptions
    if (error is ApiException) {
      return _getApiErrorMessage(error.statusCode, error.data);
    }

    if (error is UnauthorizedException) {
      return 'Your session has expired. Please log in again.';
    }

    if (error is TimeoutException) {
      return 'The request took too long. Please check your internet connection and try again.';
    }

    if (error is NetworkException) {
      return 'No internet connection. Please check your network settings and try again.';
    }

    if (error is CancelException) {
      return 'Request was cancelled. Please try again.';
    }

    if (error is CertificateException) {
      return 'There was a security issue. Please try again later.';
    }

    if (error is UnknownException) {
      return 'An unexpected error occurred. Please try again.';
    }

    // Handle string errors
    if (error is String) {
      return _parseStringError(error);
    }

    // Handle DioException directly (if not caught by custom exceptions)
    if (error.toString().contains('DioException')) {
      if (error.toString().contains('timeout')) {
        return 'The request took too long. Please check your internet connection and try again.';
      }
      if (error.toString().contains('connection') || error.toString().contains('network')) {
        return 'No internet connection. Please check your network settings and try again.';
      }
      if (error.toString().contains('401') || error.toString().contains('403')) {
        return 'Your session has expired. Please log in again.';
      }
    }

    // Handle error codes in string format
    final errorString = error.toString();
    if (errorString.contains('401') || errorString.contains('403')) {
      return 'Invalid credentials. Please check your admission number and password.';
    }
    if (errorString.contains('404')) {
      return 'The requested resource was not found.';
    }
    if (errorString.contains('500') || errorString.contains('502') || errorString.contains('503')) {
      return 'Server error. Please try again later.';
    }
    if (errorString.contains('400')) {
      return 'Invalid request. Please check your input and try again.';
    }

    // Default fallback
    return 'An error occurred. Please try again.';
  }

  /// Get user-friendly message for API error status codes
  static String _getApiErrorMessage(int statusCode, dynamic data) {
    // Try to extract message from response data first
    if (data is Map<String, dynamic>) {
      // Check for common error message fields
      if (data['message'] != null && data['message'] is String) {
        final message = data['message'] as String;
        if (message.isNotEmpty && !message.contains('Exception') && !message.contains('Error:')) {
          return message;
        }
      }
      
      // Check for error field
      if (data['error'] != null && data['error'] is String) {
        return data['error'] as String;
      }
      
      // Check for errors object (validation errors)
      if (data['errors'] != null && data['errors'] is Map) {
        final errors = data['errors'] as Map;
        if (errors.isNotEmpty) {
          return formatValidationErrors(errors);
        }
      }
    }

    // Map status codes to user-friendly messages
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input and try again.';
      case 401:
        return 'Invalid credentials. Please check your admission number and password.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'The requested resource was not found.';
      case 409:
        return 'This resource already exists. Please try a different value.';
      case 422:
        return 'Validation error. Please check your input and try again.';
      case 429:
        return 'Too many requests. Please wait a moment and try again.';
      case 500:
        return 'Server error. Please try again later.';
      case 502:
        return 'Server is temporarily unavailable. Please try again later.';
      case 503:
        return 'Service is temporarily unavailable. Please try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  /// Format validation errors into a user-friendly message
  static String formatValidationErrors(Map<dynamic, dynamic> errors) {
    final List<String> errorMessages = [];
    
    errors.forEach((field, messages) {
      if (messages is List) {
        for (final message in messages) {
          if (message is String && message.isNotEmpty) {
            // Capitalize first letter and remove field prefix if present
            String formattedMessage = message;
            if (formattedMessage.toLowerCase().startsWith(field.toString().toLowerCase())) {
              formattedMessage = formattedMessage.substring(field.toString().length).trim();
              if (formattedMessage.startsWith(':')) {
                formattedMessage = formattedMessage.substring(1).trim();
              }
            }
            errorMessages.add(formattedMessage);
          }
        }
      } else if (messages is String && messages.isNotEmpty) {
        String formattedMessage = messages;
        if (formattedMessage.toLowerCase().startsWith(field.toString().toLowerCase())) {
          formattedMessage = formattedMessage.substring(field.toString().length).trim();
          if (formattedMessage.startsWith(':')) {
            formattedMessage = formattedMessage.substring(1).trim();
          }
        }
        errorMessages.add(formattedMessage);
      }
    });
    
    if (errorMessages.isEmpty) {
      return 'Validation error. Please check your input.';
    }
    
    // Return first error message, or join if multiple
    if (errorMessages.length == 1) {
      return errorMessages.first;
    }
    
    return errorMessages.join('. ');
  }

  /// Parse string errors to extract meaningful messages
  static String _parseStringError(String error) {
    // Remove technical prefixes
    String cleaned = error;
    
    // Remove exception class names
    cleaned = cleaned.replaceAll(RegExp(r'^\w+Exception:\s*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'^\w+Error:\s*'), '');
    
    // Remove status codes if they're at the start
    cleaned = cleaned.replaceAll(RegExp(r'^\d+\s*-\s*'), '');
    
    // If the cleaned message is still technical, use default
    if (cleaned.contains('Exception') || 
        cleaned.contains('Error:') || 
        cleaned.contains('DioException') ||
        cleaned.length < 5) {
      return 'An error occurred. Please try again.';
    }
    
    return cleaned.trim();
  }
}

