from django.core.management.base import BaseCommand

from usuarios.importacao_unidades import importar_unidades_csv
from usuarios.models import Setor


class Command(BaseCommand):
    help = "Importa as unidades reais da UFSM a partir de um CSV oficial."

    def add_arguments(self, parser):
        parser.add_argument(
            "--arquivo",
            default=None,
            help="Caminho opcional para um CSV de unidades da UFSM.",
        )
        parser.add_argument(
            "--desativar-legado",
            action="store_true",
            help="Desativa setores legados que nao vierem da base oficial.",
        )

    def handle(self, *args, **options):
        resultado = importar_unidades_csv(
            setor_model=Setor,
            caminho_csv=options["arquivo"],
            desativar_legado=options["desativar_legado"],
        )

        self.stdout.write(
            self.style.SUCCESS(
                "Importacao concluida com sucesso. "
                f"Criados: {resultado['criados']}. "
                f"Atualizados: {resultado['atualizados']}. "
                f"Arquivo: {resultado['arquivo']}"
            )
        )
