import logging
from rest_framework import viewsets, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from gyaan_buddy.users.models import Class
from gyaan_buddy.utils.response_utils import success, created, validation_error

logger = logging.getLogger('gyaan_buddy.classes')
api_logger = logging.getLogger('gyaan_buddy.api')


class ClassViewSet(viewsets.ModelViewSet):
    """ViewSet for Class model."""
    queryset = Class.objects.all()
    serializer_class = None
    permission_classes = [permissions.IsAuthenticated]
    
    def list(self, request, *args, **kwargs):
        """List classes with logging."""
        api_logger.info(f"Class list requested by {request.user.username} (ID: {request.user.id}) from {request.META.get('REMOTE_ADDR', 'unknown')}")
        
        queryset = self.filter_queryset(self.get_queryset())
        
        return success(
            data=list(queryset.values()),
            message="Classes retrieved successfully"
        )
    
    def create(self, request, *args, **kwargs):
        """Create a class with logging."""
        api_logger.info(f"Class creation requested by {request.user.username} (ID: {request.user.id}) - Data: {request.data}")
        
        return validation_error({"error": "Create functionality temporarily disabled - Class model moved to users app"})
    
    def update(self, request, *args, **kwargs):
        """Update a class with logging."""
        class_id = kwargs.get('pk')
        api_logger.info(f"Class update requested by {request.user.username} (ID: {request.user.id}) for class ID: {class_id} - Data: {request.data}")
        
        return validation_error({"error": "Update functionality temporarily disabled - Class model moved to users app"})
    
    def destroy(self, request, *args, **kwargs):
        """Delete a class with logging."""
        class_id = kwargs.get('pk')
        api_logger.info(f"Class delete requested by {request.user.username} (ID: {request.user.id}) for class ID: {class_id}")
        
        return validation_error({"error": "Delete functionality temporarily disabled - Class model moved to users app"})
