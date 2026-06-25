"""
Local SQLite settings — no Docker / Postgres / Redis required.

Lets the backend run on this machine (disk-constrained) for local testing of the
quiz / chapter / XP flows. Use with:
    DJANGO_SETTINGS_MODULE=gyaan_buddy.settings.local_sqlite
"""
from .development import *  # noqa: F401,F403

# --- SQLite instead of Postgres -------------------------------------------
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'local_dev.sqlite3',
    }
}

# --- Celery runs inline (no Redis broker) ---------------------------------
CELERY_TASK_ALWAYS_EAGER = True
CELERY_TASK_EAGER_PROPAGATES = False
CELERY_BROKER_URL = 'memory://'
CELERY_RESULT_BACKEND = 'cache+memory://'

# --- In-memory cache (no Redis) -------------------------------------------
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
    }
}

# --- Console-only logging (skip the file handlers / logs dir) -------------
LOGGING['handlers'] = {
    'console': {'level': 'INFO', 'class': 'logging.StreamHandler'},
}
for _lg in LOGGING.get('loggers', {}).values():
    _lg['handlers'] = ['console']
LOGGING['root'] = {'handlers': ['console'], 'level': 'INFO'}
