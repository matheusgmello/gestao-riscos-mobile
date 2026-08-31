import csv
from pathlib import Path

from django.db import migrations


def popular_unidades_oficiais(apps, schema_editor):
    Setor = apps.get_model("usuarios", "Setor")
    caminho_csv = Path(__file__).resolve().parents[1] / "data" / "unidades_ufsm.csv"

    for setor in Setor.objects.all():
        setor.sigla_centro = setor.sigla or ""
        setor.nome_centro = setor.nome or ""
        setor.tipo_unidade = "Legado"
        setor.fonte_oficial = False
        setor.ativo = False
        setor.save(
            update_fields=[
                "sigla_centro",
                "nome_centro",
                "tipo_unidade",
                "fonte_oficial",
                "ativo",
            ]
        )

    with caminho_csv.open("r", encoding="utf-8-sig", newline="") as arquivo:
        leitor = csv.DictReader(arquivo)
        for linha in leitor:
            nome = (linha.get("NOME_UNIDADE") or "").strip()
            nome_centro = (linha.get("NOME_CENTRO") or "").strip()
            sigla_centro = (linha.get("SIGLA_CENTRO") or "").strip()
            tipo_unidade = (linha.get("TIPO_UNIDADE") or "").strip()

            if not all([nome, nome_centro, sigla_centro, tipo_unidade]):
                continue

            setor, criado = Setor.objects.get_or_create(
                nome=nome,
                sigla_centro=sigla_centro,
                tipo_unidade=tipo_unidade,
                defaults={
                    "sigla": sigla_centro,
                    "nome_centro": nome_centro,
                    "fonte_oficial": True,
                    "ativo": True,
                },
            )

            if not criado:
                setor.sigla = sigla_centro
                setor.nome_centro = nome_centro
                setor.fonte_oficial = True
                setor.ativo = True
                setor.save(
                    update_fields=[
                        "sigla",
                        "nome_centro",
                        "fonte_oficial",
                        "ativo",
                    ]
                )


def reverter_unidades_oficiais(apps, schema_editor):
    Setor = apps.get_model("usuarios", "Setor")
    Setor.objects.filter(fonte_oficial=True).delete()
    Setor.objects.filter(tipo_unidade="Legado").update(ativo=True)


class Migration(migrations.Migration):

    dependencies = [
        ("usuarios", "0004_alter_setor_options_setor_ativo_setor_fonte_oficial_and_more"),
    ]

    operations = [
        migrations.RunPython(popular_unidades_oficiais, reverter_unidades_oficiais),
    ]
