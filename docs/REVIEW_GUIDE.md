---
title: "AlfaMobi — Guia de Revisão"
subtitle: "Manual de teste por perfil"
author: "Equipe Alfa Soluções"
date: "26/04/2026"
version: "1.0.0+1"
geometry: "margin=2cm"
fontsize: 11pt
toc: true
toc-depth: 3
---

# AlfaMobi — Guia de Revisão

**Versão do app:** 1.0.0+1 · **Plataforma:** iOS / Android (Flutter) · **Data:** 26/04/2026

Este guia consolida a arquitetura do AlfaMobi, a matriz de perfis e permissões, e um checklist tela-a-tela para o revisor validar o comportamento esperado de cada usuário. Também cobre cenários negativos (token expirado, perfil rebaixado, multi-tenant leak) e os endpoints backend que cada tela exercita.

---

# 1. Visão geral

## 1.1 O que é o AlfaMobi

Cliente Flutter (iOS/Android) único que serve dois sistemas SaaS independentes:

| Sistema | Domínio | URL produção |
|---|---|---|
| **AlfaControl** | Controle de acesso de condomínios (Pessoas, Locais, Dispositivos, Perfis, Horários, Auditoria) | `https://control.alfasolucoes.cloud` |
| **AlfaGym** | Gestão de academias (Alunos, Check-in, Planos, Contratos, Financeiro, Treinos, Relatórios) | `https://gym.alfasolucoes.cloud` |

O app detecta o sistema pela escolha do usuário na tela de login (tile "AlfaControl" vs "AlfaGym") e roteia toda chamada HTTP para o backend correspondente. **Os dois sistemas nunca compartilham dados** — multi-tenant ao nível do produto.

## 1.2 Stack

- **Flutter** 3.11 / **Dart** 3.11
- **Provider** 6.x para estado (sem Riverpod/Bloc)
- **Dio** para HTTP
- **Firebase Cloud Messaging** para push (Android nativo; iOS depende de certificado APNs futuro)
- **flutter_secure_storage** + **shared_preferences** para tokens e preferências

## 1.3 Branding e tema

- **AlfaControl** usa paleta vermelha (#E53E3E)
- **AlfaGym** usa paleta laranja (#FF7A0D)
- **Dark theme** persistido (Sistema / Claro / Escuro) via `ThemeProvider`. Toggle no Menu.

## 1.4 Repositórios relacionados

- App Flutter: `/Users/rossinisantos/Documents/dev/alfa-mobile`
- Backend AlfaControl: `/Users/rossinisantos/Documents/dev/AlfaControl/backend` (Spring Boot + MySQL + Docker)
- Backend AlfaGym: `/Users/rossinisantos/Documents/dev/AlfaGym/backend/alfagym-api`
- Frontend web AlfaControl: `/Users/rossinisantos/Documents/dev/AlfaControl/frontend` (React)
- Frontend web AlfaGym: `/Users/rossinisantos/Documents/dev/AlfaGym/frontend/alfagym-web` (React/Vite)

---

# 2. Arquitetura de sessões

## 2.1 SessionType — categorias canônicas

Toda decisão de UI parte do `SessionType` derivado de `(produto, perfil)`. Implementação em `lib/features/auth/state/session_type.dart`.

| SessionType | Quando | Onde aterrissa |
|---|---|---|
| `superAdmin` | perfil ∈ {`super_admin`, `super_user`} | `SaasShell` (Dashboard SaaS / Hub SaaS / Menu) |
| `adminRevenda` | perfil = `admin_revenda` | `SaasShell` (subset — sem Manutenção/Planos no Control; sem Dashboard no Gym) |
| `usuario` | Condo: `gestor_cliente`/`porteiro`/`recepcionista`/`operador` · Gym: `admin`/`administrador`/`gerente`/`recepcionista`/`professor` | `MainShell` (Home / Cadastros ou Operação / Menu) |
| `aluno` | Gym: `aluno` | `MainShell` (Home / **Meu painel** / Menu) — telas consomem `/api/me/*` |
| `pessoa` | qualquer outro perfil ou perfil vazio (morador, dependente, etc.) | `MainShell` (Home / **Módulos** / Menu) |

Função-chave: `classifySession(product, perfil)` em `session_type.dart:38-77`. Desambigua o perfil homônimo `recepcionista` (existe nos dois produtos) pelo `product`.

## 2.2 Multi-tenant — IDs no JWT

Cada token JWT carrega claims que escopam todas as queries no backend:

| Claim | Quando aparece |
|---|---|
| `usuario_id` | sempre (operacionais / SaaS admin) |
| `revenda_id` | sempre (filtra dados do parceiro) |
| `cliente_id` | AlfaControl operacional + super_admin com cliente selecionado |
| `academia_id` | AlfaGym operacional + super_admin com academia selecionada |
| `unidade_id` | AlfaGym quando a academia tem mais de uma filial |
| `aluno_id` | só para perfil `aluno` (Gym D1.A) |
| `perfil` | sempre (AGENT, ALUNO, ADMIN, etc.) |

`TenantContext` (`lib/core/api/tenant_context.dart`) reflete isso no front. Um interceptor de auditoria compara IDs do response com o tenant esperado e loga divergências (Fase F3 — defesa contra cross-tenant leak).

## 2.3 Providers e cache por tenant

`lib/core/state/tenant_state.dart:65-117` lista 40+ providers que implementam `Clearable`. Em logout ou troca de tenant (admin_revenda Gym mudando de academia), `clearAll(tenantProviders)` zera caches em batch — alunos do tenant A nunca vazam para B.

## 2.4 Fluxos críticos

### Login → Hub

1. **`LoginScreen`** → POST `/api/auth/login` (na URL do produto escolhido) → `AuthResult { token, perfil, academiaId, unidades, senhaProvisoria }`.
2. **B1 (admin_revenda Gym sem academia)** → `SelecionarAcademiaScreen` → POST `/api/auth/selecionar-academia` → token re-emitido com `academia_id`.
3. **B2 (academia com >1 unidade)** → `SelecionarUnidadeScreen` → POST `/api/auth/selecionar-unidade` → token final com `unidade_id`. Super_admin pula a etapa.
4. **`MainShell` ou `SaasShell`** assume.

### Senha provisória do aluno (Fase D4.4)

- Gestor define senha quando ativa "Tem login no sistema" no aluno.
- Backend marca `usuarios.senha_provisoria=true`.
- Endpoints `/api/me/*` retornam **403** enquanto a flag for true.
- App detecta e força `TrocarSenhaAlunoScreen`.
- Novo POST `/api/me/senha {senhaAtual, novaSenha}` libera.

### Logout

`AuthProvider.logout` → `_pushService.logout` (DELETE FCM token) → `_storage.clear` → `clearAll(tenantProviders)` no MultiProvider listener → tela vai para `LoginScreen`. Token de servidor segue válido até expirar (1h) — JWT é stateless.

---

# 3. Matriz de permissões

Ambas as matrizes têm fallback `_full` (tudo `true`) para perfis administrativos e `_none` (tudo `false`) para perfil desconhecido. **Estas matrizes são apenas o gate visual no mobile** — o backend tem `@PreAuthorize` em cada controller como fonte de verdade da segurança.

## 3.1 PerfilCondoPermissions (AlfaControl)

Origem: `lib/features/auth/state/perfil_condo_permissions.dart:101-155`.

| Flag | super_admin / super_user / admin_revenda / gestor_cliente | recepcionista / operador | porteiro | pessoa (default) |
|---|:---:|:---:|:---:|:---:|
| canViewPessoas | ✓ | ✓ | ✓ | – |
| canEditPessoas | ✓ | ✓ | – | – |
| canDeletePessoas | ✓ | – | – | – |
| canViewLocais | ✓ | ✓ | ✓ | – |
| canEditLocais | ✓ | – | – | – |
| canViewDispositivos | ✓ | – | – | – |
| canEditDispositivos | ✓ | – | – | – |
| canViewPerfisAcesso | ✓ | – | – | – |
| canEditPerfisAcesso | ✓ | – | – | – |
| canViewHorarios | ✓ | ✓ | – | – |
| canEditHorarios | ✓ | – | – | – |
| canViewDashboard | ✓ | – | – | – |
| canViewLogsAcesso | ✓ | ✓ | ✓ | – |
| canViewAuditoria | ✓ | – | – | – |

## 3.2 PerfilGymPermissions (AlfaGym)

Origem: `lib/features/auth/state/perfil_gym_permissions.dart:128-194`.

| Flag | admin / administrador / gerente | recepcionista | professor | aluno (default) |
|---|:---:|:---:|:---:|:---:|
| canViewAlunos | ✓ | ✓ | ✓ | – |
| canEditAlunos | ✓ | ✓ | – | – |
| canDeleteAlunos | ✓ | – | – | – |
| canViewPlanos | ✓ | ✓ | – | – |
| canEditPlanos | ✓ | – | – | – |
| canViewContratos | ✓ | ✓ | – | – |
| canEditContratos | ✓ | – | – | – |
| canViewFinanceiro | ✓ | ✓ | – | – |
| canEditFinanceiro | ✓ | ✓ | – | – |
| canViewCheckin | ✓ | ✓ | – | – |
| canDoCheckin | ✓ | ✓ | – | – |
| canViewTreinos | ✓ | – | ✓ | – |
| canEditTreinos | ✓ | – | ✓ | – |
| canViewAulas | ✓ | ✓ | ✓ | – |
| canViewDashboard | ✓ | – | – | – |
| canViewFuncionarios | ✓ | – | – | – |
| canViewRelatorios | ✓ | – | – | – |
| canDoPdv | ✓ | ✓ | – | – |
| canViewAvaliacoes | ✓ | – | ✓ | – |

## 3.3 tenantFeatures (gate de plano SaaS)

Conjunto de strings (`Set<String>?`) entregue pelo backend em `/api/auth/me`. Convenções:

- `null` → tudo liberado (fallback até a Fase F1 backend ser concluída).
- `{}` (vazio) → bloqueia tudo.
- `{ 'alunos', 'checkin', 'financeiro', ... }` → interseção com `featureKey` de cada tile.

Aplicado em `ModuleCatalog.forHome` e `forGymHub` (`lib/features/modulos/models/module.dart:60-107`).

---

# 4. Inventário de telas + checklist de testes

Para cada tela, o checklist define:

- **Acesso esperado** (quem chega lá e por qual rota)
- **Endpoints** que a tela bate
- **Itens a verificar** com base nos perfis acima
- **Cenário negativo** quando aplicável

## 4.1 Auth & Shell (4 telas)

### LoginScreen — `lib/features/auth/screens/login_screen.dart`

- **Acesso:** anônimo (primeira tela depois do splash).
- **Endpoint:** `POST /api/auth/login`.
- **Checklist:**
  - Tile AlfaControl vermelho · tile AlfaGym laranja · seleção persiste em `AuthStorage.saveProduct`.
  - Email + senha → enter dispara login.
  - Credencial inválida → SnackBar "E-mail ou senha inválidos." (humanização de 401).
  - Backend offline → "Não foi possível conectar ao servidor.".
  - "Esqueci a senha" → fluxo manual com gestor (Fase 6.3 — mostra texto explicativo, sem SMTP).
- **Cenário negativo:** super_admin do Control tentando logar via tile AlfaGym (e vice-versa) recebe 401 — credenciais não cruzam produtos.

### SelecionarAcademiaScreen (B1) — `lib/features/auth/screens/selecionar_academia_screen.dart`

- **Acesso:** admin_revenda Gym sem `academia_id` no JWT inicial.
- **Endpoint:** `GET /api/academias/revenda/minhas`, `POST /api/auth/selecionar-academia`.
- **Checklist:**
  - Lista mostra só academias da revenda do admin (cross-revenda não aparece).
  - Tap em academia troca o token e abre `SelecionarUnidadeScreen` se houver >1 unidade, ou direto `MainShell`.
- **Cenário negativo:** admin_revenda de outra revenda tentar mexer via deep-link → 403.

### SelecionarUnidadeScreen (B2) — `lib/features/auth/screens/selecionar_unidade_screen.dart`

- **Acesso:** usuario Gym com `length(unidades) > 1`.
- **Endpoint:** `POST /api/auth/selecionar-unidade`.
- **Checklist:**
  - Mostra todas as unidades da academia atual.
  - Token novo carrega `unidade_id`; estado da app reseta (clearAll).
  - Super_admin pula a etapa (`precisaSelecionarUnidade` curto-circuita — Hotfix `5272518`).

### DefinirSenhaScreen — `lib/features/auth/screens/definir_senha_screen.dart`

- **Acesso:** após login com `senhaProvisoria=true` (Pessoa/usuário operacional).
- **Endpoint:** `PATCH /api/auth/perfil`.
- **Checklist:**
  - Não dá pra fechar a tela sem trocar — back button bloqueado.
  - Senha mínimo 8 caracteres; confirmação obrigatória.
  - Sucesso → entra no shell normal.

### MainShell — `lib/shell/main_shell.dart`

- **Acesso:** todos exceto `superAdmin` e `adminRevenda`.
- **Estrutura:** 3 tabs (Home / Hub dinâmico / Menu).
- **Checklist:**
  - Tab Hub muda de label e ícone conforme `HubKind` (`Cadastros` Condo, `Operação` Gym, `Meu painel` aluno, `Módulos` morador).
  - Bottom nav some quando troca-se de tenant durante carregamento.

### SaasShell — `lib/features/saas/screens/saas_shell.dart`

- **Acesso:** `superAdmin` e `adminRevenda`.
- **Estrutura:** 3 tabs (Dashboard SaaS opcional / Hub SaaS / Menu). Painel ramifica por produto: `SaasHubScreen` (Control) ou `SaasHubGymScreen` (Gym).
- **Checklist:** ver §4.6 e §4.7.

## 4.2 Home tab — HomeScreen (`lib/features/home/screens/home_screen.dart`)

A Home se ramifica internamente por `(product, sessionType)`. Três caminhos:

### 4.2.1 Caminho academia (product=academia, qualquer sessionType)

Mostra placeholder mock de "Treino A — Peito e Tríceps" + cards de resumo (Treinos / Aulas / Avaliações / Financeiro). É **conteúdo simulado** — Fase C5 (módulo de Treinos) está em reformulação. Reviewer só confere se renderiza sem crash; não há dados reais aqui.

### 4.2.2 Caminho pessoa (product=condominio, sessionType=pessoa) — morador

- **Seções:** Avatar header com tipo (morador/dependente), `_AcessosLiberadosSection` (onde posso acessar), `_QuickNav` com módulos do segmento (Encomendas, Acessos liberados, Logs próprios, Horários).
- **Endpoints:** `GET /api/me/dependentes`, `GET /api/me/acessos-liberados`, `GET /controlid/acessos?pessoaId=...`.
- **Checklist:**
  - Header mostra nome + foto + tipo.
  - Tile Encomendas só aparece se segmento = condomínio (filtra em `ModuleCatalog.forHome`).
  - Sem QR Visitante (removido na Fase 31).

### 4.2.3 Caminho operacional (sessionType=usuario, product=condominio)

- **Seções gateadas por `condoPermissions`:**
  - `_AcessosLiberadosSection` (não — só Pessoa).
  - `_PortariaCard` se perfil ∈ {porteiro, recepcionista, gestor_cliente, operador}.
  - `_LogsAcessoCard` se `canViewLogsAcesso`.
  - `_AuditoriaCard` se `canViewAuditoria`.
  - `_ResumoHojeSection` (KPIs do dia) se `canViewDashboard`.
  - `_QuickNav` com tiles Encomendas / Logs / Horários.
- **Endpoints:** `GET /api/dashboard`, `GET /controlid/acessos?...`, `GET /api/auditoria?...`.
- **Checklist por perfil:**

| Perfil | Portaria card | Logs card | Auditoria card | Resumo Hoje |
|---|:---:|:---:|:---:|:---:|
| gestor_cliente | ✓ | ✓ | ✓ | ✓ |
| recepcionista / operador | ✓ | ✓ | – | – |
| porteiro | ✓ | ✓ | – | – |

- **Cenário negativo:** porteiro chama `GET /api/auditoria` via deep-link → 403 (backend nega).

## 4.3 Cadastros — Condo (`lib/features/cadastros/`)

Hub: `CadastrosHubScreen`. Tiles condicionais por `condoPermissions.canViewX`. Veículos sempre aparece como "Em breve".

| Tile / Tela | Path | Endpoint | Quem vê | Quem edita | Quem exclui |
|---|---|---|---|---|---|
| **Pessoas** (lista, detalhe, formulário, perfis) | `pessoas/screens/*` | `GET/POST/PUT/DELETE /api/pessoas` | view ✓ | edit ✓ (sem porteiro) | delete ✓ (só `_full`) |
| **Locais** (lista, detalhe, formulário) | `locais/screens/*` | `GET/POST/PUT /api/locais` | view ✓ | edit ✓ (só `_full`) | – |
| **Horários** (lista, detalhe, formulário) | `horarios/screens/*` | `GET/POST/PUT /api/horarios` | view ✓ (sem porteiro) | edit ✓ (só `_full`) | – |
| **Perfis de Acesso** (lista, detalhe, formulário, dispositivos) | `perfis_acesso/screens/*` | `GET/POST/PUT /api/perfis-acesso` | só `_full` | só `_full` | – |
| **Dispositivos** (lista, detalhe, formulário) | `dispositivos/screens/*` | `GET/POST/PUT /api/dispositivos` | só `_full` | só `_full` | – |
| **Veículos** | (placeholder) | – | – (Fase fora de escopo) | – | – |

**Checklist por tela:**

- **PessoasListScreen:** busca debounced, paginação infinite scroll, FAB "Nova pessoa" só com `canEditPessoas`. Recepcionista cadastra mas não exclui.
- **PessoaFormScreen:** validação CPF/CEP/email/telefone client-side. Switch "Tem login no sistema" abre campo de senha provisória.
- **PessoaPerfisScreen:** vincular múltiplos perfis (Fase 30) via DraggableScrollableSheet com busca + multi-select.
- **DispositivoFormScreen:** só super_admin/admin_revenda/gestor_cliente; perfil sem `canEditDispositivos` recebe 403 do backend.
- **PerfisAcessoFormScreen:** atribuir dispositivos via tela auxiliar `PerfilDispositivosScreen`.
- **Cenário negativo cross-tenant:** alterar `?clienteId` na URL via interceptor — backend filtra por JWT e ignora override.

## 4.4 Operação Gym (`lib/features/gym/`)

Hub: `OperacaoGymHubScreen`. Tiles vêm de `ModuleCatalog.forGymHub` filtrados por `gymPermissions ∩ tenantFeatures`.

| Tile / Tela | Path | Endpoint | Perfis com acesso |
|---|---|---|---|
| **Alunos** (CRUD + foto + perfil) | `alunos/screens/*` | `/api/alunos` | admin/administrador/gerente, recepcionista (sem delete), professor (read) |
| **Check-in** | `checkin/screens/checkin_screen.dart` | `POST /api/checkin` | admin/recepcionista |
| **Planos** (CRUD + duplicar + inativar) | `planos/screens/*` | `/api/planos` | admin (full), recepcionista (read) |
| **Contratos** (lista, detalhe, matrícula) | `contratos/screens/*` | `/api/contratos`, `POST /api/matriculas` | admin (full), recepcionista (read) |
| **Recebíveis** (faturas) | `financeiro/screens/recebiveis_list_screen.dart` | `GET /api/recebiveis` | admin, recepcionista |
| **Caixa** | `caixa/screens/caixa_screen.dart` | `/api/caixa` | admin, recepcionista (canDoPdv) |
| **Despesas** (CRUD + pagar + cancelar) | `despesas/screens/*` | `/api/despesas` | admin |
| **Pagamentos por aluno** | `pagamentos/screens/pagamentos_aluno_screen.dart` | `/api/pagamentos` | admin, recepcionista |
| **Treinos** (templates) | `treinos/screens/*` | `/api/workout-templates` | **Em breve** — placeholder até reformulação |
| **Dashboard** | `dashboard/screens/dashboard_gym_screen.dart` | `GET /api/dashboard/summary` | admin/administrador/gerente |
| **Relatórios** (9 sub-telas) | `relatorios/screens/*` | `/api/relatorios/*` | admin |

**Checklist representativo:**

- **AlunosListScreen:** busca + filtro de status; FAB só com `canEditAlunos`. Foto via `image_picker` no form. CPF/CEP validados.
- **CheckinScreen:** painel de validação aluno + diálogo de motivo via `RadioGroup` (negar / autorizar manual). Feed do dia atualizado.
- **CaixaScreen:** date picker para trocar dia. Movimentações MANUAL podem ser excluídas; AUTO (do contrato/despesa) não.
- **DespesasListScreen:** chips de status, total pendente em destaque. Diálogo de pagamento abre forma de pagamento e gera saída automática no caixa.
- **InadimplenciaScreen (Relatório piloto):** range picker, KPIs, aging, top devedores com avatar+telefone.
- **TemplatesListScreen / TemplateDetalheScreen:** **NÃO testar funcionalmente** — tile aparece como "Em breve" (`PlaceholderModuleScreen` no hub).
- **Cenário negativo:** professor abrindo Recebíveis via deep-link → 403; tela mostra fallback "Sem permissão".

## 4.5 Aluno Gym (`lib/features/gym/aluno/`) — `/me/*`

Hub dedicado pra `SessionType.aluno`. Não compartilha tiles com a Operação. Endpoints sempre filtrados por `aluno_id` do JWT.

| Tela | Path | Endpoint |
|---|---|---|
| `AlunoHubScreen` | `aluno_hub_screen.dart` | resumo + tiles |
| `MeuPlanoScreen` | `meu_plano_screen.dart` | `GET /api/me/contrato` (204 se não tiver) |
| `MeusPagamentosScreen` | `meus_pagamentos_screen.dart` | `GET /api/me/faturas` |
| `MinhasPresencasScreen` | `minhas_presencas_screen.dart` | `GET /api/me/presencas?inicio&fim` |
| `MeuTreinoScreen` | `meu_treino_screen.dart` | **Em breve** — backend pronto, tile placeholder |
| `TrocarSenhaAlunoScreen` | `trocar_senha_aluno_screen.dart` | `POST /api/me/senha` |

**Checklist:**

- **AlunoHubScreen:** banner com presenças no mês + próximo vencimento (cor laranja se ≤7 dias, vermelho se vencido). IconButton de cadeado abre TrocarSenhaAluno.
- **MeusPagamentosScreen:** banner de total em aberto, lista pendentes ordenada por vencimento, toggle "Mostrar pagas".
- **MinhasPresencasScreen:** timeline com range picker; default últimos 30 dias; usa zona local da academia (Fase D3).
- **MeuPlanoScreen:** status card colorido (ATIVO verde / SUSPENSO laranja / CANCELADO vermelho) + dados do plano.
- **TrocarSenhaAlunoScreen:** senha mín. 8 chars, confirmação obrigatória; após troca volta com SnackBar de sucesso.
- **Cenário negativo (Fase D4.4):** aluno com `senha_provisoria=true` → todos os `/api/me/*` retornam 403 → app obriga `TrocarSenhaAluno` antes de acessar qualquer tile.
- **LGPD:** aluno excluindo conta (no menu) zera `usaSistema=false` e `Usuario.alunoId=null`; tentativa de re-login retorna 401.

## 4.6 SaaS Hub Condo (`lib/features/saas/`)

Acessível por `SessionType.superAdmin` e `SessionType.adminRevenda` no AlfaControl. Layout em lista (após refactor `939a68d`): seções "Carteira" e "Operação".

| Tile | Path | Endpoint | super_admin | admin_revenda |
|---|---|---|:---:|:---:|
| Revendas (lista, detalhe, formulário, provisionar) | `revendas/screens/*` | `/api/revendas` | ✓ | tile vira "Minha Revenda" → `RevendaDetailScreen(id=própria)` |
| Clientes (lista, detalhe, formulário, AlfaSync) | `clientes/screens/*` | `/api/clientes`, `/api/clientes/{id}/agent-credentials` | ✓ | ✓ (filtrado por revenda) |
| Licenças (Pendentes / Ativas + liberar + renovar + histórico) | `licencas/screens/*` | `/api/licencas` | ✓ | – (vê plano vigente no detail do Cliente) |
| Usuários (CRUD cross-tenant) | `usuarios/screens/*` | `/api/usuarios` (com X-Cliente-Id / X-Revenda-Id) | ✓ | – |
| Backup | `backup/screens/backup_screen.dart` | `/api/backup` | ✓ | ✓ (do próprio cliente) |
| Auditoria | `auditoria/screens/*` | `/api/auditoria` | ✓ | ✓ |
| Manutenção | `saas/manutencao/screens/manutencao_screen.dart` | `/api/sistema/manutencao` | ✓ | – |
| Planos SaaS (CRUD) + Tenants | `planos/screens/*` | `/api/saas/plans`, `/api/saas/tenants` | ✓ | – |
| Documentação | `documentacao/screens/documentacao_screen.dart` | WebView de `/documentacao` público | ✓ | ✓ |

**Checklist representativo:**

- **RevendasListScreen:** busca + reset de senha admin; FAB "Provisionar trial" cria revenda + admin + subscription TRIAL atomicamente.
- **ClienteDetailScreen:** edita dados + status + AlfaSync (gerar/revogar credenciais agent + toggle).
- **LicencasShellScreen:** TabBar Pendentes/Ativas. "Liberar licença" auto-provisiona agent + credenciais. "Renovar" estende validade.
- **UsuariosListScreen (super_admin):** filtros de revenda + cliente; lista cross-tenant via headers `X-Revenda-Id` / `X-Cliente-Id`.
- **BackupScreen:** triggers global + por cliente; lista de backups + restore.
- **AuditoriaScreen:** filtros (busca + período + ação); tap abre `AuditLogDetailScreen` com diff JSON.
- **ManutencaoScreen:** toggle imediato + janela programada. Logs de quem ativou + quando.
- **PlanosShellScreen:** TabBar Planos / Tenants. Tenants é read-only (provisiona vem de Revendas).

## 4.7 SaaS Hub Gym (`lib/features/saas_gym/`)

Acessível por `SessionType.superAdmin` (Gym). Layout em lista; admin_revenda Gym ainda não vê esse hub completo (Fase futura).

| Tile | Path | Endpoint | super_admin |
|---|---|---|:---:|
| Tenants (academias contratantes) | `tenants/screens/*` | `/api/saas/tenants` | ✓ |
| Revendas | `saas_gym/revendas/screens/*` | `/api/revendas` (Gym) | ✓ |
| Planos SaaS Gym (CRUD) | `saas_gym/planos/screens/*` | `/api/saas/plans` | ✓ |
| Licenças Gym | `saas_gym/licencas/screens/*` | `/api/licencas` | ✓ |
| Avisos administrativos | `saas_gym/avisos/screens/*` | `/api/avisos` | ✓ |
| Manutenção Gym | `saas_gym/manutencao/screens/*` | `/api/sistema/manutencao` | ✓ |
| Equipe (funcionários SaaS) | `saas_gym/equipe/screens/*` | `/api/funcionarios/saas` | ✓ |
| Configurações Sistema (horário, exceções, feriados) | `saas_gym/configuracoes/screens/*` | `/api/sistema/horario-atendimento`, `/api/sistema/horario-excecoes`, `/api/sistema/feriados/{ano}` | ✓ |
| Dashboard SaaS Gym | `saas_gym/dashboard/screens/saas_dashboard_gym_screen.dart` | `/api/saas/metrics` | ✓ |

**Checklist representativo:**

- **TenantsListScreen:** chips de status (TRIAL/ACTIVE/SUSPENDED/CANCELLED), busca debounced, lista paginada.
- **TenantDetailScreen:** mostra plano, uso (alunos/unidades), datas. Botão "Mudar status SaaS" com motivo opcional.
- **RevendasListScreen (Gym):** reset senha admin; provisionar tenant via FAB cria revenda + admin atomicamente.
- **PlanoGymFormScreen:** CRUD de planos SaaS para academias.
- **LicencasShellScreen (Gym):** Pendentes/Ativas; diálogos Liberar/Renovar com plano + tipo + valor + obs.
- **AvisosListScreen / AvisoFormScreen:** níveis (INFO/ALERTA/URGENTE), escopos (GLOBAL/REVENDA/ACADEMIA/SOMENTE_REVENDAS/SOMENTE_REVENDA) com escopoId condicional, expiresAt opcional.
- **ManutencaoGymScreen:** toggle global + janela programada + countdown.
- **ConfiguracoesSistemaScreen:** TabBar Horário / Exceções / Feriados; cache de feriados por ano; validação `HH:MM-HH:MM` com fim > início.
- **EquipeListScreen / EquipeFormScreen:** funcionários SaaS (admin@alfagym.com etc.) com login + permissão.

## 4.8 Comum (`lib/features/notificacoes`, `lib/features/preferencias`, `lib/features/portaria`)

| Tela | Path | Acesso |
|---|---|---|
| `NotificacoesScreen` (histórico + filtros) | `notificacoes/screens/notificacoes_screen.dart` | qualquer sessão autenticada |
| `PreferenciasNotificacoesScreen` | `preferencias/screens/preferencias_notificacoes_screen.dart` | qualquer sessão; flags variam por SessionType (Fase 32) |
| `PortariaAoVivoScreen` | `portaria/screens/portaria_ao_vivo_screen.dart` | usuário operacional Condo (perfil set: porteiro/recepcionista/gestor_cliente/operador) |

**Checklist:**

- **NotificacoesScreen:** badge no sino com contador de não-lidas (limite "99+"). Filtros: busca + status + tipo + datas. Marcar como lida.
- **PreferenciasNotificacoesScreen (Fase 32):** morador vê **2 toggles** (`notificar_acesso_proprio` + `notificar_acesso_dependente`). Operacional vê os 2 originais (feed + manutenção).
- **PortariaAoVivoScreen (Fase 20):** polling 5s, registro manual de entrada/saída/negado. Foto da pessoa via base64 → MemoryImage (Fix Fase 30).
- **Cenário negativo:** morador desligar preferência de "Acessos de dependentes" → push pra eventos de dependentes para de chegar; própria preferência continua intacta.

## 4.9 Menu / Conta (`lib/features/menu`, `lib/features/configuracoes`)

`MenuScreen` é o ponto único de configuração da sessão (Fase 28).

| Item | Path / ação | Endpoint | Disponível para |
|---|---|---|---|
| Header (foto + nome + badge perfil) | `menu_screen.dart` | – | todos |
| Editar perfil | `EditarPerfilScreen` | `PATCH /api/auth/perfil` | todos |
| Alterar senha | `AlterarSenhaScreen` | `PATCH /api/auth/perfil` | usuário operacional / pessoa (aluno usa `/api/me/senha`) |
| Preferências de notificação | `PreferenciasNotificacoesScreen` | `GET/PUT /api/me/notificacoes-preferencias` | todos |
| Tema (Sistema/Claro/Escuro) | toggle inline | – | todos |
| Sobre o app | `SobreAppSheet` modal | `package_info_plus` | todos |
| Sair | logout dialog | `POST /api/auth/logout` | todos |

**Checklist:** trocar tema persiste; logout dispara confirm dialog + clearAll de providers + redirect login.

---

# 5. Endpoints e claims do JWT

## 5.1 Mapa rápido — tela → endpoint → claim requerido

| Tela / fluxo | Endpoint | Claims requeridos | Backend gate |
|---|---|---|---|
| Login | `POST /api/auth/login` | (anônimo) | público |
| Selecionar academia (B1) | `POST /api/auth/selecionar-academia` | `perfil` ∈ {SUPER_ADMIN, ADMIN_REVENDA} | `BadCredentials` se token inválido |
| Selecionar unidade (B2) | `POST /api/auth/selecionar-unidade` | `academia_id` | filtra por usuário-unidade |
| `/api/auth/me` (Control) | `GET /api/auth/me` | autenticado | qualquer |
| `/api/me/perfil` (Gym aluno) | `GET /api/me/perfil` | `perfil = ALUNO` + `aluno_id` + `senha_provisoria=false` | 403 se provisória |
| Cadastros Pessoa | `GET /api/pessoas` | `perfil` operacional + `cliente_id` | filtra por revenda+cliente |
| Auditoria | `GET /api/auditoria` | `perfil` ∈ admin{revenda,cliente} | 403 demais |
| SaaS metrics | `GET /api/saas/metrics` | `perfil` ∈ {SUPER_ADMIN, SUPER_USER} | 403 demais |
| Voltar pro SaaS (legado) | `POST /api/auth/voltar-saas` | `perfil` ∈ {SUPER_ADMIN, SUPER_USER} | endpoint dormente — mobile não chama mais |

## 5.2 Reproduzindo manualmente via curl

Para qualquer endpoint, primeiro obtenha um token via login:

```bash
TOKEN=$(curl -s -X POST https://control.alfasolucoes.cloud/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"...","senha":"..."}' | jq -r '.accessToken // .token')

curl -H "Authorization: Bearer $TOKEN" \
  https://control.alfasolucoes.cloud/api/auditoria
```

Para o AlfaGym substitua o domínio por `gym.alfasolucoes.cloud`. Para chamadas que exigem academia/unidade no JWT, use `/api/auth/selecionar-academia` e `/api/auth/selecionar-unidade` antes do endpoint final.

---

# 6. Cenários negativos / falhas esperadas

## 6.1 Token expirado

- Token JWT expira em 1h.
- App detecta 401 em qualquer endpoint autenticado → AuthProvider faz logout automático (Fase 17a).
- Modal "Sessão expirada" + redirect `LoginScreen`.
- **Como reproduzir:** logar, esperar 1h, tentar carregar lista. Ou usar token forjado/expirado manualmente em DevTools.

## 6.2 Perfil rebaixado durante sessão

- Admin do cliente tem perfil ADMIN; gestor logado como ADMIN remove a permissão e baixa pra GERENTE.
- Próxima request com endpoint restrito (DELETE/CRUD admin) retorna 403.
- App mostra SnackBar humano: "Você não tem permissão para esta ação." em vez do erro técnico.

## 6.3 Multi-tenant leak

- Super_admin troca de tenant (alterar X-Cliente-Id manualmente, ou admin_revenda Gym mudando de academia).
- Antes da troca, lista de pessoas do cliente A está em cache (`PessoasProvider._lista`).
- `clearAll(tenantProviders)` zera todos os caches.
- **Verificação:** logar admin_revenda Gym com 2 academias, abrir Alunos da Academia A, voltar e selecionar Academia B, abrir Alunos — lista NÃO deve mostrar alunos de A.
- Interceptor de auditoria F3 (`tenant_context.dart:62-122`) loga divergência se um body retornar IDs do tenant errado.

## 6.4 Senha provisória bloqueando /me/*

- Aluno com `senha_provisoria=true`.
- Tenta abrir `MeuPlanoScreen` → backend 403 → app força `TrocarSenhaAlunoScreen`.
- Após trocar senha (POST /api/me/senha), app libera os tiles.
- **Verificação:** criar aluno via web com senha provisória, logar no app, conferir que cadeado força a troca antes de qualquer tela.

## 6.5 Backend offline / DioException

- Conectividade ruim ou backend caído.
- Em qualquer tela com lista, o estado de erro mostra ícone + mensagem "Não foi possível conectar ao servidor." com botão "Tentar novamente".
- **Verificação:** pôr o simulador em modo avião + tentar refresh em qualquer tela.

## 6.6 AlfaGym sem `/api/app/me`

- Endpoint mobile chama `/api/app/me` em academia mas o backend AlfaGym ainda não implementou (dívida F1).
- `fetchMyProfile` retorna null silenciosamente; sessão segue com os dados que vieram do `/api/auth/login`.
- **Consequência hoje:** `tenantFeatures = null` (= "tudo liberado") até o backend entregar features do plano. Reviewer deve apenas confirmar que não trava o login.

## 6.7 LGPD — exclusão de conta do aluno

- Aluno abre Menu → Excluir conta → confirma com senha.
- Backend zera `aluno.usaSistema=false` + `usuario.alunoId=null` em transação.
- Próximo login retorna 401 — usuário deletado/inativado.
- **Verificação:** criar aluno teste, logar, ir em Menu → Excluir, sair, tentar logar de novo. Esperar 401 + mensagem.

---

# 7. Como rodar localmente

## 7.1 Pré-requisitos

- Flutter SDK 3.41+ com Dart 3.11+ (`flutter --version`)
- Xcode 15+ + Simulator iOS 17+
- Android Studio + emulador Android 12+
- Acesso aos repositórios `alfa-mobile`, `AlfaControl`, `AlfaGym`

## 7.2 Setup

```bash
cd /Users/rossinisantos/Documents/dev/alfa-mobile
flutter pub get
flutter run -d <device-id>
```

`<device-id>` vem de `flutter devices`. Geralmente um simulator iOS UUID.

Hot reload sem reiniciar o `flutter run`:

```bash
PID=$(pgrep -f "flutter_tools.snapshot run")
kill -USR1 $PID    # hot reload (estado preservado)
kill -USR2 $PID    # hot restart (estado zerado, reinicia árvore)
```

## 7.3 URLs

- Default: `lib/core/api/api_client.dart:29-37` aponta pra produção.
- Para apontar pro VPS de homologação (se existir), trocar baseUrl no `ApiEnvironment` (não recomendado — não há staging hoje).

## 7.4 Credenciais de teste

Pedir à equipe Alfa Soluções:

- 1 super_admin (acesso a SaasShell completo).
- 1 admin_revenda (vê só sua carteira de clientes).
- 1 gestor_cliente AlfaControl (vê painel operacional do condomínio teste).
- 1 admin AlfaGym (vê hub Operação + Dashboard + Relatórios).
- 1 recepcionista, 1 porteiro, 1 professor (cada um com seu subset).
- 1 aluno teste com senha provisória (pra validar Fase D4.4).

---

# 8. Apêndice — bugs conhecidos e dívidas

## 8.1 Treinos do AlfaGym em "Em breve"

- Decisão do usuário em 25/04/2026 (`6ba02d7`).
- Tile mostra `PlaceholderModuleScreen`.
- Backend `/api/workout-templates` existe mas o módulo está em reformulação.
- `MeuTreinoScreen` (aluno) e `TemplatesListScreen` (operação) não devem ser testadas funcionalmente.

## 8.2 `/api/app/me` ausente no AlfaGym

- Mobile chama em pós-login Gym mas endpoint não existe.
- `fetchMyProfile` retorna null sem crash.
- `tenantFeatures` fica null → "tudo liberado".
- Pendência F1 — não bloqueia revisão; só significa que o gate de plano ainda não está em produção no Gym.

## 8.3 "Entrar como cliente" removido do app

- Tentativa em commit `77999e7` (26/04/2026) falhou em produção (sessões parciais, gates inconsistentes).
- Revertido em commit `2baa9c0`.
- Endpoints backend `/auth/voltar-saas` ficaram dormentes nos dois sistemas (additive, sem impacto).
- Funcionalidade só existe no painel web — super_admin que quer entrar num cliente abre `https://control.alfasolucoes.cloud` ou `https://gym.alfasolucoes.cloud`.

## 8.4 Cadastro de veículos

- Decisão do usuário em 20/04/2026: **fora do escopo atual**.
- Tile aparece em Cadastros do Condo como "Em breve" e mostra SnackBar genérico ao tap.
- Não testar funcionalidade.

## 8.5 Push iOS

- FCM funciona em Android (Fase 7.3).
- iOS precisa de certificado APNs Apple — fora do escopo.
- Tile de notificação no app funciona normalmente; só o push externo iOS está pendente.

## 8.6 Self-service de recuperação de senha

- Hoje gestor redefine manualmente (Fase 6.3).
- Self-service depende de SMTP — fora do escopo até infraestrutura de email entrar.

---

**Fim do guia.** Para dúvidas pontuais, consultar:

- Roadmap completo: `CLAUDE.md` na raiz do `alfa-mobile`.
- Histórico de mudanças: `CHANGELOG.md`.
- Fases backend: `AlfaControl/CLAUDE.md` e `AlfaGym/CLAUDE.md`.
