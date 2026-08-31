from django.core.management.base import BaseCommand

from usuarios.models import Setor, Usuario
from usuarios.normalizacao_legado import (
    normalizar_riscos_legados,
    normalizar_vinculos_legados,
)


class Command(BaseCommand):
    help = (
        "Remapeia usuarios e riscos vinculados a setores legados para "
        "unidades oficiais equivalentes da UFSM."
    )

    def handle(self, *args, **options):
        resultado_usuarios = normalizar_vinculos_legados(Usuario, Setor)
        resultado_riscos = normalizar_riscos_legados(Setor)

        self.stdout.write(
            self.style.SUCCESS(
                "Normalizacao concluida com sucesso. "
                f"Usuarios atualizados: {resultado_usuarios['usuarios_atualizados']}. "
                f"Riscos atualizados: {resultado_riscos['riscos_atualizados']}. "
                f"Ignorados (usuarios): {resultado_usuarios['usuarios_ignorados']}. "
                f"Ignorados (riscos): {resultado_riscos['riscos_ignorados']}."
            )
        )
