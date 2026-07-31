# Guia de Acessibilidade — AlfaMobi

## Princípio

O AlfaMobi **respeita** as configurações de acessibilidade do iOS/Android:

- Tamanho do texto (Configurações → Tela e Brilho → Tamanho do Texto)
- Texto Maior (Acessibilidade → Tela e Tamanho do Texto → Texto Maior)
- Texto em Negrito (Acessibilidade → Tela e Tamanho do Texto)

Layouts são responsáveis por **se adaptar** ao crescimento do texto, não por bloquear esse crescimento.

## Clamp global

`lib/main.dart` aplica `textScaler.clamp(0.85, 1.30)`:

- **0.85×** — usuário que prefere texto menor (categoria mínima do iOS).
- **1.30×** — cobre "Texto Grande" + dois passos da Acessibilidade. Acima disso (até 2.0× no iOS) os layouts mobile compactos não cabem nem em apps com fundo financeiro infinito.
- Negrito do sistema é aplicado independente do scale e respeitado.

Esse clamp é o ponto único de override — não usar `MediaQuery.copyWith(textScaler: ...)` em telas individuais.

## Padrões obrigatórios em layouts novos

### 1. Listas / cards / tiles com texto multi-linha

Usar `maxLines + TextOverflow.ellipsis` quando o crescimento sem limite estoura o card:

```dart
Text(
  cliente.nome,
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
)
```

Quando o texto pode quebrar duas linhas mas não três:

```dart
Text(
  descricao,
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
)
```

### 2. Rows com múltiplos textos

Wrap em vez de Row quando os filhos podem virar linhas separadas:

```dart
Wrap(
  spacing: 12,
  runSpacing: 4,
  children: [
    Text('Início: ${data}'),
    Text('Frequência: 3x'),
  ],
)
```

Em Row mantida, usar `Expanded`/`Flexible` em pelo menos um filho de texto:

```dart
Row(
  children: [
    const Icon(Icons.email),
    const SizedBox(width: 8),
    Expanded(child: Text(email, overflow: TextOverflow.ellipsis)),
  ],
)
```

### 3. Botões e CTAs

`ElevatedButton` no tema tem `minimumSize: 52h` mas SEM altura máxima — quando texto vira 2 linhas (negrito + scale alto), botão cresce. **Não envolver em `SizedBox(height: 52)`**.

Quando o botão TEM que ser uma linha (CTA principal de tela):

```dart
FilledButton(
  onPressed: ...,
  child: const FittedBox(
    fit: BoxFit.scaleDown,
    child: Text('Entrar no sistema'),
  ),
)
```

`FittedBox` reduz o texto pra caber sem quebrar visual.

### 4. Telas com Column → estouro vertical

Usar `LayoutBuilder + SingleChildScrollView + ConstrainedBox(minHeight) + IntrinsicHeight`:

```dart
LayoutBuilder(
  builder: (ctx, c) => SingleChildScrollView(
    child: ConstrainedBox(
      constraints: BoxConstraints(minHeight: c.maxHeight),
      child: IntrinsicHeight(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [...],
        ),
      ),
    ),
  ),
)
```

Esse padrão garante que o conteúdo centraliza quando cabe e rola quando não cabe — sem `RenderFlex overflowed`.

### 5. AppBar com título longo

```dart
AppBar(
  title: Text(
    titulo,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  ),
)
```

### 6. Ícones + textos em chips

`Wrap` em vez de `Row`, e `Chip(label: Text(maxLines: 1, ellipsis))`.

## Fontes — device vs emulador

iOS device respeita as três configurações de Acessibilidade que o emulador ignora:

1. Tamanho do texto (slider)
2. Texto Maior
3. Texto em Negrito

Diferenças de **0–15% no tamanho** entre os dois ambientes são esperadas e corretas. Não tentar igualar via override de tema. Se o app está esteticamente OK no emulador em 1.0×, ele deve funcionar no device em qualquer escala dentro do clamp.

Pra testar acessibilidade no simulador:
- iOS Simulator → Features → Toggle Increase Contrast / Reduce Motion / etc.
- iOS Simulator → não tem ajuste de Texto Maior nativo; usa device físico ou Flutter DevTools "Slow animations" + override manual de MediaQuery em código de teste.

## Auditoria recomendada

A cada tela nova:

1. Rodar no device com Configurações → Tela e Brilho → Tamanho do Texto **no máximo** (sem entrar na Acessibilidade) e verificar:
   - Todos os textos legíveis sem cortes.
   - Botões + tiles continuam tocáveis.
   - Sem `RenderFlex overflowed` no console.

2. Ativar **Texto em Negrito** + voltar ao tamanho default — verificar que nada vira 3 linhas onde devia ser 1.

3. Em Acessibilidade → Texto Maior → ligar e ir até o nível 4 (de 7) — confirmar que o app continua usável (clamp limita em 1.30×).

## Padrão a EVITAR

- `SizedBox(height: 52, child: ElevatedButton(...))` → bloqueia crescimento.
- `Row(children: [Text(longo), Text(longo)])` sem Expanded/Flexible → overflow.
- `Center(SingleChildScrollView(...))` → ScrollView dentro de Center não respeita constraints e quebra com texto grande.
- `MediaQuery.copyWith(textScaler: TextScaler.linear(1.0))` em telas → ignora acessibilidade do usuário.
- `Container(height: 60, child: Text(...))` com texto que pode crescer → cortado.
