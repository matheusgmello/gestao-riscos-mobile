# Banco de dados

## Diagrama de classes (UML) - Mermaid

Utilizando a ferramenta Mermaid para representar as principais classes persistidas no banco de dados e seus relacionamentos. Por se tratar de um diagrama UML conceitual, os atributos foram representados como privados (`-`) e os comportamentos como públicos (`+`).

```mermaid
classDiagram
    class Setor {
        -id: Integer
        -nome: String
        -sigla: String
    }

    class GerenciadorUsuario {
        <<service>>
        +createUser(siape: String, password: String): Usuario
        +createSuperuser(siape: String, password: String): Usuario
        +validarSiape(): void
        +definirPermissoesSuperusuario(): void
    }

    class Usuario {
        -id: Integer
        -siape: String
        -nome: String
        -email: String
        -senha: String
        -cargo: String
        -ativo: Boolean
        -equipe: Boolean
        -lastLogin: DateTime
        -isSuperuser: Boolean
        +isStaff(): Boolean
        +isActive(): Boolean
        +delete(): void
    }

    class UsuarioSetor {
        -id: Integer
    }

    class CodigoRecuperacao {
        -id: Integer
        -email: String
        -codigo: String
        -criadoEm: DateTime
        +gerarCodigo(): String
        +validarExpiracao(): Boolean
    }

    class DesafioPDI {
        -id: Integer
        -numero: Integer
        -descricao: String
        -ativo: Boolean
        +delete(): void
    }

    class ObjetivoPDI {
        -id: Integer
        -codigo: String
        -descricao: String
        -ativo: Boolean
        +delete(): void
    }

    class Macroprocesso {
        -id: Integer
        -nome: String
        -ativo: Boolean
        +delete(): void
    }

    class Risco {
        -id: Integer
        -categoria: CategoriaRisco
        -evento: String
        -causa: String
        -consequencia: String
        -controlesAtuais: String
        -eficaciaControle: EficaciaControle
        -probabilidade: Integer
        -impacto: Integer
        -nivelRisco: Integer
        -probResidual: Integer
        -impResidual: Integer
        -nivelResidual: Integer
        -ativo: Boolean
        +calcularNivelRisco(): Integer
        +calcularNivelResidual(): Integer
        +delete(): void
    }

    class PlanoAcao {
        -id: Integer
        -tipoResposta: TipoResposta
        -descricaoAcao: String
        -responsavel: String
        -parceiros: String
        -dataInicio: Date
        -dataFim: Date
        -status: StatusPlanoAcao
        -observacoes: String
        -ativo: Boolean
        +atualizarStatus(): void
        +delete(): void
    }

    class Monitoramento {
        -id: Integer
        -dataVerificacao: Date
        -resultados: String
        -acoesFuturas: String
        -analiseCritica: String
        -ativo: Boolean
        +registrarAnalise(): void
        +delete(): void
    }

    class CategoriaRisco {
        <<enumeration>>
        Operacional
        Estrategico
        Integridade
        Imagem
        Financeiro
    }

    class EficaciaControle {
        <<enumeration>>
        Inexistente
        Fraco
        Satisfatorio
        Forte
    }

    class TipoResposta {
        <<enumeration>>
        Mitigar
        Evitar
        Transferir
        Aceitar
    }

    class StatusPlanoAcao {
        <<enumeration>>
        NaoIniciada
        EmAndamento
        Concluida
        Atrasada
    }

    GerenciadorUsuario ..> Usuario : cria e gerencia
    Usuario "1" --> "0..*" UsuarioSetor : associa
    Setor "1" --> "0..*" UsuarioSetor : associa
    Usuario "1" --> "0..*" CodigoRecuperacao : solicita
    DesafioPDI "1" --> "0..*" ObjetivoPDI : organiza
    Setor "1" --> "0..*" Risco : possui
    ObjetivoPDI "1" --> "0..*" Risco : referencia
    Macroprocesso "1" --> "0..*" Risco : classifica
    Risco "1" --> "0..*" PlanoAcao : gera
    Risco "1" --> "0..*" Monitoramento : recebe
    Risco --> CategoriaRisco : categoria
    Risco --> EficaciaControle : eficaciaControle
    PlanoAcao --> TipoResposta : tipoResposta
    PlanoAcao --> StatusPlanoAcao : status

    note for GerenciadorUsuario "Serviço de suporte à criação de usuários no Django."
    note for Usuario "cargo: gestor (padrão) ou gestor_adm. Apenas gestor_adm pode gerenciar membros de equipe. delete() faz soft delete (ativo=False)."
    note for UsuarioSetor "Representa a associação muitos-para-muitos entre usuário e setor."
    note for CodigoRecuperacao "Usado no fluxo de envio, validação e redefinição de senha; o e-mail é mantido como dado operacional."
    note for Risco "delete() desativa o risco e propaga soft delete para PlanoAcao e Monitoramento vinculados."
    note for PlanoAcao "Representa o tratamento do risco em formato 5W2H. delete() faz soft delete."
    note for Monitoramento "Mantém o histórico de acompanhamento e análise do risco. delete() faz soft delete."
```

## Diagrama de casos de uso - Mermaid 

Utilizando a ferramenta Mermaid para representar os principais casos de uso relacionados às funções do sistema e às tabelas persistidas. 

```mermaid
flowchart LR
    gestor[Gestor]
    gestorAdm[Gestor Administrador]
    admin[Administrador]

    uc1((Autenticar no sistema))
    uc2((Cadastrar gestor))
    uc3((Gerenciar membros de equipe))
    uc4((Recuperar senha))
    uc5((Gerenciar perfil))
    uc6((Consultar setores))
    uc7((Cadastrar risco))
    uc8((Editar risco))
    uc9((Consultar planos de risco))
    uc10((Cadastrar plano de ação))
    uc11((Registrar monitoramento))
    uc12((Manter estrutura PDI))
    uc13((Desativar/Reativar gestor))

    gestor --> uc1
    gestor --> uc4
    gestor --> uc5
    gestor --> uc6
    gestor --> uc7
    gestor --> uc8
    gestor --> uc9
    gestor --> uc10
    gestor --> uc11

    gestorAdm --> uc1
    gestorAdm --> uc4
    gestorAdm --> uc5
    gestorAdm --> uc6
    gestorAdm --> uc7
    gestorAdm --> uc8
    gestorAdm --> uc9
    gestorAdm --> uc10
    gestorAdm --> uc11
    gestorAdm --> uc3

    admin --> uc2
    admin --> uc3
    admin --> uc12
    admin --> uc6
    admin --> uc9
    admin --> uc13

    uc1 --> db1[(USUARIOS)]
    uc2 --> db1
    uc3 --> db2[(USUARIO_SETORES)]
    uc3 --> db3[(SETORES)]
    uc4 --> db4[(CODIGOS_RECUPERACAO)]
    uc4 --> db1
    uc5 --> db1
    uc5 --> db2
    uc6 --> db3
    uc7 --> db5[(RISCOS)]
    uc7 --> db3
    uc7 --> db6[(OBJETIVOS_PDI)]
    uc7 --> db7[(MACROPROCESSOS)]
    uc8 --> db5
    uc9 --> db5
    uc9 --> db8[(PLANOS_ACAO)]
    uc9 --> db9[(MONITORAMENTOS)]
    uc10 --> db8
    uc11 --> db9
    uc12 --> db10[(DESAFIOS_PDI)]
    uc12 --> db6
    uc12 --> db7
    uc13 --> db1
```

## Diagrama entidade relacionamento (ER) (Padrão ISO/Min-max) - Dbdiagram.io

Utilizando a sintaxe do Dbdiagram.io para representar a estrutura relacional do banco com base nas tabelas atuais do projeto.

![Modelo ER](images/model-banco/modelo-er.png)

## Tecnologia utilizada

O sistema utiliza **PostgreSQL 16**, executado localmente por meio do Docker Compose.

## Configuração local

O container do banco é definido em `docker-compose.yml` com:

- banco: `gestao_risco_ufsm`;
- usuário: `postgres`;
- senha: `postgres`;
- porta externa: `5433`;
- porta interna do container: `5432`.

## Conexão usada pelo Django

O backend espera as seguintes variáveis no `.env`:

```env
DATABASE_NAME=gestao_risco_ufsm
DATABASE_USER=postgres
DATABASE_PASSWORD=postgres
DATABASE_HOST=localhost
DATABASE_PORT=5433
```

## Estrutura principal

As entidades mais relevantes do sistema incluem:

- `setores`
  - armazena as unidades administrativas vinculadas a usuários e riscos;
- `usuarios`
  - representa os gestores autenticados no sistema;
  - campo `cargo`: `gestor` (padrão) ou `gestor_adm` (pode gerenciar membros de equipe);
  - campo `ativo`: soft delete — usuário desativado não consegue autenticar;
- `usuario_setores`
  - tabela intermediária para o relacionamento muitos-para-muitos entre gestores e setores;
- `codigos_recuperacao`
  - registra códigos temporários usados no fluxo de recuperação de senha;
- `desafios_pdi`, `objetivos_pdi` e `macroprocessos`
  - representam a estrutura estratégica utilizada como referência para os riscos;
  - possuem campo `ativo` para soft delete;
- `riscos`
  - armazena os registros centrais do sistema e os níveis calculados;
  - campo `ativo`: soft delete — ao desativar um risco, planos de ação e monitoramentos vinculados também são desativados em cascata;
- `planos_acao`
  - guarda as ações de tratamento associadas a cada risco;
  - campo `ativo`: soft delete;
- `monitoramentos`
  - mantém o histórico de acompanhamento dos riscos;
  - campo `ativo`: soft delete.
