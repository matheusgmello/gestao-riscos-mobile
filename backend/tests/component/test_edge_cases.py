"""Categoria 2 — Edge case / fronteira.

Coleção vazia em operações de save/merge (que podem apagar vínculos),
listagens/exportações sem dados, e o parâmetro de fronteira do pull.
"""

import pytest

pytestmark = pytest.mark.django_db


class TestSetoresListaVazia:
    def test_admin_removendo_todos_os_setores_liga_o_contador(
        self, api_client, usuario_superuser, usuario_gestor
    ):
        api_client.force_authenticate(user=usuario_superuser)
        resp = api_client.patch(
            f"/api/usuarios/gestores/{usuario_gestor.uuid}/",
            {"id_setores": []},
            format="json",
        )
        assert resp.status_code == 200
        usuario_gestor.refresh_from_db()
        assert usuario_gestor.setores.count() == 0
        assert usuario_gestor.sem_equipe_desde is not None

    def test_admin_devolvendo_um_setor_desliga_o_contador(
        self, api_client, usuario_superuser, usuario_gestor, setor_oficial
    ):
        from django.utils import timezone

        usuario_gestor.setores.clear()
        usuario_gestor.sem_equipe_desde = timezone.now()
        usuario_gestor.save(update_fields=["sem_equipe_desde"])

        api_client.force_authenticate(user=usuario_superuser)
        resp = api_client.patch(
            f"/api/usuarios/gestores/{usuario_gestor.uuid}/",
            {"id_setores": [setor_oficial.id]},
            format="json",
        )
        assert resp.status_code == 200
        usuario_gestor.refresh_from_db()
        assert usuario_gestor.sem_equipe_desde is None

    def test_editar_perfil_sem_id_setores_nao_apaga_vinculos(
        self, api_client, usuario_gestor, setor_oficial
    ):
        api_client.force_authenticate(user=usuario_gestor)
        resp = api_client.patch(
            "/api/usuarios/me/", {"email": "novo@ufsm.br"}, format="json"
        )
        assert resp.status_code == 200
        usuario_gestor.refresh_from_db()
        assert setor_oficial in usuario_gestor.setores.all()


class TestListagensVazias:
    def test_lista_de_riscos_vazia(self, api_client, usuario_gestor):
        api_client.force_authenticate(user=usuario_gestor)
        resp = api_client.get("/api/riscos/planos/")
        assert resp.status_code == 200
        assert resp.json()["count"] == 0
        assert resp.json()["results"] == []

    def test_dashboard_sem_riscos_nao_quebra(self, api_client, usuario_gestor):
        api_client.force_authenticate(user=usuario_gestor)
        resp = api_client.get("/api/riscos/planos/dashboard/")
        assert resp.status_code == 200
        corpo = resp.json()
        assert corpo["total_planos"] == 0
        assert corpo["taxa_mitigacao"] == 0
        assert corpo["cobertura_monitoramento"] == 0
        assert len(corpo["matriz_residual"]) == 25

    def test_exportar_excel_lista_vazia(self, api_client, usuario_gestor):
        api_client.force_authenticate(user=usuario_gestor)
        resp = api_client.get("/api/riscos/planos/exportar-excel/")
        assert resp.status_code == 200
        assert len(resp.content) > 0

    def test_historico_de_risco_recem_criado_e_vazio(self, api_client, usuario_gestor, risco_basico):
        api_client.force_authenticate(user=usuario_gestor)
        resp = api_client.get(f"/api/riscos/planos/{risco_basico.uuid}/historico/")
        assert resp.status_code == 200
        assert resp.json() == []


class TestFronteiraPull:
    def test_modificado_apos_invalido_da_400(self, api_client, usuario_gestor):
        api_client.force_authenticate(user=usuario_gestor)
        resp = api_client.get("/api/riscos/planos/?modificado_apos=nao-e-data")
        assert resp.status_code == 400

    def test_modificado_apos_no_futuro_retorna_vazio(self, api_client, usuario_gestor, risco_basico):
        api_client.force_authenticate(user=usuario_gestor)
        resp = api_client.get(
            "/api/riscos/planos/?modificado_apos=2099-01-01T00:00:00Z"
        )
        assert resp.status_code == 200
        assert resp.json()["count"] == 0
