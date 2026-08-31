import pytest

from riscos.models import (
    DesafioPDI,
    Macroprocesso,
    Monitoramento,
    ObjetivoPDI,
    PlanoAcao,
    Risco,
)
from usuarios.models import Setor


@pytest.fixture
def infra_pdi(db):
    # este fixture prepara os objetos minimos exigidos para criacao de risco
    desafio = DesafioPDI.objects.create(numero=999, descricao="Desafio Teste")
    objetivo = ObjetivoPDI.objects.create(codigo="OBJ-TESTE-999", descricao="Objetivo Teste", desafio=desafio)
    macro = Macroprocesso.objects.create(nome="Processo Teste Exclusivo")
    setor = Setor.objects.create(nome="Setor Teste", sigla="ST")
    return {"desafio": desafio, "objetivo": objetivo, "macro": macro, "setor": setor}


@pytest.mark.django_db
class TestRiscoModel:
    def test_calculo_nivel_risco(self, infra_pdi):
        # o teste cria um risco com valores simples para demonstrar os calculos
        risco = Risco.objects.create(
            setor=infra_pdi['setor'],
            objetivo=infra_pdi['objetivo'],
            macroprocesso=infra_pdi['macro'],
            categoria="Operacional",
            evento="Evento X",
            causa="Causa Y",
            consequencia="Consequência Z",
            controles_atuais="Controle A",
            eficacia_controle="Satisfatório",
            probabilidade=4,
            impacto=5,
            prob_residual=2,
            imp_residual=3
        )

        # aqui sao verificados o nivel inerente e o nivel residual
        assert risco.nivel_risco == 20
        assert risco.nivel_residual == 6

        # estas validacoes adicionais conferem a representacao textual dos objetos
        assert str(risco) == f"Risco {risco.id} - ST - Setor Teste"
        assert str(infra_pdi['desafio']) == "999 - Desafio Teste"
        assert str(infra_pdi['macro']) == "Processo Teste Exclusivo"
        assert str(infra_pdi['objetivo']) == "OBJ-TESTE-999 - Objetivo Teste"


@pytest.mark.django_db
class TestPlanoAcaoModel:
    def test_criar_plano_acao(self, infra_pdi):
        # o primeiro passo e criar um risco que servira de base para o tratamento
        risco = Risco.objects.create(
            setor=infra_pdi['setor'],
            objetivo=infra_pdi['objetivo'],
            macroprocesso=infra_pdi['macro'],
            categoria="Operacional",
            evento="E", causa="C", consequencia="C", controles_atuais="C", eficacia_controle="Satisfatório",
            probabilidade=1, impacto=1, prob_residual=1, imp_residual=1
        )

        # em seguida o teste cria o plano de acao ligado a esse risco
        plano = PlanoAcao.objects.create(
            risco=risco,
            tipo_resposta="Mitigar",
            descricao_acao="Ação X",
            responsavel="Gestor",
            parceiros="P",
            data_inicio="2024-01-01",
            data_fim="2024-12-31",
            status="Não iniciada",
            observacoes="Obs"
        )

        # a validacao garante o vinculo correto entre plano e risco
        assert plano.risco == risco
        assert str(plano.risco.id) in str(plano.risco)


@pytest.mark.django_db
class TestMonitoramentoModel:
    def test_criar_monitoramento(self, infra_pdi):
        # assim como no teste anterior, o monitoramento depende de um risco previo
        risco = Risco.objects.create(
            setor=infra_pdi['setor'],
            objetivo=infra_pdi['objetivo'],
            macroprocesso=infra_pdi['macro'],
            categoria="Operacional",
            evento="E", causa="C", consequencia="C", controles_atuais="C", eficacia_controle="Satisfatório",
            probabilidade=1, impacto=1, prob_residual=1, imp_residual=1
        )

        # aqui e criada a etapa de acompanhamento do risco
        monitor = Monitoramento.objects.create(
            risco=risco,
            resultados="R",
            acoes_futuras="AF",
            analise_critica="AC"
        )

        # a ultima verificacao confirma o relacionamento esperado
        assert monitor.risco == risco
        assert str(monitor.risco.id) in str(monitor.risco)


@pytest.mark.django_db
class TestSoftDelete:
    def _risco(self, infra_pdi):
        return Risco.objects.create(
            setor=infra_pdi['setor'],
            objetivo=infra_pdi['objetivo'],
            macroprocesso=infra_pdi['macro'],
            categoria="Operacional",
            evento="E", causa="C", consequencia="C",
            controles_atuais="C", eficacia_controle="Satisfatório",
            probabilidade=2, impacto=2, prob_residual=1, imp_residual=1,
        )

    def test_soft_delete_risco_mantem_no_banco(self, infra_pdi):
        risco = self._risco(infra_pdi)
        risco_id = risco.id
        risco.delete()
        assert Risco.all_objects.filter(id=risco_id, ativo=False).exists()

    def test_soft_delete_risco_some_do_queryset_padrao(self, infra_pdi):
        risco = self._risco(infra_pdi)
        risco_id = risco.id
        risco.delete()
        assert not Risco.objects.filter(id=risco_id).exists()

    def test_soft_delete_risco_cascata_plano_acao(self, infra_pdi):
        risco = self._risco(infra_pdi)
        PlanoAcao.objects.create(
            risco=risco, tipo_resposta="Mitigar", descricao_acao="D",
            responsavel="R", data_inicio="2026-01-01", data_fim="2026-06-01",
            status="Em andamento",
        )
        risco.delete()
        assert not PlanoAcao.objects.filter(risco_id=risco.id).exists()
        assert PlanoAcao.all_objects.filter(risco_id=risco.id, ativo=False).exists()

    def test_soft_delete_risco_cascata_monitoramento(self, infra_pdi):
        risco = self._risco(infra_pdi)
        Monitoramento.objects.create(
            risco=risco, resultados="R", acoes_futuras="AF", analise_critica="AC",
        )
        risco.delete()
        assert not Monitoramento.objects.filter(risco_id=risco.id).exists()
        assert Monitoramento.all_objects.filter(risco_id=risco.id, ativo=False).exists()
