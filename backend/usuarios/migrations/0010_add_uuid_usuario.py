import uuid

from django.db import migrations, models


def popular_uuids_usuario(apps, schema_editor):
    Usuario = apps.get_model('usuarios', 'Usuario')
    for usuario in Usuario.objects.all():
        usuario.uuid = uuid.uuid4()
        usuario.save(update_fields=['uuid'])


class Migration(migrations.Migration):

    dependencies = [
        ('usuarios', '0009_usuario_cargo'),
    ]

    operations = [
        # 1. Adiciona o campo sem restrição unique para não colidir nas linhas existentes
        migrations.AddField(
            model_name='usuario',
            name='uuid',
            field=models.UUIDField(db_column='uuid', default=uuid.uuid4, editable=False, null=True),
        ),
        # 2. Popula cada linha existente com um UUID único
        migrations.RunPython(popular_uuids_usuario, migrations.RunPython.noop),
        # 3. Remove nullable e adiciona a restrição unique
        migrations.AlterField(
            model_name='usuario',
            name='uuid',
            field=models.UUIDField(db_column='uuid', default=uuid.uuid4, editable=False, unique=True),
        ),
    ]
