from django.urls import path

from .views import csrf_token, current_user, health_check, register, sign_in, sign_out


urlpatterns = [
    path("auth/csrf/", csrf_token, name="csrf-token"),
    path("auth/me/", current_user, name="current-user"),
    path("auth/register/", register, name="register"),
    path("auth/login/", sign_in, name="sign-in"),
    path("auth/logout/", sign_out, name="sign-out"),
    path(
        "health/",
        health_check,
        name="health-check",
    ),
]
