import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Réplica vetorial do símbolo oficial do AlfaJornada (o "α-Percurso" —
/// ver BRAND-BRIEFING.md no repo do backend): o alfa desenhado como uma
/// única linha de rota entre dois marcos. Pontos calculados a partir do
/// SVG canônico (`frontend/src/components/Logo.tsx`) — mesmo path, mesma
/// proporção — pra ficar igual à versão web em qualquer tamanho, sem
/// depender de asset raster.
///
/// `filled=true` reproduz o `LogoIcone` (quadrado azul arredondado, marca
/// branca — usado em badges/ícones isolados). `filled=false` reproduz o
/// `LogoSimbolo` (só o traço, sem fundo — usado ao lado do wordmark).
class AlfaJornadaMark extends StatelessWidget {
  const AlfaJornadaMark({
    super.key,
    this.size = 40,
    this.background = const Color(0xFF2563EB),
    this.symbolColor = Colors.white,
    this.filled = true,
  });

  final double size;
  final Color background;
  final Color symbolColor;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _AlfaJornadaMarkPainter(
        background: filled ? background : null,
        symbolColor: symbolColor,
      ),
    );
  }
}

/// Path do α-Percurso já com o transform do SVG original (translate(8 8)
/// scale(0.75)) aplicado aos pontos do ALFA_PATH — coordenadas finais
/// num viewBox 64×64.
Path _alfaPercursoPath() => Path()
  ..moveTo(49.25, 18.5)
  ..cubicTo(41.75, 38, 14, 48.5, 14, 32)
  ..cubicTo(14, 15.5, 41.75, 26, 49.25, 45.5);

const _kMarcoInicio = Offset(49.25, 18.5);
const _kMarcoFim = Offset(49.25, 45.5);

class _AlfaJornadaMarkPainter extends CustomPainter {
  _AlfaJornadaMarkPainter({
    required this.symbolColor,
    this.background,
    this.drawProgress = 1.0,
    this.dot1Opacity = 1.0,
    this.dot2Opacity = 1.0,
    this.pulseT,
  });

  final Color? background;
  final Color symbolColor;
  final double drawProgress;
  final double dot1Opacity;
  final double dot2Opacity;
  final double? pulseT;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 64;
    canvas.save();
    canvas.scale(scale);

    if (background != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 64, 64), const Radius.circular(16)),
        Paint()..color = background!,
      );
    }

    final metrics = _alfaPercursoPath().computeMetrics().toList();
    final totalLength = metrics.fold<double>(0, (sum, m) => sum + m.length);
    final targetLength = totalLength * drawProgress.clamp(0.0, 1.0);

    final strokePaint = Paint()
      ..color = symbolColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.875
      ..strokeCap = StrokeCap.round;

    var consumed = 0.0;
    for (final metric in metrics) {
      if (consumed >= targetLength) break;
      final remaining = targetLength - consumed;
      final extractLength = remaining >= metric.length ? metric.length : remaining;
      canvas.drawPath(metric.extractPath(0, extractLength), strokePaint);
      consumed += metric.length;
    }

    if (dot1Opacity > 0) {
      canvas.drawCircle(_kMarcoInicio, 4.875, Paint()..color = symbolColor.withValues(alpha: dot1Opacity));
    }
    if (dot2Opacity > 0) {
      canvas.drawCircle(_kMarcoFim, 4.875, Paint()..color = symbolColor.withValues(alpha: dot2Opacity));
    }

    if (pulseT != null) {
      var target = totalLength * pulseT!.clamp(0.0, 1.0);
      for (final metric in metrics) {
        if (target <= metric.length) {
          final tangent = metric.getTangentForOffset(target);
          if (tangent != null) {
            // Halo colorido (visível tanto no fundo claro do login quanto
            // no fundo escuro do splash) + núcleo na cor da marca (maior
            // que a espessura do traço, pra "abaular" visivelmente por
            // cima da linha) + faísca branca central pro brilho.
            canvas.drawCircle(
              tangent.position,
              9,
              Paint()
                ..color = symbolColor.withValues(alpha: 0.45)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
            );
            canvas.drawCircle(tangent.position, 3.6, Paint()..color = symbolColor);
            canvas.drawCircle(tangent.position, 1.5, Paint()..color = Colors.white);
          }
          break;
        }
        target -= metric.length;
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AlfaJornadaMarkPainter oldDelegate) =>
      oldDelegate.background != background ||
      oldDelegate.symbolColor != symbolColor ||
      oldDelegate.drawProgress != drawProgress ||
      oldDelegate.dot1Opacity != dot1Opacity ||
      oldDelegate.dot2Opacity != dot2Opacity ||
      oldDelegate.pulseT != pulseT;
}

/// Wordmark "AlfaJornada" — mesma fonte (Righteous) e a mesma regra de
/// cor da versão web: "Alfa" no tom de texto padrão, "Jornada" no azul
/// da marca (`Logo.tsx` / `.aj-logo-jornada` em global.css).
class AlfaJornadaWordmark extends StatelessWidget {
  const AlfaJornadaWordmark(
    this.fontSize, {
    super.key,
    this.textColor = const Color(0xFF1E293B),
    this.brandColor = const Color(0xFF2563EB),
    this.centered = false,
  });

  final double fontSize;
  final Color textColor;
  final Color brandColor;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: centered ? TextAlign.center : TextAlign.left,
      text: TextSpan(
        style: GoogleFonts.righteous(fontSize: fontSize, height: 1.0),
        children: [
          TextSpan(text: 'Alfa', style: TextStyle(color: textColor)),
          TextSpan(text: 'Jornada', style: TextStyle(color: brandColor)),
        ],
      ),
    );
  }
}

/// Lockup completo (símbolo solto + wordmark), com a mesma animação de
/// entrada do login web (`.login-logo` em global.css): o traço se
/// desenha (0.8s), os dois marcos aparecem, e depois um ponto de luz
/// percorre a rota em loop. Uso: cabeçalho da tela de login.
class AlfaJornadaAnimatedLogo extends StatefulWidget {
  const AlfaJornadaAnimatedLogo({
    super.key,
    this.size = 44,
    this.textColor = const Color(0xFF1E293B),
    this.brandColor = const Color(0xFF2563EB),
    this.centered = false,
  });

  final double size;
  final Color textColor;
  final Color brandColor;
  final bool centered;

  @override
  State<AlfaJornadaAnimatedLogo> createState() => _AlfaJornadaAnimatedLogoState();
}

class _AlfaJornadaAnimatedLogoState extends State<AlfaJornadaAnimatedLogo>
    with TickerProviderStateMixin {
  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));

  @override
  void initState() {
    super.initState();
    _intro.addStatusListener((status) {
      if (status == AnimationStatus.completed) _pulse.repeat();
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([_intro, _pulse]),
          builder: (context, _) {
            final t = _intro.value.clamp(0.0, 1.0);
            return CustomPaint(
              size: Size.square(widget.size),
              painter: _AlfaJornadaMarkPainter(
                symbolColor: widget.brandColor,
                drawProgress: Curves.easeOut.transform(t),
                dot1Opacity: const Interval(0.10, 0.35, curve: Curves.easeOut).transform(t),
                dot2Opacity: const Interval(0.80, 1.0, curve: Curves.easeOut).transform(t),
                pulseT: _intro.isCompleted ? _pulse.value : null,
              ),
            );
          },
        ),
        SizedBox(width: widget.size * 0.16),
        AlfaJornadaWordmark(
          widget.size * 0.78,
          textColor: widget.textColor,
          brandColor: widget.brandColor,
        ),
      ],
    );
    // scaleDown: em tela estreita ou text scale alto o lockup encolhe
    // inteiro em vez de estourar o Row (overflow visto em aparelho real).
    final fitted = FittedBox(fit: BoxFit.scaleDown, child: row);
    return widget.centered ? Center(child: fitted) : fitted;
  }
}
