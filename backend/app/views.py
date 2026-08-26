import time

from django.db import connection
from django.http import JsonResponse
from django.utils import timezone
from django.views.decorators.http import require_GET


@require_GET
def health_check(request):
    started = time.perf_counter()
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT current_database(), current_user, "
                "current_setting('server_version')"
            )
            database_name, database_user, database_version = cursor.fetchone()

        return JsonResponse({
            "status": "ok",
            "database": "connected",
            "database_name": database_name,
            "database_user": database_user,
            "database_version": database_version,
            "database_query_ms": round((time.perf_counter() - started) * 1000, 2),
            "checked_at": timezone.now().isoformat(),
        })
    except Exception as error:
        return JsonResponse({
            "status": "error",
            "database": "disconnected",
            "error": type(error).__name__,
            "checked_at": timezone.now().isoformat(),
        }, status=503)