import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/branding/app_branding.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/update/app_update_dialog.dart';
import '../../../core/update/app_update_service.dart';
import '../../auth/state/auth_provider.dart';
import '../../configuracoes/screens/alterar_senha_screen.dart';
import '../../configuracoes/screens/editar_perfil_screen.dart';
import '../widgets/menu_profile_header.dart';
import '../widgets/menu_section.dart';
import '../widgets/sobre_app_sheet.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final b = AppBranding.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const MenuProfileHeader(),
          const SizedBox(height: 24),
          MenuSection(
            titulo: 'Conta',
            child: MenuCard(
              children: [
                _MenuItem(
                  icon: Icons.person_outline,
                  label: 'Editar perfil',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const EditarPerfilScreen(),
                    ),
                  ),
                ),
                _MenuItem(
                  icon: Icons.lock_outline,
                  label: 'Alterar senha',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AlterarSenhaScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          MenuSection(
            titulo: 'Preferências',
            child: MenuCard(
              children: const [_TemaInline()],
            ),
          ),
          const SizedBox(height: 20),
          MenuSection(
            titulo: 'Sobre',
            child: MenuCard(
              children: [
                _MenuItem(
                  icon: Icons.info_outline,
                  label: 'Sobre o app',
                  onTap: () => showSobreAppSheet(context),
                ),
                _MenuItem(
                  icon: Icons.system_update_rounded,
                  label: 'Verificar atualização',
                  onTap: () => _verificarAtualizacao(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          MenuCard(
            children: [
              _MenuItem(
                icon: Icons.logout,
                label: 'Sair',
                destrutivo: true,
                onTap: () => _confirmLogout(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'AlfaJornada',
              style: TextStyle(
                fontSize: 11,
                color: b.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _verificarAtualizacao(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(
      content: Text('Verificando atualização…'),
      duration: Duration(seconds: 2),
    ));
    final produto = context.read<AuthProvider>().product;
    final r = await AppUpdateService().checar(produto: produto);
    if (!context.mounted) return;
    messenger.hideCurrentSnackBar();
    if (r == null) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Você já está na versão mais recente.'),
      ));
      return;
    }
    await mostrarUpdateDialog(context, r);
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Deseja realmente sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().logout();
    }
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destrutivo = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destrutivo;

  @override
  Widget build(BuildContext context) {
    final b = AppBranding.of(context);
    final cor = destrutivo ? b.danger : b.primary;
    final corTexto = destrutivo ? b.danger : b.textDark;
    return ListTile(
      leading: Icon(icon, color: cor),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: corTexto,
        ),
      ),
      trailing: destrutivo
          ? null
          : Icon(Icons.chevron_right, color: b.textMuted),
      onTap: onTap,
    );
  }
}

class _TemaInline extends StatelessWidget {
  const _TemaInline();

  @override
  Widget build(BuildContext context) {
    final b = AppBranding.of(context);
    final provider = context.watch<ThemeProvider>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.brightness_6_outlined, color: b.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tema',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: b.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<ThemeMode>(
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              padding: WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              ),
            ),
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Sistema'),
                ),
                icon: Icon(Icons.smartphone),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Claro'),
                ),
                icon: Icon(Icons.light_mode_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Escuro'),
                ),
                icon: Icon(Icons.dark_mode_outlined),
              ),
            ],
            selected: {provider.mode},
            onSelectionChanged: (s) => provider.setMode(s.first),
          ),
        ],
      ),
    );
  }
}
