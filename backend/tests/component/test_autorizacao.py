"""Categoria 3 — Autorização.

Para cada endpoint de escrita: papel autorizado passa, papel errado recebe
403, sem token recebe 401. A distinção 401/403 é verificada de fato.

Fecha os buracos encontrados na auditoria da issue #5:
- `UnidadeOrganizacionalViewSet` era `AllowAny` (qualquer um criava/removia setor);
- ViewSets do PDI eram `IsAuthenticated` (qualquer gestor editava a estrutura);
- criação de `PlanoAcao`/`Monitoramento` não checava o setor do risco alvo.
"""

import pytest
from django.urls import get_resolver
from rest_framework import permissions
from rest_framework.views import APIView

pytestmark = pytest.mark.django_db


# --------------------------------------------------------------------------- #
# Helpers
# --------------------------------------------------------------------------- #

def _payload_risco(setor, objetivo, macro):
    return {
        "setor": setor.id,
        "objetivo": objetivo.id,
        "macroprocesso": macro.id,
        "categoria": "Operacional",
        "evento": "Novo risco",
        "causa": "c",
        "consequencia": "q",
        "controles_atuais": "x",
        "eficacia_controle": "Fraco",
        "probabilidade": 2,
        "impacto": 2,
        "prob_residual": 1,
        "imp_residual": 1,
    }


# --------------------------------------------------------------------------- #
# 401 vs 403 — a distinção precisa existir
# --------------------------------------------------------------------------- #

class TestSemTokenRecebe401:
    """Sem autenticação: 401 (WWW-Authenticate: Token), nunca 403."""

    def test_criar_risco_sem_token(self, api_client, setor_oficial, objetivo_padrao, macroprocesso_padrao):
        resp = api_client.post(
            "/api/riscos/planos/",
            _payload_risco(setor_oficial, objetivo_padrao, macroprocesso_padrao),
            format="json",
        )
        assert resp.status_code == 401

    def test_editar_risco_sem_token(self, api_client, risco_basico):
        resp = api_client.patch(
            f"/api/riscos/planos/{risco_basico.uuid}/",
            {"evento": "hack"},
            format="json",
        )
        assert resp.status_code == 401

    def test_criar_desafio_pdi_sem_token(self, api_client):
        resp = api_client.post(
            "/api/riscos/desafios/", {"numero": 1, "descricao": "x"}, format="json"
        )
        assert resp.status_code == 401

    def test_criar_gestor_sem_token(self, api_client):
        resp = api_client.post("/api/usuarios/registro/", {}, format="json")
        assert resp.status_code == 401

    def test_me_sem_token(self, api_client):
        assert api_client.get("/api/usuarios/me/").status_code == 401


# --------------------------------------------------------------------------- #
# Riscos — PertenceAoSetorDoRisco
# --------------------------------------------------------------------------- #

class TestAutorizacaoRiscos:
    def test_gestor_do_setor_cria(self, api_client, usuario_gestor, setor_oficial, objetivo_padrao, macroprocesso_padrao):
        api_client.force_authenticate(user=usuario_gestor)
        resp = api_client.post(
            "/api/riscos/planos/",
            _payload_risco(setor_oficial, objetivo_padrao, macroprocesso_padrao),
            format="json",
        )
        assert resp.status_code == 201

    def test_gestor_de_outro_setor_nao_cria(self, api_client, usuario_outro_setor, setor_oficial, objetivo_padrao, macroprocesso_padrao):
        api_client.force_authenticate(user=usuario_outro_setor)
        resp = api_client.post(
            "/api/riscos/planos/",
            _payload_risco(setor_oficial, objetivo_padrao, macroprocesso_padrao),
            format="json",
        )
        assert resp.status_code == 403

    def test_gestor_de_outro_setor_nao_edita(self, api_client, usuario_outro_setor, risco_basico):
        api_client.force_authenticate(user=usuario_outro_setor)
        resp = api_client.patch(
            f"/api/riscos/planos/{risco_basico.uuid}/",
            {"evento": "alterado"},
            format="json",
        )
        assert resp.status_code == 403

    def test_gestor_de_outro_setor_le(self, api_client, usuario_outro_setor, risco_basico):
        """Leitura é liberada a qualquer gestor logado."""
        api_client.force_authenticate(user=usuario_outro_setor)
        resp = api_client.get(f"/api/riscos/planos/{risco_basico.uuid}/")
        assert resp.status_code == 200

    def test_gestor_de_outro_setor_nao_exclui(self, api_client, usuario_outro_setor, risco_basico):
        api_client.force_authenticate(user=usuario_outro_setor)
        resp = api_client.delete(f"/api/riscos/planos/{risco_basico.uuid}/")
        assert resp.status_code == 403

    def test_gestor_de_outro_setor_nao_duplica(self, api_client, usuario_outro_setor, risco_basico):
        api_client.force_authenticate(user=usuario_outro_setor)
        resp = api_client.post(f"/api/riscos/planos/{risco_basico.uuid}/duplicar/")
        assert resp.status_code == 403


class TestAutorizacaoFilhosDoRisco:
    """Criar PlanoAcao/Monitoramento exige pertencer ao setor do risco alvo."""

    def test_gestor_do_setor_cria_acao(self, api_client, usuario_gestor, risco_basico):
        api_client.force_authenticate(user=usuario_gestor)
        resp = api_client.post(
            "/api/riscos/acoes/",
            {
                "risco": str(risco_basico.uuid),
                "tipo_resposta": "Mitigar",
                "descricao_acao": "d",
                "responsavel": "r",
                "data_inicio": "2026-01-01",
                "data_fim": "2026-02-01",
                "status": "Em andamento",
            },
            format="json",
        )
        assert resp.status_code == 201

    def test_gestor_de_outro_setor_nao_cria_acao(self, api_client, usuario_outro_setor, risco_basico):
        api_client.force_authenticate(user=usuario_outro_setor)
        resp = api_client.post(
            "/api/riscos/acoes/",
            {
                "risco": str(risco_basico.uuid),
                "tipo_resposta": "Mitigar",
                "descricao_acao": "d",
                "responsavel": "r",
                "data_inicio": "2026-01-01",
                "data_fim": "2026-02-01",
                "status": "Em andamento",
            },
            format="json",
        )
        assert resp.status_code == 403

    def test_gestor_de_outro_setor_nao_cria_monitoramento(self, api_client, usuario_outro_setor, risco_basico):
        api_client.force_authenticate(user=usuario_outro_setor)
        resp = api_client.post(
            "/api/riscos/monitoramentos/",
            {
                "risco": str(risco_basico.uuid),
                "resultados": "r",
                "acoes_futuras": "a",
                "analise_critica": "c",
            },
            format="json",
        )
        assert resp.status_code == 403


# --------------------------------------------------------------------------- #
# Estrutura do PDI — só superusuário escreve
# --------------------------------------------------------------------------- #

class TestAutorizacaoPDI:
    RECURSOS = ["desafios", "objetivos", "macroprocessos"]

    @pytest.mark.parametrize("recurso", RECURSOS)
    def test_gestor_le(self, api_client, usuario_gestor, recurso):
        api_client.force_authenticate(user=usuario_gestor)
        assert api_client.get(f"/api/riscos/{recurso}/").status_code == 200

    def test_gestor_nao_cria_desafio(self, api_client, usuario_gestor):
        api_client.force_authenticate(user=usuario_gestor)
        resp = api_client.post(
            "/api/riscos/desafios/", {"numero": 42, "descricao": "x"}, format="json"
        )
        assert resp.status_code == 403

    def test_superusuario_cria_desafio(self, api_client, usuario_superuser):
        api_client.force_authenticate(user=usuario_superuser)
        resp = api_client.post(
            "/api/riscos/desafios/", {"numero": 42, "descricao": "x"}, format="json"
        )
        assert resp.status_code == 201

    def test_gestor_nao_cria_macroprocesso(self, api_client, usuario_gestor):
        api_client.force_authenticate(user=usuario_gestor)
        resp = api_client.post(
            "/api/riscos/macroprocessos/", {"nome": "M"}, format="json"
        )
        assert resp.status_code == 403

    def test_gestor_nao_edita_desafio(self, api_client, usuario_gestor, desafio_padrao):
        api_client.force_authenticate(user=usuario_gestor)
        resp = api_client.patch(
            f"/api/riscos/desafios/{desafio_padrao.id}/",
            {"descricao": "editado"},
            format="json",
        )
        assert resp.status_code == 403

    def test_gestor_nao_exclui_desafio(self, api_client, usuario_gestor, desafio_padrao):
        api_client.force_authenticate(user=usuario_gestor)
        resp = api_client.delete(f"/api/riscos/desafios/{desafio_padrao.id}/")
        assert resp.status_code == 403


# --------------------------------------------------------------------------- #
# Unidades — leitura pública, escrita só superusuário
# --------------------------------------------------------------------------- #

class TestAutorizacaoUnidades:
    def _payload(self):
        return {
            "nome": "Nova Unidade",
            "sigla": "NU",
            "sigla_centro": "CT",
            "nome_centro": "Centro de Tecnologia",
            "tipo_unidade": "Departamento",
        }

    def test_lista_publica(self, api_client, setor_oficial):
        assert api_client.get("/api/usuarios/setores/").status_code == 200

    def test_anonimo_nao_cria(self, api_client):
        resp = api_client.post("/api/usuarios/setores/", self._payload(), format="json")
        assert resp.status_code == 401

    def test_gestor_nao_cria(self, api_client, usuario_gestor):
        api_client.force_authenticate(user=usuario_gestor)
        resp = api_client.post("/api/usuarios/setores/", self._payload(), format="json")
        assert resp.status_code == 403

    def test_superusuario_cria(self, api_client, usuario_superuser):
        api_client.force_authenticate(user=usuario_superuser)
        resp = api_client.post("/api/usuarios/setores/", self._payload(), format="json")
        assert resp.status_code == 201

    def test_gestor_nao_edita(self, api_client, usuario_gestor, setor_oficial):
        api_client.force_authenticate(user=usuario_gestor)
        resp = api_client.patch(
            f"/api/usuarios/setores/{setor_oficial.id}/",
            {"nome": "Outro nome"},
            format="json",
        )
        assert resp.status_code == 403

    def test_gestor_nao_exclui(self, api_client, usuario_gestor, setor_oficial):
        api_client.force_authenticate(user=usuario_gestor)
        resp = api_client.delete(f"/api/usuarios/setores/{setor_oficial.id}/")
        assert resp.status_code == 403

    def test_gestor_nao_desativa(self, api_client, usuario_gestor, setor_oficial):
        api_client.force_authenticate(user=usuario_gestor)
        resp = api_client.post(f"/api/usuarios/setores/{setor_oficial.id}/desativar/")
        assert resp.status_code == 403


# --------------------------------------------------------------------------- #
# Equipe — gestor_adm / superusuário
# --------------------------------------------------------------------------- #

class TestAutorizacaoEquipe:
    def test_gestor_comum_nao_adiciona_membro(self, api_client, usuario_gestor, usuario_outro_setor, setor_oficial):
        api_client.force_authenticate(user=usuario_gestor)
        resp = api_client.post(
            f"/api/usuarios/setores/{setor_oficial.id}/adicionar_membro/",
            {"siape": usuario_outro_setor.siape},
            format="json",
        )
        assert resp.status_code == 403

    def test_gestor_adm_adiciona_membro(self, api_client, usuario_gestor_adm, usuario_outro_setor, setor_oficial):
        api_client.force_authenticate(user=usuario_gestor_adm)
        resp = api_client.post(
            f"/api/usuarios/setores/{setor_oficial.id}/adicionar_membro/",
            {"siape": usuario_outro_setor.siape},
            format="json",
        )
        assert resp.status_code == 200

    def test_gestor_comum_nao_remove_membro(self, api_client, usuario_gestor, setor_oficial):
        api_client.force_authenticate(user=usuario_gestor)
        resp = api_client.post(
            f"/api/usuarios/setores/{setor_oficial.id}/remover_membro/",
            {"usuario_id": usuario_gestor.id},
            format="json",
        )
        assert resp.status_code == 403

    def test_membros_sem_token(self, api_client, setor_oficial):
        assert api_client.get(
            f"/api/usuarios/setores/{setor_oficial.id}/membros/"
        ).status_code == 401


# --------------------------------------------------------------------------- #
# Gestão de usuários — superusuário
# --------------------------------------------------------------------------- #

class TestAutorizacaoGestores:
    def test_gestor_nao_lista(self, api_client, usuario_gestor):
        api_client.force_authenticate(user=usuario_gestor)
        assert api_client.get("/api/usuarios/gestores/").status_code == 403

    def test_superusuario_lista(self, api_client, usuario_superuser):
        api_client.force_authenticate(user=usuario_superuser)
        assert api_client.get("/api/usuarios/gestores/").status_code == 200

    def test_gestor_nao_registra(self, api_client, usuario_gestor, setor_oficial):
        api_client.force_authenticate(user=usuario_gestor)
        resp = api_client.post(
            "/api/usuarios/registro/",
            {
                "siape": "4444444",
                "nome": "X",
                "email": "x@ufsm.br",
                "senha": "12345678",
                "id_setores": [setor_oficial.id],
            },
            format="json",
        )
        assert resp.status_code == 403

    def test_gestor_nao_desativa_outro(self, api_client, usuario_gestor, usuario_outro_setor):
        api_client.force_authenticate(user=usuario_gestor)
        resp = api_client.delete(f"/api/usuarios/gestores/{usuario_outro_setor.uuid}/")
        assert resp.status_code == 403

    def test_gestor_nao_reativa(self, api_client, usuario_gestor, usuario_outro_setor):
        api_client.force_authenticate(user=usuario_gestor)
        resp = api_client.post(f"/api/usuarios/gestores/{usuario_outro_setor.uuid}/reativar/")
        assert resp.status_code == 403


# --------------------------------------------------------------------------- #
# Registros inativos — só superusuário enxerga
# --------------------------------------------------------------------------- #

class TestRegistrosInativos:
    def test_gestor_nao_ve_inativos(self, api_client, usuario_gestor, risco_basico):
        risco_basico.delete()  # soft delete
        api_client.force_authenticate(user=usuario_gestor)
        resp = api_client.get("/api/riscos/planos/?incluir_inativos=true")
        uuids = [r["uuid"] for r in resp.json()["results"]]
        assert str(risco_basico.uuid) not in uuids

    def test_superusuario_ve_inativos(self, api_client, usuario_superuser, risco_basico):
        risco_basico.delete()
        api_client.force_authenticate(user=usuario_superuser)
        resp = api_client.get("/api/riscos/planos/?incluir_inativos=true")
        uuids = [r["uuid"] for r in resp.json()["results"]]
        assert str(risco_basico.uuid) in uuids


# --------------------------------------------------------------------------- #
# Varredura por reflexão — nenhum endpoint de escrita sem regra de autorização
# --------------------------------------------------------------------------- #

# Views cujo POST/PUT/PATCH/DELETE é público de propósito.
_ALLOWLIST_ESCRITA_PUBLICA = {
    "LoginView",
    "EnviarCodigoRecuperacaoView",
    "ValidarCodigoRecuperacaoView",
    "RedefinirSenhaView",
}

_PERMISSOES_ACEITAS = {
    "IsAuthenticated",
    "IsAdminUser",
    "ApenasSuperusuarioParaEscrita",
    "PertenceAoSetorDoRisco",
}


def _todas_as_views():
    vistas = {}
    for padrao in get_resolver().url_patterns:
        _coletar(padrao, vistas)
    return vistas


def _coletar(padrao, acc):
    if hasattr(padrao, "url_patterns"):
        for p in padrao.url_patterns:
            _coletar(p, acc)
        return
    callback = getattr(padrao, "callback", None)
    cls = getattr(callback, "cls", getattr(callback, "view_class", None))
    if cls is not None and isinstance(cls, type) and issubclass(cls, APIView):
        acc[cls.__name__] = cls


class TestVarreduraAutorizacao:
    def test_toda_view_de_escrita_tem_regra_de_autorizacao(self):
        problemas = []
        for nome, cls in _todas_as_views().items():
            if nome in _ALLOWLIST_ESCRITA_PUBLICA:
                continue
            perms = getattr(cls, "permission_classes", [])
            nomes_perm = {p.__name__ for p in perms}
            # AllowAny sozinho num endpoint de escrita é o cheiro que a issue caça.
            if permissions.AllowAny in perms and not (nomes_perm & _PERMISSOES_ACEITAS):
                # get_permissions pode restringir por ação — aceita se existir.
                if "get_permissions" in cls.__dict__:
                    continue
                problemas.append(nome)
            if not perms and "get_permissions" not in cls.__dict__:
                problemas.append(f"{nome} (sem permission_classes)")
        assert not problemas, (
            "Views sem regra de autorização (adicione à allowlist se público de "
            f"propósito): {problemas}"
        )
