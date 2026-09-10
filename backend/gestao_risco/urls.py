from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/usuarios/', include('usuarios.urls')),
    path('api/riscos/', include('riscos.urls')),
]

# Sem MinIO, o Django serve as fotos de evidência localmente (dev/testes).
if settings.DEBUG and not settings.MEDIA_URL.startswith('http'):
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
