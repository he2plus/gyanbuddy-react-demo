#!/usr/bin/env python
"""Django's command-line utility for administrative tasks."""
import os
import sys
import weakref
from dotenv import load_dotenv

def _patch_autoreload_for_google_ai():
    import django.utils.autoreload as _autoreload
    _orig = _autoreload.iter_all_python_module_files

    def _iter_all_python_module_files():
        keys = sorted(sys.modules)
        modules = tuple(
            m
            for k in keys
            for m in (sys.modules.get(k),)
            if m is not None and not isinstance(m, weakref.ProxyTypes)
        )
        return _autoreload.iter_modules_and_files(modules, frozenset(_autoreload._error_files))

    _autoreload.iter_all_python_module_files = _iter_all_python_module_files


def main():
    """Run administrative tasks."""
    load_dotenv()
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'gyaan_buddy.settings.development')
    try:
        from django.core.management import execute_from_command_line
    except ImportError as exc:
        raise ImportError(
            "Couldn't import Django. Are you sure it's installed and "
            "available on your PYTHONPATH environment variable? Did you "
            "forget to activate a virtual environment?"
        ) from exc
    _patch_autoreload_for_google_ai()
    execute_from_command_line(sys.argv)


if __name__ == '__main__':
    main()
