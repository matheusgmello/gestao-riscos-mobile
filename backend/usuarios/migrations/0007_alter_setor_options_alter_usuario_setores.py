from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("usuarios", "0006_usuariosetor_alter_unidadeorganizacional_options_and_more"),
    ]

    operations = [
        migrations.SeparateDatabaseAndState(
            state_operations=[
                migrations.AlterModelOptions(
                    name="setor",
                    options={
                        "ordering": ["sigla_centro", "nome"],
                        "verbose_name": "Unidade Organizacional",
                        "verbose_name_plural": "Unidades Organizacionais",
                    },
                ),
                migrations.AlterField(
                    model_name="usuario",
                    name="setores",
                    field=models.ManyToManyField(
                        blank=True,
                        db_table="usuario_setores",
                        related_name="usuarios",
                        to="usuarios.setor",
                        verbose_name="Unidades do Usuário",
                    ),
                ),
            ],
            database_operations=[],
        ),
    ]
