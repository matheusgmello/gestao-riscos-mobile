from django.contrib import admin

from .models import UnidadeOrganizacional, Usuario


@admin.register(UnidadeOrganizacional)
class UnidadeOrganizacionalAdmin(admin.ModelAdmin):
    list_display = (
        'label_curto_admin',
        'nome_centro',
        'tipo_unidade',
        'fonte_oficial',
        'ativo',
    )
    search_fields = ('nome', 'sigla', 'sigla_centro', 'nome_centro', 'tipo_unidade')
    list_filter = ('fonte_oficial', 'ativo', 'tipo_unidade', 'sigla_centro')

    def label_curto_admin(self, obj):
        return obj.label_completo
    label_curto_admin.short_description = "Unidade"

@admin.register(Usuario)
class UsuarioAdmin(admin.ModelAdmin):
    list_display = ('siape', 'nome', 'email', 'exibir_setores', 'ativo', 'equipe')
    search_fields = ('siape', 'nome', 'email')
    list_filter = ('ativo', 'equipe', 'setores')
    ordering = ('nome',)

    def exibir_setores(self, obj):
        return ", ".join([s.label_curto for s in obj.setores.all()])
    exibir_setores.short_description = "Unidades"
