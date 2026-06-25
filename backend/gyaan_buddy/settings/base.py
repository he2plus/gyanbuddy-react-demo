"""
Base Django settings for gyaan_buddy project.
"""

from pathlib import Path
import os

BASE_DIR = Path(__file__).resolve().parent.parent.parent

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    
    'gyaan_buddy.users',
    'gyaan_buddy.subjects',
    
    'rest_framework',
    'corsheaders',
]

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'gyaan_buddy.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'gyaan_buddy.wsgi.application'

AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]

LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'

GS_BUCKET_NAME = os.environ.get('GS_BUCKET_NAME', 'gyaanbuddy-media')
GS_PROJECT_ID = os.environ.get('GS_PROJECT_ID', 'caramel-goal-473111-t3')
MEDIA_URL = f'https://storage.googleapis.com/{GS_BUCKET_NAME}/'
MEDIA_ROOT = BASE_DIR / 'media'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

AUTH_USER_MODEL = 'users.Account'

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 10,
    'DEFAULT_RENDERER_CLASSES': [
        'rest_framework.renderers.JSONRenderer',
        'rest_framework.renderers.BrowsableAPIRenderer',
    ],
}

from datetime import timedelta
JWT_NEVER_EXPIRE = timedelta(days=36525)  # ~100 years
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': JWT_NEVER_EXPIRE,
    'REFRESH_TOKEN_LIFETIME': JWT_NEVER_EXPIRE,
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': True,
    'UPDATE_LAST_LOGIN': True,
    'ALGORITHM': 'HS256',
    'SIGNING_KEY': os.environ.get('SECRET_KEY', 'django-insecure-kt#12p=846$0t6md(k+caiziy+oi1-tts+ymiy1s^9^4eb%0it'),
    'VERIFYING_KEY': None,
    'AUDIENCE': None,
    'ISSUER': None,
    'JWK_URL': None,
    'LEEWAY': 0,
    'AUTH_HEADER_TYPES': ('Bearer',),
    'AUTH_HEADER_NAME': 'HTTP_AUTHORIZATION',
    'USER_ID_FIELD': 'id',
    'USER_ID_CLAIM': 'user_id',
    'USER_AUTHENTICATION_RULE': 'rest_framework_simplejwt.authentication.default_user_authentication_rule',
    'AUTH_TOKEN_CLASSES': ('rest_framework_simplejwt.tokens.AccessToken',),
    'TOKEN_TYPE_CLAIM': 'token_type',
    'TOKEN_USER_CLASS': 'rest_framework_simplejwt.models.TokenUser',
    'JTI_CLAIM': 'jti',
    'SLIDING_TOKEN_REFRESH_EXP_CLAIM': 'refresh_exp',
    'SLIDING_TOKEN_LIFETIME': JWT_NEVER_EXPIRE,
    'SLIDING_TOKEN_REFRESH_LIFETIME': JWT_NEVER_EXPIRE,
}

FIREBASE_PROJECT_ID = os.environ.get('FIREBASE_PROJECT_ID', 'gyaanbuddy-600f2')
FIREBASE_AUTH_DOMAIN = os.environ.get('FIREBASE_AUTH_DOMAIN', 'gyaanbuddy-600f2.firebaseapp.com')
FIREBASE_MESSAGING_SENDER_ID = os.environ.get('FIREBASE_MESSAGING_SENDER_ID', '130750342442')
FIREBASE_API_KEY = os.environ.get('FIREBASE_API_KEY', 'AIzaSyDF7v_TVnyuxx_jV_Mian1MVwdM6BewSrU')
FIREBASE_APP_ID = os.environ.get('FIREBASE_APP_ID', '1:130750342442:web:ad75caa6a301eed312ea53')
FIREBASE_SERVICE_ACCOUNT_KEY_PATH = BASE_DIR / 'gyaanbuddy-600f2-firebase-adminsdk-fbsvc-a2fc6d160b.json'
FIREBASE_SERVICE_ACCOUNT_INFO = os.environ.get('FIREBASE_SERVICE_ACCOUNT_INFO', None)

DEFAULT_FILE_STORAGE = 'storages.backends.gcloud.GoogleCloudStorage'
STORAGES = {
    'default': {
        'BACKEND': 'storages.backends.gcloud.GoogleCloudStorage',
    },
    'staticfiles': {
        'BACKEND': 'django.contrib.staticfiles.storage.StaticFilesStorage',
    },
}

GS_CREDENTIALS_PATH = os.environ.get('GOOGLE_APPLICATION_CREDENTIALS')
if not GS_CREDENTIALS_PATH:
    project_root = BASE_DIR
    all_json_files = list(project_root.glob('*.json'))
    
    gcp_service_account = None
    firebase_service_account = None
    
    for json_file in all_json_files:
        filename = json_file.name.lower()
        if GS_PROJECT_ID and GS_PROJECT_ID.lower() in filename:
            gcp_service_account = json_file
            break
        elif 'firebase' in filename or 'adminsdk' in filename:
            firebase_service_account = json_file
        elif not gcp_service_account:
            gcp_service_account = json_file
    
    service_account_file = gcp_service_account or (firebase_service_account if all_json_files else None)
    if service_account_file:
        GS_CREDENTIALS_PATH = str(service_account_file)
        os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = GS_CREDENTIALS_PATH

if GS_CREDENTIALS_PATH and os.path.exists(GS_CREDENTIALS_PATH):
    try:
        from google.oauth2 import service_account
        GS_CREDENTIALS = service_account.Credentials.from_service_account_file(GS_CREDENTIALS_PATH)
    except (ImportError, Exception) as e:
        import logging
        logger = logging.getLogger(__name__)
        logger.warning(f"Failed to load GCP credentials from {GS_CREDENTIALS_PATH}: {e}")
        GS_CREDENTIALS = None
else:
    GS_CREDENTIALS = None

GS_DEFAULT_ACL = None
if os.environ.get('GS_DEFAULT_ACL'):
    env_acl = os.environ.get('GS_DEFAULT_ACL')
    if env_acl.lower() in ('none', ''):
        GS_DEFAULT_ACL = None
    else:
        GS_DEFAULT_ACL = env_acl
GS_FILE_OVERWRITE = True
GS_LOCATION = ''

CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",
    "http://localhost:3001",
    "http://localhost:5173",
    "http://127.0.0.1:3000",
    "http://127.0.0.1:3001",
    "http://127.0.0.1:5173",
    "https://gyanbuddy.ai",
    "https://www.gyanbuddy.ai",
]

CORS_ALLOW_CREDENTIALS = True

CORS_ALLOW_ALL_ORIGINS = True

CORS_ALLOW_HEADERS = [
    'accept',
    'accept-encoding',
    'authorization',
    'content-type',
    'dnt',
    'origin',
    'user-agent',
    'x-csrftoken',
    'x-requested-with',
]

# ── Assessment Generator ───────────────────────────────────────────────────────
AI_SERVICE_URL = os.environ.get('AI_SERVICE_URL', 'http://localhost:8001')

CELERY_BROKER_URL = os.environ.get('CELERY_BROKER_URL', 'redis://localhost:6379/2')
CELERY_RESULT_BACKEND = os.environ.get('CELERY_RESULT_BACKEND', 'redis://localhost:6379/3')
CELERY_TASK_ALWAYS_EAGER = os.environ.get('CELERY_TASK_ALWAYS_EAGER', 'False').lower() == 'true'
CELERY_TASK_SERIALIZER = 'json'
CELERY_RESULT_SERIALIZER = 'json'
CELERY_ACCEPT_CONTENT = ['json']
CELERY_TIMEZONE = TIME_ZONE
CELERY_ENABLE_UTC = True
