import pytest
from rest_framework import status

from riscos.models import PlanoAcao, Risco


@pytest.mark.django_db
class TestGerencialFluxo:
    def test_dashboard_e_mapa_retorna_analytics_gerenciais(
        self,
        api_client,
        usuario_gestor,
        setor_oficial,
        objetivo_padrao,
        macroprocesso_padrao,
    ):
        # este fluxo cria dois riscos (um base e um critico), associa um plano de acao ao
        # risco critico e valida que dashboard e mapa-analytics refletem os dados corretamente
        api_client.force_authenticate(user=usuario_gestor)

        Risco.objects.create(
            setor=setor_oficial,
            objetivo=objetivo_padrao,
            macroprocesso=macroprocesso_padrao,
            categoria="Operacional",
            evento="Risco base",
            causa="C",
            consequencia="C",
            controles_atuais="C",
            eficacia_controle="Satisfatório",
            probabilidade=3,
            impacto=3,
            prob_residual=1,
            imp_residual=1,
        )

        risco_critico = Risco.objects.create(
            setor=setor_oficial,
            objetivo=objetivo_padrao,
            macroprocesso=macroprocesso_padrao,
            categoria="Estratégico",
            evento="Risco crítico",
            causa="Causa crítica",
            consequencia="Consequência crítica",
            controles_atuais="Controle",
            eficacia_controle="Satisfatório",
            probabilidade=5,
            impacto=5,
            prob_residual=4,
            imp_residual=5,
        )

        PlanoAcao.objects.create(
            risco=risco_critico,
            tipo_resposta="Mitigar",
            descricao_acao="Mitigar risco crítico.",
            responsavel="Gestor estratégico",
            data_inicio="2026-02-01",
            data_fim="2026-02-28",
            status="Em andamento",
        )

        dashboard_response = api_client.get("/api/riscos/planos/dashboard/")
        mapa_response = api_client.get("/api/riscos/planos/mapa-analytics/")

        # valida os numeros consolidados da dashboard
        assert dashboard_response.status_code == status.HTTP_200_OK
        assert dashboard_response.data["total_planos"] == 2
        assert dashboard_response.data["riscos_criticos"] == 1
        assert dashboard_response.data["status_tratamentos"]["em_andamento"] == 1
        assert dashboard_response.data["unidades_maior_exposicao"][0]["pontos"] >= 20
        assert any(
            item["nome"] == "Estratégico" and item["quantidade"] == 1
            for item in dashboard_response.data["distribuicao_categorias"]
        )

        # valida os dados analiticos do mapa de riscos
        assert mapa_response.status_code == status.HTTP_200_OK
        assert mapa_response.data["total_riscos"] == 2
        assert mapa_response.data["resumo_niveis"]["extremo"] == 1
        assert mapa_response.data["status_tratamentos"]["em_andamento"] == 1
        assert len(mapa_response.data["matriz_residual"]) == 25
        assert mapa_response.data["riscos_prioritarios"][0]["uuid"] == str(risco_critico.uuid)
