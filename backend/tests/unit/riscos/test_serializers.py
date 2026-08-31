import pytest

from riscos.serializers import MonitoramentoSerializer, PlanoAcaoSerializer, RiscoSerializer


@pytest.mark.django_db
class TestRiscoSerializer:
    def test_serializa_detalhes_relacionados_do_risco(self, risco_basico):
        # este teste garante que os dados detalhados sao expostos no serializer
        serializer = RiscoSerializer(instance=risco_basico)
        dados = serializer.data

        assert dados["uuid"] == str(risco_basico.uuid)
        assert dados["nivel_risco"] == risco_basico.nivel_risco
        assert dados["nivel_residual"] == risco_basico.nivel_residual
        assert dados["setor_detalhes"]["label_curto"] == risco_basico.setor.label_curto
        assert dados["objetivo_detalhes"]["codigo"] == risco_basico.objetivo.codigo
        assert dados["macroprocesso_detalhes"]["nome"] == risco_basico.macroprocesso.nome

    def test_cria_risco_com_dados_validos(self, setor_oficial, objetivo_padrao, macroprocesso_padrao):
        # a validacao deve aceitar um payload completo e coerente
        serializer = RiscoSerializer(
            data={
                "setor": setor_oficial.id,
                "objetivo": objetivo_padrao.id,
                "macroprocesso": macroprocesso_padrao.id,
                "categoria": "Operacional",
                "evento": "Evento serializer",
                "causa": "Causa serializer",
                "consequencia": "Consequencia serializer",
                "controles_atuais": "Controle serializer",
                "eficacia_controle": "Fraco",
                "probabilidade": 2,
                "impacto": 5,
                "prob_residual": 1,
                "imp_residual": 3,
            }
        )

        assert serializer.is_valid(), serializer.errors

        risco = serializer.save()

        assert risco.nivel_risco == 10
        assert risco.nivel_residual == 3

    def test_rejeita_categoria_invalida(self, setor_oficial, objetivo_padrao, macroprocesso_padrao):
        # o serializer deve bloquear opcoes fora das escolhas do model
        serializer = RiscoSerializer(
            data={
                "setor": setor_oficial.id,
                "objetivo": objetivo_padrao.id,
                "macroprocesso": macroprocesso_padrao.id,
                "categoria": "Categoria Invalida",
                "evento": "Evento invalido",
                "causa": "Causa invalida",
                "consequencia": "Consequencia invalida",
                "controles_atuais": "Controle",
                "eficacia_controle": "Fraco",
                "probabilidade": 2,
                "impacto": 2,
                "prob_residual": 1,
                "imp_residual": 1,
            }
        )

        assert serializer.is_valid() is False
        assert "categoria" in serializer.errors

    def test_rejeita_probabilidade_fora_do_intervalo(self, setor_oficial, objetivo_padrao, macroprocesso_padrao):
        # valores acima de 5 ou abaixo de 1 devem ser bloqueados pelo serializer
        for campo, valor_invalido in [
            ("probabilidade", 0),
            ("probabilidade", 6),
            ("impacto", -1),
            ("impacto", 10),
            ("prob_residual", 0),
            ("imp_residual", 99),
        ]:
            serializer = RiscoSerializer(
                data={
                    "setor": setor_oficial.id,
                    "objetivo": objetivo_padrao.id,
                    "macroprocesso": macroprocesso_padrao.id,
                    "categoria": "Operacional",
                    "evento": "Evento range",
                    "causa": "Causa",
                    "consequencia": "Consequencia",
                    "controles_atuais": "Controle",
                    "eficacia_controle": "Fraco",
                    "probabilidade": valor_invalido if campo == "probabilidade" else 3,
                    "impacto": valor_invalido if campo == "impacto" else 3,
                    "prob_residual": valor_invalido if campo == "prob_residual" else 2,
                    "imp_residual": valor_invalido if campo == "imp_residual" else 2,
                }
            )
            assert serializer.is_valid() is False, f"Deveria rejeitar {campo}={valor_invalido}"
            assert campo in serializer.errors, f"Erro esperado em '{campo}', obtido: {serializer.errors}"

    def test_rejeita_campo_obrigatorio_ausente(self, setor_oficial, objetivo_padrao):
        # aqui o payload deixa de fora o macroprocesso para validar erro de obrigatoriedade
        serializer = RiscoSerializer(
            data={
                "setor": setor_oficial.id,
                "objetivo": objetivo_padrao.id,
                "categoria": "Operacional",
                "evento": "Evento sem macro",
                "causa": "Causa sem macro",
                "consequencia": "Consequencia sem macro",
                "controles_atuais": "Controle",
                "eficacia_controle": "Fraco",
                "probabilidade": 1,
                "impacto": 1,
                "prob_residual": 1,
                "imp_residual": 1,
            }
        )

        assert serializer.is_valid() is False
        assert "macroprocesso" in serializer.errors


@pytest.mark.django_db
class TestPlanoAcaoSerializerUUID:
    def test_aceita_uuid_no_campo_risco(self, risco_basico):
        # o serializer deve aceitar uuid como identificador do risco vinculado
        serializer = PlanoAcaoSerializer(
            data={
                "risco": str(risco_basico.uuid),
                "tipo_resposta": "Mitigar",
                "descricao_acao": "Descricao",
                "responsavel": "Responsavel",
                "data_inicio": "2026-01-01",
                "data_fim": "2026-06-30",
                "status": "Não iniciada",
            }
        )
        assert serializer.is_valid(), serializer.errors
        acao = serializer.save()
        assert acao.risco_id == risco_basico.pk

    def test_rejeita_uuid_invalido(self, risco_basico):
        serializer = PlanoAcaoSerializer(
            data={
                "risco": "nao-e-um-uuid",
                "tipo_resposta": "Mitigar",
                "descricao_acao": "Descricao",
                "responsavel": "Responsavel",
                "data_inicio": "2026-01-01",
                "data_fim": "2026-06-30",
                "status": "Não iniciada",
            }
        )
        assert serializer.is_valid() is False
        assert "risco" in serializer.errors


@pytest.mark.django_db
class TestMonitoramentoSerializerUUID:
    def test_aceita_uuid_no_campo_risco(self, risco_basico):
        # o serializer deve aceitar uuid como identificador do risco vinculado
        serializer = MonitoramentoSerializer(
            data={
                "risco": str(risco_basico.uuid),
                "resultados": "Resultado",
                "acoes_futuras": "Acoes",
                "analise_critica": "Analise",
            }
        )
        assert serializer.is_valid(), serializer.errors
        monitoramento = serializer.save()
        assert monitoramento.risco_id == risco_basico.pk
