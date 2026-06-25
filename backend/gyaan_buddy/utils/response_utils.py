from rest_framework import status
from rest_framework.response import Response
from typing import Any, Dict, List, Optional, Union


class ResponseUtils:
    """Utility class for standardized API responses."""
    
    @staticmethod
    def success_response(
        data: Any = None,
        message: str = "Success",
        status_code: int = status.HTTP_200_OK
    ) -> Response:
        """
        Create a standardized success response.
        
        Args:
            data: Response data
            message: Success message
            status_code: HTTP status code
            
        Returns:
            Response object
        """
        response_data = {
            "success": True,
            "message": message,
            "data": data
        }
        return Response(response_data, status=status_code)
    
    @staticmethod
    def error_response(
        message: str = "Error occurred",
        errors: Optional[Dict] = None,
        status_code: int = status.HTTP_400_BAD_REQUEST
    ) -> Response:
        """
        Create a standardized error response.
        
        Args:
            message: Error message
            errors: Detailed error information
            status_code: HTTP status code
            
        Returns:
            Response object
        """
        response_data = {
            "success": False,
            "message": message,
            "errors": errors
        }
        return Response(response_data, status=status_code)
    
    @staticmethod
    def created_response(
        data: Any = None,
        message: str = "Resource created successfully"
    ) -> Response:
        """Create a 201 Created response."""
        return ResponseUtils.success_response(data, message, status.HTTP_201_CREATED)
    
    @staticmethod
    def no_content_response(
        message: str = "No content"
    ) -> Response:
        """Create a 204 No Content response."""
        return ResponseUtils.success_response(None, message, status.HTTP_204_NO_CONTENT)
    
    @staticmethod
    def accepted_response(
        data: Any = None,
        message: str = "Request accepted"
    ) -> Response:
        """Create a 202 Accepted response."""
        return ResponseUtils.success_response(data, message, status.HTTP_202_ACCEPTED)
    
    @staticmethod
    def not_found_response(
        message: str = "Resource not found"
    ) -> Response:
        """Create a 404 Not Found response."""
        return ResponseUtils.error_response(message, status_code=status.HTTP_404_NOT_FOUND)
    
    @staticmethod
    def unauthorized_response(
        message: str = "Authentication required"
    ) -> Response:
        """Create a 401 Unauthorized response."""
        return ResponseUtils.error_response(message, status_code=status.HTTP_401_UNAUTHORIZED)
    
    @staticmethod
    def forbidden_response(
        message: str = "Permission denied"
    ) -> Response:
        """Create a 403 Forbidden response."""
        return ResponseUtils.error_response(message, status_code=status.HTTP_403_FORBIDDEN)
    
    @staticmethod
    def validation_error_response(
        errors: Dict,
        message: str = "Validation error"
    ) -> Response:
        """Create a 400 Bad Request response for validation errors."""
        return ResponseUtils.error_response(message, errors, status.HTTP_400_BAD_REQUEST)
    
    @staticmethod
    def server_error_response(
        message: str = "Internal server error"
    ) -> Response:
        """Create a 500 Internal Server Error response."""
        return ResponseUtils.error_response(message, status_code=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    @staticmethod
    def paginated_response(
        data: List,
        count: int,
        next_url: Optional[str] = None,
        previous_url: Optional[str] = None,
        message: str = "Data retrieved successfully"
    ) -> Response:
        """
        Create a paginated response.
        
        Args:
            data: List of items
            count: Total count of items
            next_url: URL for next page
            previous_url: URL for previous page
            message: Success message
            
        Returns:
            Response object
        """
        response_data = {
            "success": True,
            "message": message,
            "data": data,
            "pagination": {
                "count": count,
                "next": next_url,
                "previous": previous_url
            }
        }
        return Response(response_data, status=status.HTTP_200_OK)


class StatusCodes:
    """Common HTTP status codes for easy reference."""
    
    OK = status.HTTP_200_OK
    CREATED = status.HTTP_201_CREATED
    ACCEPTED = status.HTTP_202_ACCEPTED
    NO_CONTENT = status.HTTP_204_NO_CONTENT
    
    BAD_REQUEST = status.HTTP_400_BAD_REQUEST
    UNAUTHORIZED = status.HTTP_401_UNAUTHORIZED
    FORBIDDEN = status.HTTP_403_FORBIDDEN
    NOT_FOUND = status.HTTP_404_NOT_FOUND
    METHOD_NOT_ALLOWED = status.HTTP_405_METHOD_NOT_ALLOWED
    CONFLICT = status.HTTP_409_CONFLICT
    UNPROCESSABLE_ENTITY = status.HTTP_422_UNPROCESSABLE_ENTITY
    
    INTERNAL_SERVER_ERROR = status.HTTP_500_INTERNAL_SERVER_ERROR
    NOT_IMPLEMENTED = status.HTTP_501_NOT_IMPLEMENTED
    SERVICE_UNAVAILABLE = status.HTTP_503_SERVICE_UNAVAILABLE


class Messages:
    """Common response messages."""
    
    SUCCESS = "Success"
    CREATED = "Resource created successfully"
    UPDATED = "Resource updated successfully"
    DELETED = "Resource deleted successfully"
    ACCEPTED = "Request accepted"
    NO_CONTENT = "No content"
    
    ERROR = "Error occurred"
    NOT_FOUND = "Resource not found"
    UNAUTHORIZED = "Authentication required"
    FORBIDDEN = "Permission denied"
    VALIDATION_ERROR = "Validation error"
    SERVER_ERROR = "Internal server error"
    
    USER_CREATED = "User created successfully"
    USER_UPDATED = "User updated successfully"
    USER_DELETED = "User deleted successfully"
    LOGIN_SUCCESS = "Login successful"
    LOGOUT_SUCCESS = "Logout successful"
    PASSWORD_CHANGED = "Password changed successfully"
    EXP_ADDED = "Experience points added successfully"
    
    INVALID_CREDENTIALS = "Invalid username or password"
    USER_DISABLED = "User account is disabled"
    PASSWORD_MISMATCH = "Passwords don't match"
    ROLL_NUMBER_REQUIRED = "Roll number is required for students"
    ROLL_NUMBER_INVALID = "Roll number should only be set for students"
    ROLL_NUMBER_EXISTS = "A user with this roll number already exists"
    OLD_PASSWORD_INCORRECT = "Old password is incorrect"


def success(data=None, message=Messages.SUCCESS, status_code=StatusCodes.OK):
    """Quick success response."""
    return ResponseUtils.success_response(data, message, status_code)


def error(message=Messages.ERROR, errors=None, status_code=StatusCodes.BAD_REQUEST):
    """Quick error response."""
    return ResponseUtils.error_response(message, errors, status_code)


def created(data=None, message=Messages.CREATED):
    """Quick created response."""
    return ResponseUtils.created_response(data, message)


def not_found(message=Messages.NOT_FOUND):
    """Quick not found response."""
    return ResponseUtils.not_found_response(message)


def unauthorized(message=Messages.UNAUTHORIZED):
    """Quick unauthorized response."""
    return ResponseUtils.unauthorized_response(message)


def forbidden(message=Messages.FORBIDDEN):
    """Quick forbidden response."""
    return ResponseUtils.forbidden_response(message)


def validation_error(errors, message=Messages.VALIDATION_ERROR):
    """Quick validation error response."""
    return ResponseUtils.validation_error_response(errors, message)


def server_error(message=Messages.SERVER_ERROR):
    """Quick server error response."""
    return ResponseUtils.server_error_response(message)
