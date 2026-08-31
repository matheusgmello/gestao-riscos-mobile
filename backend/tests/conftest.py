import pytest
from rest_framework.test import APIClient

from riscos.models import (
    DesafioPDI,
    Macroprocesso,
    Monitoramento,
    ObjetivoPDI,
    PlanoAcao,
    Risco,
)
from usuarios.models import Setor, Usuario


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def setor_oficial(db):
    return Setor.objects.create(
        nome="Departamento de Computacao Aplicada",
        sigla="CT",
        sigla_centro="CT",
        nome_centro="Centro de Tecnologia",
        tipo_unidade="Departamento Didatico",
        fonte_oficial=True,
        ativo=True,
    )


@pytest.fixture
def setor_secundario(db):
    return Setor.objects.create(
        nome="Centro de Ciencias Rurais",
        sigla="CCR",
        sigla_centro="CCR",
        nome_centro="Centro de Ciencias Rurais",
        tipo_unidade="Unidade de Ensino",
        fonte_oficial=True,
        ativo=True,
    )


@pytest.fixture
def usuario_gestor(db, setor_oficial):
    usuario = Usuario.objects.create_user(
        siape="1111111",
        password="senha_original",
        nome="Gestor Principal",
        email="gestor@ufsm.br",
    )
    usuario.setores.add(setor_oficial)
    return usuario


@pytest.fixture
def usuario_superuser(db, setor_oficial):
    usuario = Usuario.objects.create_superuser(
        siape="9999999",
        password="senha_admin",
        nome="Admin Sistema",
        email="admin@ufsm.br",
    )
    usuario.setores.add(setor_oficial)
    return usuario


@pytest.fixture
def usuario_outro_setor(db, setor_secundario):
    usuario = Usuario.objects.create_user(
        siape="2222222",
        password="senha_outro",
        nome="Gestor Secundario",
        email="outro@ufsm.br",
    )
    usuario.setores.add(setor_secundario)
    return usuario


@pytest.fixture
def desafio_padrao(db):
    return DesafioPDI.objects.create(numero=999, descricao="Desafio de Teste")


@pytest.fixture
def objetivo_padrao(db, desafio_padrao):
    return ObjetivoPDI.objects.create(
        codigo="OBJ-TESTE-001",
        descricao="Objetivo de Teste",
        desafio=desafio_padrao,
    )


@pytest.fixture
def macroprocesso_padrao(db):
    return Macroprocesso.objects.create(nome="Macroprocesso de Teste")


@pytest.fixture
def risco_basico(db, setor_oficial, objetivo_padrao, macroprocesso_padrao):
    return Risco.objects.create(
        setor=setor_oficial,
        objetivo=objetivo_padrao,
        macroprocesso=macroprocesso_padrao,
        categoria="Operacional",
        evento="Evento de teste",
        causa="Causa de teste",
        consequencia="Consequencia de teste",
        controles_atuais="Controle existente",
        eficacia_controle="Fraco",
        probabilidade=3,
        impacto=4,
        prob_residual=2,
        imp_residual=3,
    )


@pytest.fixture
def risco_com_plano(db, risco_basico):
    PlanoAcao.objects.create(
        risco=risco_basico,
        tipo_resposta="Mitigar",
        descricao_acao="Executar plano de mitigacao",
        responsavel="Gestor responsavel",
        parceiros="Equipe de apoio",
        data_inicio="2026-01-10",
        data_fim="2026-03-10",
        status="Em andamento",
        observacoes="Observacao de teste",
    )
    return risco_basico


@pytest.fixture
def risco_com_monitoramento(db, risco_com_plano):
    Monitoramento.objects.create(
        risco=risco_com_plano,
        resultados="Resultados iniciais",
        acoes_futuras="Proximas acoes",
        analise_critica="Analise critica",
    )
    return risco_com_plano
