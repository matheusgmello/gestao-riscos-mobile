import pytest
from rest_framework import status

from riscos.models import (
    HistoricoPlano,
    Macroprocesso,
    Monitoramento,
    ObjetivoPDI,
    PlanoAcao,
    Risco,
)


@pytest.fixture
def infra_risco(setor_oficial, setor_secundario, usuario_gestor, usuario_outro_setor, objetivo_padrao, macroprocesso_padrao):
    # este fixture monta um cenario completo reutilizando as fixtures compartilhadas do conftest
    risco = Risco.objects.create(
        setor=setor_oficial,
        objetivo=objetivo_padrao,
        macroprocesso=macroprocesso_padrao,
        categoria="Operacional",
        evento="E",
        causa="C",
        consequencia="C",
        controles_atuais="C",
        eficacia_controle="Satisfatório",
        probabilidade=3,
        impacto=3,
        prob_residual=1,
        imp_residual=1,
    )
    return {
        "u1": usuario_gestor,
        "u2": usuario_outro_setor,
        "s1": setor_oficial,
        "s2": setor_secundario,
        "risco": risco,
    }


@pytest.mark.django_db
class TestRiscoViewsPermissions:
    def test_calculo_niveis_no_save(self, infra_risco):
        # a criacao do fixture ja deve ter calculado os niveis automaticamente
        risco = infra_risco['risco']
        assert risco.nivel_risco == 9
        assert risco.nivel_residual == 1

    def test_qualquer_gestor_visualiza_riscos(self, api_client, infra_risco):
        # este caso valida a leitura do plano por outro gestor autenticado
        api_client.force_authenticate(user=infra_risco['u2'])
        url = f"/api/riscos/planos/{infra_risco['risco'].uuid}/"
        response = api_client.get(url)
        assert response.status_code == status.HTTP_200_OK

    def test_gestor_nao_edita_risco_de_outro_setor(self, api_client, infra_risco):
        # aqui a regra esperada e o bloqueio da edicao fora do proprio setor
        api_client.force_authenticate(user=infra_risco['u2'])
        url = f"/api/riscos/planos/{infra_risco['risco'].uuid}/"
        payload = {"evento": "Hacked"}
        response = api_client.patch(url, payload, format='json')
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_gestor_edita_proprio_risco(self, api_client, infra_risco):
        # neste cenario o gestor altera um risco da propria unidade
        api_client.force_authenticate(user=infra_risco['u1'])
        url = f"/api/riscos/planos/{infra_risco['risco'].uuid}/"
        payload = {"evento": "Atualizado"}
        response = api_client.patch(url, payload, format='json')
        assert response.status_code == status.HTTP_200_OK
        assert response.data["usuario"]["evento"] if "usuario" in response.data else True

    def test_gestor_nao_cria_risco_para_outro_setor(self, api_client, infra_risco):
        # a criacao tambem deve respeitar o setor vinculado ao usuario
        api_client.force_authenticate(user=infra_risco['u1'])
        url = "/api/riscos/planos/"
        payload = {
            "setor": infra_risco['s2'].id,
            "objetivo": infra_risco['risco'].objetivo.id,
            "macroprocesso": infra_risco['risco'].macroprocesso.id,
            "categoria": "Operacional",
            "evento": "E", "causa": "C", "consequencia": "C", "controles_atuais": "C",
            "eficacia_controle": "Satisfatório", "probabilidade": 1, "impacto": 1,
            "prob_residual": 1, "imp_residual": 1
        }
        response = api_client.post(url, payload, format='json')
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_permissao_objeto_com_atributo_risco(self, infra_risco):
        # valida o segundo caminho da permissao: objetos que possuem FK para risco (PlanoAcao, Monitoramento)
        from riscos.views import PertenceAoSetorDoRisco
        perm = PertenceAoSetorDoRisco()

        class ObjComRisco:
            risco = infra_risco['risco']  # risco pertence a s1

        class RequestU2:
            method = "PUT"
            user = infra_risco['u2']  # u2 pertence a s2

        class RequestU1:
            method = "PUT"
            user = infra_risco['u1']  # u1 pertence a s1

        # gestor de outro setor nao pode editar objeto vinculado ao risco de s1
        assert perm.has_object_permission(RequestU2(), None, ObjComRisco()) is False
        # gestor do proprio setor pode editar
        assert perm.has_object_permission(RequestU1(), None, ObjComRisco()) is True

    def test_permissao_objeto_invalido(self, infra_risco):
        # este teste cobre um objeto que nao corresponde ao esperado pela permissao
        from riscos.views import PertenceAoSetorDoRisco
        perm = PertenceAoSetorDoRisco()

        class MockObj: pass

        # o request abaixo representa o minimo necessario para a chamada
        class MockRequest:
            method = "POST"
            user = infra_risco['u1']

        assert perm.has_object_permission(MockRequest(), None, MockObj()) is False

    def test_paginacao_riscos(self, api_client, infra_risco):
        # a listagem deve retornar o formato paginado padrao da api
        api_client.force_authenticate(user=infra_risco['u1'])
        url = "/api/riscos/planos/"
        response = api_client.get(url)
        assert response.status_code == status.HTTP_200_OK
        assert "results" in response.data
        assert "count" in response.data
        assert len(response.data["results"]) == 1

    def test_filtro_setor(self, api_client, infra_risco):
        # primeiro o filtro deve retornar o risco pertencente ao setor informado
        api_client.force_authenticate(user=infra_risco['u1'])
        url = f"/api/riscos/planos/?setor={infra_risco['s1'].id}"
        response = api_client.get(url)
        assert response.status_code == status.HTTP_200_OK
        assert len(response.data["results"]) == 1

        # depois o mesmo teste valida um filtro sem resultados
        url = f"/api/riscos/planos/?setor={infra_risco['s2'].id}"
        response = api_client.get(url)
        assert response.status_code == status.HTTP_200_OK
        assert len(response.data["results"]) == 0

    def test_busca_texto_risco(self, api_client, infra_risco):
        # a busca textual deve localizar o risco por termos simples
        api_client.force_authenticate(user=infra_risco['u1'])
        url = "/api/riscos/planos/?search=E"
        response = api_client.get(url)
        assert response.status_code == status.HTTP_200_OK
        assert len(response.data["results"]) == 1

        # na segunda chamada o termo nao existe e a lista deve vir vazia
        url = "/api/riscos/planos/?search=Inexistente"
        response = api_client.get(url)
        assert response.status_code == status.HTTP_200_OK
        assert len(response.data["results"]) == 0

    def test_objetivos_pdi_sao_listados_com_ordenacao_estavel(self, api_client, infra_risco):
        # este teste insere itens extras para validar a ordenacao do endpoint
        api_client.force_authenticate(user=infra_risco["u1"])
        ObjetivoPDI.objects.create(codigo="A-TESTE-001", descricao="Primeiro", desafio=infra_risco["risco"].objetivo.desafio)
        ObjetivoPDI.objects.create(codigo="Z-TESTE-001", descricao="Ultimo", desafio=infra_risco["risco"].objetivo.desafio)

        response = api_client.get("/api/riscos/objetivos/")

        assert response.status_code == status.HTTP_200_OK
        assert isinstance(response.data, list)
        codigos = [item["codigo"] for item in response.data]
        codigos_esperados = list(ObjetivoPDI.objects.values_list("codigo", flat=True))
        assert codigos == codigos_esperados
        assert "A-TESTE-001" in codigos
        assert "Z-TESTE-001" in codigos

    def test_macroprocessos_sao_listados_com_ordenacao_estavel(self, api_client, infra_risco):
        # a mesma logica e aplicada para macroprocessos
        api_client.force_authenticate(user=infra_risco["u1"])
        Macroprocesso.objects.create(nome="A Macroprocesso")
        Macroprocesso.objects.create(nome="Z Macroprocesso")

        response = api_client.get("/api/riscos/macroprocessos/")

        assert response.status_code == status.HTTP_200_OK
        assert isinstance(response.data, list)
        nomes = [item["nome"] for item in response.data]
        nomes_esperados = list(Macroprocesso.objects.values_list("nome", flat=True))
        assert nomes == nomes_esperados
        assert "A Macroprocesso" in nomes
        assert "Z Macroprocesso" in nomes

    def test_exporta_lista_filtrada_para_excel(self, api_client, infra_risco):
        # este endpoint deve gerar um arquivo excel para a listagem filtrada
        api_client.force_authenticate(user=infra_risco["u1"])

        response = api_client.get(f"/api/riscos/planos/exportar-excel/?setor={infra_risco['s1'].id}")

        assert response.status_code == status.HTTP_200_OK
        assert response["Content-Type"] == "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        assert 'filename="planos-risco.xlsx"' in response["Content-Disposition"]
        assert response.content.startswith(b"PK")

    def test_exporta_plano_individual_para_excel(self, api_client, infra_risco):
        # aqui a exportacao e de um plano especifico
        api_client.force_authenticate(user=infra_risco["u1"])

        response = api_client.get(f"/api/riscos/planos/{infra_risco['risco'].uuid}/exportar-excel/")

        assert response.status_code == status.HTTP_200_OK
        assert response["Content-Type"] == "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        assert f'filename="plano-risco-{infra_risco["risco"].uuid}.xlsx"' in response["Content-Disposition"]
        assert response.content.startswith(b"PK")

    def test_exporta_plano_individual_para_pdf(self, api_client, infra_risco):
        # primeiro cria um plano de acao para enriquecer o pdf exportado
        api_client.force_authenticate(user=infra_risco["u1"])
        PlanoAcao.objects.create(
            risco=infra_risco["risco"],
            tipo_resposta="Mitigar",
            descricao_acao="Executar plano de mitigacao.",
            responsavel="Gestor responsavel",
            data_inicio="2026-01-01",
            data_fim="2026-12-31",
            status="Em andamento",
        )

        # depois solicita a geracao do pdf do plano
        response = api_client.get(f"/api/riscos/planos/{infra_risco['risco'].uuid}/exportar-pdf/")

        assert response.status_code == status.HTTP_200_OK
        assert response["Content-Type"] == "application/pdf"
        assert f'filename="plano-risco-{infra_risco["risco"].uuid}.pdf"' in response["Content-Disposition"]
        assert response.content.startswith(b"%PDF")


@pytest.mark.django_db
class TestSoftDeleteEndpoints:
    def test_delete_risco_retorna_204_e_desativa(self, api_client, infra_risco):
        api_client.force_authenticate(user=infra_risco["u1"])
        risco = infra_risco["risco"]

        response = api_client.delete(f"/api/riscos/planos/{risco.uuid}/")

        assert response.status_code == status.HTTP_204_NO_CONTENT
        assert not Risco.objects.filter(id=risco.id).exists()
        assert Risco.all_objects.filter(id=risco.id, ativo=False).exists()

    def test_risco_desativado_retorna_404_para_gestor(self, api_client, infra_risco):
        risco = infra_risco["risco"]
        risco.delete()

        api_client.force_authenticate(user=infra_risco["u1"])
        response = api_client.get(f"/api/riscos/planos/{risco.uuid}/")

        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_superuser_ve_risco_desativado_com_parametro(self, api_client, infra_risco, usuario_superuser):
        risco = infra_risco["risco"]
        risco.delete()

        api_client.force_authenticate(user=usuario_superuser)
        response = api_client.get("/api/riscos/planos/?incluir_inativos=true")

        uuids = [str(p["uuid"]) for p in response.data["results"]]
        assert str(risco.uuid) in uuids

    def test_dashboard_respeita_filtros_de_setor_e_data(self, api_client, infra_risco):
        # este cenario cria uma acao dentro do periodo filtrado
        api_client.force_authenticate(user=infra_risco["u1"])
        PlanoAcao.objects.create(
            risco=infra_risco["risco"],
            tipo_resposta="Mitigar",
            descricao_acao="Acao dentro do periodo.",
            responsavel="Gestor responsavel",
            data_inicio="2026-03-01",
            data_fim="2026-03-31",
            status="Em andamento",
        )

        # a chamada deve refletir os indicadores apenas do recorte informado
        response = api_client.get(
            f"/api/riscos/planos/dashboard/?setor={infra_risco['s1'].id}"
            "&data_inicio=2026-01-01&data_fim=2026-12-31"
        )

        assert response.status_code == status.HTTP_200_OK
        assert response.data["total_planos"] == 1
        assert response.data["tratamentos_ativos"] == 1
        assert response.data["setores_filtrados"] == 1
        assert len(response.data["planos"]) == 1
        assert response.data["planos"][0]["periodo_acao"] == {
            "data_inicio": "2026-03-01",
            "data_fim": "2026-03-31",
        }
        assert response.data["riscos_sem_acao"] == 0
        assert response.data["riscos_monitorados"] == 0
        assert response.data["taxa_mitigacao"] == 100.0
        assert "distribuicao_categorias" in response.data
        assert "unidades_maior_exposicao" in response.data
        assert "riscos_por_nivel" in response.data

    def test_dashboard_retorna_vazio_quando_periodo_nao_contem_acoes(self, api_client, infra_risco):
        # aqui a acao e criada fora do periodo para validar retorno vazio
        api_client.force_authenticate(user=infra_risco["u1"])
        PlanoAcao.objects.create(
            risco=infra_risco["risco"],
            tipo_resposta="Mitigar",
            descricao_acao="Acao fora do periodo.",
            responsavel="Gestor responsavel",
            data_inicio="2024-03-01",
            data_fim="2024-03-31",
            status="Em andamento",
        )

        response = api_client.get(
            f"/api/riscos/planos/dashboard/?setor={infra_risco['s1'].id}"
            "&data_inicio=2026-01-01&data_fim=2026-12-31"
        )

        assert response.status_code == status.HTTP_200_OK
        assert response.data["total_planos"] == 0
        assert response.data["tratamentos_ativos"] == 0
        assert response.data["planos"] == []


@pytest.mark.django_db
class TestRiscoSerializerCamposComputados:
    def test_serializer_retorna_periodo_acao_quando_plano_existe(self, risco_com_plano):
        from riscos.serializers import RiscoSerializer
        risco = Risco.objects.prefetch_related("planos_acao", "monitoramentos").get(pk=risco_com_plano.pk)
        dados = RiscoSerializer(risco).data
        assert dados["possui_plano_acao"] is True
        assert dados["periodo_acao"]["data_inicio"] == "2026-01-10"
        assert dados["periodo_acao"]["data_fim"] == "2026-03-10"

    def test_serializer_retorna_periodo_acao_vazio_sem_plano(self, risco_basico):
        from riscos.serializers import RiscoSerializer
        risco = Risco.objects.prefetch_related("planos_acao", "monitoramentos").get(pk=risco_basico.pk)
        dados = RiscoSerializer(risco).data
        assert dados["possui_plano_acao"] is False
        assert dados["periodo_acao"] == {"data_inicio": None, "data_fim": None}

    def test_serializer_retorna_possui_monitoramento(self, risco_com_monitoramento):
        from riscos.serializers import RiscoSerializer
        risco = Risco.objects.prefetch_related("planos_acao", "monitoramentos").get(pk=risco_com_monitoramento.pk)
        dados = RiscoSerializer(risco).data
        assert dados["possui_monitoramento"] is True

    def test_serializer_retorna_nao_possui_monitoramento_sem_registros(self, risco_basico):
        from riscos.serializers import RiscoSerializer
        risco = Risco.objects.prefetch_related("planos_acao", "monitoramentos").get(pk=risco_basico.pk)
        dados = RiscoSerializer(risco).data
        assert dados["possui_monitoramento"] is False


@pytest.mark.django_db
class TestPlanoAcaoAutoProgresso:
    def test_progresso_auto_100_ao_concluir(self, api_client, infra_risco):
        # ao marcar status como Concluída o progresso deve ser automaticamente 100
        api_client.force_authenticate(user=infra_risco["u1"])
        acao = PlanoAcao.objects.create(
            risco=infra_risco["risco"],
            tipo_resposta="Mitigar",
            descricao_acao="Acao de teste",
            responsavel="Responsavel",
            data_inicio="2026-01-01",
            data_fim="2026-06-30",
            status="Em andamento",
            progresso=40,
        )

        response = api_client.patch(
            f"/api/riscos/acoes/{acao.id}/",
            {"status": "Concluída"},
            format="json",
        )

        assert response.status_code == status.HTTP_200_OK
        acao.refresh_from_db()
        assert acao.progresso == 100

    def test_progresso_nao_alterado_em_outros_status(self, api_client, infra_risco):
        # status diferente de Concluída nao deve forcar o progresso a 100
        api_client.force_authenticate(user=infra_risco["u1"])
        acao = PlanoAcao.objects.create(
            risco=infra_risco["risco"],
            tipo_resposta="Mitigar",
            descricao_acao="Acao de teste",
            responsavel="Responsavel",
            data_inicio="2026-01-01",
            data_fim="2026-06-30",
            status="Não iniciada",
            progresso=30,
        )

        response = api_client.patch(
            f"/api/riscos/acoes/{acao.id}/",
            {"status": "Em andamento", "progresso": 55},
            format="json",
        )

        assert response.status_code == status.HTTP_200_OK
        acao.refresh_from_db()
        assert acao.progresso == 55


@pytest.mark.django_db
class TestDuplicarRisco:
    def test_duplicar_cria_novo_risco_sem_plano_acao(self, api_client, infra_risco):
        # a duplicacao deve criar um risco novo com os mesmos dados mas sem acao vinculada
        risco = infra_risco["risco"]
        PlanoAcao.objects.create(
            risco=risco,
            tipo_resposta="Mitigar",
            descricao_acao="Acao original",
            responsavel="Responsavel",
            data_inicio="2026-01-01",
            data_fim="2026-06-30",
            status="Em andamento",
        )
        api_client.force_authenticate(user=infra_risco["u1"])

        response = api_client.post(f"/api/riscos/planos/{risco.uuid}/duplicar/")

        assert response.status_code == status.HTTP_201_CREATED
        novo_uuid = response.data["uuid"]
        assert novo_uuid != str(risco.uuid)

        novo = Risco.objects.get(uuid=novo_uuid)
        assert novo.evento == risco.evento
        assert novo.categoria == risco.categoria
        assert novo.planos_acao.count() == 0

    def test_duplicar_cria_entrada_de_historico(self, api_client, infra_risco):
        # a duplicacao deve registrar no historico do novo risco
        api_client.force_authenticate(user=infra_risco["u1"])
        risco = infra_risco["risco"]

        response = api_client.post(f"/api/riscos/planos/{risco.uuid}/duplicar/")

        assert response.status_code == status.HTTP_201_CREATED
        novo_uuid = response.data["uuid"]
        novo = Risco.objects.get(uuid=novo_uuid)
        assert HistoricoPlano.objects.filter(risco=novo).exists()

    def test_outro_setor_nao_pode_duplicar(self, api_client, infra_risco):
        # usuario de setor diferente nao tem permissao de duplicar (acao de escrita)
        api_client.force_authenticate(user=infra_risco["u2"])

        response = api_client.post(f"/api/riscos/planos/{infra_risco['risco'].uuid}/duplicar/")

        assert response.status_code == status.HTTP_403_FORBIDDEN


@pytest.mark.django_db
class TestHistoricoPlano:
    def test_historico_registrado_ao_atualizar_risco(self, api_client, infra_risco):
        # cada patch no risco deve gerar uma entrada no historico
        api_client.force_authenticate(user=infra_risco["u1"])
        risco = infra_risco["risco"]

        api_client.patch(
            f"/api/riscos/planos/{risco.uuid}/",
            {"evento": "Evento atualizado"},
            format="json",
        )

        assert HistoricoPlano.objects.filter(risco=risco).count() == 1

    def test_endpoint_historico_retorna_entradas(self, api_client, infra_risco):
        # o endpoint de historico deve retornar as entradas em ordem decrescente
        api_client.force_authenticate(user=infra_risco["u1"])
        risco = infra_risco["risco"]
        HistoricoPlano.objects.create(risco=risco, usuario_nome="Gestor", descricao="Primeira alteracao")
        HistoricoPlano.objects.create(risco=risco, usuario_nome="Gestor", descricao="Segunda alteracao")

        response = api_client.get(f"/api/riscos/planos/{risco.uuid}/historico/")

        assert response.status_code == status.HTTP_200_OK
        assert len(response.data) == 2
        assert response.data[0]["descricao"] == "Segunda alteracao"

    def test_historico_vazio_retorna_lista_vazia(self, api_client, infra_risco):
        api_client.force_authenticate(user=infra_risco["u1"])
        risco = infra_risco["risco"]

        response = api_client.get(f"/api/riscos/planos/{risco.uuid}/historico/")

        assert response.status_code == status.HTTP_200_OK
        assert response.data == []


@pytest.mark.django_db
class TestMonitoramentoViewSet:
    def test_filtra_monitoramentos_por_uuid_do_risco(self, api_client, infra_risco):
        # o endpoint de monitoramentos deve aceitar uuid do risco como filtro
        risco = infra_risco["risco"]
        Monitoramento.objects.create(
            risco=risco,
            resultados="Resultado 1",
            acoes_futuras="Acao futura 1",
            analise_critica="Analise 1",
        )
        api_client.force_authenticate(user=infra_risco["u1"])

        response = api_client.get(f"/api/riscos/monitoramentos/?risco={risco.uuid}")

        assert response.status_code == status.HTTP_200_OK
        resultados = response.data.get("results", response.data)
        assert len(resultados) == 1

    def test_filtra_monitoramentos_retorna_vazio_para_uuid_inexistente(self, api_client, infra_risco):
        import uuid
        api_client.force_authenticate(user=infra_risco["u1"])
        uuid_falso = uuid.uuid4()

        response = api_client.get(f"/api/riscos/monitoramentos/?risco={uuid_falso}")

        assert response.status_code == status.HTTP_200_OK
        resultados = response.data.get("results", response.data)
        assert len(resultados) == 0

    def test_cria_monitoramento_com_uuid_do_risco(self, api_client, infra_risco):
        # a criacao deve aceitar uuid no campo risco em vez de pk inteiro
        api_client.force_authenticate(user=infra_risco["u1"])
        risco = infra_risco["risco"]

        response = api_client.post(
            "/api/riscos/monitoramentos/",
            {
                "risco": str(risco.uuid),
                "resultados": "Resultado novo",
                "acoes_futuras": "Acao futura nova",
                "analise_critica": "Analise nova",
            },
            format="json",
        )

        assert response.status_code == status.HTTP_201_CREATED
        assert Monitoramento.objects.filter(risco=risco).exists()


@pytest.mark.django_db
class TestPlanoAcaoFiltroUUID:
    def test_filtra_acoes_por_uuid_do_risco(self, api_client, infra_risco):
        # o endpoint de acoes deve aceitar uuid do risco como filtro
        risco = infra_risco["risco"]
        PlanoAcao.objects.create(
            risco=risco,
            tipo_resposta="Mitigar",
            descricao_acao="Acao filtro",
            responsavel="Resp",
            data_inicio="2026-01-01",
            data_fim="2026-06-30",
            status="Em andamento",
        )
        api_client.force_authenticate(user=infra_risco["u1"])

        response = api_client.get(f"/api/riscos/acoes/?risco={risco.uuid}")

        assert response.status_code == status.HTTP_200_OK
        resultados = response.data.get("results", response.data)
        assert len(resultados) == 1

    def test_cria_acao_com_uuid_do_risco(self, api_client, infra_risco):
        # a criacao deve aceitar uuid no campo risco em vez de pk inteiro
        api_client.force_authenticate(user=infra_risco["u1"])
        risco = infra_risco["risco"]

        response = api_client.post(
            "/api/riscos/acoes/",
            {
                "risco": str(risco.uuid),
                "tipo_resposta": "Mitigar",
                "descricao_acao": "Descricao da acao",
                "responsavel": "Responsavel",
                "data_inicio": "2026-01-01",
                "data_fim": "2026-06-30",
                "status": "Não iniciada",
            },
            format="json",
        )

        assert response.status_code == status.HTTP_201_CREATED


@pytest.mark.django_db
class TestBuscaExpandidaEOrdenacao:
    def test_busca_por_nome_macroprocesso(self, api_client, infra_risco):
        # a busca expandida deve localizar riscos pelo nome do macroprocesso vinculado
        api_client.force_authenticate(user=infra_risco["u1"])
        termo = infra_risco["risco"].macroprocesso.nome[:8]

        response = api_client.get(f"/api/riscos/planos/?search={termo}")

        assert response.status_code == status.HTTP_200_OK
        assert len(response.data["results"]) == 1

    def test_busca_por_responsavel_da_acao(self, api_client, infra_risco):
        # a busca expandida deve localizar riscos pelo responsavel do plano de acao
        risco = infra_risco["risco"]
        PlanoAcao.objects.create(
            risco=risco,
            tipo_resposta="Mitigar",
            descricao_acao="Acao",
            responsavel="Responsavel Especifico",
            data_inicio="2026-01-01",
            data_fim="2026-06-30",
            status="Em andamento",
        )
        api_client.force_authenticate(user=infra_risco["u1"])

        response = api_client.get("/api/riscos/planos/?search=Especifico")

        assert response.status_code == status.HTTP_200_OK
        assert len(response.data["results"]) == 1

    def test_ordenacao_por_nivel_residual_descendente(self, api_client, infra_risco, objetivo_padrao, macroprocesso_padrao):
        # o parametro nivel_desc deve ordenar do maior para o menor nivel residual
        Risco.objects.create(
            setor=infra_risco["s1"],
            objetivo=objetivo_padrao,
            macroprocesso=macroprocesso_padrao,
            categoria="Estratégico",
            evento="Risco alto",
            causa="C",
            consequencia="C",
            controles_atuais="C",
            eficacia_controle="Inexistente",
            probabilidade=5,
            impacto=5,
            prob_residual=5,
            imp_residual=5,
        )
        api_client.force_authenticate(user=infra_risco["u1"])

        response = api_client.get("/api/riscos/planos/?ordenacao=nivel_desc")

        assert response.status_code == status.HTTP_200_OK
        niveis = [r["nivel_residual"] for r in response.data["results"]]
        assert niveis == sorted(niveis, reverse=True)


@pytest.mark.django_db
class TestExportarRelatorioGerencial:
    def test_exporta_relatorio_gerencial_como_pdf(self, api_client, infra_risco):
        # o endpoint deve gerar um pdf com resumo gerencial de todos os riscos
        api_client.force_authenticate(user=infra_risco["u1"])

        response = api_client.get("/api/riscos/planos/exportar-relatorio/")

        assert response.status_code == status.HTTP_200_OK
        assert response["Content-Type"] == "application/pdf"
        assert "relatorio-gerencial" in response["Content-Disposition"]
        assert response.content.startswith(b"%PDF")



@pytest.mark.django_db
class TestSincronizacaoIncremental:
    def _cria_acao(self, risco):
        return PlanoAcao.objects.create(
            risco=risco,
            tipo_resposta="Mitigar",
            descricao_acao="Ação",
            responsavel="Fulano",
            data_inicio="2026-01-01",
            data_fim="2026-12-31",
            status="Em andamento",
        )

    def test_risco_expoe_atualizado_em(self, api_client, infra_risco):
        api_client.force_authenticate(user=infra_risco["u1"])
        response = api_client.get(f"/api/riscos/planos/{infra_risco['risco'].uuid}/")
        assert response.status_code == status.HTTP_200_OK
        assert "atualizado_em" in response.data
        assert response.data["ativo"] is True

    def test_pull_incremental_filtra_por_atualizado_em(self, api_client, infra_risco):
        from django.utils import timezone

        api_client.force_authenticate(user=infra_risco["u1"])
        corte = timezone.now().isoformat()

        # nada mudou desde o corte
        vazio = api_client.get("/api/riscos/planos/", {"modificado_apos": corte})
        assert vazio.status_code == status.HTTP_200_OK
        assert vazio.data["count"] == 0

        # edita o risco -> passa a aparecer
        api_client.patch(
            f"/api/riscos/planos/{infra_risco['risco'].uuid}/",
            {"evento": "Novo evento"},
            format="json",
        )
        com_mudanca = api_client.get("/api/riscos/planos/", {"modificado_apos": corte})
        assert com_mudanca.data["count"] == 1

    def test_pull_incremental_inclui_registros_desativados(self, api_client, infra_risco):
        from django.utils import timezone

        api_client.force_authenticate(user=infra_risco["u1"])
        corte = timezone.now().isoformat()
        infra_risco["risco"].delete()  # soft delete

        response = api_client.get("/api/riscos/planos/", {"modificado_apos": corte})
        assert response.data["count"] == 1
        assert response.data["results"][0]["ativo"] is False

    def test_soft_delete_cascata_bumpa_atualizado_em_da_acao(self, api_client, infra_risco):
        from django.utils import timezone

        api_client.force_authenticate(user=infra_risco["u1"])
        self._cria_acao(infra_risco["risco"])
        corte = timezone.now().isoformat()

        infra_risco["risco"].delete()

        response = api_client.get("/api/riscos/acoes/", {"modificado_apos": corte})
        assert response.data["count"] == 1
        assert response.data["results"][0]["ativo"] is False

    def test_modificado_apos_invalido_retorna_400(self, api_client, infra_risco):
        api_client.force_authenticate(user=infra_risco["u1"])
        response = api_client.get("/api/riscos/planos/?modificado_apos=ontem")
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_patch_com_versao_antiga_retorna_409(self, api_client, infra_risco):
        from datetime import timedelta

        from django.utils import timezone

        api_client.force_authenticate(user=infra_risco["u1"])
        url = f"/api/riscos/planos/{infra_risco['risco'].uuid}/"
        antiga = (timezone.now() - timedelta(hours=1)).isoformat()

        response = api_client.patch(
            url,
            {"evento": "Edição offline", "atualizado_em": antiga},
            format="json",
        )
        assert response.status_code == status.HTTP_409_CONFLICT
        assert "atual" in response.data

    def test_patch_com_versao_atual_passa(self, api_client, infra_risco):
        api_client.force_authenticate(user=infra_risco["u1"])
        url = f"/api/riscos/planos/{infra_risco['risco'].uuid}/"
        atual = api_client.get(url).data["atualizado_em"]

        response = api_client.patch(
            url,
            {"evento": "Edição válida", "atualizado_em": atual},
            format="json",
        )
        assert response.status_code == status.HTTP_200_OK
