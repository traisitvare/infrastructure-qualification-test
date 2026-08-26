import json
import time
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.models import User
from django.db import connection
from django.http import JsonResponse
from django.utils import timezone
from django.views.decorators.csrf import ensure_csrf_cookie
from django.views.decorators.http import require_GET
from django.views.decorators.http import require_POST


def json_error(message, status=400):
    return JsonResponse({"error": message}, status=status)


def request_data(request):
    try:
        return json.loads(request.body)
    except (json.JSONDecodeError, UnicodeDecodeError):
        return None


@require_GET
@ensure_csrf_cookie
def csrf_token(request):
    return JsonResponse({"detail": "CSRF cookie set"})


@require_GET
def current_user(request):
    if not request.user.is_authenticated:
        return json_error("Authentication required", 401)
    return JsonResponse({"username": request.user.username, "email": request.user.email})


@require_POST
def register(request):
    data = request_data(request)
    if not data:
        return json_error("Invalid request body")

    username = str(data.get("username", "")).strip()
    email = str(data.get("email", "")).strip()
    password = str(data.get("password", ""))
    if len(username) < 3 or len(username) > 150:
        return json_error("Username must contain 3 to 150 characters")
    if not email or "@" not in email:
        return json_error("Enter a valid email address")
    if len(password) < 8:
        return json_error("Password must contain at least 8 characters")
    if User.objects.filter(username__iexact=username).exists():
        return json_error("Username is already in use")
    if User.objects.filter(email__iexact=email).exists():
        return json_error("Email is already in use")

    user = User.objects.create_user(username=username, email=email, password=password)
    login(request, user)
    return JsonResponse({"username": user.username, "email": user.email}, status=201)


@require_POST
def sign_in(request):
    data = request_data(request)
    if not data:
        return json_error("Invalid request body")
    username = str(data.get("username", "")).strip()
    password = str(data.get("password", ""))
    user = authenticate(request, username=username, password=password)
    if user is None:
        return json_error("Invalid username or password", 401)
    login(request, user)
    return JsonResponse({"username": user.username, "email": user.email})


@require_POST
def sign_out(request):
    logout(request)
    return JsonResponse({"detail": "Signed out"})

@require_GET
def health_check(request):
    if not request.user.is_authenticated:
        return json_error("Authentication required", 401)
    started = time.perf_counter()
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT current_database(), current_user, current_setting('server_version')")
            database_name, database_user, database_version = cursor.fetchone()
        return JsonResponse({
            "status": "ok",
            "database": "connected",
            "database_name": database_name,
            "database_user": database_user,
            "database_version": database_version,
            "database_query_ms": round((time.perf_counter() - started) * 1000, 2),
            "checked_at": timezone.now().isoformat()
        })
    except Exception as error:
        return JsonResponse({
            "status": "error",
            "database": "disconnected",
            "error": type(error).__name__,
            "checked_at": timezone.now().isoformat()
        }, status=503)
