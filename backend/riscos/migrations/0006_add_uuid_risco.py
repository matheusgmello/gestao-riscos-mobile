import uuid

from django.db import migrations, models


def popular_uuids_risco(apps, schema_editor):
    Risco = apps.get_model('riscos', 'Risco')
    for risco in Risco.objects.all():
        risco.uuid = uuid.uuid4()
        risco.save(update_fields=['uuid'])


class Migration(migrations.Migration):

    dependencies = [
        ('riscos', '0005_add_soft_delete'),
    ]

    operations = [
        # 1. Adiciona o campo sem restrição unique para não colidir nas linhas existentes
        migrations.AddField(
            model_name='risco',
            name='uuid',
            field=models.UUIDField(db_column='uuid', default=uuid.uuid4, editable=False, null=True),
        ),
        # 2. Popula cada linha existente com um UUID único
        migrations.RunPython(popular_uuids_risco, migrations.RunPython.noop),
        # 3. Remove nullable e adiciona a restrição unique
        migrations.AlterField(
            model_name='risco',
            name='uuid',
            field=models.UUIDField(db_column='uuid', default=uuid.uuid4, editable=False, unique=True),
        ),
    ]
