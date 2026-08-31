import random
from datetime import timedelta

from django.conf import settings as django_settings
from django.contrib.auth import authenticate
from django.core.mail import send_mail
from django.db.models import Q
from django.utils import timezone
from rest_framework import generics, status, viewsets
from rest_framework.authtoken.models import Token
from rest_framework.decorators import action
from rest_framework.pagination import PageNumberPagination
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import CodigoRecuperacao, UnidadeOrganizacional, Usuario
from .serializers import (
    AdminEditarUsuarioSerializer,
    AtualizarPerfilSerializer,
    RegistroUsuarioSerializer,
    UnidadeOrganizacionalSerializer,
    UsuarioSerializer,
)


def _usuario_eh_superusuario(usuario):
    return bool(getattr(usuario, "is_superuser", False))


def _query_int(request, nome, padrao):
    try:
        return int(request.query_params.get(nome, padrao))
    except (TypeError, ValueError):
        return padrao

class EnviarCodigoRecuperacaoView(APIView):
    """
    Gera e "envia" um código de 6 dígitos para o e-mail informado.
    Valida se o e-mail pertence a um usuário cadastrado.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email')
        if not email:
            return Response({'erro': 'O e-mail é obrigatório.'}, status=status.HTTP_400_BAD_REQUEST)

        # Valida se o usuário existe
        if not Usuario.objects.filter(email=email).exists():
            return Response({'erro': 'E-mail não encontrado no sistema.'}, status=status.HTTP_404_NOT_FOUND)

        # Gera código de 6 dígitos
        codigo = ''.join([str(random.randint(0, 9)) for _ in range(6)])
        
        # Salva o código (remove códigos anteriores do mesmo e-mail para limpar)
        CodigoRecuperacao.objects.filter(email=email).delete()
        CodigoRecuperacao.objects.create(email=email, codigo=codigo)

        try:
            send_mail(
                subject='Código de Recuperação de Senha — SIGR UFSM',
                message=(
                    f'Olá!\n\n'
                    f'Seu código de recuperação de senha é: {codigo}\n\n'
                    f'Este código é válido por 1 minuto. Caso não tenha solicitado a recuperação, ignore este e-mail.\n\n'
                    f'— Equipe SIGR UFSM'
                ),
                from_email=django_settings.DEFAULT_FROM_EMAIL,
                recipient_list=[email],
                fail_silently=False,
            )
        except Exception:  # pylint: disable=broad-exception-caught
            return Response(
                {'erro': 'Não foi possível enviar o e-mail. Tente novamente em instantes.'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

        return Response({'mensagem': 'Código enviado com sucesso!'})


class ValidarCodigoRecuperacaoView(APIView):
    """
    Valida se o código informado é correto e se ainda não expirou (1 minuto).
    """
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email')
        codigo = request.data.get('codigo')

        if not email or not codigo:
            return Response({'erro': 'E-mail e código são obrigatórios.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            registro = CodigoRecuperacao.objects.get(email=email, codigo=codigo)
            
            # Verifica expiração (1 minuto)
            agora = timezone.now()
            if agora > registro.criado_em + timedelta(minutes=1):
                registro.delete()
                return Response({'erro': 'Este código expirou.'}, status=status.HTTP_400_BAD_REQUEST)
            
            return Response({'mensagem': 'Código validado com sucesso!'})
            
        except CodigoRecuperacao.DoesNotExist:
            return Response({'erro': 'Código inválido.'}, status=status.HTTP_400_BAD_REQUEST)


class RedefinirSenhaView(APIView):
    """
    Realiza a troca de senha após a validação do código de recuperação.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email')
        codigo = request.data.get('codigo')
        nova_senha = request.data.get('nova_senha')
        confirmacao = request.data.get('confirmacao_senha')

        if not all([email, codigo, nova_senha, confirmacao]):
            return Response({'erro': 'Todos os campos são obrigatórios.'}, status=status.HTTP_400_BAD_REQUEST)

        if nova_senha != confirmacao:
            return Response({'erro': 'As senhas não coincidem.'}, status=status.HTTP_400_BAD_REQUEST)

        if len(nova_senha) < 8:
            return Response({'erro': 'A senha deve ter pelo menos 8 caracteres.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            # Valida o código uma última vez por segurança
            registro = CodigoRecuperacao.objects.get(email=email, codigo=codigo)
            
            # Verifica expiração (1 minuto)
            agora = timezone.now()
            if agora > registro.criado_em + timedelta(minutes=1):
                registro.delete()
                return Response({'erro': 'O tempo para redefinir a senha expirou.'}, status=status.HTTP_400_BAD_REQUEST)
            
            # Atualiza a senha do usuário
            usuario = Usuario.objects.get(email=email)
            usuario.set_password(nova_senha)
            usuario.save()
            
            # Remove o código usado
            registro.delete()
            
            return Response({'mensagem': 'Senha redefinida com sucesso!'})
            
        except (CodigoRecuperacao.DoesNotExist, Usuario.DoesNotExist):
            return Response({'erro': 'Dados inválidos ou sessão expirada.'}, status=status.HTTP_400_BAD_REQUEST)


class UnidadeOrganizacionalViewSet(viewsets.ModelViewSet):
    """
    CRUD completo de Setores da UFSM.
    Inclui gestão de equipe (membros).
    """
    queryset = UnidadeOrganizacional.objects.filter(ativo=True).order_by("sigla_centro", "nome")
    serializer_class = UnidadeOrganizacionalSerializer
    permission_classes = [AllowAny] # Aberto para cadastro
    pagination_class = None

    def partial_update(self, request, *args, **kwargs):
        if not _usuario_eh_superusuario(request.user):
            return Response(
                {'erro': 'Apenas administradores podem editar unidades.'},
                status=status.HTTP_403_FORBIDDEN,
            )
        try:
            unidade = UnidadeOrganizacional.objects.get(pk=kwargs.get('pk'))
        except UnidadeOrganizacional.DoesNotExist:
            return Response({'erro': 'Unidade não encontrada.'}, status=status.HTTP_404_NOT_FOUND)

        serializador = UnidadeOrganizacionalSerializer(unidade, data=request.data, partial=True)
        serializador.is_valid(raise_exception=True)
        serializador.save()
        return Response(serializador.data)

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated], url_path='desativar')
    def desativar(self, request, pk=None):
        """Desativa ou reativa uma unidade organizacional."""
        if not _usuario_eh_superusuario(request.user):
            return Response(
                {'erro': 'Apenas administradores podem desativar unidades.'},
                status=status.HTTP_403_FORBIDDEN,
            )
        try:
            unidade = UnidadeOrganizacional.objects.get(pk=pk)
        except UnidadeOrganizacional.DoesNotExist:
            return Response({'erro': 'Unidade não encontrada.'}, status=status.HTTP_404_NOT_FOUND)

        unidade.ativo = not unidade.ativo
        unidade.save(update_fields=['ativo'])
        estado = 'reativada' if unidade.ativo else 'desativada'
        return Response({'mensagem': f'Unidade {estado} com sucesso.', 'ativo': unidade.ativo})

    @action(detail=False, methods=['get'], permission_classes=[IsAuthenticated], url_path='admin')
    def listar_admin(self, request):
        """Retorna a lista completa de unidades para administradores do sistema."""
        if not _usuario_eh_superusuario(request.user):
            return Response(
                {'erro': 'Apenas administradores do sistema podem visualizar esta tela.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        base_qs = self.get_queryset()
        queryset = base_qs.order_by("sigla_centro", "tipo_unidade", "nome")
        termo = request.query_params.get("search", "").strip()
        centro = request.query_params.get("centro", "").strip()
        tipo = request.query_params.get("tipo", "").strip()
        page_size = max(_query_int(request, "page_size", 20), 1)

        if termo:
            queryset = queryset.filter(
                Q(nome__icontains=termo)
                | Q(sigla_centro__icontains=termo)
                | Q(nome_centro__icontains=termo)
                | Q(tipo_unidade__icontains=termo)
            )
        if centro:
            queryset = queryset.filter(sigla_centro=centro)
        if tipo:
            queryset = queryset.filter(tipo_unidade=tipo)

        paginador = PageNumberPagination()
        paginador.page_size = page_size
        pagina = paginador.paginate_queryset(queryset, request, view=self)
        serializador = self.get_serializer(pagina, many=True)
        return Response({
            "count": paginador.page.paginator.count,
            "page": paginador.page.number,
            "page_size": page_size,
            "total_pages": paginador.page.paginator.num_pages,
            "centros": list(
                base_qs.exclude(sigla_centro="")
                .values_list("sigla_centro", flat=True)
                .distinct()
                .order_by("sigla_centro")
            ),
            "tipos": list(
                base_qs.exclude(tipo_unidade="")
                .values_list("tipo_unidade", flat=True)
                .distinct()
                .order_by("tipo_unidade")
            ),
            "results": serializador.data,
        })

    @action(detail=True, methods=['get'], permission_classes=[IsAuthenticated])
    def membros(self, request, pk=None):
        """Retorna a lista de gestores vinculados a esta unidade."""
        setor = self.get_object()
        usuarios = setor.usuarios.all()
        serializador = UsuarioSerializer(usuarios, many=True)
        return Response(serializador.data)

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def remover_membro(self, request, pk=None):
        """Remove o vínculo de um gestor com esta unidade. Requer cargo gestor_adm ou superusuário."""
        if not (_usuario_eh_superusuario(request.user) or getattr(request.user, 'cargo', '') == 'gestor_adm'):
            return Response(
                {'erro': 'Apenas Gestores Administradores podem remover membros da equipe.'},
                status=status.HTTP_403_FORBIDDEN,
            )
        setor = self.get_object()
        usuario_id = request.data.get('usuario_id')

        try:
            usuario = Usuario.objects.get(id=usuario_id)
            if setor in usuario.setores.all():
                usuario.setores.remove(setor)
                if not usuario.setores.exists():
                    usuario.sem_equipe_desde = timezone.now()
                    usuario.save(update_fields=['sem_equipe_desde'])
                return Response({'mensagem': 'Membro removido da equipe com sucesso.'})
            return Response({'erro': 'Usuário não pertence a esta unidade.'}, status=status.HTTP_400_BAD_REQUEST)
        except Usuario.DoesNotExist:
            return Response({'erro': 'Usuário não encontrado.'}, status=status.HTTP_404_NOT_FOUND)

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def adicionar_membro(self, request, pk=None):
        """Adiciona um usuário (existente pelo SIAPE) a esta unidade. Requer cargo gestor_adm ou superusuário."""
        if not (_usuario_eh_superusuario(request.user) or getattr(request.user, 'cargo', '') == 'gestor_adm'):
            return Response(
                {'erro': 'Apenas Gestores Administradores podem adicionar membros à equipe.'},
                status=status.HTTP_403_FORBIDDEN,
            )
        setor = self.get_object()
        siape = request.data.get('siape')

        if not siape:
            return Response({'erro': 'O SIAPE é obrigatório.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            usuario = Usuario.objects.get(siape=siape)
            if setor in usuario.setores.all():
                return Response({'erro': 'Este usuário já faz parte desta unidade.'}, status=status.HTTP_400_BAD_REQUEST)

            usuario.setores.add(setor)
            if usuario.sem_equipe_desde is not None:
                usuario.sem_equipe_desde = None
                usuario.save(update_fields=['sem_equipe_desde'])
            return Response({
                'mensagem': 'Membro adicionado com sucesso!',
                'usuario': UsuarioSerializer(usuario).data
            })
        except Usuario.DoesNotExist:
            return Response({'erro': 'Usuário com este SIAPE não encontrado.'}, status=status.HTTP_404_NOT_FOUND)


class RegistroUsuarioView(generics.CreateAPIView):
    """
    Cria um novo usuário gestor. Restrito a superusuários.
    """
    queryset = Usuario.objects.all()
    serializer_class = RegistroUsuarioSerializer
    permission_classes = [IsAuthenticated]

    def create(self, request, *args, **kwargs):
        if not _usuario_eh_superusuario(request.user):
            return Response(
                {'erro': 'Apenas administradores podem criar novos usuários.'},
                status=status.HTTP_403_FORBIDDEN,
            )
        serializador = self.get_serializer(data=request.data)
        serializador.is_valid(raise_exception=True)
        usuario = serializador.save()
        return Response(
            {'usuario': UsuarioSerializer(usuario).data},
            status=status.HTTP_201_CREATED,
        )


class LoginView(APIView):
    """
    Endpoint de Login 100% em português. Recebe 'siape' e 'senha'.
    Retorna o Token de acesso e dados básicos do usuário.
    """
    permission_classes = [AllowAny]

    def post(self, request, *args, **kwargs):
        siape = request.data.get('siape')
        senha = request.data.get('senha')

        # Autentica usando o backend do Django, mapeando username para siape
        usuario = authenticate(request, username=siape, password=senha)
        
        if usuario is not None:
            token, _ = Token.objects.get_or_create(user=usuario)
            return Response({
                'token': token.key,
                'usuario': UsuarioSerializer(usuario).data
            })
        return Response(
            {'erro': 'SIAPE ou senha inválidos.'},
            status=status.HTTP_400_BAD_REQUEST
        )


class UsuarioLogadoView(APIView):
    """
    Gerencia os dados do próprio usuário (Leitura e Atualização).
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        """Retorna os dados do usuário autenticado."""
        serializador = UsuarioSerializer(request.user)
        return Response(serializador.data)

    def patch(self, request):
        """Atualiza parcialmente os dados do usuário (senha, e-mail e unidades)."""
        serializador = AtualizarPerfilSerializer(
            instance=request.user, 
            data=request.data, 
            partial=True
        )
        serializador.is_valid(raise_exception=True)
        serializador.save()
        
        # Retorna os dados atualizados usando o serializador de exibição
        return Response({
            "mensagem": "Perfil atualizado com sucesso!",
            "usuario": UsuarioSerializer(request.user).data
        })


SetorViewSet = UnidadeOrganizacionalViewSet


class UsuarioViewSet(viewsets.GenericViewSet):
    """
    Gestão administrativa de usuários (superusuário only).
    GET  /api/usuarios/gestores/                   — lista todos os usuários
    DELETE /api/usuarios/gestores/<uuid>/          — desativa (soft delete)
    POST /api/usuarios/gestores/<uuid>/reativar/   — reativa
    """
    serializer_class = UsuarioSerializer
    permission_classes = [IsAuthenticated]
    lookup_field = 'uuid'

    def get_queryset(self):
        qs = Usuario.objects.all().prefetch_related('setores').order_by('nome')
        search = self.request.query_params.get('search', '').strip()
        if search:
            qs = qs.filter(
                Q(siape__icontains=search)
                | Q(nome__icontains=search)
                | Q(email__icontains=search)
            )
        return qs

    def list(self, request):
        if not _usuario_eh_superusuario(request.user):
            return Response(
                {'erro': 'Apenas administradores podem acessar esta listagem.'},
                status=status.HTTP_403_FORBIDDEN,
            )
        page_size = max(_query_int(request, 'page_size', 20), 1)
        paginador = PageNumberPagination()
        paginador.page_size = page_size
        pagina = paginador.paginate_queryset(self.get_queryset(), request)
        serializador = self.get_serializer(pagina, many=True)
        return Response({
            'count': paginador.page.paginator.count,
            'page': paginador.page.number,
            'total_pages': paginador.page.paginator.num_pages,
            'results': serializador.data,
        })

    def destroy(self, request, *args, **kwargs):
        if not _usuario_eh_superusuario(request.user):
            return Response(
                {'erro': 'Apenas administradores podem desativar usuários.'},
                status=status.HTTP_403_FORBIDDEN,
            )
        try:
            usuario = Usuario.objects.get(uuid=kwargs.get('uuid'))
        except Usuario.DoesNotExist:
            return Response({'erro': 'Usuário não encontrado.'}, status=status.HTTP_404_NOT_FOUND)

        if usuario.is_superuser:
            return Response(
                {'erro': 'Não é possível desativar um superusuário.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if usuario.pk == request.user.pk:
            return Response(
                {'erro': 'Você não pode desativar sua própria conta.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        usuario.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

    def partial_update(self, request, *args, **kwargs):
        if not _usuario_eh_superusuario(request.user):
            return Response(
                {'erro': 'Apenas administradores podem editar usuários.'},
                status=status.HTTP_403_FORBIDDEN,
            )
        try:
            usuario = Usuario.objects.get(uuid=kwargs.get('uuid'))
        except Usuario.DoesNotExist:
            return Response({'erro': 'Usuário não encontrado.'}, status=status.HTTP_404_NOT_FOUND)

        serializador = AdminEditarUsuarioSerializer(usuario, data=request.data, partial=True)
        serializador.is_valid(raise_exception=True)
        serializador.save()
        return Response({'usuario': UsuarioSerializer(usuario).data})

    @action(detail=True, methods=['post'])
    def reativar(self, request, *args, **kwargs):
        if not _usuario_eh_superusuario(request.user):
            return Response(
                {'erro': 'Apenas administradores podem reativar usuários.'},
                status=status.HTTP_403_FORBIDDEN,
            )
        try:
            usuario = Usuario.objects.get(uuid=kwargs.get('uuid'))
        except Usuario.DoesNotExist:
            return Response({'erro': 'Usuário não encontrado.'}, status=status.HTTP_404_NOT_FOUND)

        usuario.ativo = True
        usuario.save(update_fields=['ativo'])
        return Response({'usuario': UsuarioSerializer(usuario).data})
