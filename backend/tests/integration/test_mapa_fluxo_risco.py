import pytest
from rest_framework import status

from riscos.models import PlanoAcao, Risco


@pytest.mark.django_db
class TestMapaFluxoRisco:
    def test_criacao_de_risco_reflete_no_mapa_analytics(self, api_client, usuario_gestor, setor_oficial, objetivo_padrao, macroprocesso_padrao):
        # este fluxo valida se a criacao do risco aparece no mapa com os agregados corretos
        api_client.force_authenticate(user=usuario_gestor)

        resposta_criacao = api_client.post(
            "/api/riscos/planos/",
            {
                "setor": setor_oficial.id,
                "objetivo": objetivo_padrao.id,
                "macroprocesso": macroprocesso_padrao.id,
                "categoria": "Financeiro",
                "evento": "Reducao de verba para manutencao",
                "causa": "Contingenciamento",
                "consequencia": "Interrupcao de contratos",
                "controles_atuais": "Reserva minima",
                "eficacia_controle": "Fraco",
                "probabilidade": 5,
                "impacto": 4,
                "prob_residual": 4,
                "imp_residual": 4,
            },
            format="json",
        )

        assert resposta_criacao.status_code == status.HTTP_201_CREATED

        risco = Risco.objects.get(evento="Reducao de verba para manutencao")
        PlanoAcao.objects.create(
            risco=risco,
            tipo_resposta="Mitigar",
            descricao_acao="Replanejar contratos e reservas",
            responsavel="Gestor Principal",
            data_inicio="2026-05-01",
            data_fim="2026-06-01",
            status="Nao iniciada",
        )

        response = api_client.get("/api/riscos/planos/mapa-analytics/")

        assert response.status_code == status.HTTP_200_OK
        assert response.data["total_riscos"] == 1
        assert response.data["resumo_niveis"]["alto"] == 1
        assert response.data["riscos_prioritarios"][0]["evento"] == "Reducao de verba para manutencao"
        assert any(
            item["nome"] == "Financeiro" and item["quantidade"] == 1
            for item in response.data["distribuicao_categorias"]
        )
        assert response.data["unidades_maior_pontuacao"][0]["nome"] == setor_oficial.label_curto
