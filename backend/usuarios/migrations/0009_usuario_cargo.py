from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('usuarios', '0008_renomear_coluna_legada_usuario_setores'),
    ]

    operations = [
        migrations.AddField(
            model_name='usuario',
            name='cargo',
            field=models.CharField(
                choices=[('gestor', 'Gestor'), ('gestor_adm', 'Gestor Administrador')],
                db_column='cargo',
                default='gestor',
                max_length=20,
                verbose_name='Cargo',
            ),
        ),
    ]
