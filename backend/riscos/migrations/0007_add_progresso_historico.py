import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('riscos', '0006_add_uuid_risco'),
    ]

    operations = [
        migrations.AddField(
            model_name='planoacao',
            name='progresso',
            field=models.IntegerField(db_column='progresso', default=0),
        ),
        migrations.CreateModel(
            name='HistoricoPlano',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('usuario_nome', models.CharField(db_column='usuario_nome', max_length=255)),
                ('data_hora', models.DateTimeField(auto_now_add=True, db_column='data_hora')),
                ('descricao', models.CharField(db_column='descricao', max_length=255)),
                ('risco', models.ForeignKey(
                    db_column='id_risco',
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='historico',
                    to='riscos.risco',
                )),
            ],
            options={
                'verbose_name': 'Histórico do Plano',
                'verbose_name_plural': 'Históricos dos Planos',
                'db_table': 'historico_planos',
                'ordering': ['-data_hora'],
            },
        ),
    ]
