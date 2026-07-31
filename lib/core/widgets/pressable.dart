import 'package:flutter/material.dart';

/// Wrapper padrão pra "press animation" em cards/tiles clicáveis: leve
/// scale-down no tap-down + ripple do Material — usado em vez de `InkWell`
/// cru pra deixar o toque com a mesma sensação em todo o app.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius = 16,
  });

  final Widget child;
  final VoidCallback onTap;
  final double borderRadius;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          child: widget.child,
        ),
      ),
    );
  }
}
