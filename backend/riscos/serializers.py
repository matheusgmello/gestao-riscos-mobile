from rest_framework import serializers
from rest_framework.exceptions import ValidationError

from usuarios.serializers import UnidadeOrganizacionalSerializer

from .models import (
    DesafioPDI,
    HistoricoPlano,
    Macroprocesso,
    Monitoramento,
    ObjetivoPDI,
    PlanoAcao,
    Risco,
)


class DesafioPDISerializer(serializers.ModelSerializer):
    class Meta:
        model = DesafioPDI
        fields = '__all__'

class MacroprocessoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Macroprocesso
        fields = '__all__'

class ObjetivoPDISerializer(serializers.ModelSerializer):
    desafio_detalhes = DesafioPDISerializer(source='desafio', read_only=True)
    
    class Meta:
        model = ObjetivoPDI
        fields = ['id', 'codigo', 'descricao', 'desafio', 'desafio_detalhes']

class RiscoSerializer(serializers.ModelSerializer):
    nivel_risco = serializers.IntegerField(read_only=True)
    nivel_residual = serializers.IntegerField(read_only=True)
    setor_detalhes = UnidadeOrganizacionalSerializer(source='setor', read_only=True)
    objetivo_detalhes = ObjetivoPDISerializer(source='objetivo', read_only=True)
    macroprocesso_detalhes = MacroprocessoSerializer(source='macroprocesso', read_only=True)
    periodo_acao = serializers.SerializerMethodField()
    possui_plano_acao = serializers.SerializerMethodField()
    possui_monitoramento = serializers.SerializerMethodField()

    class Meta:
        model = Risco
        fields = [
            'uuid', 'setor', 'setor_detalhes', 'objetivo', 'objetivo_detalhes',
            'macroprocesso', 'macroprocesso_detalhes', 'categoria', 'evento',
            'causa', 'consequencia', 'controles_atuais', 'eficacia_controle',
            'probabilidade', 'impacto', 'nivel_risco', 'prob_residual',
            'imp_residual', 'nivel_residual', 'latitude', 'longitude',
            'endereco', 'ativo', 'atualizado_em', 'periodo_acao',
            'possui_plano_acao', 'possui_monitoramento',
        ]
        read_only_fields = ['ativo', 'atualizado_em']

    def get_periodo_acao(self, obj):
        acao = next(iter(obj.planos_acao.all()), None)
        if not acao:
            return {"data_inicio": None, "data_fim": None}
        return {
            "data_inicio": acao.data_inicio.isoformat(),
            "data_fim": acao.data_fim.isoformat(),
        }

    def get_possui_plano_acao(self, obj):
        return any(True for _ in obj.planos_acao.all())

    def get_possui_monitoramento(self, obj):
        return any(True for _ in obj.monitoramentos.all())

    def validate(self, data):
        campos_escala = ['probabilidade', 'impacto', 'prob_residual', 'imp_residual']
        erros = {}
        for campo in campos_escala:
            valor = data.get(campo)
            if valor is not None and not 1 <= valor <= 5:
                erros[campo] = "O valor deve estar entre 1 e 5."

        # Coordenadas: valida só quando alguma delas veio no payload. Num PATCH
        # parcial que não mexe em localização, completa com o valor da instância.
        if 'latitude' in data or 'longitude' in data:
            atual_lat = getattr(self.instance, 'latitude', None)
            atual_lng = getattr(self.instance, 'longitude', None)
            lat = data.get('latitude', atual_lat)
            lng = data.get('longitude', atual_lng)
            if (lat is None) != (lng is None):
                erros['latitude'] = "Informe latitude e longitude juntas ou nenhuma."
            if lat is not None and not -90 <= lat <= 90:
                erros['latitude'] = "Latitude deve estar entre -90 e 90."
            if lng is not None and not -180 <= lng <= 180:
                erros['longitude'] = "Longitude deve estar entre -180 e 180."

        if erros:
            raise ValidationError(erros)
        return data

class PlanoAcaoSerializer(serializers.ModelSerializer):
    risco = serializers.SlugRelatedField(slug_field='uuid', queryset=Risco.objects.all())

    class Meta:
        model = PlanoAcao
        fields = '__all__'

class MonitoramentoSerializer(serializers.ModelSerializer):
    risco = serializers.SlugRelatedField(slug_field='uuid', queryset=Risco.objects.all())

    class Meta:
        model = Monitoramento
        fields = '__all__'

class HistoricoPlanoSerializer(serializers.ModelSerializer):
    class Meta:
        model = HistoricoPlano
        fields = ['id', 'usuario_nome', 'data_hora', 'descricao']
        read_only_fields = ['id', 'data_hora']
