import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/branding/app_branding.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/image_decode.dart';
import '../../auth/state/auth_provider.dart';
import '../../auth/utils/perfil_labels.dart';

/// Cabeçalho do Menu: avatar (foto ou iniciais) + nome + badge do perfil.
class MenuProfileHeader extends StatelessWidget {
  const MenuProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final b = AppBranding.of(context);
    final auth = context.watch<AuthProvider>();
    final nome = auth.displayName ?? '—';
    final fotoRaw = auth.pessoaFoto;
    final perfilTxt = labelPerfil(auth.perfil);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        color: b.card,
        border: Border.all(color: b.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Avatar(
                foto: fotoRaw,
                nome: nome,
                branding: b,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: b.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: b.primarySoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        perfilTxt,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: b.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.foto,
    required this.nome,
    required this.branding,
  });

  final String? foto;
  final String nome;
  final AppBranding branding;

  @override
  Widget build(BuildContext context) {
    final b = branding;
    final fallback = CircleAvatar(
      radius: 28,
      backgroundColor: b.primarySoft,
      child: Text(
        iniciaisDeNome(nome),
        style: TextStyle(
          color: b.primary,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
    );
    final f = foto;
    if (f == null || f.isEmpty) return fallback;

    if (f.startsWith('http')) {
      return ClipOval(
        child: Image.network(
          f,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback,
        ),
      );
    }
    final bytes = decodeFotoBase64(f);
    if (bytes == null) return fallback;
    return ClipOval(
      child: Image.memory(
        bytes,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}
