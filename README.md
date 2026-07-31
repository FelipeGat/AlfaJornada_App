# AlfaJornada App

App móvel (Flutter) do AlfaJornada — ponto eletrônico e gestão de jornada.
Colaborador bate ponto e acompanha histórico/banco de horas/humor; gestor
de RH acompanha a equipe.

Extraído do app unificado AlfaMobi (Academia + Condomínio + Jornada) em
31/07/2026 — histórico completo do módulo Jornada está preservado na
branch `alfajornada`/commits relacionados do repo `alfa-mobile`.

## Rodando localmente

```bash
flutter pub get
flutter run -d chrome --web-port=81   # ou -d <device> num celular/emulador
```

Backend: repo `AlfaJornada` (`C:\xampp\htdocs\AlfaJornada`), branch
`Felipe`. Pra testar contra o backend local (docker), aponte
`ApiEnvironment.baseUrlFor` em `lib/core/api/api_client.dart` pra
`http://localhost:8085` temporariamente — nunca commitar esse ponteiro.
