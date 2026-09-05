"""Categoria 5 — Fronteira de segurança.

Recuperação de senha: janela de expiração testada com relógio deslocado
(não `sleep`), código de uso único, e a mesma mensagem genérica para
"errado" / "expirado" / "já usado" (sem oráculo).
"""

from datetime import timedelta

import pytest
from django.utils import timezone

from usuarios.models import CodigoRecuperacao, Usuario

pytestmark = pytest.mark.django_db

ENVIAR = "/api/usuarios/recuperar-senha/enviar/"
VALIDAR = "/api/usuarios/recuperar-senha/validar/"
REDEFINIR = "/api/usuarios/recuperar-senha/redefinir/"


@pytest.fixture
def usuario_email(db):
    return Usuario.objects.create_user(
        siape="8080808", password="senha_velha", nome="Fulano", email="fulano@ufsm.br"
    )


def _codigo_para(email):
    return CodigoRecuperacao.objects.get(email=email).codigo


def _envelhecer(email, segundos):
    """Empurra `criado_em` para o passado — relógio deslocado, sem sleep."""
    CodigoRecuperacao.objects.filter(email=email).update(
        criado_em=timezone.now() - timedelta(seconds=segundos)
    )


class TestJanelaDeExpiracao:
    def test_codigo_no_limite_ainda_vale(self, api_client, usuario_email):
        api_client.post(ENVIAR, {"email": usuario_email.email}, format="json")
        codigo = _codigo_para(usuario_email.email)
        _envelhecer(usuario_email.email, 59)  # dentro de 1 min
        resp = api_client.post(
            VALIDAR, {"email": usuario_email.email, "codigo": codigo}, format="json"
        )
        assert resp.status_code == 200

    def test_codigo_expirado_um_segundo_depois_falha(self, api_client, usuario_email):
        api_client.post(ENVIAR, {"email": usuario_email.email}, format="json")
        codigo = _codigo_para(usuario_email.email)
        _envelhecer(usuario_email.email, 61)  # 1 min + 1 s
        resp = api_client.post(
            VALIDAR, {"email": usuario_email.email, "codigo": codigo}, format="json"
        )
        assert resp.status_code == 400


class TestSemOraculo:
    def test_errado_expirado_e_ausente_dao_a_mesma_mensagem(self, api_client, usuario_email):
        api_client.post(ENVIAR, {"email": usuario_email.email}, format="json")
        codigo = _codigo_para(usuario_email.email)

        # código errado
        r_errado = api_client.post(
            VALIDAR, {"email": usuario_email.email, "codigo": "000000"}, format="json"
        )
        # código expirado
        _envelhecer(usuario_email.email, 120)
        r_expirado = api_client.post(
            VALIDAR, {"email": usuario_email.email, "codigo": codigo}, format="json"
        )
        # sem código nenhum para o e-mail
        r_ausente = api_client.post(
            VALIDAR, {"email": "ninguem@ufsm.br", "codigo": "123456"}, format="json"
        )

        assert r_errado.status_code == r_expirado.status_code == r_ausente.status_code == 400
        assert r_errado.json()["erro"] == r_expirado.json()["erro"] == r_ausente.json()["erro"]


class TestUsoUnico:
    def test_codigo_nao_funciona_duas_vezes(self, api_client, usuario_email):
        api_client.post(ENVIAR, {"email": usuario_email.email}, format="json")
        codigo = _codigo_para(usuario_email.email)
        corpo = {
            "email": usuario_email.email,
            "codigo": codigo,
            "nova_senha": "novaSenha123",
            "confirmacao_senha": "novaSenha123",
        }
        primeira = api_client.post(REDEFINIR, corpo, format="json")
        assert primeira.status_code == 200

        segunda = api_client.post(REDEFINIR, corpo, format="json")
        assert segunda.status_code == 400

    def test_novo_pedido_invalida_o_codigo_anterior(self, api_client, usuario_email):
        api_client.post(ENVIAR, {"email": usuario_email.email}, format="json")
        codigo_antigo = _codigo_para(usuario_email.email)
        api_client.post(ENVIAR, {"email": usuario_email.email}, format="json")  # novo
        resp = api_client.post(
            VALIDAR, {"email": usuario_email.email, "codigo": codigo_antigo}, format="json"
        )
        assert resp.status_code == 400


class TestEmailInexistente:
    def test_enviar_para_email_desconhecido(self, api_client):
        resp = api_client.post(ENVIAR, {"email": "naoexiste@ufsm.br"}, format="json")
        assert resp.status_code == 404
