"""
Seed de apresentação do SIGR-UFSM.

Limpa usuários e planos existentes e recria dados realistas para demonstração:
- 1 administrador (conta do apresentador), vinculado ao CT/DCTA
- 18 gestores — cada equipe tem pelo menos 1 gestor_adm e 1 gestor
- 9 planos de risco — um por setor de cada gestor cadastrado
- Senha padrão para todos: 12345678
"""

from datetime import date

from django.core.management.base import BaseCommand
from rest_framework.authtoken.models import Token

from riscos.models import Macroprocesso, Monitoramento, ObjetivoPDI, PlanoAcao, Risco
from usuarios.importacao_unidades import importar_unidades_csv
from usuarios.models import Setor, Usuario

SENHA_PADRAO = "12345678"

ADMIN = {
    "siape": "202512603",
    "nome": "Administrador SIGR",
    "email": "admin.sigr@ufsm.br",
    "cargo": "gestor_adm",
    "setor_admin": ("CT", "Departamento de Computação Aplicada"),
}

GESTORES = [
    # ── CCR ──────────────────────────────────────────────────────────────────
    {
        "siape": "1847293",
        "nome": "Maria Cláudia Fonseca",
        "email": "maria.fonseca@ufsm.br",
        "cargo": "gestor_adm",
        "setores": [("CCR", "Centro de Ciências Rurais")],
    },
    {
        "siape": "1023847",
        "nome": "Luiz Fernando Becker",
        "email": "luiz.becker@ufsm.br",
        "cargo": "gestor",
        "setores": [("CCR", "Centro de Ciências Rurais")],
    },
    # ── CT / DCTA ─────────────────────────────────────────────────────────────
    {
        "siape": "2356184",
        "nome": "João Paulo Silveira",
        "email": "joao.silveira@ufsm.br",
        "cargo": "gestor_adm",
        "setores": [("CT", "Departamento de Computação Aplicada")],
    },
    {
        "siape": "2094815",
        "nome": "Patrícia Moraes Lima",
        "email": "patricia.lima@ufsm.br",
        "cargo": "gestor",
        "setores": [("CT", "Departamento de Computação Aplicada")],
    },
    # ── CCNE ─────────────────────────────────────────────────────────────────
    {
        "siape": "3741826",
        "nome": "Roberto César Almeida",
        "email": "roberto.almeida@ufsm.br",
        "cargo": "gestor_adm",
        "setores": [("CCNE", "Centro de Ciências Naturais e Exatas")],
    },
    {
        "siape": "3074512",
        "nome": "Ana Beatriz Rodrigues",
        "email": "ana.rodrigues@ufsm.br",
        "cargo": "gestor",
        "setores": [("CCNE", "Centro de Ciências Naturais e Exatas")],
    },
    # ── CCSH ─────────────────────────────────────────────────────────────────
    {
        "siape": "4852037",
        "nome": "Sandra Vieira Duarte",
        "email": "sandra.duarte@ufsm.br",
        "cargo": "gestor_adm",
        "setores": [("CCSH", "Centro de Ciências Sociais e Humanas")],
    },
    {
        "siape": "4198627",
        "nome": "Carlos Eduardo Nunes",
        "email": "carlos.nunes@ufsm.br",
        "cargo": "gestor",
        "setores": [("CCSH", "Centro de Ciências Sociais e Humanas")],
    },
    # ── CE ───────────────────────────────────────────────────────────────────
    {
        "siape": "5914038",
        "nome": "Paulo Henrique Mota",
        "email": "paulo.mota@ufsm.br",
        "cargo": "gestor_adm",
        "setores": [("CE", "Centro de Educação")],
    },
    {
        "siape": "5263049",
        "nome": "Fernanda Lima Costa",
        "email": "fernanda.costa@ufsm.br",
        "cargo": "gestor",
        "setores": [("CE", "Centro de Educação")],
    },
    # ── CT / EPS ─────────────────────────────────────────────────────────────
    {
        "siape": "6047192",
        "nome": "Camila Ramos Ferreira",
        "email": "camila.ferreira@ufsm.br",
        "cargo": "gestor_adm",
        "setores": [("CT", "Departamento de Engenharia de Produção e Sistemas")],
    },
    {
        "siape": "6381720",
        "nome": "Rafael Andrade Souza",
        "email": "rafael.souza@ufsm.br",
        "cargo": "gestor",
        "setores": [("CT", "Departamento de Engenharia de Produção e Sistemas")],
    },
    # ── PM ───────────────────────────────────────────────────────────────────
    {
        "siape": "7183064",
        "nome": "Diego Oliveira Teixeira",
        "email": "diego.teixeira@ufsm.br",
        "cargo": "gestor_adm",
        "setores": [("PM", "Campus da Universidade Federal de Santa Maria em Palmeira das Missões")],
    },
    {
        "siape": "7492053",
        "nome": "Juliana Pereira Martins",
        "email": "juliana.martins@ufsm.br",
        "cargo": "gestor",
        "setores": [("PM", "Campus da Universidade Federal de Santa Maria em Palmeira das Missões")],
    },
    # ── POLI ─────────────────────────────────────────────────────────────────
    {
        "siape": "8062947",
        "nome": "Renata Gomes Pinheiro",
        "email": "renata.pinheiro@ufsm.br",
        "cargo": "gestor_adm",
        "setores": [("POLI", "Colégio Politécnico")],
    },
    {
        "siape": "8517364",
        "nome": "Marcelo Santos Alves",
        "email": "marcelo.alves@ufsm.br",
        "cargo": "gestor",
        "setores": [("POLI", "Colégio Politécnico")],
    },
    # ── CAL ──────────────────────────────────────────────────────────────────
    {
        "siape": "9305821",
        "nome": "Leonardo Castro Freitas",
        "email": "leonardo.freitas@ufsm.br",
        "cargo": "gestor_adm",
        "setores": [("CAL", "Centro de Artes e Letras")],
    },
    {
        "siape": "9630481",
        "nome": "Vanessa Oliveira Cruz",
        "email": "vanessa.cruz@ufsm.br",
        "cargo": "gestor",
        "setores": [("CAL", "Centro de Artes e Letras")],
    },
]

PLANOS = [
    # 1 — Operacional · Extremo (nivel_residual = 4×5 = 20)
    {
        "setor": ("CT", "Departamento de Computação Aplicada"),
        "objetivo": "AI-D5-03",
        "macroprocesso": "Tecnologia da Informação",
        "categoria": "Operacional",
        "evento": (
            "Indisponibilidade prolongada dos sistemas acadêmicos críticos "
            "(SIE, portal do aluno, e-mail institucional)."
        ),
        "causa": (
            "Infraestrutura de TI envelhecida, ausência de redundância e "
            "baixo tempo de resposta para incidentes fora do horário comercial."
        ),
        "consequencia": (
            "Paralisia de matrículas, emissão de documentos e comunicação "
            "institucional, com impacto direto nos estudantes e servidores."
        ),
        "controles_atuais": (
            "Backups diários em servidor local, monitoramento reativo e equipe "
            "de suporte disponível apenas em horário comercial."
        ),
        "eficacia_controle": "Fraco",
        "probabilidade": 5,
        "impacto": 5,
        "prob_residual": 4,
        "imp_residual": 5,
        "plano": {
            "tipo_resposta": "Mitigar",
            "descricao_acao": (
                "Implementar solução de alta disponibilidade com failover automático, "
                "formalizar plantão 24h para incidentes críticos e contratar serviço "
                "de backup em nuvem com RTO de 4h."
            ),
            "responsavel": "João Paulo Silveira",
            "parceiros": "CPD UFSM, Diretoria de TI",
            "data_inicio": date(2026, 3, 1),
            "data_fim": date(2026, 8, 31),
            "status": "Em andamento",
            "progresso": 35,
            "observacoes": "Risco prioritário para o semestre. Aprovação orçamentária obtida.",
        },
        "monitoramento": {
            "resultados": (
                "Mapeamento dos sistemas críticos concluído. Proposta técnica de "
                "redundância encaminhada para aprovação da Reitoria."
            ),
            "acoes_futuras": (
                "Contratar serviço de colocation, finalizar testes de failover "
                "e treinar equipe para o novo protocolo de incidentes."
            ),
            "analise_critica": (
                "Risco permanece extremo até a implantação da redundância. "
                "Prazo de conclusão estimado para julho/2026."
            ),
        },
    },

    # 2 — Estratégico · Alto (nivel_residual = 3×4 = 12)
    {
        "setor": ("CCNE", "Centro de Ciências Naturais e Exatas"),
        "objetivo": "PR-D2-03",
        "macroprocesso": "Ensino",
        "categoria": "Estratégico",
        "evento": (
            "Defasagem curricular dos cursos de graduação frente às novas "
            "demandas científicas, tecnológicas e do mercado de trabalho."
        ),
        "causa": (
            "Ciclos de revisão curricular longos, baixa integração entre "
            "departamentos e pouca escuta ativa de egressos e empregadores."
        ),
        "consequencia": (
            "Perda de atratividade dos cursos, queda nos indicadores de "
            "empregabilidade dos egressos e avaliação negativa em rankings."
        ),
        "controles_atuais": (
            "Revisões pontuais por NDE a cada 3 anos e avaliações do INEP "
            "que indicam lacunas, porém sem plano estruturado de resposta."
        ),
        "eficacia_controle": "Fraco",
        "probabilidade": 4,
        "impacto": 5,
        "prob_residual": 3,
        "imp_residual": 4,
        "plano": {
            "tipo_resposta": "Mitigar",
            "descricao_acao": (
                "Instituir comitê permanente de atualização curricular com "
                "representantes docentes, discentes e egressos; realizar workshop "
                "anual de alinhamento com o mercado."
            ),
            "responsavel": "Ana Beatriz Rodrigues",
            "parceiros": "NDEs, Coordenações de Curso, Pró-Reitoria de Graduação",
            "data_inicio": date(2026, 5, 1),
            "data_fim": date(2026, 11, 30),
            "status": "Não iniciada",
            "progresso": 0,
            "observacoes": "Depende de aprovação em assembleia departamental prevista para maio.",
        },
    },

    # 3 — Financeiro · Alto (nivel_residual = 3×4 = 12)
    {
        "setor": ("PM", "Campus da Universidade Federal de Santa Maria em Palmeira das Missões"),
        "objetivo": "SF-D5-03",
        "macroprocesso": "Orçamento e Finanças",
        "categoria": "Financeiro",
        "evento": (
            "Contingenciamento orçamentário imprevisto comprometendo atividades "
            "fins do campus de Palmeira das Missões."
        ),
        "causa": (
            "Dependência quase exclusiva do orçamento federal com baixa "
            "captação de recursos externos e reserva de contingência inexistente."
        ),
        "consequencia": (
            "Paralisação de projetos de pesquisa, extensão e manutenção "
            "predial, com reflexo no atendimento à comunidade local."
        ),
        "controles_atuais": (
            "Revisão trimestral das dotações orçamentárias e priorização "
            "reativa conforme demanda dos departamentos."
        ),
        "eficacia_controle": "Fraco",
        "probabilidade": 4,
        "impacto": 4,
        "prob_residual": 3,
        "imp_residual": 4,
        "plano": {
            "tipo_resposta": "Mitigar",
            "descricao_acao": (
                "Elaborar plano de captação de recursos via projetos externos "
                "(FINEP, CNPq, parcerias municipais) e constituir fundo de reserva "
                "com 5% do orçamento anual."
            ),
            "responsavel": "Juliana Pereira Martins",
            "parceiros": "Pró-Reitoria de Planejamento, Prefeitura Municipal",
            "data_inicio": date(2026, 4, 15),
            "data_fim": date(2026, 12, 15),
            "status": "Em andamento",
            "progresso": 20,
            "observacoes": "",
        },
        "monitoramento": {
            "resultados": (
                "Levantamento de editais de fomento externo realizado. "
                "Três projetos submetidos ao CNPq em março/2026."
            ),
            "acoes_futuras": (
                "Aguardar resultado dos projetos submetidos e articular "
                "convênio com prefeitura para contrapartida em extensão."
            ),
            "analise_critica": (
                "Ações em andamento dentro do prazo. Risco de não aprovação "
                "dos projetos mantém nível alto até confirmação de recursos."
            ),
        },
    },

    # 4 — Integridade · Moderado (nivel_residual = 2×3 = 6)
    {
        "setor": ("CCSH", "Centro de Ciências Sociais e Humanas"),
        "objetivo": "AS-D5-01",
        "macroprocesso": "Pessoas",
        "categoria": "Integridade",
        "evento": (
            "Conflito de interesses não declarado em bancas de avaliação, "
            "processos seletivos e pareceres de pesquisa."
        ),
        "causa": (
            "Ausência de política formal de declaração de conflito de interesses "
            "e baixa cultura de transparência nos processos colegiados."
        ),
        "consequencia": (
            "Questionamento da imparcialidade institucional, risco de "
            "judicialização e danos à reputação do centro."
        ),
        "controles_atuais": (
            "Declaração voluntária em alguns colegiados e normas gerais da "
            "legislação federal, sem protocolo interno estruturado."
        ),
        "eficacia_controle": "Satisfatório",
        "probabilidade": 3,
        "impacto": 4,
        "prob_residual": 2,
        "imp_residual": 3,
        "plano": {
            "tipo_resposta": "Mitigar",
            "descricao_acao": (
                "Aprovar resolução interna de conflito de interesses, "
                "implantar formulário digital de declaração obrigatória e "
                "capacitar servidores sobre ética pública."
            ),
            "responsavel": "Carlos Eduardo Nunes",
            "parceiros": "Secretaria do CCSH, Ouvidoria UFSM",
            "data_inicio": date(2026, 4, 1),
            "data_fim": date(2026, 9, 30),
            "status": "Em andamento",
            "progresso": 50,
            "observacoes": "Minuta da resolução em análise pela procuradoria jurídica.",
        },
    },

    # 5 — Imagem · Moderado (nivel_residual = 2×2 = 4)
    {
        "setor": ("CE", "Centro de Educação"),
        "objetivo": "PR-D5-03",
        "macroprocesso": "Comunicação Institucional",
        "categoria": "Imagem",
        "evento": (
            "Gestão inadequada da comunicação em situações de crise "
            "envolvendo denúncias ou episódios de repercussão pública."
        ),
        "causa": (
            "Ausência de protocolo formal de gestão de crise, fluxo de "
            "comunicação descentralizado e sem porta-voz definido."
        ),
        "consequencia": (
            "Amplificação negativa nas redes sociais, perda de confiança "
            "da comunidade e dificuldade de resposta institucional tempestiva."
        ),
        "controles_atuais": (
            "Comunicação reativamente coordenada pela direção e "
            "assessoria de comunicação central, sem protocolo específico."
        ),
        "eficacia_controle": "Inexistente",
        "probabilidade": 3,
        "impacto": 3,
        "prob_residual": 2,
        "imp_residual": 2,
        "plano": {
            "tipo_resposta": "Mitigar",
            "descricao_acao": (
                "Elaborar protocolo de gestão de crise comunicacional, "
                "designar porta-voz e realizar simulado de crise com a equipe."
            ),
            "responsavel": "Fernanda Lima Costa",
            "parceiros": "Assessoria de Comunicação UFSM, Diretoria CE",
            "data_inicio": date(2026, 6, 1),
            "data_fim": date(2026, 10, 31),
            "status": "Não iniciada",
            "progresso": 0,
            "observacoes": "",
        },
    },

    # 6 — Operacional · Baixo (nivel_residual = 1×2 = 2)
    {
        "setor": ("POLI", "Colégio Politécnico"),
        "objetivo": "PR-D5-01",
        "macroprocesso": "Compras, Suprimentos e Patrimônio",
        "categoria": "Operacional",
        "evento": (
            "Atrasos recorrentes nos processos de compra de insumos e "
            "materiais didáticos para os cursos técnicos."
        ),
        "causa": (
            "Planejamento de compras realizado tardiamente, especificações "
            "técnicas imprecisas e alto índice de impugnação de licitações."
        ),
        "consequencia": (
            "Paralisação pontual de atividades práticas e retrabalho "
            "administrativo com impacto na experiência do aluno."
        ),
        "controles_atuais": (
            "Almoxarifado com estoque mínimo e compras emergenciais via "
            "dispensa de licitação quando necessário."
        ),
        "eficacia_controle": "Forte",
        "probabilidade": 2,
        "impacto": 2,
        "prob_residual": 1,
        "imp_residual": 2,
        "plano": {
            "tipo_resposta": "Mitigar",
            "descricao_acao": (
                "Antecipar o planejamento de compras para o primeiro trimestre "
                "e padronizar especificações técnicas por área, reduzindo "
                "impugnações e agilizando licitações."
            ),
            "responsavel": "Marcelo Santos Alves",
            "parceiros": "Setor de Compras UFSM, Coordenações de Curso",
            "data_inicio": date(2026, 2, 1),
            "data_fim": date(2026, 5, 31),
            "status": "Concluída",
            "progresso": 100,
            "observacoes": (
                "Planejamento 2026 antecipado com sucesso. Redução de 40% no "
                "tempo médio de processos licitatórios em relação ao ano anterior."
            ),
        },
    },

    # 7 — Operacional · Moderado (nivel_residual = 3×3 = 9) — CCR
    {
        "setor": ("CCR", "Centro de Ciências Rurais"),
        "objetivo": "PR-D7-01",
        "macroprocesso": "Controle Ambiental",
        "categoria": "Operacional",
        "evento": (
            "Perda de áreas experimentais e culturas de pesquisa em campo "
            "decorrente de eventos climáticos extremos não previstos."
        ),
        "causa": (
            "Ausência de seguro agrícola para áreas experimentais, inexistência "
            "de plano de contingência climática e dependência de irrigação manual."
        ),
        "consequencia": (
            "Interrupção de pesquisas de longa duração, perda de investimento "
            "em insumos e impacto nos resultados de projetos financiados."
        ),
        "controles_atuais": (
            "Monitoramento meteorológico pontual e adoção de calendário agrícola "
            "padrão sem ajuste dinâmico para variações climáticas."
        ),
        "eficacia_controle": "Fraco",
        "probabilidade": 4,
        "impacto": 4,
        "prob_residual": 3,
        "imp_residual": 3,
        "plano": {
            "tipo_resposta": "Mitigar",
            "descricao_acao": (
                "Contratar seguro para áreas experimentais, instalar sistema "
                "de irrigação automatizado e elaborar plano de contingência "
                "climática com rotas alternativas de cultivo."
            ),
            "responsavel": "Maria Cláudia Fonseca",
            "parceiros": "Pró-Reitoria de Pesquisa, EMBRAPA",
            "data_inicio": date(2026, 3, 1),
            "data_fim": date(2026, 9, 30),
            "status": "Em andamento",
            "progresso": 25,
            "observacoes": "Contato iniciado com seguradora em fevereiro/2026.",
        },
    },

    # 8 — Estratégico · Alto (nivel_residual = 4×3 = 12) — CT/EPS
    {
        "setor": ("CT", "Departamento de Engenharia de Produção e Sistemas"),
        "objetivo": "AI-D5-02",
        "macroprocesso": "Pessoas",
        "categoria": "Estratégico",
        "evento": (
            "Déficit de docentes qualificados em áreas específicas do curso de "
            "Engenharia de Produção, com risco de descredenciamento de disciplinas."
        ),
        "causa": (
            "Alta taxa de aposentadoria no quadro docente, dificuldade de "
            "reposição por exigências do concurso público e baixa atratividade "
            "salarial frente ao mercado privado."
        ),
        "consequencia": (
            "Sobrecarga dos docentes remanescentes, queda na qualidade do ensino "
            "e risco de avaliação negativa pelo MEC no próximo ciclo."
        ),
        "controles_atuais": (
            "Redistribuição de carga horária entre docentes disponíveis e "
            "contratação eventual de substitutos por processo seletivo simplificado."
        ),
        "eficacia_controle": "Fraco",
        "probabilidade": 4,
        "impacto": 4,
        "prob_residual": 4,
        "imp_residual": 3,
        "plano": {
            "tipo_resposta": "Mitigar",
            "descricao_acao": (
                "Solicitar abertura de concurso público prioritário para as "
                "vagas críticas, mapear professores colaboradores e firmar "
                "acordo de cooperação com setor produtivo para docência compartilhada."
            ),
            "responsavel": "Rafael Andrade Souza",
            "parceiros": "Pró-Reitoria de Gestão de Pessoas, Direção do CT",
            "data_inicio": date(2026, 4, 1),
            "data_fim": date(2027, 3, 31),
            "status": "Não iniciada",
            "progresso": 0,
            "observacoes": "Aguarda abertura de edital para concurso público federal.",
        },
    },

    # 9 — Imagem · Moderado (nivel_residual = 2×3 = 6) — CAL
    {
        "setor": ("CAL", "Centro de Artes e Letras"),
        "objetivo": "AS-D4-03",
        "macroprocesso": "Extensão",
        "categoria": "Imagem",
        "evento": (
            "Deterioração do acervo físico de obras artísticas e documentos "
            "históricos sob guarda do Centro de Artes e Letras."
        ),
        "causa": (
            "Instalações sem controle adequado de temperatura e umidade, "
            "ausência de política de conservação preventiva e equipe "
            "técnica especializada insuficiente."
        ),
        "consequencia": (
            "Perda irreversível de patrimônio cultural institucional, "
            "danos à imagem da UFSM como guardiã da memória regional "
            "e potencial responsabilização jurídica."
        ),
        "controles_atuais": (
            "Inventário anual do acervo e armazenamento em sala climatizada "
            "parcialmente funcional, sem monitoramento contínuo."
        ),
        "eficacia_controle": "Fraco",
        "probabilidade": 3,
        "impacto": 4,
        "prob_residual": 2,
        "imp_residual": 3,
        "plano": {
            "tipo_resposta": "Mitigar",
            "descricao_acao": (
                "Instalar sistema de monitoramento contínuo de temperatura e "
                "umidade, elaborar política de conservação preventiva e firmar "
                "parceria com laboratório de restauro para diagnóstico do acervo."
            ),
            "responsavel": "Vanessa Oliveira Cruz",
            "parceiros": "Museu da UFSM, Pró-Reitoria de Extensão",
            "data_inicio": date(2026, 5, 1),
            "data_fim": date(2026, 11, 30),
            "status": "Não iniciada",
            "progresso": 0,
            "observacoes": "",
        },
    },
]


def _obter_setor(sigla_centro, nome):
    try:
        return Setor.objects.get(sigla_centro=sigla_centro, nome=nome, fonte_oficial=True)
    except Setor.DoesNotExist:
        return Setor.objects.get(sigla_centro=sigla_centro, nome=nome)


class Command(BaseCommand):
    help = (
        "Limpa usuários e planos existentes e popula o banco com dados "
        "realistas para apresentação do SIGR-UFSM."
    )

    def handle(self, *args, **options):
        self.stdout.write("→ Importando unidades oficiais da UFSM...")
        importar_unidades_csv(Setor, desativar_legado=True)

        # ── Limpeza ──────────────────────────────────────────────────────────
        self.stdout.write("→ Removendo planos de risco existentes...")
        Risco.all_objects.all().delete()

        self.stdout.write("→ Removendo usuários existentes...")
        Usuario.objects.all().delete()

        # ── Admin ─────────────────────────────────────────────────────────────
        self.stdout.write("→ Criando administrador...")
        admin = Usuario.objects.create_superuser(
            siape=ADMIN["siape"],
            password=SENHA_PADRAO,
            nome=ADMIN["nome"],
            email=ADMIN["email"],
        )
        admin.cargo = ADMIN["cargo"]
        admin.save(update_fields=["cargo"])

        setor_admin = _obter_setor(*ADMIN["setor_admin"])
        admin.setores.add(setor_admin)
        Token.objects.get_or_create(user=admin)

        # ── Gestores ──────────────────────────────────────────────────────────
        self.stdout.write("→ Criando gestores...")

        for dados in GESTORES:
            usuario = Usuario.objects.create_user(
                siape=dados["siape"],
                password=SENHA_PADRAO,
                nome=dados["nome"],
                email=dados["email"],
            )
            usuario.cargo = dados["cargo"]
            usuario.equipe = True
            usuario.save(update_fields=["cargo", "equipe"])

            setores = [_obter_setor(sigla, nome) for sigla, nome in dados["setores"]]
            usuario.setores.set(setores)
            Token.objects.get_or_create(user=usuario)

        # ── Planos de risco ───────────────────────────────────────────────────
        self.stdout.write("→ Criando planos de risco...")
        for dados in PLANOS:
            sigla, nome_setor = dados["setor"]
            setor = _obter_setor(sigla, nome_setor)
            objetivo = ObjetivoPDI.objects.get(codigo=dados["objetivo"])
            macroprocesso = Macroprocesso.objects.get(nome=dados["macroprocesso"])

            risco = Risco.objects.create(
                setor=setor,
                objetivo=objetivo,
                macroprocesso=macroprocesso,
                categoria=dados["categoria"],
                evento=dados["evento"],
                causa=dados["causa"],
                consequencia=dados["consequencia"],
                controles_atuais=dados["controles_atuais"],
                eficacia_controle=dados["eficacia_controle"],
                probabilidade=dados["probabilidade"],
                impacto=dados["impacto"],
                prob_residual=dados["prob_residual"],
                imp_residual=dados["imp_residual"],
            )

            PlanoAcao.objects.create(risco=risco, **dados["plano"])

            if "monitoramento" in dados:
                Monitoramento.objects.create(risco=risco, **dados["monitoramento"])

        # ── Resumo ────────────────────────────────────────────────────────────
        self.stdout.write("")
        self.stdout.write(self.style.SUCCESS("✔  Seed de apresentação concluído!"))
        self.stdout.write("")
        self.stdout.write(f"  Senha padrão (todos) → {SENHA_PADRAO}")
        self.stdout.write("")
        self.stdout.write(f"  Admin   → SIAPE {ADMIN['siape']} | {ADMIN['nome']} | setor: {ADMIN['setor_admin'][0]}/{ADMIN['setor_admin'][1]}")
        self.stdout.write(f"  Gestores → {len(GESTORES)} usuários")
        self.stdout.write(f"  Planos  → {len(PLANOS)} planos de risco (um por setor)")
        self.stdout.write("")
        self.stdout.write("  Usuários criados:")
        for dados in GESTORES:
            cargo_label = "Gestor Adm" if dados["cargo"] == "gestor_adm" else "Gestor    "
            setores_str = ", ".join(f"{s[0]}" for s in dados["setores"])
            self.stdout.write(f"    {cargo_label} | SIAPE {dados['siape']} | {dados['nome']} | {setores_str}")
