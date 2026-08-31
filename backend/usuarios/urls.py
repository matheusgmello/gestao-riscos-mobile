from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    EnviarCodigoRecuperacaoView,
    LoginView,
    RedefinirSenhaView,
    RegistroUsuarioView,
    SetorViewSet,
    UsuarioLogadoView,
    UsuarioViewSet,
    ValidarCodigoRecuperacaoView,
)

router = DefaultRouter()
router.register(r'setores', SetorViewSet)
router.register(r'gestores', UsuarioViewSet, basename='gestores')

urlpatterns = [
    path('', include(router.urls)),
    path('registro/', RegistroUsuarioView.as_view(), name='registro'),
    path('login/', LoginView.as_view(), name='login'),
    path('me/', UsuarioLogadoView.as_view(), name='usuario-logado'),
    path('recuperar-senha/enviar/', EnviarCodigoRecuperacaoView.as_view(), name='recuperar_senha_enviar'),
    path('recuperar-senha/validar/', ValidarCodigoRecuperacaoView.as_view(), name='recuperar_senha_validar'),
    path('recuperar-senha/redefinir/', RedefinirSenhaView.as_view(), name='recuperar_senha_redefinir'),
]
