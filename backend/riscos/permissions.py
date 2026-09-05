"""Permissões reutilizáveis do domínio de riscos.

`PertenceAoSetorDoRisco` mora aqui (antes estava em `views.py`); mantém-se
importável de lá por compatibilidade.
"""

from rest_framework import permissions

from .models import Risco


class ApenasSuperusuarioParaEscrita(permissions.BasePermission):
    """Leitura para qualquer usuário autenticado; escrita só para superusuário.

    Usada nas ViewSets da estrutura do PDI (desafios / objetivos /
    macroprocessos) — que qualquer gestor consulta mas só o admin edita.
    """

    message = "Apenas administradores do sistema podem alterar a estrutura do PDI."

    def has_permission(self, request, view):
        if not (request.user and request.user.is_authenticated):
            return False
        if request.method in permissions.SAFE_METHODS:
            return True
        return bool(request.user.is_superuser)


class PertenceAoSetorDoRisco(permissions.BasePermission):
    """Leitura liberada a qualquer gestor logado; escrita só se o setor do
    risco estiver entre os setores do usuário.

    Cobre tanto a checagem por objeto (edição/exclusão) quanto a criação de
    `PlanoAcao`/`Monitoramento`, onde o risco alvo vem no corpo (`risco`).
    """

    message = "Você só pode alterar riscos dos setores aos quais está vinculado."

    def has_permission(self, request, view):
        if not (request.user and request.user.is_authenticated):
            return False
        # Só a criação precisa de checagem aqui — nos demais métodos de escrita
        # o DRF chama has_object_permission via get_object().
        if request.method != "POST" or getattr(view, "action", None) != "create":
            return True
        uuid_risco = request.data.get("risco")
        if not uuid_risco:
            # Sem risco no corpo: deixa o serializer devolver 400.
            return True
        setor_id = (
            Risco.all_objects.filter(uuid=uuid_risco)
            .values_list("setor_id", flat=True)
            .first()
        )
        if setor_id is None:
            return True  # risco inexistente -> serializer devolve 400
        return request.user.setores.filter(id=setor_id).exists()

    def has_object_permission(self, request, view, obj):
        if request.method in permissions.SAFE_METHODS:
            return True
        if isinstance(obj, Risco):
            setor_do_risco = obj.setor
        elif hasattr(obj, "risco"):
            setor_do_risco = obj.risco.setor
        else:
            return False
        return request.user.setores.filter(id=setor_do_risco.id).exists()
