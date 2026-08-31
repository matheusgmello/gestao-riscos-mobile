import csv
from pathlib import Path

CAMPOS_OBRIGATORIOS = (
    "NOME_UNIDADE",
    "NOME_CENTRO",
    "SIGLA_CENTRO",
    "TIPO_UNIDADE",
)


def caminho_padrao_unidades():
    return Path(__file__).resolve().parent / "data" / "unidades_ufsm.csv"


def importar_unidades_csv(setor_model, caminho_csv=None, desativar_legado=False):
    caminho = Path(caminho_csv) if caminho_csv else caminho_padrao_unidades()
    if not caminho.exists():
        raise FileNotFoundError(f"Arquivo CSV nao encontrado em {caminho}")

    criados = 0
    atualizados = 0

    with caminho.open("r", encoding="utf-8-sig", newline="") as arquivo:
        leitor = csv.DictReader(arquivo)
        cabecalho = leitor.fieldnames or []
        faltantes = [campo for campo in CAMPOS_OBRIGATORIOS if campo not in cabecalho]
        if faltantes:
            raise ValueError(
                "CSV invalido. Campos obrigatorios ausentes: " + ", ".join(faltantes)
            )

        vistos = set()
        for linha in leitor:
            nome = (linha.get("NOME_UNIDADE") or "").strip()
            nome_centro = (linha.get("NOME_CENTRO") or "").strip()
            sigla_centro = (linha.get("SIGLA_CENTRO") or "").strip()
            tipo_unidade = (linha.get("TIPO_UNIDADE") or "").strip()

            if not all([nome, nome_centro, sigla_centro, tipo_unidade]):
                continue

            chave = (nome, sigla_centro, tipo_unidade)
            vistos.add(chave)

            setor, criado = setor_model.objects.get_or_create(
                nome=nome,
                sigla_centro=sigla_centro,
                tipo_unidade=tipo_unidade,
                defaults={
                    "sigla": sigla_centro,
                    "nome_centro": nome_centro,
                    "fonte_oficial": True,
                    "ativo": True,
                },
            )

            houve_mudanca = False
            if setor.sigla != sigla_centro:
                setor.sigla = sigla_centro
                houve_mudanca = True
            if setor.nome_centro != nome_centro:
                setor.nome_centro = nome_centro
                houve_mudanca = True
            if setor.fonte_oficial is not True:
                setor.fonte_oficial = True
                houve_mudanca = True
            if setor.ativo is not True:
                setor.ativo = True
                houve_mudanca = True

            if criado:
                criados += 1
            else:
                if houve_mudanca:
                    setor.save(
                        update_fields=[
                            "sigla",
                            "nome_centro",
                            "fonte_oficial",
                            "ativo",
                        ]
                    )
                atualizados += 1

    if desativar_legado:
        setor_model.objects.filter(fonte_oficial=False).update(ativo=False)

    return {
        "criados": criados,
        "atualizados": atualizados,
        "arquivo": str(caminho),
    }
