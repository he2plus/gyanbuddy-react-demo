"""
Development settings for gyaan_buddy project.
"""

import os
from pathlib import Path
from dotenv import load_dotenv
from .base import *

env_path = Path(__file__).resolve().parent.parent.parent / '.env'
load_dotenv(dotenv_path=env_path)

OPENAI_API_KEY = os.environ.get('OPENAI_API_KEY', '')

SECRET_KEY = os.environ.get('SECRET_KEY', 'django-insecure-kt#12p=846$0t6md(k+caiziy+oi1-tts+ymiy1s^9^4eb%0it')

DEBUG = os.environ.get('DEBUG', 'True').lower() == 'true'

ALLOWED_HOSTS = [
    'localhost',
    '127.0.0.1',
    '0.0.0.0',
    '.ngrok-free.app',
    '.ngrok.io',
    '.ngrok.com',
    'gyanbuddy.ai',
    'www.gyanbuddy.ai',
    '*'
]

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get('POSTGRES_DB', 'gyaan_buddy'),
        'USER': os.environ.get('POSTGRES_USER', 'gyaan_buddy_user'),
        'PASSWORD': os.environ.get('POSTGRES_PASSWORD', 'gyaan_buddy_password'),
        'HOST': os.environ.get('POSTGRES_HOST', 'localhost'),
        'PORT': os.environ.get('POSTGRES_PORT', '5432'),
        'OPTIONS': {
            'client_encoding': 'UTF8',
        },
    }
}

LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {process:d} {thread:d} {message}',
            'style': '{',
        },
        'simple': {
            'format': '{levelname} {message}',
            'style': '{',
        },
        'detailed': {
            'format': '[{asctime}] {levelname} {name} {funcName}:{lineno} - {message}',
            'style': '{',
        },
    },
    'filters': {
        'require_debug_true': {
            '()': 'django.utils.log.RequireDebugTrue',
        },
    },
    'handlers': {
        'console': {
            'level': 'DEBUG',
            'class': 'logging.StreamHandler',
            'formatter': 'detailed',
        },
        'file': {
            'level': 'INFO',
            'class': 'logging.FileHandler',
            'filename': 'logs/gyaan_buddy.log',
            'formatter': 'detailed',
        },
        'error_file': {
            'level': 'ERROR',
            'class': 'logging.FileHandler',
            'filename': 'logs/errors.log',
            'formatter': 'detailed',
        },
        'auth_file': {
            'level': 'INFO',
            'class': 'logging.FileHandler',
            'filename': 'logs/auth.log',
            'formatter': 'detailed',
        },
        'api_file': {
            'level': 'INFO',
            'class': 'logging.FileHandler',
            'filename': 'logs/api.log',
            'formatter': 'detailed',
        },
    },
    'loggers': {
        'django': {
            'handlers': ['console', 'file'],
            'level': 'INFO',
            'propagate': False,
        },
        'django.request': {
            'handlers': ['console', 'error_file'],
            'level': 'ERROR',
            'propagate': False,
        },
        'django.security': {
            'handlers': ['console', 'error_file'],
            'level': 'ERROR',
            'propagate': False,
        },
        'django.db.backends': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'gyaan_buddy.auth': {
            'handlers': ['console', 'auth_file'],
            'level': 'INFO',
            'propagate': False,
        },
        'gyaan_buddy.api': {
            'handlers': ['console', 'api_file'],
            'level': 'INFO',
            'propagate': False,
        },
        'users': {
            'handlers': ['console', 'api_file'],
            'level': 'INFO',
            'propagate': False,
        },
        'gyaan_buddy.classes': {
            'handlers': ['console', 'api_file'],
            'level': 'INFO',
            'propagate': False,
        },
        'gyaan_buddy.subjects': {
            'handlers': ['console', 'api_file'],
            'level': 'INFO',
            'propagate': False,
        },
    },
    'root': {
        'handlers': ['console', 'file'],
        'level': 'INFO',
    },
}

CORS_ALLOWED_ORIGINS = [
    'http://localhost:3000',
    'http://127.0.0.1:3000',
    'http://localhost:8000',
    'http://127.0.0.1:8000',
    'https://gyanbuddy.ai',
    'https://www.gyanbuddy.ai',
]

CORS_ALLOW_CREDENTIALS = True
