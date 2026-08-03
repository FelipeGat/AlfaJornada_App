# AlfaJornada App — Instruções para Claude

## Projeto & Stack

App Flutter (iOS/Android/Web) cliente do **AlfaJornada** (ponto eletrônico e
gestão de jornada/RH) — produto único, sem seletor de sistema.

- **Flutter** 3.41.x / **Dart** 3.11.x
- **Provider** para estado (sem Riverpod/Bloc)
- **Dio** para HTTP
- **Firebase** (FCM para push) — inicializado em `main.dart`
- Estrutura por feature em `lib/features/<feature>/{screens,services,state,models}`

## Origem

Extraído em 31/07/2026 do app unificado AlfaMobi (`alfa-mobile`, que
também atende AlfaGym e AlfaControl) — era um dos três produtos dentro do
mesmo binário. O histórico completo do desenvolvimento do módulo Jornada
dentro daquele app está preservado lá (branch `alfajornada` e commits
relacionados).

`AlfaProduct` (em `lib/core/api/api_client.dart`) sobrevive como enum de
um valor só (`jornada`) — decisão deliberada pra não precisar reescrever
`AuthProvider`/`AuthStorage`/`TenantContext`, que threadeiam esse tipo por
várias camadas. Não adicionar outros valores a esse enum.

## Perfis (colaborador × gestor)

Não existe seletor de produto nem `SessionType` operacional cheio (isso é
resquício do app compartilhado, mantido só pra super_admin/admin_revenda
de plataforma). A distinção real é feita direto pelo `perfil` do usuário:

- `auth.perfil == null || 'colaborador'` → `_JornadaHomeSection` (bater
  ponto, meu status do dia, humor).
- Qualquer outro perfil (RH, diretor_rh, gestor_cliente, gerente,
  gestor_depto, admin_revenda, super_admin) → `_JornadaGestorHomeSection`
  (resumo do dia da equipe, clima, vincular colaborador — ver
  `_kPerfisGestaoPonto` em `home_screen.dart` pra quem pode vincular).

## Repo relacionado & produção

| Repo / local | Papel |
|---|---|
| Este repo | Cliente Flutter |
| `C:\xampp\htdocs\AlfaJornada` | Backend Spring Boot + frontend web React, branch `Felipe` |

- Produção: `https://jornada.alfasolucoes.cloud` (configurado em
  `lib/core/api/api_client.dart`).
- SSH de produção: `ssh alfajornada-prod` (blue/green — ver
  `alfajornada-backend-green`/`-blue`).
- Dev local: `docker compose up -d` no repo do backend, porta 8085. Pra
  apontar o app pra lá:
  `flutter run --dart-define=API_BASE_URL=http://localhost:8085` —
  não editar `ApiEnvironment` na mão.

## Convenções

- `flutter analyze` limpo antes de considerar qualquer mudança pronta.
- Testar visualmente via `flutter run -d chrome --web-port=81` (porta
  liberada no CORS do backend) — não só analyze/build.
- Comentários só quando o "porquê" não é óbvio pelo nome das coisas.
- Comunicação sempre em português.
