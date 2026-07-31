import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/branding/app_branding.dart';
import '../../auth/state/auth_provider.dart';
import '../../auth/utils/perfil_labels.dart';
import 'alterar_senha_screen.dart';
import 'editar_perfil_screen.dart';

class ConfiguracoesScreen extends StatelessWidget {
  const ConfiguracoesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final b = AppBranding.of(context);
    final auth = context.watch<AuthProvider>();
    final perfilLabel = labelPerfil(auth.perfil);
    final iniciais = iniciaisDeNome(auth.displayName);

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _SecaoTitulo(titulo: 'Meu perfil', branding: b),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: b.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: b.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: b.primary.withValues(alpha: 0.12),
                      child: Text(
                        iniciais,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: b.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.displayName ?? '—',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: b.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          _BadgePerfil(label: perfilLabel, branding: b),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const EditarPerfilScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Editar perfil'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SecaoTitulo(titulo: 'Segurança', branding: b),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: b.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: b.border),
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.lock_outline, color: b.primary),
                  title: const Text('Alterar senha'),
                  subtitle: Text(
                    'Defina uma nova senha de acesso ao app.',
                    style: TextStyle(fontSize: 12, color: b.textMuted),
                  ),
                  trailing: Icon(Icons.chevron_right, color: b.textMuted),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AlterarSenhaScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SecaoTitulo extends StatelessWidget {
  const _SecaoTitulo({required this.titulo, required this.branding});
  final String titulo;
  final AppBranding branding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
      child: Text(
        titulo.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: branding.textMuted,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _BadgePerfil extends StatelessWidget {
  const _BadgePerfil({required this.label, required this.branding});
  final String label;
  final AppBranding branding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: branding.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: branding.primary,
        ),
      ),
    );
  }
}

