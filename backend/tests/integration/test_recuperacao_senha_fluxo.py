import pytest
from rest_framework import status

from usuarios.models import CodigoRecuperacao


@pytest.mark.django_db
class TestRecuperacaoSenhaFluxo:
    def test_fluxo_completo_de_recuperacao_de_senha(self, api_client, usuario_gestor):
        # este fluxo passa por envio do codigo, validacao, redefinicao e novo login
        envio_response = api_client.post(
            "/api/usuarios/recuperar-senha/enviar/",
            {"email": usuario_gestor.email},
            format="json",
        )

        assert envio_response.status_code == status.HTTP_200_OK

        codigo = CodigoRecuperacao.objects.get(email=usuario_gestor.email).codigo

        validar_response = api_client.post(
            "/api/usuarios/recuperar-senha/validar/",
            {"email": usuario_gestor.email, "codigo": codigo},
            format="json",
        )

        assert validar_response.status_code == status.HTTP_200_OK

        redefinir_response = api_client.post(
            "/api/usuarios/recuperar-senha/redefinir/",
            {
                "email": usuario_gestor.email,
                "codigo": codigo,
                "nova_senha": "nova_senha_fluxo_123",
                "confirmacao_senha": "nova_senha_fluxo_123",
            },
            format="json",
        )

        assert redefinir_response.status_code == status.HTTP_200_OK

        login_response = api_client.post(
            "/api/usuarios/login/",
            {"siape": usuario_gestor.siape, "senha": "nova_senha_fluxo_123"},
            format="json",
        )

        assert login_response.status_code == status.HTTP_200_OK
        assert "token" in login_response.data
