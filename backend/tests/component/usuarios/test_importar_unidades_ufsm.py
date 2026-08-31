import pytest
from django.core.management import call_command

from usuarios.models import Setor

# este csv sintetico representa o minimo necessario para validar a importacao
CSV_EXEMPLO = """COD_ESTRUTURADO,NOME_UNIDADE,NOME_CENTRO,SIGLA_CENTRO,TIPO_UNIDADE,SITUACAO
07.67.00.00.0.0,Departamento de Computacao Aplicada,Centro de Tecnologia,CT,Departamento Didatico,Formal
07.37.00.00.0.0,Departamento de Eletromecanica e Sistemas de Potencia,Centro de Tecnologia,CT,Departamento Didatico,Formal
"""


@pytest.mark.django_db
class TestImportarUnidadesUfsm:
    def test_importa_unidades_oficiais_com_labels(self, tmp_path):
        # o teste cria um arquivo temporario para simular a entrada do comando
        caminho_csv = tmp_path / "unidades.csv"
        caminho_csv.write_text(CSV_EXEMPLO, encoding="utf-8")

        # em seguida executa o comando de importacao usando esse arquivo
        call_command("importar_unidades_ufsm", arquivo=str(caminho_csv))

        # por fim consulta a unidade gerada e valida os campos principais
        setor = Setor.objects.get(
            nome="Departamento de Computacao Aplicada",
            sigla_centro="CT",
            tipo_unidade="Departamento Didatico",
        )
        assert setor.fonte_oficial is True
        assert setor.ativo is True
        assert setor.label_curto == "CT - Departamento de Computacao Aplicada"
        assert (
            setor.label_completo
            == "CT - Departamento de Computacao Aplicada - Centro de Tecnologia - Departamento Didatico"
        )

    def test_importacao_e_idempotente(self, tmp_path):
        # a preparacao e a mesma do teste anterior
        caminho_csv = tmp_path / "unidades.csv"
        caminho_csv.write_text(CSV_EXEMPLO, encoding="utf-8")

        # aqui o comando e executado duas vezes para verificar duplicacao indevida
        call_command("importar_unidades_ufsm", arquivo=str(caminho_csv))
        call_command("importar_unidades_ufsm", arquivo=str(caminho_csv))

        # a validacao confirma que a unidade aparece apenas uma vez
        assert (
            Setor.objects.filter(
                nome="Departamento de Computacao Aplicada",
                sigla_centro="CT",
                tipo_unidade="Departamento Didatico",
            ).count()
            == 1
        )

    def test_desativa_setores_legados_quando_solicitado(self, tmp_path):
        # primeiro cria o csv e um registro legado para servir de comparacao
        caminho_csv = tmp_path / "unidades.csv"
        caminho_csv.write_text(CSV_EXEMPLO, encoding="utf-8")

        legado = Setor.objects.create(nome="Legado", sigla="LEG")

        # aqui o comando e executado com a opcao de desativar registros antigos
        call_command(
            "importar_unidades_ufsm",
            arquivo=str(caminho_csv),
            desativar_legado=True,
        )

        # por fim o teste verifica se o setor legado foi marcado como inativo
        legado.refresh_from_db()
        assert legado.ativo is False
