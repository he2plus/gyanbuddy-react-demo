import uuid

from django.db import models
from django.utils import timezone


class TimeStampUUID(models.Model):
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False,
        help_text='Unique identifier for this record'
    )
    
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text='Timestamp when this record was created'
    )
    
    updated_at = models.DateTimeField(
        auto_now=True,
        help_text='Timestamp when this record was last updated'
    )
    
    class Meta:
        abstract = True
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.__class__.__name__} - {self.id}"

    @property
    def created_date(self):
        return self.created_at.date() if self.created_at else None

    @property
    def updated_date(self):
        return self.updated_at.date() if self.updated_at else None

    def save(self, *args, **kwargs):
        if not self.pk:
            self.created_at = timezone.now()
        self.updated_at = timezone.now()
        super().save(*args, **kwargs)


class TimeStamp(models.Model):
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text='Timestamp when this record was created'
    )
    
    updated_at = models.DateTimeField(
        auto_now=True,
        help_text='Timestamp when this record was last updated'
    )
    
    class Meta:
        abstract = True
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.__class__.__name__} - {self.id}"

    @property
    def created_date(self):
        return self.created_at.date() if self.created_at else None

    @property
    def updated_date(self):
        return self.updated_at.date() if self.updated_at else None

    def save(self, *args, **kwargs):
        if not self.pk:
            self.created_at = timezone.now()
        self.updated_at = timezone.now()
        super().save(*args, **kwargs)


class SoftDelete(models.Model):
    is_deleted = models.BooleanField(
        default=False,
        help_text='Whether this record has been soft deleted'
    )
    
    deleted_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text='Timestamp when this record was soft deleted'
    )
    
    class Meta:
        abstract = True
    
    def soft_delete(self):
        self.is_deleted = True
        self.deleted_at = timezone.now()
        self.save(update_fields=['is_deleted', 'deleted_at'])

    def restore(self):
        self.is_deleted = False
        self.deleted_at = None
        self.save(update_fields=['is_deleted', 'deleted_at'])

    def hard_delete(self, *args, **kwargs):
        super().delete(*args, **kwargs)


class TimeStampUUIDSoftDelete(TimeStampUUID, SoftDelete):
    class Meta:
        abstract = True


class SoftDeleteModel(TimeStampUUID, SoftDelete):
    class Meta:
        abstract = True
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.__class__.__name__} - {self.id}"

    @property
    def created_date(self):
        return self.created_at.date() if self.created_at else None

    @property
    def updated_date(self):
        return self.updated_at.date() if self.updated_at else None

    @property
    def deleted_date(self):
        return self.deleted_at.date() if self.deleted_at else None

    def save(self, *args, **kwargs):
        if not self.pk:
            self.created_at = timezone.now()
        self.updated_at = timezone.now()
        super().save(*args, **kwargs)

    def soft_delete(self):
        self.is_deleted = True
        self.deleted_at = timezone.now()
        self.save(update_fields=['is_deleted', 'deleted_at'])

    def restore(self):
        self.is_deleted = False
        self.deleted_at = None
        self.save(update_fields=['is_deleted', 'deleted_at'])

    def hard_delete(self, *args, **kwargs):
        super().delete(*args, **kwargs)
