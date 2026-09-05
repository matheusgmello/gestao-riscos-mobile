# API

## Visao geral

O backend expoe uma API REST organizada em dois grandes grupos:

- `/api/usuarios/`
- `/api/riscos/`

O projeto utiliza **Token Authentication** com Django REST Framework. Rotas publicas sao apenas login, recuperacao de senha e listagem simples de unidades. Todas as demais exigem token valido no header `Authorization: Token <token>`.

---

## Rotas de usuarios

### Autenticacao

- `POST /api/usuarios/login/`
  - autentica um usuario com `siape` e `senha`;
  - retorna o token de acesso e os dados do usuario.

- `GET /api/usuarios/me/`
  - retorna os dados do usuario autenticado: `uuid`, `siape`, `nome`, `email`, `setores`, `cargo`, `ativo`, `is_superuser` e `sem_equipe_desde`.

- `PATCH /api/usuarios/me/`
  - atualiza e-mail e senha do usuario autenticado;
  - o campo `id_setores` (unidade/departamento) so pode ser alterado pelo superusuario; gestores comuns nao podem trocar o proprio setor via este endpoint.

---

### Cadastro de gestores (restrito a superusuario)

- `POST /api/usuarios/registro/`
  - cria um novo gestor no sistema;
  - **requer autenticacao e perfil superusuario**;
  - payload: `siape`, `nome`, `email`, `senha`, `id_setores`, `cargo`;
  - campo `cargo`: `"gestor"` (padrao) ou `"gestor_adm"`;
  - retorna os dados do usuario criado (sem token).

---

### Gestao administrativa de usuarios (superusuario only)

- `GET /api/usuarios/gestores/`
  - lista todos os usuarios cadastrados (ativos e inativos);
  - suporta busca por `search` (nome, SIAPE ou e-mail) e paginacao.

- `DELETE /api/usuarios/gestores/{uuid}/`
  - **soft delete**: desativa o usuario (ativo=False) sem remover do banco;
  - nao e permitido desativar superusuarios ou a propria conta.

- `POST /api/usuarios/gestores/{uuid}/reativar/`
  - reativa um usuario previamente desativado.

---

### Unidades e equipe

- `GET /api/usuarios/setores/` e `GET /api/usuarios/setores/{id}/`
  - listam/retornam as unidades/departamentos disponiveis;
  - endpoints publicos, nao exigem autenticacao.

- `POST/PUT/PATCH/DELETE /api/usuarios/setores/` e `.../{id}/desativar/`
  - criacao, edicao e (des)ativacao de unidades;
  - **exigem superusuario** — sem token retorna `401`, gestor comum retorna `403`.

- `GET /api/usuarios/setores/admin/`
  - listagem administrativa completa com busca, filtros e paginacao;
  - requer superusuario.

#### Parametros de filtro — `GET /api/usuarios/setores/admin/`

| Parametro   | Tipo   | Descricao                                 |
|-------------|--------|-------------------------------------------|
| `search`    | string | Busca por nome, sigla ou label da unidade |
| `centro`    | string | Filtra pelo campo `sigla_centro`          |
| `tipo`      | string | Filtra pelo campo `tipo_unidade`          |
| `page`      | int    | Numero da pagina (default: 1)             |
| `page_size` | int    | Itens por pagina (default: 20)            |

- `GET /api/usuarios/setores/{id}/membros/`
  - lista os membros vinculados ao setor.

- `POST /api/usuarios/setores/{id}/adicionar_membro/`
  - adiciona um usuario ao setor pelo `siape`;
  - **requer cargo `gestor_adm` ou superusuario**;
  - ao adicionar, limpa o campo `sem_equipe_desde` do usuario adicionado.

- `POST /api/usuarios/setores/{id}/remover_membro/`
  - remove um usuario do setor;
  - **requer cargo `gestor_adm` ou superusuario**;
  - se o usuario ficar sem nenhum setor, registra `sem_equipe_desde` com a data/hora atual; apos 7 dias sem setor, o acesso e bloqueado automaticamente.

---

### Recuperacao de senha

- `POST /api/usuarios/recuperar-senha/enviar/`
  - envia o codigo de recuperacao para o e-mail informado.

- `POST /api/usuarios/recuperar-senha/validar/`
  - valida o codigo recebido (expira em 1 minuto).

- `POST /api/usuarios/recuperar-senha/redefinir/`
  - redefine a senha com o codigo validado.

---

## Rotas de riscos

### Estrutura estrategica (PDI)

- `GET /api/riscos/desafios/`, `GET /api/riscos/objetivos/`, `GET /api/riscos/macroprocessos/`
  - listam a estrutura do PDI; leitura para qualquer gestor logado.

- `POST/PUT/PATCH/DELETE` nesses mesmos recursos
  - **exigem superusuario** — sem token `401`, gestor comum `403`.

---

### Planos de risco (CRUD principal)

- `GET /api/riscos/planos/`
  - lista os planos de risco ativos com suporte a filtros, busca e paginacao;
  - superusuarios podem incluir registros desativados com `?incluir_inativos=true`.

- `POST /api/riscos/planos/`
  - cria um novo plano de risco (apenas para setores do usuario).

- `GET /api/riscos/planos/{uuid}/`
  - retorna um plano especifico com todos os detalhes.

- `PATCH /api/riscos/planos/{uuid}/`
  - atualiza campos de um plano existente (apenas do setor do usuario).

- `DELETE /api/riscos/planos/{uuid}/`
  - **soft delete**: desativa o plano (ativo=False) e propaga a desativacao para PlanoAcao e Monitoramento vinculados;
  - o registro permanece no banco e pode ser consultado por superusuarios.

- `POST /api/riscos/planos/{uuid}/duplicar/`
  - cria uma copia do plano de risco, incluindo os planos de acao vinculados;
  - retorna o novo plano com seu proprio UUID.

- `GET /api/riscos/planos/{uuid}/historico/`
  - retorna o historico de alteracoes do plano em ordem cronologica decrescente;
  - cada entrada contem `usuario_nome`, `data_hora` e `descricao` da acao realizada.

#### Parametros de filtro — `GET /api/riscos/planos/`

| Parametro          | Tipo    | Descricao                                                                  |
|--------------------|---------|----------------------------------------------------------------------------|
| `search`           | string  | Busca por evento, causa, consequencia, macroprocesso, objetivo e responsavel |
| `setor`            | int     | Filtra pelo ID da unidade/setor                                            |
| `categoria`        | string  | Filtra pela categoria do risco                                             |
| `data_inicio`      | date    | Filtra planos com data de inicio >= valor (ISO)                            |
| `data_fim`         | date    | Filtra planos com data de fim <= valor (ISO)                               |
| `ordenacao`        | string  | `asc`, `desc`, `nivel_asc`, `nivel_desc`, `prazo_asc` ou `prazo_desc`     |
| `page`             | int     | Numero da pagina                                                           |
| `incluir_inativos` | boolean | `true` para incluir desativados (somente superusuario)                     |
| `modificado_apos`  | datetime| ISO 8601. Retorna so os registros com `atualizado_em` maior que o valor, **incluindo os desativados** (para o cliente propagar o soft delete). Formato invalido responde `400`. |

---

### Sincronizacao incremental (app mobile)

- `Risco`, `PlanoAcao` e `Monitoramento` expoem `atualizado_em` (ISO 8601, UTC) e `ativo` em todas as respostas. `atualizado_em` e atualizado a cada gravacao, inclusive quando o registro e desativado (direto ou em cascata).
- **Pull incremental:** `GET /api/riscos/planos/?modificado_apos=<iso8601>` (tambem em `acoes/` e `monitoramentos/`). O cliente guarda o maior `atualizado_em` recebido e usa na proxima chamada.
- **Concorrencia otimista:** ao enviar `PATCH` de risco/acao/monitoramento, inclua no payload o `atualizado_em` que o cliente tinha ao editar. Se o servidor tiver uma versao mais nova, responde `409 Conflict` com `{"erro": "...", "atual": <registro atualizado>}` e nenhuma alteracao e aplicada. Sem o campo `atualizado_em` no payload, o `PATCH` sempre sobrescreve.

---

### Dashboard gerencial

- `GET /api/riscos/planos/dashboard/`
  - retorna dados consolidados do sistema para exibicao na dashboard.

#### Parametros de filtro — `GET /api/riscos/planos/dashboard/`

| Parametro     | Tipo   | Descricao                          |
|---------------|--------|------------------------------------|
| `setor`       | int    | Filtra dados pelo ID da unidade    |
| `data_inicio` | date   | Filtra planos a partir dessa data  |
| `data_fim`    | date   | Filtra planos ate essa data        |
| `search`      | string | Busca textual sobre os planos      |

---

### Mapa de riscos (analytics)

- `GET /api/riscos/planos/mapa-analytics/`
  - retorna dados analiticos para o mapa de riscos.

#### Parametros de filtro — `GET /api/riscos/planos/mapa-analytics/`

| Parametro   | Tipo   | Descricao                      |
|-------------|--------|--------------------------------|
| `setor`     | int    | Filtra pelo ID da unidade      |
| `categoria` | string | Filtra pela categoria do risco |

---

### Estatisticas resumidas

- `GET /api/riscos/planos/estatisticas/`
  - retorna contagens rapidas de riscos por nivel.

---

### Exportacoes

- `GET /api/riscos/planos/exportar-excel/`
  - exporta a lista filtrada de planos em formato Excel (`.xlsx`); aceita os mesmos parametros de filtro da listagem.

- `GET /api/riscos/planos/exportar-relatorio/`
  - exporta um relatorio gerencial consolidado em formato PDF, com distribuicao por categoria, unidade e nivel de risco.

- `GET /api/riscos/planos/{uuid}/exportar-excel/`
  - exporta o plano individual em formato Excel.

- `GET /api/riscos/planos/{uuid}/exportar-pdf/`
  - exporta o plano individual em formato PDF.

---

### Planos de acao e monitoramentos

- `GET|POST /api/riscos/acoes/`
  - lista e cria planos de acao vinculados a um risco;
  - suporta filtro `?risco=<uuid>` para retornar apenas as acoes de um plano especifico;
  - no payload de criacao, o campo `risco` aceita o UUID do risco (nao o ID interno);
  - campo `progresso` (0–100): calculado automaticamente com base no status da acao, mas pode ser sobrescrito manualmente.

- `GET|PATCH|DELETE /api/riscos/acoes/{id}/`
  - detalha, atualiza ou desativa (soft delete) um plano de acao.
  - `GET` aceita `?modificado_apos=<iso8601>` (pull incremental, inclui desativados).

- `GET|POST /api/riscos/monitoramentos/`
  - lista e cria registros de monitoramento;
  - suporta filtro `?risco=<uuid>` para retornar apenas os monitoramentos de um plano especifico;
  - `GET` aceita `?modificado_apos=<iso8601>` (pull incremental, inclui desativados);
  - no payload de criacao, o campo `risco` aceita o UUID do risco (nao o ID interno).

- `GET|PATCH|DELETE /api/riscos/monitoramentos/{id}/`
  - detalha, atualiza ou desativa (soft delete) um monitoramento.

---

## Observacoes importantes

- a listagem de unidades (`/api/usuarios/setores/`) e publica e nao exige autenticacao;
- o cadastro de novos usuarios (`/api/usuarios/registro/`) exige superusuario — nao ha auto-cadastro publico;
- adicionar e remover membros de equipe exige `cargo = gestor_adm` ou superusuario;
- operacoes `DELETE` nos recursos de riscos sao **soft delete**: os dados permanecem no banco marcados como `ativo=False`;
- campos `nivel_risco` e `nivel_residual` sao calculados automaticamente pelo backend no `save()` do model;
- identificadores publicos (URLs, respostas da API) usam sempre `uuid` — IDs internos sequenciais nunca sao expostos ao cliente;
- a edicao de riscos (e a criacao de `acoes`/`monitoramentos`) respeita o vinculo do usuario com a unidade do risco (permissao `PertenceAoSetorDoRisco`); gestor de outro setor recebe `403`;
- a estrutura do PDI (`desafios`/`objetivos`/`macroprocessos`) e as unidades (`setores`) sao leitura para qualquer usuario mas so o superusuario escreve;
- sem token de autenticacao, endpoints protegidos retornam `401`; autenticado sem o perfil necessario, `403`;
- o codigo de recuperacao de senha vale 1 minuto, e de uso unico, e um novo pedido invalida o anterior; codigo errado, expirado ou ja usado devolvem a mesma mensagem generica;
- gestores sem setor ha mais de 7 dias tem o acesso bloqueado automaticamente; o campo `sem_equipe_desde` na resposta de `/api/usuarios/me/` indica quando o bloqueio comecara.
