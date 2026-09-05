"""Categoria 4 — Regressão.

A migration 0008 nasceu de um drift entre models e migrations (o campo
`atualizado_em` e `AlterModelOptions` de `historicoplano` só existiam nos
models). Este teste garante que não há mais drift: `makemigrations --check`
tem que sair limpo.
"""

from io import StringIO

import pytest
from django.core.management import call_command


@pytest.mark.django_db
def test_sem_migracoes_pendentes():
    out = StringIO()
    try:
        call_command("makemigrations", "--check", "--dry-run", stdout=out, stderr=out)
    except SystemExit:  # --check sai com código != 0 se houver drift
        pytest.fail(
            "Models e migrations divergiram — rode `makemigrations`.\n" + out.getvalue()
        )
