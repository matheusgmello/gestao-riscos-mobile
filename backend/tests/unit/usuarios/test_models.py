import pytest

from usuarios.models import Setor, Usuario


@pytest.mark.django_db
class TestSetorModel:
    def test_criar_setor(self):
        # este teste valida a criacao basica de uma unidade no banco
        setor = Setor.objects.create(nome="Setor de Teste", sigla="TST")

        # a validacao cobre a representacao textual e a tabela utilizada
        assert str(setor) == "TST - Setor de Teste"
        assert setor._meta.db_table == "setores"

    def test_labels_curto_e_completo(self):
        # aqui a unidade e criada com todos os campos usados nos labels
        setor = Setor.objects.create(
            nome="Departamento de Computacao Aplicada",
            sigla="CT",
            sigla_centro="CT",
            nome_centro="Centro de Tecnologia",
            tipo_unidade="Departamento Didatico",
            fonte_oficial=True,
        )

        # a validacao confirma os dois formatos de exibicao usados pelo sistema
        assert setor.label_curto == "CT - Departamento de Computacao Aplicada"
        assert (
            setor.label_completo
            == "CT - Departamento de Computacao Aplicada - Centro de Tecnologia - Departamento Didatico"
        )


@pytest.mark.django_db
class TestUsuarioModel:
    def test_criar_usuario(self, db):
        # o primeiro passo e criar uma unidade para vincular ao usuario
        setor = Setor.objects.create(nome="Setor A", sigla="SA")

        # em seguida o teste cria um usuario comum pelo manager customizado
        usuario = Usuario.objects.create_user(
            siape="1234567",
            password="senha_segura",
            nome="Usuário de Teste",
            email="teste@ufsm.br",
        )
        usuario.setores.add(setor)

        # a validacao cobre dados essenciais, vinculo e flags de acesso
        assert usuario.siape == "1234567"
        assert usuario.nome == "Usuário de Teste"
        assert usuario.setores.count() == 1
        assert str(usuario) == "1234567 - Usuário de Teste"
        assert usuario.is_active is True
        assert usuario.is_staff is False

    def test_create_user_sem_siape(self):
        # este teste garante a validacao minima exigida na criacao de usuario
        with pytest.raises(ValueError, match="O SIAPE é obrigatório"):
            Usuario.objects.create_user(siape="")

    def test_create_superuser_com_flags_invalidas(self):
        # aqui o foco e impedir superusuarios com configuracao inconsistente
        with pytest.raises(ValueError, match="Superusuario deve ter equipe=True"):
            Usuario.objects.create_superuser(siape="1", password="p", nome="n", equipe=False)
        with pytest.raises(ValueError, match="Superusuario deve ter is_superuser=True"):
            Usuario.objects.create_superuser(siape="1", password="p", nome="n", is_superuser=False)

    def test_create_superuser_valido(self):
        # neste caso o teste valida o caminho correto para criacao de admin
        superuser = Usuario.objects.create_superuser(
            siape="9999999",
            password="admin_password",
            nome="Admin Master",
            email="admin@ufsm.br",
        )

        # a validacao final confere as flags de administracao
        assert superuser.is_superuser is True
        assert superuser.is_staff is True
