from pathlib import Path

import pytest

from usuarios.importacao_unidades import caminho_padrao_unidades, importar_unidades_csv
from usuarios.models import Setor

CSV_VALIDO = """COD_ESTRUTURADO,NOME_UNIDADE,NOME_CENTRO,SIGLA_CENTRO,TIPO_UNIDADE,SITUACAO
01,Departamento de Teste,Centro de Testes,CT,Departamento Didatico,Formal
"""


CSV_INCOMPLETO = """COD_ESTRUTURADO,NOME_UNIDADE,NOME_CENTRO,SIGLA_CENTRO,SITUACAO
01,Departamento de Teste,Centro de Testes,CT,Formal
"""


@pytest.mark.django_db
class TestImportacaoUnidades:
    def test_retorna_caminho_padrao_csv(self):
        # este teste confere o local padrao esperado para o csv oficial
        caminho = caminho_padrao_unidades()

        assert isinstance(caminho, Path)
        assert caminho.name == "unidades_ufsm.csv"

    def test_falha_quando_csv_nao_existe(self, tmp_path):
        # um caminho inexistente deve gerar erro explicito
        caminho_inexistente = tmp_path / "nao_existe.csv"

        with pytest.raises(FileNotFoundError):
            importar_unidades_csv(Setor, caminho_csv=caminho_inexistente)

    def test_falha_quando_campos_obrigatorios_ausentes(self, tmp_path):
        # o modulo deve recusar csv sem o cabecalho minimo necessario
        caminho_csv = tmp_path / "invalido.csv"
        caminho_csv.write_text(CSV_INCOMPLETO, encoding="utf-8")

        with pytest.raises(ValueError, match="CSV invalido. Campos obrigatorios ausentes"):
            importar_unidades_csv(Setor, caminho_csv=caminho_csv)

    def test_ignora_linha_com_dados_incompletos(self, tmp_path):
        # linhas incompletas nao devem gerar registros invalidos
        caminho_csv = tmp_path / "incompleto.csv"
        caminho_csv.write_text(
            """COD_ESTRUTURADO,NOME_UNIDADE,NOME_CENTRO,SIGLA_CENTRO,TIPO_UNIDADE,SITUACAO
01,Departamento de Teste,Centro de Testes,CT,Departamento Didatico,Formal
02,,Centro de Testes,CT,Departamento Didatico,Formal
""",
            encoding="utf-8",
        )

        resultado = importar_unidades_csv(Setor, caminho_csv=caminho_csv)

        assert resultado["criados"] == 1
        assert Setor.objects.filter(nome="Departamento de Teste", sigla_centro="CT").count() == 1

    def test_atualiza_dados_de_unidade_existente(self, tmp_path):
        # se a unidade ja existe, a importacao deve corrigir os campos relevantes
        Setor.objects.create(
            nome="Departamento de Teste",
            sigla="LEG",
            sigla_centro="CT",
            nome_centro="Centro Antigo",
            tipo_unidade="Departamento Didatico",
            fonte_oficial=False,
            ativo=False,
        )
        caminho_csv = tmp_path / "valido.csv"
        caminho_csv.write_text(CSV_VALIDO, encoding="utf-8")

        resultado = importar_unidades_csv(Setor, caminho_csv=caminho_csv)
        setor = Setor.objects.get(nome="Departamento de Teste", sigla_centro="CT")

        assert resultado["criados"] == 0
        assert resultado["atualizados"] == 1
        assert setor.sigla == "CT"
        assert setor.nome_centro == "Centro de Testes"
        assert setor.fonte_oficial is True
        assert setor.ativo is True
