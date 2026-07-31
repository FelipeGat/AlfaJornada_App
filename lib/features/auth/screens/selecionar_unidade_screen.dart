import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/branding/app_branding.dart';
import '../../../core/state/tenant_state.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/pressable.dart';
import '../models/unidade.dart';
import '../state/auth_provider.dart';

/// Tela exibida pós-login (ou pós-seleção de academia) quando o
/// usuário tem mais de uma unidade na academia atual (Fase B2).
/// Bypass automático pra length==1 acontece no `AuthProvider.login` /
/// `escolherAcademia` — esta tela só é renderizada quando há
/// realmente escolha a fazer.
class SelecionarUnidadeScreen extends StatelessWidget {
  const SelecionarUnidadeScreen({super.key});

  Future<void> _escolher(BuildContext context, Unidade unidade) async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.escolherUnidade(
      unidade.id,
      tenantCaches: tenantProviders(context),
    );
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Falha ao selecionar unidade.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = AppBranding.of(context);
    final auth = context.watch<AuthProvider>();
    final unidades = auth.unidadesPendentes;

    return Scaffold(
      backgroundColor: b.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(branding: b, nome: auth.displayName, temUnidades: unidades.isNotEmpty),
            Expanded(
              child: unidades.isEmpty
                  ? _Vazio(branding: b)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                      itemCount: unidades.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.grid),
                      itemBuilder: (_, i) {
                        final u = unidades[i];
                        return _UnidadeTile(
                          unidade: u,
                          branding: b,
                          disabled: auth.loading,
                          onTap: () => _escolher(context, u),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.branding, required this.nome, required this.temUnidades});

  final AppBranding branding;
  final String? nome;
  final bool temUnidades;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 24),
      decoration: BoxDecoration(
        color: branding.primarySoft,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.card),
          bottomRight: Radius.circular(AppRadius.card),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: branding.card,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.storefront_rounded, color: branding.primary),
                ),
                const SizedBox(height: 14),
                Text(
                  nome != null ? 'Olá, $nome' : 'Bem-vindo',
                  style: AppTypeScale.subtitulo.copyWith(color: branding.textDark),
                ),
                const SizedBox(height: 4),
                Text(
                  temUnidades
                      ? 'Selecione a unidade que deseja acessar'
                      : 'Vamos verificar o acesso à sua unidade',
                  style: AppTypeScale.descricao.copyWith(color: branding.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Sair',
            icon: Icon(Icons.logout_rounded, color: branding.textMuted),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
    );
  }
}

class _UnidadeTile extends StatelessWidget {
  const _UnidadeTile({
    required this.unidade,
    required this.branding,
    required this.onTap,
    this.disabled = false,
  });

  final Unidade unidade;
  final AppBranding branding;
  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      borderRadius: AppRadius.card,
      onTap: disabled ? () {} : onTap,
      child: Opacity(
        opacity: disabled ? 0.5 : 1,
        child: AppCard(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: branding.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.store_rounded, color: branding.primary, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  unidade.nome,
                  style: AppTypeScale.texto.copyWith(
                    fontWeight: FontWeight.w700,
                    color: branding.textDark,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: branding.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _Vazio extends StatelessWidget {
  const _Vazio({required this.branding});
  final AppBranding branding;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: branding.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.store_mall_directory_outlined, size: 40, color: branding.danger),
            ),
            const SizedBox(height: 20),
            Text(
              'Nenhuma unidade disponível',
              textAlign: TextAlign.center,
              style: AppTypeScale.subtitulo.copyWith(color: branding.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              'Seu usuário ainda não está vinculado a nenhuma unidade '
              'desta academia. Fale com o administrador do sistema para '
              'liberar o acesso.',
              textAlign: TextAlign.center,
              style: AppTypeScale.descricao.copyWith(color: branding.textMuted),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => auth.logout(),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sair e tentar outra conta'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
