import pytest
from rest_framework import status


@pytest.mark.django_db
class TestExportacoesFluxo:
    def test_exportacoes_individuais_funcionam_para_risco_com_plano(self, api_client, usuario_gestor, risco_com_plano):
        # este fluxo cobre autenticacao, leitura do risco e exportacoes finais
        api_client.force_authenticate(user=usuario_gestor)

        excel_response = api_client.get(f"/api/riscos/planos/{risco_com_plano.uuid}/exportar-excel/")
        pdf_response = api_client.get(f"/api/riscos/planos/{risco_com_plano.uuid}/exportar-pdf/")

        assert excel_response.status_code == status.HTTP_200_OK
        assert excel_response["Content-Type"] == "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        assert excel_response.content.startswith(b"PK")

        assert pdf_response.status_code == status.HTTP_200_OK
        assert pdf_response["Content-Type"] == "application/pdf"
        assert pdf_response.content.startswith(b"%PDF")
