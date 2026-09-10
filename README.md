# Gestão de Risco UFSM — API + App Mobile

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![Django](https://img.shields.io/badge/Django-5.2-092E20)
![DRF](https://img.shields.io/badge/DRF-3.15-A30000)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169E1)
![Tests](https://img.shields.io/badge/tests-214%20backend%20%2B%2082%20mobile-brightgreen)

App **Android (Flutter/Dart)** para gestão de riscos institucionais, com API **REST em Django REST Framework**. Cadastro de riscos por unidade organizacional, planos de tratamento, monitoramento, dashboard analítico e **operação offline com sincronização**.

Desenvolvido para a disciplina de Programação Mobile, a partir do sistema web *Gestão de Risco UFSM* — repositório independente do sistema em produção.

---

## Preview

| Lista de riscos (tema claro) | Dashboard (tema escuro) |
|:---:|:---:|
| <img src="docs/images/previewapp.png" width="280"> | <img src="docs/images/previewapp2.jpg" width="280"> |

---

## Tecnologias

| Camada | Tecnologias |
|---|---|
| **Mobile** | Flutter / Dart, `dio`, `go_router`, `sqflite` (cache offline), `flutter_secure_storage`, `geolocator` + `geocoding` (GPS), `image_picker` (câmera), `url_launcher`, `share_plus`, `connectivity_plus`, `intl` |
| **Backend** | Django 5.2, Django REST Framework 3.15, `django-cors-headers`, `Pillow` + `django-storages` (upload de fotos) |
| **Segurança** | `TokenAuthentication` do DRF (login por SIAPE), RBAC de 3 papéis, permissão por vínculo de setor, concorrência otimista (HTTP 409) |
| **Banco de Dados** | PostgreSQL 16, migrations do Django |
| **Documentação** | `docs/api.md` (endpoints, payloads, filtros) · `docs/banco-de-dados.md` (modelo de dados) |
| **Relatórios** | `openpyxl` (Excel) e `reportlab` (PDF) — geração nativa de planilhas e relatórios |
| **Infraestrutura** | Docker, Docker Compose (banco + API + MinIO/S3, seed automático) |

---

## Principais Funcionalidades

1. **Gestão de Riscos:**
   - Cadastro completo por unidade organizacional, `ObjetivoPDI` e `Macroprocesso`, com categoria (`Operacional`, `Estratégico`, `Integridade`, `Imagem`, `Financeiro`).
   - Escalas 1–5 de probabilidade e impacto, inerente e residual. `nível_risco` e `nível_residual` (produto prob × impacto) **calculados no backend** — read-only na API.
   - Filtros por unidade, categoria, período e busca textual; ordenação por nível ou prazo.
   - Aviso quando o risco residual fica maior que o inerente.
   - **Localização por GPS** (opcional): captura das coordenadas de onde o risco foi identificado no campus, com o endereço aproximado resolvido por *geocoding* reverso e link "Ver no mapa".

2. **Planos de Ação (5W2H):**
   - Tipo de resposta (`Mitigar`, `Evitar`, `Transferir`, `Aceitar`), responsável, parceiros, datas, status e progresso (%).
   - Progresso vai a 100% automaticamente ao concluir.

3. **Monitoramento:**
   - Registro de acompanhamento (resultados, ações futuras, análise crítica) por risco.
   - **Foto de evidência** tirada pela câmera no momento da verificação; armazenada em *object storage* (MinIO/S3) e enviada por `multipart` — inclusive de forma diferida quando o registro é criado offline.

4. **Dashboard & Analytics:**
   - KPIs (total, críticos, cobertura de monitoramento, taxa de mitigação).
   - Distribuição por categoria e por nível, **matriz de risco residual 5×5**, ranking de unidades por exposição, riscos prioritários.
   - Todo o payload respeita os mesmos filtros da listagem.

5. **Estrutura Estratégica (PDI):**
   - CRUD de `DesafioPDI` → `ObjetivoPDI` e `Macroprocesso` (somente administrador).

6. **Equipe & Administração:**
   - Gestão de membros de uma unidade por SIAPE (`gestor_adm`).
   - Cadastro/edição/(re)ativação de gestores e de unidades organizacionais (administrador).
   - Trilha `HistoricoPlano` — log *append-only*: toda alteração de risco, plano ou monitoramento gera uma entrada.

7. **Exportações:**
   - Planilha Excel da lista filtrada, relatório gerencial em PDF, e Excel/PDF de um risco individual — compartilhados via *share sheet* do Android.

8. **Recursos Nativos do Celular:**
   - **GPS** (`geolocator`): posição atual para georreferenciar o risco, com permissão em tempo de execução.
   - **Geocoding reverso** (`geocoding`): coordenadas → endereço legível, usando o geocoder nativo do Android (sem chave de API).
   - **Câmera** (`image_picker`): foto de evidência do monitoramento, capturada em campo.
   - **App de mapas do sistema** via URI `geo:` para abrir a localização do risco.
   - **Armazenamento seguro** (`flutter_secure_storage`): token de sessão no Keystore do Android.

9. **Modo Offline + Sincronização:**
   - Cache local em `sqflite`; a lista, o detalhe e o dashboard funcionam sem rede a partir dos dados salvos.
   - **Escritas otimistas** aplicadas na hora e enfileiradas; a fila colapsa mutações redundantes.
   - **Pull incremental** (`?modificado_apos=`) e **concorrência otimista** — um `PATCH` com versão antiga recebe `409` e o servidor vence.
   - Foto de evidência tirada offline fica no dispositivo e sobe junto quando o monitoramento sincroniza.
   - Faixa de status: "offline · N alterações aguardando envio", "sincronizando…", conflitos descartados.

10. **Segurança & Controle de Acesso:**
   - **RBAC (3 papéis)**, detalhado abaixo. `PertenceAoSetorDoRisco`: escrita só nos setores do usuário — gestor de outro setor recebe `403`.
   - **Bloqueio automático:** gestor sem nenhuma unidade há mais de 7 dias fica inativo (`sem_equipe_desde`).
   - **Recuperação de senha:** código de 6 dígitos válido por 1 minuto, de uso único; um novo pedido invalida o anterior. Código errado, expirado ou já usado devolvem a mesma mensagem genérica.
   - **Tema Claro / Escuro / Sistema:** seletor no Perfil, com persistência.

---

## Perfis de Acesso

- **`admin` (`is_superuser`):** acesso irrestrito — cadastro de gestores, gestão de unidades, estrutura do PDI, registros inativos, todos os riscos.
- **`gestor_adm` (`cargo = gestor_adm`):** tudo do gestor + adicionar/remover membros das equipes das suas unidades.
- **`gestor` (padrão):** CRUD de riscos, planos e monitoramentos **apenas nas unidades às quais está vinculado**; leitura liberada de qualquer risco.

Sem token de autenticação, endpoints protegidos retornam `401`; autenticado sem o perfil necessário, `403`.

---

## Modelagem do Banco de Dados

Modelagem conceitual e lógica na ferramenta **brModelo** — arquivos-fonte em [`db/`](db/).

### Modelo Conceitual (MER)

Entidades (`USUARIO`, `SETOR`, `RISCO`, `PLANO_ACAO`, `MONITORAMENTO`, `HISTORICO_PLANO`, `DESAFIO_PDI`, `OBJETIVO_PDI`, `MACROPROCESSO`, `CODIGO_RECUPERACAO`), atributos e cardinalidades (1:N e a N:N `usuario × setor`).

![Modelo Conceitual (MER)](docs/images/modelo-conceitual.png)

### Modelo Lógico (DER)

Esquema relacional com PKs, FKs, os campos de *soft delete* (`ativo`) e o cursor de sincronização (`atualizado_em`), além da tabela associativa `usuario_setores`.

![Modelo Lógico (DER)](docs/images/modelo-logico.png)

Descrição completa das tabelas e regras em [docs/banco-de-dados.md](docs/banco-de-dados.md).

---

## Como Rodar

### API — com Docker (recomendado)

```bash
git clone git@github.com:matheuskotayko/gestao-riscos-mobile.git
cd gestao-riscos-mobile
docker compose up --build
```

A API sobe em **http://localhost:8000** (e o MinIO em **:9000**, console **:9001**) — o entrypoint roda `migrate` e `seed_apresentacao` automaticamente. As fotos de evidência ficam no bucket `gestao-risco`; sem as variáveis `MINIO_*` no `.env`, o Django guarda os arquivos localmente em `backend/media/`.

### API — desenvolvimento local (sem Docker)

```bash
python -m venv .venv && source .venv/bin/activate   # Windows: .venv\Scripts\Activate.ps1
pip install -r backend/requirements-dev.txt
cp .env.example .env
docker compose up -d db                              # só o Postgres (localhost:5433)
cd backend && python manage.py migrate && python manage.py runserver
```

Dados de demonstração a qualquer momento:

```bash
python backend/manage.py seed_apresentacao
```

### App Mobile

```bash
cd mobile
cp .env.example .env          # API_BASE_URL=http://10.0.2.2:8000 (emulador Android → host)
flutter pub get
flutter run                   # precisa de emulador/dispositivo Android
```

> Do emulador Android use `http://10.0.2.2:8000`. De um celular físico, aponte o `.env` para o IP da máquina na rede (`http://192.168.x.x:8000`).
> As fotos de evidência são servidas pelo MinIO em `:9000` — o mesmo host da API, porta 9000.

### Acesso Inicial

```
SIAPE: 202512603
Senha: 12345678
```

(Administrador criado pelo seed. Os demais gestores de demonstração usam a senha `12345678`.)

---

## Documentação da API

- **Endpoints, autenticação, payloads e filtros:** [docs/api.md](docs/api.md)
- **Modelo de dados:** [docs/banco-de-dados.md](docs/banco-de-dados.md)
- **Navegável no navegador:** com a API rodando, a raiz de cada rota (`http://localhost:8000/api/riscos/`, `http://localhost:8000/api/usuarios/`) abre a *browsable API* do DRF.

---

## Testes Automatizados

**Backend — 214 testes** (pytest, com cobertura; reusa o banco entre execuções):

```bash
cd backend && pytest
```

Cobre a matriz de autorização (`401` vs `403` por endpoint de escrita + varredura por reflexão), invariantes de domínio com caminhos negativos, edge cases, e a fronteira de segurança da recuperação de senha.

**Mobile — 82 testes** (unitários + widget, sem emulador):

```bash
cd mobile && flutter test
```

Cobre a camada de dados (cache/sync, filtros, analítica offline, upload de foto por `multipart`), os recursos nativos (captura de GPS, geocoding reverso), os estados de tela, e a regressão dos bugs de sincronização.

---

## Estrutura do Repositório

```
backend/   API Django REST — apps `usuarios` (identidade, unidades, equipes) e `riscos` (domínio)
mobile/    App Flutter — core/ data/ features/ routes/
docs/      Documentação da API e do banco + diagramas exportados (docs/images/)
db/        Fontes brModelo (.brM3) — modelo conceitual e lógico
```

---

## Licença

Distribuído sob a licença MIT. Veja [LICENSE](LICENSE) para o texto completo.
