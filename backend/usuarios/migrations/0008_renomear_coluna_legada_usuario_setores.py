from django.db import migrations


def renomear_coluna_legada_usuario_setores(apps, schema_editor):
    with schema_editor.connection.cursor() as cursor:
        cursor.execute(
            """
            SELECT column_name
            FROM information_schema.columns
            WHERE table_name = 'usuario_setores'
            """
        )
        colunas = {row[0] for row in cursor.fetchall()}

        if "unidadeorganizacional_id" in colunas and "setor_id" not in colunas:
            cursor.execute(
                'ALTER TABLE "usuario_setores" RENAME COLUMN "unidadeorganizacional_id" TO "setor_id"'
            )


def desfazer_renomeacao_coluna_legada_usuario_setores(apps, schema_editor):
    with schema_editor.connection.cursor() as cursor:
        cursor.execute(
            """
            SELECT column_name
            FROM information_schema.columns
            WHERE table_name = 'usuario_setores'
            """
        )
        colunas = {row[0] for row in cursor.fetchall()}

        if "setor_id" in colunas and "unidadeorganizacional_id" not in colunas:
            cursor.execute(
                'ALTER TABLE "usuario_setores" RENAME COLUMN "setor_id" TO "unidadeorganizacional_id"'
            )


class Migration(migrations.Migration):

    dependencies = [
        ("usuarios", "0007_alter_setor_options_alter_usuario_setores"),
    ]

    operations = [
        migrations.RunPython(
            renomear_coluna_legada_usuario_setores,
            reverse_code=desfazer_renomeacao_coluna_legada_usuario_setores,
        ),
    ]
