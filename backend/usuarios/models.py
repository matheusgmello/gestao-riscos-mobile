import uuid as uuid_lib
from datetime import timedelta

from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.db import models
from django.utils import timezone


class Setor(models.Model):
    """
    Representa as unidades administrativas da UFSM.
    """
    nome = models.CharField(max_length=255, verbose_name="Nome do Setor", db_column="nome")
    sigla = models.CharField(max_length=255, verbose_name="Sigla", db_column="sigla")
    sigla_centro = models.CharField(
        max_length=20,
        verbose_name="Sigla do Centro",
        db_column="sigla_centro",
        blank=True,
        default="",
    )
    nome_centro = models.CharField(
        max_length=255,
        verbose_name="Nome do Centro",
        db_column="nome_centro",
        blank=True,
        default="",
    )
    tipo_unidade = models.CharField(
        max_length=100,
        verbose_name="Tipo da Unidade",
        db_column="tipo_unidade",
        blank=True,
        default="",
    )
    fonte_oficial = models.BooleanField(
        default=False,
        db_column="fonte_oficial",
        verbose_name="Importado de base oficial",
    )
    ativo = models.BooleanField(default=True, db_column="ativo")

    class Meta:
        db_table = "setores"
        verbose_name = "Unidade Organizacional"
        verbose_name_plural = "Unidades Organizacionais"
        ordering = ["sigla_centro", "nome"]
        constraints = [
            models.UniqueConstraint(
                fields=["nome", "sigla_centro", "tipo_unidade"],
                name="uniq_setor_nome_centro_tipo",
            )
        ]

    @property
    def label_curto(self):
        sigla_base = self.sigla_centro or self.sigla
        if sigla_base:
            return f"{sigla_base} - {self.nome}"
        return self.nome

    @property
    def label_completo(self):
        partes = [self.label_curto]
        if self.nome_centro:
            partes.append(self.nome_centro)
        if self.tipo_unidade:
            partes.append(self.tipo_unidade)
        return " - ".join(partes)

    def __str__(self):
        return self.label_curto


class GerenciadorUsuario(BaseUserManager):
    """
    Gerenciador customizado para o modelo Usuario que usa o 'siape' em vez de 'username'.
    """
    def create_user(self, siape, password=None, **campos_extras):
        if not siape:
            raise ValueError('O SIAPE é obrigatório.')
        usuario = self.model(siape=siape, **campos_extras)
        usuario.set_password(password)
        usuario.save(using=self._db)
        return usuario

    def create_superuser(self, siape, password=None, **campos_extras):
        campos_extras.setdefault('equipe', True)
        campos_extras.setdefault('is_superuser', True)

        if campos_extras.get('equipe') is not True:
            raise ValueError('Superusuario deve ter equipe=True.')
        if campos_extras.get('is_superuser') is not True:
            raise ValueError('Superusuario deve ter is_superuser=True.')

        return self.create_user(siape, password, **campos_extras)


class Usuario(AbstractBaseUser, PermissionsMixin):
    """
    Modelo customizado de usuário para gestores da UFSM.
    Focado em SIAPE, Nome Completo, E-mail e múltiplos Setores.
    """
    uuid = models.UUIDField(default=uuid_lib.uuid4, unique=True, editable=False, db_column='uuid')

    CARGO_CHOICES = [
        ('gestor', 'Gestor'),
        ('gestor_adm', 'Gestor Administrador'),
    ]

    siape = models.CharField(
        max_length=20, unique=True, verbose_name="Matrícula SIAPE", db_column="siape"
    )
    nome = models.CharField(max_length=255, verbose_name="Nome Completo", db_column="nome")
    email = models.EmailField(
        verbose_name="E-mail", unique=True, db_column="email", null=True, blank=True
    )
    cargo = models.CharField(
        max_length=20,
        choices=CARGO_CHOICES,
        default='gestor',
        db_column='cargo',
        verbose_name='Cargo',
    )
    setores = models.ManyToManyField(
        Setor,
        related_name="usuarios",
        blank=True,
        verbose_name="Unidades do Usuário",
        db_table="usuario_setores",
    )
    ativo = models.BooleanField(default=True, db_column="ativo")
    equipe = models.BooleanField(default=False, db_column="equipe")
    sem_equipe_desde = models.DateTimeField(null=True, blank=True, db_column="sem_equipe_desde")

    objects = GerenciadorUsuario()

    USERNAME_FIELD = 'siape'
    REQUIRED_FIELDS = ['nome']

    @property
    def is_staff(self):
        return self.equipe

    @property
    def is_active(self):
        if not self.ativo:
            return False
        if not self.is_superuser and self.sem_equipe_desde is not None:
            if timezone.now() - self.sem_equipe_desde > timedelta(days=7):
                return False
        return True

    class Meta:
        db_table = "usuarios"
        verbose_name = "Usuário"
        verbose_name_plural = "Usuários"

    def delete(self, *args, **kwargs):
        self.ativo = False
        self.save(update_fields=['ativo'])

    def __str__(self):
        return f"{self.siape} - {self.nome}"


class CodigoRecuperacao(models.Model):
    email = models.EmailField(db_column="email")
    codigo = models.CharField(max_length=6, db_column="codigo")
    criado_em = models.DateTimeField(auto_now_add=True, db_column="criado_em")

    class Meta:
        db_table = "codigos_recuperacao"
        verbose_name = "Código de Recuperação"
        verbose_name_plural = "Códigos de Recuperação"


# Alias público para o modelo Setor.
# Internamente (migrations, tabela DB, FKs), o modelo se chama "Setor" e a tabela
# é "setores" — renomear exigiria uma migration de dados.
# Conceitualmente, cada registro representa uma UnidadeOrganizacional oficial da UFSM
# (importada de base oficial via manage.py importar_unidades_ufsm).
# Use "UnidadeOrganizacional" no código novo; "Setor" existe apenas por compatibilidade.
UnidadeOrganizacional = Setor
