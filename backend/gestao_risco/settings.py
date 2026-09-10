import os
from pathlib import Path

from dotenv import load_dotenv

# Carrega o arquivo .env da raiz do projeto
load_dotenv(override=True)

BASE_DIR = Path(__file__).resolve().parent.parent.parent

SECRET_KEY = os.environ.get('SECRET_KEY', 'django-insecure-development-only-key')

DEBUG = os.environ.get('DEBUG', 'True') == 'True'

ALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS', '*').split(',')

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'rest_framework.authtoken', # Para autenticação via Token
    'corsheaders',
    'usuarios',
    'riscos',
]

AUTH_USER_MODEL = 'usuarios.Usuario'

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    # WhiteNoise deve ficar logo após SecurityMiddleware para servir arquivos
    # estáticos com eficiência em produção (sem Nginx/CDN dedicado).
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'gestao_risco.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'gestao_risco.wsgi.application'

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get('DATABASE_NAME', 'gestao_risco_ufsm'),
        'USER': os.environ.get('DATABASE_USER', 'postgres'),
        'PASSWORD': os.environ.get('DATABASE_PASSWORD', 'postgres'),
        'HOST': os.environ.get('DATABASE_HOST', 'localhost'),
        'PORT': os.environ.get('DATABASE_PORT', '5432'),
    }
}

# Configuração do Django REST Framework
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework.authentication.TokenAuthentication',
    ),
    'DEFAULT_PERMISSION_CLASSES': (
        'rest_framework.permissions.IsAuthenticated',
    ),
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 5,
}


AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

LANGUAGE_CODE = 'pt-br'
TIME_ZONE = 'America/Sao_Paulo'
USE_I18N = True
USE_TZ = True

# Arquivos estáticos
# STATIC_ROOT é o diretório de saída de "collectstatic".
# WhiteNoiseMiddleware o serve diretamente em produção (sem Nginx).
STATIC_URL = 'static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# Mídia (fotos de evidência dos monitoramentos).
# Com MINIO_ENDPOINT_URL definido, os uploads vão para um object storage
# S3-compatível (MinIO). Sem ele, sistema de arquivos local — usado em
# desenvolvimento e nos testes.
MEDIA_URL = os.environ.get('MEDIA_URL', '/media/')
MEDIA_ROOT = BASE_DIR / 'media'

if os.environ.get('MINIO_ENDPOINT_URL'):
    _MINIO_BUCKET = os.environ.get('MINIO_BUCKET', 'gestao-risco')
    _MINIO_PUBLIC = os.environ.get('MINIO_PUBLIC_DOMAIN')
    STORAGES = {
        'default': {
            'BACKEND': 'storages.backends.s3.S3Storage',
            'OPTIONS': {
                'bucket_name': _MINIO_BUCKET,
                'endpoint_url': os.environ['MINIO_ENDPOINT_URL'],
                'access_key': os.environ.get('MINIO_ACCESS_KEY', 'minioadmin'),
                'secret_key': os.environ.get('MINIO_SECRET_KEY', 'minioadmin'),
                # URL path-style que o celular consegue abrir: <host>/<bucket>/<key>.
                # O endpoint interno 'minio:9000' não resolve fora da rede do compose.
                'custom_domain': (
                    f'{_MINIO_PUBLIC}/{_MINIO_BUCKET}' if _MINIO_PUBLIC else None
                ),
                'addressing_style': 'path',
                'url_protocol': 'http:',
                # bucket com download anônimo -> URL limpa, sem assinatura
                'querystring_auth': False,
                'file_overwrite': False,
            },
        },
        'staticfiles': {
            'BACKEND': 'django.contrib.staticfiles.storage.StaticFilesStorage',
        },
    }

CORS_ALLOW_ALL_ORIGINS = os.environ.get('CORS_ALLOW_ALL_ORIGINS', 'True') == 'True'

# Configuração de e-mail
# Em desenvolvimento: usa o backend de console (imprime no terminal, sem SMTP)
# Em produção: configure EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend no .env
EMAIL_BACKEND = os.environ.get('EMAIL_BACKEND', 'django.core.mail.backends.console.EmailBackend')
EMAIL_HOST = os.environ.get('EMAIL_HOST', 'smtp.gmail.com')
EMAIL_PORT = int(os.environ.get('EMAIL_PORT', '587'))
EMAIL_USE_TLS = os.environ.get('EMAIL_USE_TLS', 'True') == 'True'
EMAIL_HOST_USER = os.environ.get('EMAIL_HOST_USER', '')
EMAIL_HOST_PASSWORD = os.environ.get('EMAIL_HOST_PASSWORD', '')
DEFAULT_FROM_EMAIL = os.environ.get('DEFAULT_FROM_EMAIL', 'SIGR UFSM <noreply@ufsm.br>')
