import pytest
from rest_framework import status

from usuarios.models import Setor, Usuario


@pytest.fixture
def setor(db):
    return Setor.objects.create(nome="Setor A", sigla="SA")

@pytest.fixture
def usuario(db, setor):
    u = Usuario.objects.create_user(
        siape="1111111", 
        password="senha_original", 
        nome="Teste Original", 
        email="orig@ufsm.br"
    )
    u.setores.add(setor)
    return u

@pytest.fixture
def admin_usuario(db, setor):
    u = Usuario.objects.create_superuser(
        siape="7777777",
        password="senha_admin",
        nome="Admin Sistema",
        email="admin@ufsm.br"
    )
    u.setores.add(setor)
    return u

@pytest.fixture
def gestor_adm(db, setor):
    u = Usuario.objects.create_user(
        siape="5555555",
        password="senha_gestadm",
        nome="Gestor Administrador",
        email="gestadm@ufsm.br",
        cargo="gestor_adm",
    )
    u.setores.add(setor)
    return u

@pytest.mark.django_db
class TestUsuarioViews:
    def test_listar_setores_publico(self, api_client, setor):
        url = "/api/usuarios/setores/"
        response = api_client.get(url)
        assert response.status_code == status.HTTP_200_OK
        assert isinstance(response.data, list)
        assert len(response.data) >= 1

    def test_registro_usuario(self, api_client, setor, admin_usuario):
        api_client.force_authenticate(user=admin_usuario)
        url = "/api/usuarios/registro/"
        payload = {
            "siape": "2222222",
            "senha": "senha_segura_123",
            "nome": "Novo Gestor",
            "email": "novo@ufsm.br",
            "id_setores": [setor.id]
        }
        response = api_client.post(url, payload, format='json')
        assert response.status_code == status.HTTP_201_CREATED
        assert response.data["usuario"]["nome"] == "Novo Gestor"

    def test_login_usuario(self, api_client, usuario):
        url = "/api/usuarios/login/"
        payload = {"siape": "1111111", "senha": "senha_original"}
        response = api_client.post(url, payload, format='json')
        assert response.status_code == status.HTTP_200_OK
        assert "token" in response.data

    def test_login_invalido(self, api_client, usuario):
        url = "/api/usuarios/login/"
        payload = {"siape": "1111111", "senha": "senha_errada"}
        response = api_client.post(url, payload, format='json')
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_perfil_usuario_autenticado(self, api_client, usuario):
        api_client.force_authenticate(user=usuario)
        url = "/api/usuarios/me/"
        response = api_client.get(url)
        assert response.status_code == status.HTTP_200_OK
        assert response.data["siape"] == usuario.siape
        assert response.data["setores"][0]["label_curto"] == "SA - Setor A"

    def test_atualizar_perfil(self, api_client, usuario):
        api_client.force_authenticate(user=usuario)
        url = "/api/usuarios/me/"
        novo_email = "atualizado@ufsm.br"
        # Agora exige senha_atual, nova_senha e confirmacao_senha
        payload = {
            "email": novo_email, 
            "senha_atual": "senha_original",
            "nova_senha": "nova_senha_456",
            "confirmacao_senha": "nova_senha_456"
        }
        response = api_client.patch(url, payload, format='json')
        assert response.status_code == status.HTTP_200_OK
        assert response.data["usuario"]["email"] == novo_email
        
        # Verificar se a senha realmente mudou
        usuario.refresh_from_db()
        assert usuario.check_password("nova_senha_456") is True

    def test_enviar_codigo_sucesso(self, api_client, usuario):
        url = "/api/usuarios/recuperar-senha/enviar/"
        payload = {"email": usuario.email}
        response = api_client.post(url, payload, format='json')
        assert response.status_code == status.HTTP_200_OK
        assert response.data["mensagem"] == "Código enviado com sucesso!"

    def test_enviar_codigo_email_inexistente(self, api_client):
        url = "/api/usuarios/recuperar-senha/enviar/"
        payload = {"email": "fantasma@ufsm.br"}
        response = api_client.post(url, payload, format='json')
        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_validar_codigo_sucesso(self, api_client, usuario):
        from usuarios.models import CodigoRecuperacao
        CodigoRecuperacao.objects.create(email=usuario.email, codigo="123456")
        
        url = "/api/usuarios/recuperar-senha/validar/"
        payload = {"email": usuario.email, "codigo": "123456"}
        response = api_client.post(url, payload, format='json')
        assert response.status_code == status.HTTP_200_OK

    def test_validar_codigo_errado(self, api_client, usuario):
        from usuarios.models import CodigoRecuperacao
        CodigoRecuperacao.objects.create(email=usuario.email, codigo="123456")
        
        url = "/api/usuarios/recuperar-senha/validar/"
        payload = {"email": usuario.email, "codigo": "000000"}
        response = api_client.post(url, payload, format='json')
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_validar_codigo_expirado(self, api_client, usuario):
        from datetime import timedelta

        from django.utils import timezone

        from usuarios.models import CodigoRecuperacao
        
        # Cria o código
        registro = CodigoRecuperacao.objects.create(email=usuario.email, codigo="123456")
        
        # Retrocede o tempo de criação manualmente para simular expiração (ex: 2 minutos atrás)
        CodigoRecuperacao.objects.filter(id=registro.id).update(
            criado_em=timezone.now() - timedelta(minutes=2)
        )
        
        url = "/api/usuarios/recuperar-senha/validar/"
        payload = {"email": usuario.email, "codigo": "123456"}
        response = api_client.post(url, payload, format='json')
        
        assert response.status_code == status.HTTP_400_BAD_REQUEST
        # mensagem genérica (código expirado e código errado não viram oráculo)
        assert response.data["erro"] == "Código inválido ou expirado. Solicite um novo."

    def test_redefinir_senha_sucesso(self, api_client, usuario):
        from usuarios.models import CodigoRecuperacao
        CodigoRecuperacao.objects.create(email=usuario.email, codigo="123456")
        
        url = "/api/usuarios/recuperar-senha/redefinir/"
        payload = {
            "email": usuario.email,
            "codigo": "123456",
            "nova_senha": "nova_senha_ultra_segura",
            "confirmacao_senha": "nova_senha_ultra_segura"
        }
        response = api_client.post(url, payload, format='json')
        assert response.status_code == status.HTTP_200_OK
        
        # Valida se a senha mudou mesmo
        usuario.refresh_from_db()
        assert usuario.check_password("nova_senha_ultra_segura") is True

    def test_redefinir_senha_senhas_divergentes(self, api_client, usuario):
        url = "/api/usuarios/recuperar-senha/redefinir/"
        payload = {
            "email": usuario.email,
            "codigo": "123456",
            "nova_senha": "senha1",
            "confirmacao_senha": "senha2"
        }
        response = api_client.post(url, payload, format='json')
        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert response.data["erro"] == "As senhas não coincidem."

    def test_listar_membros_setor(self, api_client, usuario, setor):
        api_client.force_authenticate(user=usuario)
        url = f"/api/usuarios/setores/{setor.id}/membros/"
        response = api_client.get(url)
        assert response.status_code == status.HTTP_200_OK
        assert len(response.data) == 1
        assert response.data[0]["siape"] == usuario.siape

    def test_listar_unidades_admin_exige_superusuario(self, api_client, usuario):
        api_client.force_authenticate(user=usuario)
        response = api_client.get("/api/usuarios/setores/admin/")
        assert response.status_code == status.HTTP_403_FORBIDDEN
        assert response.data["erro"] == "Apenas administradores do sistema podem visualizar esta tela."

    def test_listar_unidades_admin_sucesso(self, api_client, admin_usuario, setor):
        api_client.force_authenticate(user=admin_usuario)
        response = api_client.get("/api/usuarios/setores/admin/")
        assert response.status_code == status.HTTP_200_OK
        assert isinstance(response.data, dict)
        assert response.data["count"] >= 1
        assert response.data["results"][0]["label_completo"]
        assert "centros" in response.data
        assert "tipos" in response.data

    def test_listar_unidades_admin_com_filtro_e_paginacao(self, api_client, admin_usuario):
        unidade_ct = Setor.objects.create(
            nome="Departamento de Computacao",
            sigla="CT",
            sigla_centro="CT",
            nome_centro="Centro de Tecnologia",
            tipo_unidade="Departamento Didatico",
            fonte_oficial=True,
        )
        Setor.objects.create(
            nome="Biblioteca Central",
            sigla="BC",
            sigla_centro="REI",
            nome_centro="Reitoria",
            tipo_unidade="Orgao Suplementar",
            fonte_oficial=True,
        )
        api_client.force_authenticate(user=admin_usuario)
        response = api_client.get(
            "/api/usuarios/setores/admin/",
            {"centro": "CT", "search": "Computacao", "page": 1, "page_size": 1},
        )
        assert response.status_code == status.HTTP_200_OK
        assert response.data["count"] == 1
        assert response.data["page"] == 1
        assert response.data["total_pages"] == 1
        assert response.data["results"][0]["id"] == unidade_ct.id

    def test_remover_membro_setor_sucesso(self, api_client, gestor_adm, setor):
        api_client.force_authenticate(user=gestor_adm)
        url = f"/api/usuarios/setores/{setor.id}/remover_membro/"
        payload = {"usuario_id": gestor_adm.id}
        response = api_client.post(url, payload, format='json')
        assert response.status_code == status.HTTP_200_OK
        assert response.data["mensagem"] == "Membro removido da equipe com sucesso."
        assert setor not in gestor_adm.setores.all()

    def test_remover_membro_nao_pertencente(self, api_client, gestor_adm):
        setor_vazio = Setor.objects.create(nome="Vazio", sigla="VV")
        api_client.force_authenticate(user=gestor_adm)
        url = f"/api/usuarios/setores/{setor_vazio.id}/remover_membro/"
        payload = {"usuario_id": gestor_adm.id}
        response = api_client.post(url, payload, format='json')
        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert response.data["erro"] == "Usuário não pertence a esta unidade."

    def test_adicionar_membro_setor_sucesso(self, api_client, gestor_adm, setor):
        novo_usuario = Usuario.objects.create_user(siape="999", password="p", nome="Novo", email="n@u.com")
        api_client.force_authenticate(user=gestor_adm)
        url = f"/api/usuarios/setores/{setor.id}/adicionar_membro/"
        payload = {"siape": "999"}
        response = api_client.post(url, payload, format='json')
        assert response.status_code == status.HTTP_200_OK
        assert response.data["mensagem"] == "Membro adicionado com sucesso!"
        assert setor in novo_usuario.setores.all()

    def test_adicionar_membro_ja_existente(self, api_client, gestor_adm, setor):
        api_client.force_authenticate(user=gestor_adm)
        url = f"/api/usuarios/setores/{setor.id}/adicionar_membro/"
        payload = {"siape": gestor_adm.siape}
        response = api_client.post(url, payload, format='json')
        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert response.data["erro"] == "Este usuário já faz parte desta unidade."


@pytest.mark.django_db
class TestRegistroAdminOnly:
    def test_registro_bloqueado_para_nao_autenticado(self, api_client):
        response = api_client.post("/api/usuarios/registro/", {
            "siape": "3333333", "nome": "Novo", "senha": "Senha@123",
        }, format='json')
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_registro_bloqueado_para_gestor_comum(self, api_client, usuario):
        api_client.force_authenticate(user=usuario)
        response = api_client.post("/api/usuarios/registro/", {
            "siape": "3333333", "nome": "Novo", "senha": "Senha@123",
        }, format='json')
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_admin_cria_usuario_com_sucesso(self, api_client, setor, usuario_superuser):
        api_client.force_authenticate(user=usuario_superuser)
        response = api_client.post("/api/usuarios/registro/", {
            "siape": "7654321",
            "nome": "Novo Gestor",
            "senha": "Senha@12345",
            "id_setores": [setor.id],
        }, format='json')
        assert response.status_code == status.HTTP_201_CREATED
        assert response.data["usuario"]["siape"] == "7654321"
        assert Usuario.objects.filter(siape="7654321").exists()


@pytest.mark.django_db
class TestGestaoUsuariosAdmin:
    def test_listar_usuarios_bloqueado_para_gestor(self, api_client, usuario):
        api_client.force_authenticate(user=usuario)
        response = api_client.get("/api/usuarios/gestores/")
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_listar_usuarios_retorna_todos_para_admin(self, api_client, usuario, usuario_superuser):
        api_client.force_authenticate(user=usuario_superuser)
        response = api_client.get("/api/usuarios/gestores/")
        assert response.status_code == status.HTTP_200_OK
        siapes = [u["siape"] for u in response.data["results"]]
        assert usuario.siape in siapes

    def test_admin_desativa_usuario(self, api_client, usuario, usuario_superuser):
        api_client.force_authenticate(user=usuario_superuser)
        response = api_client.delete(f"/api/usuarios/gestores/{usuario.uuid}/")
        assert response.status_code == status.HTTP_204_NO_CONTENT
        usuario.refresh_from_db()
        assert not usuario.ativo

    def test_admin_reativa_usuario(self, api_client, usuario, usuario_superuser):
        usuario.ativo = False
        usuario.save()
        api_client.force_authenticate(user=usuario_superuser)
        response = api_client.post(f"/api/usuarios/gestores/{usuario.uuid}/reativar/")
        assert response.status_code == status.HTTP_200_OK
        usuario.refresh_from_db()
        assert usuario.ativo

    def test_admin_nao_pode_desativar_superusuario(self, api_client, usuario_superuser):
        api_client.force_authenticate(user=usuario_superuser)
        response = api_client.delete(f"/api/usuarios/gestores/{usuario_superuser.uuid}/")
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_adicionar_membro_nao_encontrado(self, api_client, gestor_adm, setor):
        api_client.force_authenticate(user=gestor_adm)
        url = f"/api/usuarios/setores/{setor.id}/adicionar_membro/"
        payload = {"siape": "000"}
        response = api_client.post(url, payload, format='json')
        assert response.status_code == status.HTTP_404_NOT_FOUND
        assert response.data["erro"] == "Usuário com este SIAPE não encontrado."

    def test_admin_exibir_setores(self, db, usuario, setor):
        from django.contrib.admin.sites import AdminSite

        from usuarios.admin import UsuarioAdmin
        
        ua = UsuarioAdmin(Usuario, AdminSite())
        display = ua.exibir_setores(usuario)
        assert setor.label_curto in display
