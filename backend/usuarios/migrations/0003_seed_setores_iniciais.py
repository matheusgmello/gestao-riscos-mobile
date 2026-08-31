from django.db import migrations

SETORES_INICIAIS = [
    "CAL",
    "CCR",
    "CCS",
    "CCNE",
    "CCSH",
    "CE",
    "CEFD",
    "CT",
    "CTISM",
    "Politecnico",
]


def criar_setores_iniciais(apps, schema_editor):
    Setor = apps.get_model("usuarios", "Setor")

    for sigla in SETORES_INICIAIS:
        Setor.objects.get_or_create(
            sigla=sigla,
            defaults={"nome": sigla},
        )


def remover_setores_iniciais(apps, schema_editor):
    Setor = apps.get_model("usuarios", "Setor")
    Setor.objects.filter(sigla__in=SETORES_INICIAIS, nome__in=SETORES_INICIAIS).delete()


class Migration(migrations.Migration):

    dependencies = [
        ("usuarios", "0002_codigorecuperacao"),
    ]

    operations = [
        migrations.RunPython(criar_setores_iniciais, remover_setores_iniciais),
    ]
