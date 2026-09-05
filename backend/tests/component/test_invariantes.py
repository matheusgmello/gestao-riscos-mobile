"""Categoria 1 — Regra de negócio / invariante (com caminhos negativos).

Complementa `test_views.py` cobrindo o que faltava um caminho proibido:
nível read-only, ciclo do `sem_equipe_desde`, histórico append-only em toda
mutação, e o soft delete sobre os managers.
"""

from datetime import timedelta

import pytest
from django.utils import timezone

from riscos.models import HistoricoPlano, Monitoramento, PlanoAcao, Risco

pytestmark = pytest.mark.django_db


# --------------------------------------------------------------------------- #
# nivel_risco / nivel_residual são derivados — cliente não escreve
# --------------------------------------------------------------------------- #

class TestNivelReadOnly:
    def _payload(self, setor, objetivo, macro, **extra):
        base = {
            "setor": setor.id,
            "objetivo": objetivo.id,
            "macroprocesso": macro.id,
            "categoria": "Operacional",
            "evento": "e",
            "causa": "c",
            "consequencia": "q",
            "controles_atuais": "x",
            "eficacia_controle": "Fraco",
            "probabilidade": 3,
            "impacto": 3,
            "prob_residual": 2,
            "imp_residual": 2,
        }
        base.update(extra)
        return base

    def test_valor_de_nivel_no_payload_e_ignorado_na_criacao(
        self, api_client, usuario_gestor, setor_oficial, objetivo_padrao, macroprocesso_padrao
    ):
        api_client.force_authenticate(user=usuario_gestor)
        resp = api_client.post(
            "/api/riscos/planos/",
            self._payload(
                setor_oficial, objetivo_padrao, macroprocesso_padrao,
                nivel_risco=999, nivel_residual=999,
            ),
            format="json",
        )
        assert resp.status_code == 201
        # 3*3 e 2*2, não o 999 enviado
        assert resp.json()["nivel_risco"] == 9
        assert resp.json()["nivel_residual"] == 4

    def test_valor_de_nivel_no_payload_e_ignorado_na_edicao(
        self, api_client, usuario_gestor, risco_basico
    ):
        api_client.force_authenticate(user=usuario_gestor)
        resp = api_client.patch(
            f"/api/riscos/planos/{risco_basico.uuid}/",
            {"probabilidade": 5, "impacto": 4, "nivel_risco": 1},
            format="json",
        )
        assert resp.status_code == 200
        assert resp.json()["nivel_risco"] == 20  # 5*4, não o 1

    def test_recalcula_ao_salvar_o_model_direto(self, risco_basico):
        risco_basico.prob_residual = 5
        risco_basico.imp_residual = 5
        risco_basico.save()
        risco_basico.refresh_from_db()
        assert risco_basico.nivel_residual == 25


# --------------------------------------------------------------------------- #
# sem_equipe_desde — ciclo completo
# --------------------------------------------------------------------------- #

class TestBloqueioSemEquipe:
    def test_remover_do_ultimo_setor_marca_data(
        self, api_client, usuario_gestor_adm, usuario_gestor, setor_oficial
    ):
        api_client.force_authenticate(user=usuario_gestor_adm)
        resp = api_client.post(
            f"/api/usuarios/setores/{setor_oficial.id}/remover_membro/",
            {"usuario_id": usuario_gestor.id},
            format="json",
        )
        assert resp.status_code == 200
        usuario_gestor.refresh_from_db()
        assert usuario_gestor.sem_equipe_desde is not None

    def test_readicionar_a_um_setor_limpa_a_data(
        self, api_client, usuario_gestor_adm, usuario_gestor, setor_oficial
    ):
        usuario_gestor.setores.clear()
        usuario_gestor.sem_equipe_desde = timezone.now()
        usuario_gestor.save(update_fields=["sem_equipe_desde"])

        api_client.force_authenticate(user=usuario_gestor_adm)
        resp = api_client.post(
            f"/api/usuarios/setores/{setor_oficial.id}/adicionar_membro/",
            {"siape": usuario_gestor.siape},
            format="json",
        )
        assert resp.status_code == 200
        usuario_gestor.refresh_from_db()
        assert usuario_gestor.sem_equipe_desde is None

    def test_gestor_sem_setor_ha_mais_de_7_dias_fica_inativo(self, usuario_gestor):
        usuario_gestor.setores.clear()
        usuario_gestor.sem_equipe_desde = timezone.now() - timedelta(days=7, hours=1)
        usuario_gestor.save(update_fields=["sem_equipe_desde"])
        assert usuario_gestor.is_active is False

    def test_gestor_sem_setor_ha_menos_de_7_dias_continua_ativo(self, usuario_gestor):
        usuario_gestor.setores.clear()
        usuario_gestor.sem_equipe_desde = timezone.now() - timedelta(days=6)
        usuario_gestor.save(update_fields=["sem_equipe_desde"])
        assert usuario_gestor.is_active is True

    def test_superusuario_sem_setor_nao_e_bloqueado(self, usuario_superuser):
        usuario_superuser.setores.clear()
        usuario_superuser.sem_equipe_desde = timezone.now() - timedelta(days=30)
        usuario_superuser.save(update_fields=["sem_equipe_desde"])
        assert usuario_superuser.is_active is True


# --------------------------------------------------------------------------- #
# HistoricoPlano — append-only, uma entrada por mutação
# --------------------------------------------------------------------------- #

class TestHistoricoAppendOnly:
    def test_criar_acao_gera_entrada(self, api_client, usuario_gestor, risco_basico):
        antes = HistoricoPlano.objects.filter(risco=risco_basico).count()
        api_client.force_authenticate(user=usuario_gestor)
        api_client.post(
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
        assert HistoricoPlano.objects.filter(risco=risco_basico).count() == antes + 1

    def test_criar_monitoramento_gera_entrada(self, api_client, usuario_gestor, risco_basico):
        antes = HistoricoPlano.objects.filter(risco=risco_basico).count()
        api_client.force_authenticate(user=usuario_gestor)
        api_client.post(
            "/api/riscos/monitoramentos/",
            {
                "risco": str(risco_basico.uuid),
                "resultados": "r",
                "acoes_futuras": "a",
                "analise_critica": "c",
            },
            format="json",
        )
        assert HistoricoPlano.objects.filter(risco=risco_basico).count() == antes + 1

    def test_editar_risco_duas_vezes_gera_duas_entradas(self, api_client, usuario_gestor, risco_basico):
        antes = HistoricoPlano.objects.filter(risco=risco_basico).count()
        api_client.force_authenticate(user=usuario_gestor)
        api_client.patch(f"/api/riscos/planos/{risco_basico.uuid}/", {"evento": "e1"}, format="json")
        api_client.patch(f"/api/riscos/planos/{risco_basico.uuid}/", {"evento": "e2"}, format="json")
        assert HistoricoPlano.objects.filter(risco=risco_basico).count() == antes + 2

    def test_historico_endpoint_e_somente_leitura(self, api_client, usuario_gestor, risco_basico):
        # a única rota de historico é GET /planos/{uuid}/historico/ — sem POST/PUT/DELETE
        api_client.force_authenticate(user=usuario_gestor)
        url = f"/api/riscos/planos/{risco_basico.uuid}/historico/"
        assert api_client.get(url).status_code == 200
        assert api_client.post(url, {}, format="json").status_code == 405
        assert api_client.delete(url).status_code == 405


# --------------------------------------------------------------------------- #
# Soft delete sobre os managers
# --------------------------------------------------------------------------- #

class TestSoftDeleteManagers:
    def test_objects_esconde_all_objects_mostra(self, risco_com_plano):
        risco_com_plano.delete()
        assert not Risco.objects.filter(pk=risco_com_plano.pk).exists()
        assert Risco.all_objects.filter(pk=risco_com_plano.pk).exists()

    def test_cascata_desativa_filhos_nos_dois_managers(self, risco_com_monitoramento):
        risco_com_monitoramento.delete()
        assert not PlanoAcao.objects.filter(risco=risco_com_monitoramento).exists()
        assert not Monitoramento.objects.filter(risco=risco_com_monitoramento).exists()
        assert PlanoAcao.all_objects.filter(risco=risco_com_monitoramento).exists()
        assert Monitoramento.all_objects.filter(risco=risco_com_monitoramento).exists()

    def test_delete_nao_apaga_fisicamente(self, risco_basico):
        pk = risco_basico.pk
        risco_basico.delete()
        assert Risco.all_objects.get(pk=pk).ativo is False
