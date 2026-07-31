import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/branding/app_branding.dart';

/// Bottom sheet "Sobre o app" — mostra logo, versão e informações da
/// Alfa Soluções Tecnológicas: pitch curto, sistemas próprios em
/// produção e atalhos pra site, WhatsApp e Instagram.
Future<void> showSobreAppSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _SobreAppSheet(),
  );
}

class _SobreAppSheet extends StatefulWidget {
  const _SobreAppSheet();

  @override
  State<_SobreAppSheet> createState() => _SobreAppSheetState();
}

class _SobreAppSheetState extends State<_SobreAppSheet> {
  Future<PackageInfo>? _future;

  @override
  void initState() {
    super.initState();
    _future = PackageInfo.fromPlatform();
  }

  Future<void> _abrir(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = AppBranding.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              20 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: b.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/app_icon/alfamobi-icon-alt2.png',
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: b.primarySoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(Icons.info_outline,
                            size: 48, color: b.primary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'AlfaMobi',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: b.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                FutureBuilder<PackageInfo>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox(height: 16);
                    }
                    final info = snapshot.data!;
                    return Text(
                      'Versão ${info.version}+${info.buildNumber}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: b.textMuted),
                    );
                  },
                ),
                const SizedBox(height: 22),
                _Bloco(
                  b: b,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alfa Soluções Tecnológicas',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: b.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sites, sistemas e aplicativos feitos sob medida.',
                        style: TextStyle(
                          fontSize: 12,
                          color: b.primary,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Estúdio que desenvolve sites, sistemas e aplicativos que organizam a rotina, atendem seus clientes e fazem o negócio render mais. Um time próximo, que acompanha de perto do primeiro rascunho ao uso no dia a dia — e que também mantém três SaaS próprios em produção.',
                        style: TextStyle(
                          fontSize: 13,
                          color: b.textDark,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _SectionTitle('SAAS PRÓPRIOS', b: b),
                const SizedBox(height: 10),
                _ProdutoTile(
                  icon: Icons.fitness_center,
                  nome: 'AlfaGym',
                  descricao:
                      'Gestão completa para academias: matrículas, planos, treinos, financeiro e controle de acesso com catracas.',
                  url: 'https://gym.alfasolucoes.cloud',
                  onTap: _abrir,
                  b: b,
                ),
                const SizedBox(height: 8),
                _ProdutoTile(
                  icon: Icons.shield_outlined,
                  nome: 'AlfaControl',
                  descricao:
                      'Controle de acesso inteligente para condomínios, clubes e empresas: pessoas, veículos, visitantes e eventos em tempo real.',
                  url: 'https://control.alfasolucoes.cloud',
                  onTap: _abrir,
                  b: b,
                ),
                const SizedBox(height: 8),
                _ProdutoTile(
                  icon: Icons.home_work_outlined,
                  nome: 'AlfaHome',
                  descricao:
                      'Gestão financeira para a família toda: despesas, receitas, bancos e investimentos por familiar, com dashboard.',
                  url: 'https://home.alfasolucoes.cloud',
                  onTap: _abrir,
                  b: b,
                ),
                const SizedBox(height: 18),
                _SectionTitle('CONTATO', b: b),
                const SizedBox(height: 10),
                _ContatoTile(
                  icon: Icons.chat,
                  label: 'WhatsApp',
                  valor: '(27) 4042-4157',
                  url: 'https://wa.me/552740424157',
                  onTap: _abrir,
                  b: b,
                ),
                _ContatoTile(
                  icon: Icons.phone_outlined,
                  label: 'Telefone',
                  valor: '(27) 3109-3265',
                  url: 'tel:+552731093265',
                  onTap: _abrir,
                  b: b,
                ),
                _ContatoTile(
                  icon: Icons.email_outlined,
                  label: 'E-mail',
                  valor: 'comercial@solucoesgrupo.com',
                  url: 'mailto:comercial@solucoesgrupo.com',
                  onTap: _abrir,
                  b: b,
                ),
                _ContatoTile(
                  icon: Icons.language,
                  label: 'Site',
                  valor: 'alfasolucoes.cloud',
                  url: 'https://alfasolucoes.cloud',
                  onTap: _abrir,
                  b: b,
                ),
                _ContatoTile(
                  icon: Icons.camera_alt_outlined,
                  label: 'Instagram',
                  valor: '@alfa.solucoestecnologicas',
                  url: 'https://www.instagram.com/alfa.solucoestecnologicas/',
                  onTap: _abrir,
                  b: b,
                ),
                _ContatoTile(
                  icon: Icons.location_on_outlined,
                  label: 'Endereço',
                  valor: 'R. Pedro Palácios, 79 · Centro, Vila Velha/ES',
                  url:
                      'https://maps.google.com/?q=R.+Pedro+Pal%C3%A1cios,+79,+Centro,+Vila+Velha,+ES',
                  onTap: _abrir,
                  b: b,
                ),
                _ContatoTile(
                  icon: Icons.access_time,
                  label: 'Atendimento',
                  valor: 'Seg a sex, 8h às 18h',
                  url: null,
                  onTap: _abrir,
                  b: b,
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'Feito com ♥ em Vila Velha/ES',
                    style: TextStyle(
                      color: b.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {required this.b});
  final String text;
  final AppBranding b;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: b.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _Bloco extends StatelessWidget {
  const _Bloco({required this.b, required this.child});
  final AppBranding b;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: b.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: b.border),
      ),
      child: child,
    );
  }
}

class _ProdutoTile extends StatelessWidget {
  const _ProdutoTile({
    required this.icon,
    required this.nome,
    required this.descricao,
    required this.url,
    required this.onTap,
    required this.b,
  });
  final IconData icon;
  final String nome;
  final String descricao;
  final String url;
  final ValueChanged<String> onTap;
  final AppBranding b;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(url),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: b.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: b.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: b.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: b.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nome,
                    style: TextStyle(
                      color: b.textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    descricao,
                    style: TextStyle(
                      color: b.textMuted,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new, color: b.textMuted, size: 16),
          ],
        ),
      ),
    );
  }
}

class _ContatoTile extends StatelessWidget {
  const _ContatoTile({
    required this.icon,
    required this.label,
    required this.valor,
    required this.url,
    required this.onTap,
    required this.b,
  });
  final IconData icon;
  final String label;
  final String valor;
  final String? url;
  final ValueChanged<String> onTap;
  final AppBranding b;

  @override
  Widget build(BuildContext context) {
    final clickable = url != null;
    return InkWell(
      onTap: clickable ? () => onTap(url!) : null,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: b.primary, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: b.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    valor,
                    style: TextStyle(
                      color: b.textDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (clickable)
              Icon(Icons.chevron_right, color: b.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
