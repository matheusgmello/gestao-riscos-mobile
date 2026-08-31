import pytest
from rest_framework import status

from riscos.models import PlanoAcao, Risco


@pytest.mark.django_db
class TestDashboardFluxoRisco:
    def test_criacao_de_risco_reflete_na_dashboard(self, api_client, usuario_gestor, setor_oficial, objetivo_padrao, macroprocesso_padrao):
        # este fluxo cobre criacao de risco, criacao de plano e leitura consolidada da dashboard
        api_client.force_authenticate(user=usuario_gestor)

        criar_risco = api_client.post(
            "/api/riscos/planos/",
            {
                "setor": setor_oficial.id,
                "objetivo": objetivo_padrao.id,
                "macroprocesso": macroprocesso_padrao.id,
                "categoria": "Operacional",
                "evento": "Risco de indisponibilidade do portal",
                "causa": "Infraestrutura instavel",
                "consequencia": "Parada de servicos",
                "controles_atuais": "Monitoramento inicial",
                "eficacia_controle": "Fraco",
                "probabilidade": 4,
                "impacto": 4,
                "prob_residual": 3,
                "imp_residual": 4,
            },
            format="json",
        )

        assert criar_risco.status_code == status.HTTP_201_CREATED

        risco = Risco.objects.get(evento="Risco de indisponibilidade do portal")
        PlanoAcao.objects.create(
            risco=risco,
            tipo_resposta="Mitigar",
            descricao_acao="Expandir observabilidade e redundancia",
            responsavel="Gestor Principal",
            data_inicio="2026-04-01",
            data_fim="2026-04-30",
            status="Em andamento",
        )

        response = api_client.get("/api/riscos/planos/dashboard/")

        assert response.status_code == status.HTTP_200_OK
        assert response.data["total_planos"] == 1
        assert response.data["tratamentos_ativos"] == 1
        assert response.data["riscos_sem_acao"] == 0
        assert response.data["planos"][0]["evento"] == "Risco de indisponibilidade do portal"
        assert response.data["planos"][0]["periodo_acao"] == {
            "data_inicio": "2026-04-01",
            "data_fim": "2026-04-30",
        }
