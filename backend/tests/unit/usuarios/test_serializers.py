import pytest

from usuarios.serializers import AtualizarPerfilSerializer, RegistroUsuarioSerializer


@pytest.mark.django_db
class TestRegistroUsuarioSerializer:
    def test_cria_usuario_com_setor_vinculado(self, setor_oficial):
        # este teste valida a criacao completa de um usuario via serializer
        serializer = RegistroUsuarioSerializer(
            data={
                "siape": "3333333",
                "senha": "senha_segura_123",
                "nome": "Gestor Criado",
                "email": "gestor.criado@ufsm.br",
                "id_setores": [setor_oficial.id],
            }
        )

        assert serializer.is_valid(), serializer.errors

        usuario = serializer.save()

        assert usuario.siape == "3333333"
        assert usuario.nome == "Gestor Criado"
        assert usuario.email == "gestor.criado@ufsm.br"
        assert usuario.check_password("senha_segura_123") is True
        assert list(usuario.setores.values_list("id", flat=True)) == [setor_oficial.id]


@pytest.mark.django_db
class TestAtualizarPerfilSerializer:
    def test_atualiza_email_e_setores_sem_mudar_senha(self, usuario_gestor, setor_secundario):
        # este cenario cobre uma atualizacao parcial sem troca de senha
        serializer = AtualizarPerfilSerializer(
            instance=usuario_gestor,
            data={
                "email": "novo.email@ufsm.br",
                "id_setores": [setor_secundario.id],
            },
            partial=True,
        )

        assert serializer.is_valid(), serializer.errors

        usuario = serializer.save()

        assert usuario.email == "novo.email@ufsm.br"
        assert list(usuario.setores.values_list("id", flat=True)) == [setor_secundario.id]
        assert usuario.check_password("senha_original") is True

    def test_rejeita_mudanca_de_senha_sem_senha_atual(self, usuario_gestor):
        # a troca de senha deve exigir a senha atual
        serializer = AtualizarPerfilSerializer(
            instance=usuario_gestor,
            data={
                "nova_senha": "nova_senha_123",
                "confirmacao_senha": "nova_senha_123",
            },
            partial=True,
        )

        assert serializer.is_valid() is False
        assert "senha_atual" in serializer.errors

    def test_rejeita_senha_atual_incorreta(self, usuario_gestor):
        # este caso garante a validacao da credencial antiga
        serializer = AtualizarPerfilSerializer(
            instance=usuario_gestor,
            data={
                "senha_atual": "senha_errada",
                "nova_senha": "nova_senha_123",
                "confirmacao_senha": "nova_senha_123",
            },
            partial=True,
        )

        assert serializer.is_valid() is False
        assert serializer.errors["senha_atual"][0] == "Senha atual incorreta."

    def test_rejeita_confirmacao_divergente(self, usuario_gestor):
        # a confirmacao deve coincidir com a nova senha
        serializer = AtualizarPerfilSerializer(
            instance=usuario_gestor,
            data={
                "senha_atual": "senha_original",
                "nova_senha": "nova_senha_123",
                "confirmacao_senha": "senha_diferente_123",
            },
            partial=True,
        )

        assert serializer.is_valid() is False
        assert "confirmacao_senha" in serializer.errors

    def test_aplica_nova_senha_quando_todos_os_dados_estao_corretos(self, usuario_gestor):
        # quando os dados estao corretos o hash da senha deve ser atualizado
        serializer = AtualizarPerfilSerializer(
            instance=usuario_gestor,
            data={
                "senha_atual": "senha_original",
                "nova_senha": "nova_senha_123",
                "confirmacao_senha": "nova_senha_123",
            },
            partial=True,
        )

        assert serializer.is_valid(), serializer.errors

        usuario = serializer.save()

        assert usuario.check_password("nova_senha_123") is True
