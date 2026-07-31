import 'dart:math';

import 'package:flutter/material.dart';

import '../jornada/branding/alfa_jornada_mark.dart';

/// Splash screen de abertura do AlfaJornada. Reusa o mesmo símbolo animado
/// (α-Percurso) e a mesma paleta da tela de login — fica na tela ~3s, sem
/// cards, só o logo se desenhando, o slogan oficial do produto e um fundo
/// discreto com partículas na cor da marca.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  static const _kBgTop = Color(0xFF0B1020);
  static const _kBgBottom = Color(0xFF101828);
  static const _kCyan = Color(0xFF2563EB);
  /// Ponto de convergência do logo — deslocado pra cima do centro pra não
  /// repetir a composição da tela de login que vem em seguida.
  static const _kLogoAlign = Alignment(0, -0.32);

  late final AnimationController _seq = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  )..forward();

  late final AnimationController _particlesCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  )..repeat();

  late final List<_Particle> _particles = _generateParticles(32);

  late final Animation<double> _bgOpacity = CurvedAnimation(
    parent: _seq,
    curve: const Interval(0.0, 0.12, curve: Curves.easeOut),
  );

  late final Animation<double> _logoOpacity = CurvedAnimation(
    parent: _seq,
    curve: const Interval(0.25, 0.44, curve: Curves.easeOut),
  );

  late final Animation<double> _particlesOpacity = CurvedAnimation(
    parent: _seq,
    curve: const Interval(0.55, 0.72, curve: Curves.easeIn),
  );

  late final Animation<double> _sloganOpacity = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 30),
  ]).animate(CurvedAnimation(parent: _seq, curve: const Interval(0.30, 0.80)));

  late final Animation<double> _loaderOpacity = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 25),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 25),
  ]).animate(CurvedAnimation(parent: _seq, curve: const Interval(0.48, 0.90)));

  late final Animation<double> _logoLift = Tween<double>(begin: 0, end: -20).animate(
    CurvedAnimation(parent: _seq, curve: const Interval(0.78, 0.875, curve: Curves.easeOut)),
  );

  List<_Particle> _generateParticles(int count) {
    final rnd = Random(7);
    return List.generate(count, (_) {
      return _Particle(
        dx: rnd.nextDouble(),
        dy: rnd.nextDouble(),
        radius: 1.0 + rnd.nextDouble() * 1.6,
        speed: 0.5 + rnd.nextDouble() * 1.0,
        phase: rnd.nextDouble() * 2 * pi,
        baseOpacity: 0.08 + rnd.nextDouble() * 0.14,
      );
    });
  }

  /// Zoom sutil e contínuo no logo ("respiração"), amarrado ao
  /// `_particlesCtrl` (não ao `_seq`) — continua vivo mesmo depois do
  /// reveal, em vez de travar assim que a sequência principal termina.
  double get _breathScale {
    final elapsedSeconds = _particlesCtrl.value * 16;
    return 1.015 + 0.015 * sin(2 * pi * 0.6 * elapsedSeconds);
  }

  @override
  void initState() {
    super.initState();
    _seq.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onFinished();
    });
  }

  @override
  void dispose() {
    _seq.dispose();
    _particlesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBgTop,
      body: AnimatedBuilder(
        animation: Listenable.merge([_seq, _particlesCtrl]),
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Fundo — gradiente quase-preto, aparece suavemente.
              Opacity(
                opacity: _bgOpacity.value,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_kBgTop, _kBgBottom],
                    ),
                  ),
                ),
              ),
              // Glow discreto atrás do logo — nunca uma bola sólida, só um
              // radial gradient bem suave pra dar profundidade.
              Opacity(
                opacity: _logoOpacity.value * 0.5,
                child: Align(
                  alignment: _kLogoAlign,
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Color(0x262563EB), Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ),
              // Partículas digitais + linhas de conexão sutis, na cor da marca.
              Opacity(
                opacity: _particlesOpacity.value,
                child: CustomPaint(
                  painter: _ParticleFieldPainter(
                    particles: _particles,
                    t: _particlesCtrl.value,
                    color: _kCyan,
                  ),
                ),
              ),
              // Logo (mesmo símbolo animado da tela de login) + slogan +
              // loader — deslocados pra cima do centro pra não repetir a
              // composição da tela que vem em seguida.
              Align(
                alignment: _kLogoAlign,
                child: Transform.translate(
                  offset: Offset(0, _logoLift.value),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _breathScale,
                          child: const AlfaJornadaAnimatedLogo(
                            size: 72,
                            textColor: Colors.white,
                            centered: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Opacity(
                        opacity: _sloganOpacity.value,
                        child: Text(
                          'Gestão e controle do seu Departamento Pessoal',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Opacity(
                        opacity: _loaderOpacity.value,
                        child: _DotsLoader(controller: _particlesCtrl, color: _kCyan),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Três pontinhos com opacidade pulsando em sequência — loader minimalista,
/// sem barra de progresso nem spinner padrão.
class _DotsLoader extends StatelessWidget {
  const _DotsLoader({required this.controller, required this.color});

  final Animation<double> controller;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final phase = (i * 0.25) % 1.0;
        final t = ((controller.value * 2.5) + phase) % 1.0;
        final opacity = 0.25 + 0.6 * (0.5 - (t - 0.5).abs()) * 2;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Opacity(
            opacity: opacity.clamp(0.25, 0.85),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
        );
      }),
    );
  }
}

class _Particle {
  const _Particle({
    required this.dx,
    required this.dy,
    required this.radius,
    required this.speed,
    required this.phase,
    required this.baseOpacity,
  });

  final double dx;
  final double dy;
  final double radius;
  final double speed;
  final double phase;
  final double baseOpacity;
}

/// Campo de partículas bem discreto — pontos digitais com leve deriva
/// vertical + linhas finas conectando os que estão próximos. Tudo em
/// opacidade baixa: "o fundo deve parecer vivo, nunca poluído".
class _ParticleFieldPainter extends CustomPainter {
  _ParticleFieldPainter({required this.particles, required this.t, required this.color});

  final List<_Particle> particles;
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final positions = particles.map((p) {
      final y = (p.dy + sin(t * 2 * pi * p.speed + p.phase) * 0.035) * size.height;
      final x = (p.dx + cos(t * 2 * pi * p.speed * 0.6 + p.phase) * 0.028) * size.width;
      return Offset(x, y);
    }).toList();

    // Linhas de conexão — só entre pontos próximos, opacidade baixa.
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.06)
      ..strokeWidth = 0.6;
    for (var i = 0; i < positions.length; i++) {
      for (var j = i + 1; j < positions.length; j++) {
        final dist = (positions[i] - positions[j]).distance;
        if (dist < 90) {
          canvas.drawLine(positions[i], positions[j], linePaint);
        }
      }
    }

    for (var i = 0; i < particles.length; i++) {
      final p = particles[i];
      final paint = Paint()..color = color.withValues(alpha: p.baseOpacity);
      canvas.drawCircle(positions[i], p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticleFieldPainter oldDelegate) => oldDelegate.t != t;
}
