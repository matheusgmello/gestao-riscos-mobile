from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    DesafioPDIViewSet,
    MacroprocessoViewSet,
    MonitoramentoViewSet,
    ObjetivoPDIViewSet,
    PlanoAcaoViewSet,
    RiscoViewSet,
)

router = DefaultRouter()
router.register(r'desafios', DesafioPDIViewSet)
router.register(r'macroprocessos', MacroprocessoViewSet)
router.register(r'objetivos', ObjetivoPDIViewSet)
router.register(r'planos', RiscoViewSet)
router.register(r'acoes', PlanoAcaoViewSet)
router.register(r'monitoramentos', MonitoramentoViewSet)

urlpatterns = [
    path('', include(router.urls)),
]
