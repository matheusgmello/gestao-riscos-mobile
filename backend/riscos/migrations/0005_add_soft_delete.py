from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('riscos', '0004_alter_desafiopdi_options_alter_macroprocesso_options_and_more'),
    ]

    operations = [
        migrations.AddField(
            model_name='desafiopdi',
            name='ativo',
            field=models.BooleanField(db_column='ativo', default=True),
        ),
        migrations.AddField(
            model_name='macroprocesso',
            name='ativo',
            field=models.BooleanField(db_column='ativo', default=True),
        ),
        migrations.AddField(
            model_name='objetivopdi',
            name='ativo',
            field=models.BooleanField(db_column='ativo', default=True),
        ),
        migrations.AddField(
            model_name='risco',
            name='ativo',
            field=models.BooleanField(db_column='ativo', default=True),
        ),
        migrations.AddField(
            model_name='planoacao',
            name='ativo',
            field=models.BooleanField(db_column='ativo', default=True),
        ),
        migrations.AddField(
            model_name='monitoramento',
            name='ativo',
            field=models.BooleanField(db_column='ativo', default=True),
        ),
    ]
