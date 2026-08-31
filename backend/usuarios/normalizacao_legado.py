from riscos.models import Risco

SIGLAS_LEGADAS_ALIASES = {
    "Politecnico": "POLI",
}


def encontrar_setor_oficial_equivalente(setor_legado, setor_model):
    sigla_base = SIGLAS_LEGADAS_ALIASES.get(setor_legado.sigla, setor_legado.sigla)

    setor_oficial = (
        setor_model.objects.filter(
            fonte_oficial=True,
            ativo=True,
            sigla_centro=sigla_base,
            tipo_unidade="Unidade de Ensino",
        )
        .order_by("nome")
        .first()
    )
    if setor_oficial:
        return setor_oficial

    return (
        setor_model.objects.filter(
            fonte_oficial=True,
            ativo=True,
            sigla_centro=sigla_base,
        )
        .order_by("tipo_unidade", "nome")
        .first()
    )


def normalizar_vinculos_legados(usuario_model, setor_model):
    atualizados = 0
    ignorados = 0

    usuarios = usuario_model.objects.filter(setores__fonte_oficial=False).distinct()
    for usuario in usuarios:
        setores_atuais = list(usuario.setores.all())
        setores_para_adicionar = []
        setores_legados = []

        for setor in setores_atuais:
            if setor.fonte_oficial:
                continue
            setores_legados.append(setor)
            setor_oficial = encontrar_setor_oficial_equivalente(setor, setor_model)
            if setor_oficial:
                setores_para_adicionar.append(setor_oficial)
            else:
                ignorados += 1

        if setores_para_adicionar:
            usuario.setores.add(*setores_para_adicionar)
        if setores_legados:
            usuario.setores.remove(*setores_legados)
            atualizados += 1

    return {
        "usuarios_atualizados": atualizados,
        "usuarios_ignorados": ignorados,
    }


def normalizar_riscos_legados(setor_model):
    atualizados = 0
    ignorados = 0

    for risco in Risco.objects.select_related("setor").filter(setor__fonte_oficial=False):
        setor_oficial = encontrar_setor_oficial_equivalente(risco.setor, setor_model)
        if setor_oficial:
            risco.setor = setor_oficial
            risco.save(update_fields=["setor"])
            atualizados += 1
        else:
            ignorados += 1

    return {
        "riscos_atualizados": atualizados,
        "riscos_ignorados": ignorados,
    }
