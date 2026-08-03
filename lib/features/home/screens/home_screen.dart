import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/branding/app_branding.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/image_decode.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../auth/state/auth_provider.dart';
import '../../jornada/models/ponto_status.dart';
import '../../jornada/utils/jornada_format.dart';
import '../../jornada/screens/equipe_hoje_screen.dart';
import '../../jornada/screens/vincular_screen.dart';
import '../../jornada/services/localizacao_service.dart';
import '../../jornada/state/jornada_gestor_provider.dart';
import '../../jornada/state/jornada_provider.dart';
import '../../notificacoes/screens/notificacoes_screen.dart';
import '../../notificacoes/state/notificacoes_provider.dart';

/// Espelha `Roles.GESTAO_PONTO` do backend — quem pode vincular usuário a
/// colaborador. Mais restrito que `Roles.GESTAO_DEPTO` (que também vê
/// equipe/clima, mas não vincula).
const _kPerfisGestaoPonto = {
  'rh', 'diretor_rh', 'gestor_cliente', 'admin_revenda', 'super_admin', 'super_user',
};

const _kEmojisHumor = ['😞', '😕', '😐', '🙂', '😄'];
String _emojiHumor(int nota) => _kEmojisHumor[(nota.clamp(1, 5)) - 1];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final b = AppBranding.of(context);
    final name = auth.displayName ?? 'Usuário';
    final ehColaborador =
        auth.perfil == null || auth.perfil!.toLowerCase() == 'colaborador';

    final conteudoHome = <Widget>[
      _AvatarHeader(name: name, foto: auth.pessoaFoto, branding: b),
      const SizedBox(height: 24),
      ehColaborador ? const _JornadaHomeSection() : const _JornadaGestorHomeSection(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _saudacao(name),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
        ),
        actions: [
          _NotifBell(branding: b),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<JornadaProvider>().carregarStatus(refresh: true),
        // Pouco conteúdo na tela (um card de ponto + humor) — sem isso
        // ficava preso no topo com um vazio grande embaixo. Centraliza
        // vertical e horizontalmente (teto de 480px) quando a tela sobra.
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: conteudoHome,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}


class _JornadaHomeSection extends StatefulWidget {
  const _JornadaHomeSection();

  @override
  State<_JornadaHomeSection> createState() => _JornadaHomeSectionState();
}

class _JornadaHomeSectionState extends State<_JornadaHomeSection> {
  Timer? _relogio;
  DateTime _agora = DateTime.now();
  bool _batendoPonto = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final prov = context.read<JornadaProvider>();
      if (prov.status == null && !prov.loadingStatus) {
        prov.carregarStatus();
      }
      if (prov.temPendentes && !prov.sincronizando) {
        prov.sincronizarFila();
      }
      if (prov.meuHumor == null && !prov.loadingHumor) {
        prov.carregarMeuHumor();
      }
    });
    // Relógio ao vivo no card de hoje — só enquanto a Home está montada.
    _relogio = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _agora = DateTime.now());
    });
  }

  @override
  void dispose() {
    _relogio?.cancel();
    super.dispose();
  }

  Future<void> _registrarHumor(int nota, {String? motivo}) async {
    final prov = context.read<JornadaProvider>();
    final ok = await prov.registrarHumor(nota, motivo: motivo);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Não foi possível registrar o humor. Verifique sua conexão e tente de novo.')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(motivo != null && motivo.trim().isNotEmpty
            ? 'Humor e motivo registrados!'
            : 'Humor do dia registrado!'),
      ),
    );
  }

  Future<void> _baterPonto() async {
    // Guarda local: o `registrando` do provider só liga depois do GPS
    // (janela de até ~5s) — sem isso, toque duplo dispara duas batidas.
    if (_batendoPonto) return;
    setState(() => _batendoPonto = true);
    try {
      await _baterPontoInterno();
    } finally {
      if (mounted) setState(() => _batendoPonto = false);
    }
  }

  Future<void> _baterPontoInterno() async {
    final prov = context.read<JornadaProvider>();
    final posicao = await obterLocalizacaoAtual();
    if (!mounted) return;
    final resultado = await prov.registrarPonto(
      latitude: posicao?.latitude,
      longitude: posicao?.longitude,
      isMocked: posicao?.isMocked,
    );
    if (!mounted || resultado.jaEmAndamento) return;
    if (resultado.enfileirado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Sem conexão — a marcação foi guardada e será enviada assim que a rede voltar.')),
      );
      return;
    }
    final erro = resultado.erro;
    if (erro == null) {
      final statusAtual = prov.status;
      final marcacoes = statusAtual?.marcacoesHoje ?? const <String>[];
      final mensagem = marcacoes.isEmpty
          ? 'Marcação registrada!'
          : '${rotuloMarcacaoJornada(marcacoes.length - 1)} registrada às ${marcacoes.last}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem)),
      );
      return;
    }
    if (erro.naoVinculado) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Conta não vinculada'),
          content: Text(erro.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Entendi'),
            ),
          ],
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(erro.message)));
  }

  @override
  Widget build(BuildContext context) {
    final b = AppBranding.of(context);
    final prov = context.watch<JornadaProvider>();
    final status = prov.status;

    if (prov.loadingStatus && status == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (prov.erroStatus != null && status == null) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(prov.erroStatus!, style: TextStyle(color: b.danger)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => prov.carregarStatus(refresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar de novo'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (prov.temPendentes) ...[
          _PendentesBanner(prov: prov, branding: b),
          const SizedBox(height: 12),
        ],
        _JornadaClockCard(
          status: status,
          branding: b,
          agora: _agora,
          registrando: prov.registrando || _batendoPonto,
          onBaterPonto: _baterPonto,
        ),
        const SizedBox(height: 12),
        _HumorDoDiaCard(
          prov: prov,
          branding: b,
          onEscolher: _registrarHumor,
          onSalvarMotivo: (motivo) {
            final nota = prov.meuHumor;
            if (nota != null) _registrarHumor(nota, motivo: motivo);
          },
        ),
      ],
    );
  }
}


/// Card "Hoje" do colaborador — relógio ao vivo, horas trabalhadas, banco
/// de horas e a mini-timeline das marcações do dia, num card com
/// gradiente da cor de marca (inspirado no card de ponto do AlfaDesk
/// Mobile). O CTA de bater ponto fica embutido, em branco, pra destacar
/// dentro do gradiente.
class _JornadaClockCard extends StatelessWidget {
  const _JornadaClockCard({
    required this.status,
    required this.branding,
    required this.agora,
    required this.registrando,
    required this.onBaterPonto,
  });

  final PontoStatus? status;
  final AppBranding branding;
  final DateTime agora;
  final bool registrando;
  final VoidCallback onBaterPonto;

  @override
  Widget build(BuildContext context) {
    final corEscura = Color.lerp(branding.primary, Colors.black, 0.35)!;
    final saldoPositivo = (status?.saldoBancoHorasMinutos ?? 0) >= 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [branding.primary, corEscura],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dataExtensoJornada(agora),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${duasCasasJornada(agora.hour)}:${duasCasasJornada(agora.minute)}:${duasCasasJornada(agora.second)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w800,
              height: 1.0,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _StatColunaJornada(
                label: 'Trabalhadas hoje',
                valor: status?.horasTrabalhadasHoje ?? '—',
              ),
              const SizedBox(width: 28),
              _StatColunaJornada(
                label: 'Banco de horas',
                valor: status?.saldoBancoHoras ?? '—',
                valorColor: status == null
                    ? Colors.white
                    : (saldoPositivo ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5)),
              ),
            ],
          ),
          if (status != null && status!.marcacoesHoje.isNotEmpty) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  for (final (i, m) in status!.marcacoesHoje.indexed) ...[
                    if (i > 0)
                      const Divider(height: 1, color: Colors.white24),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      child: Row(
                        children: [
                          Icon(
                            i.isEven ? Icons.login_rounded : Icons.logout_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              rotuloMarcacaoJornada(i),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(m,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  fontFeatures: [FontFeature.tabularFigures()])),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: registrando ? null : onBaterPonto,
              icon: registrando
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: branding.primary),
                    )
                  : Icon(status?.proximaEhEntrada ?? true
                      ? Icons.login_rounded
                      : Icons.logout_rounded),
              label: Text(status?.proximaEhEntrada ?? true
                  ? 'Registrar entrada'
                  : 'Registrar saída'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: branding.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColunaJornada extends StatelessWidget {
  const _StatColunaJornada({
    required this.label,
    required this.valor,
    this.valorColor = Colors.white,
  });

  final String label;
  final String valor;
  final Color valorColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(valor,
            style: TextStyle(
                color: valorColor, fontSize: 20, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

/// Card "Como você está hoje?" — 5 emojis, 1 registro por dia (sobrescrevível).
/// O RH vê a nota agregada e individual no dashboard web, mas NUNCA o
/// motivo — esse campo é opcional e sigiloso, só o próprio colaborador
/// tem acesso (ver `HumorService.resumoDoDia` no backend).
class _HumorDoDiaCard extends StatefulWidget {
  const _HumorDoDiaCard({
    required this.prov,
    required this.branding,
    required this.onEscolher,
    required this.onSalvarMotivo,
  });

  final JornadaProvider prov;
  final AppBranding branding;
  final ValueChanged<int> onEscolher;
  final ValueChanged<String> onSalvarMotivo;

  @override
  State<_HumorDoDiaCard> createState() => _HumorDoDiaCardState();
}

class _HumorDoDiaCardState extends State<_HumorDoDiaCard> {
  bool _contandoMotivo = false;
  late final _motivoCtrl = TextEditingController(text: widget.prov.meuHumorMotivo ?? '');

  @override
  void dispose() {
    _motivoCtrl.dispose();
    super.dispose();
  }

  void _salvar() {
    final texto = _motivoCtrl.text.trim();
    if (texto.isEmpty) return;
    widget.onSalvarMotivo(texto);
    setState(() => _contandoMotivo = false);
  }

  @override
  Widget build(BuildContext context) {
    final branding = widget.branding;
    final prov = widget.prov;
    final selecionado = prov.meuHumor;
    final motivoSalvo = prov.meuHumorMotivo;
    final ocupado = prov.registrandoHumor || prov.loadingHumor;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Como você está hoje?',
              style: AppTypeScale.subtitulo.copyWith(color: branding.textDark)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_kEmojisHumor.length, (i) {
              final nota = i + 1;
              final ativo = selecionado == nota;
              return Semantics(
                button: true,
                selected: ativo,
                label: 'Humor $nota de ${_kEmojisHumor.length}',
                child: InkWell(
                onTap: ocupado ? null : () => widget.onEscolher(nota),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ativo ? branding.primarySoft : Colors.transparent,
                    border: Border.all(
                      color: ativo ? branding.primary : branding.textMuted.withValues(alpha: 0.3),
                      width: ativo ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    _kEmojisHumor[i],
                    style: const TextStyle(
                      fontSize: 22,
                      // O tema global usa Inter (GoogleFonts), que não tem glifos de
                      // emoji — sem isso, o iOS mostra "tofu" (□?) em vez do emoji.
                      fontFamily: 'Apple Color Emoji',
                      fontFamilyFallback: ['Noto Color Emoji'],
                    ),
                  ),
                ),
                ),
              );
            }),
          ),
          if (selecionado != null) ...[
            const SizedBox(height: 8),
            Text('Humor registrado hoje.',
                style: TextStyle(color: branding.textMuted, fontSize: 12)),
            const SizedBox(height: 10),
            if (motivoSalvo != null && !_contandoMotivo) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: branding.bg,
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  border: Border.all(color: branding.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lock_outline_rounded, size: 13, color: branding.textMuted),
                        const SizedBox(width: 5),
                        Text('Seu motivo (sigiloso)',
                            style: TextStyle(
                                color: branding.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                        const Spacer(),
                        InkWell(
                          onTap: () => setState(() => _contandoMotivo = true),
                          child: Icon(Icons.edit_outlined, size: 15, color: branding.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(motivoSalvo, style: TextStyle(color: branding.textDark, fontSize: 13)),
                  ],
                ),
              ),
            ] else if (_contandoMotivo) ...[
              TextField(
                controller: _motivoCtrl,
                maxLength: 500,
                maxLines: 3,
                autofocus: true,
                enabled: !ocupado,
                decoration: const InputDecoration(
                  hintText: 'Conte o que quiser sobre sua escolha…',
                  isDense: true,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.lock_outline_rounded, size: 13, color: branding.textMuted),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Sigiloso — só você tem acesso a esse texto, nem o gestor nem o RH veem.',
                      style: TextStyle(color: branding.textMuted, fontSize: 11.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: ocupado ? null : () => setState(() => _contandoMotivo = false),
                    child: const Text('Cancelar'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: ocupado ? null : _salvar,
                    style: FilledButton.styleFrom(backgroundColor: branding.primary),
                    child: const Text('Salvar'),
                  ),
                ],
              ),
            ] else ...[
              InkWell(
                onTap: () => setState(() => _contandoMotivo = true),
                borderRadius: BorderRadius.circular(999),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, size: 15, color: branding.primary),
                    const SizedBox(width: 6),
                    Text('Quer registrar o motivo da escolha?',
                        style: TextStyle(
                            color: branding.primary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text('Opcional e sigiloso — só você vê o que escrever.',
                  style: TextStyle(color: branding.textMuted, fontSize: 11)),
            ],
          ],
        ],
      ),
    );
  }
}

/// Home do gestor de RH/departamento do AlfaJornada — quem não é COLABORADOR.
/// Resumo do dia + clima da equipe (inline) e atalhos pra Equipe/Vincular
/// (telas próprias). "Vincular" só aparece pra quem o backend deixa vincular
/// (`Roles.GESTAO_PONTO`) — os demais perfis de gestão (gerente, gestor de
/// depto, assistente de RH) só consultam.
class _JornadaGestorHomeSection extends StatefulWidget {
  const _JornadaGestorHomeSection();

  @override
  State<_JornadaGestorHomeSection> createState() => _JornadaGestorHomeSectionState();
}

class _JornadaGestorHomeSectionState extends State<_JornadaGestorHomeSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final prov = context.read<JornadaGestorProvider>();
      if (prov.resumo == null && !prov.loadingResumo) prov.carregarResumo();
      if (prov.humor == null && !prov.loadingHumorEquipe) prov.carregarHumorEquipe();
    });
  }

  void _abrirClima(BuildContext context, AppBranding b) {
    final humor = context.read<JornadaGestorProvider>().humor;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Clima da equipe hoje',
                  style: AppTypeScale.subtitulo.copyWith(color: b.textDark)),
              const SizedBox(height: 12),
              if (humor == null || humor.individual.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text('Ninguém informou o humor ainda hoje.',
                      style: TextStyle(color: b.textMuted)),
                )
              else
                ...humor.individual.map((h) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Text(_emojiHumor(h.nota),
                              style: const TextStyle(
                                fontSize: 20,
                                fontFamily: 'Apple Color Emoji',
                                fontFamilyFallback: ['Noto Color Emoji'],
                              )),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(h.funcionarioNome,
                                style: TextStyle(color: b.textDark)),
                          ),
                        ],
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = AppBranding.of(context);
    final auth = context.watch<AuthProvider>();
    final prov = context.watch<JornadaGestorProvider>();
    final resumo = prov.resumo;
    final humor = prov.humor;
    final podeVincular = _kPerfisGestaoPonto.contains(auth.perfil?.toLowerCase());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Resumo do dia',
                  style: AppTypeScale.subtitulo.copyWith(color: b.textDark)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppStatTile(
                      icon: Icons.fingerprint,
                      value: resumo != null
                          ? '${resumo.registrosHoje}/${resumo.funcionariosAtivos}'
                          : '—',
                      label: 'BATERAM PONTO',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppStatTile(
                      icon: Icons.error_outline,
                      value: resumo != null ? '${resumo.jornadasInconsistentesHoje}' : '—',
                      label: 'INCONSISTÊNCIAS',
                      valueColor: (resumo?.jornadasInconsistentesHoje ?? 0) > 0 ? b.danger : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Pressable(
          onTap: () => _abrirClima(context, b),
          borderRadius: AppRadius.card,
          child: AppCard(
            child: Row(
              children: [
                Text(
                  humor != null && humor.responderam > 0 ? _emojiHumor(humor.media.round()) : '💬',
                  style: const TextStyle(
                    fontSize: 28,
                    fontFamily: 'Apple Color Emoji',
                    fontFamilyFallback: ['Noto Color Emoji'],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Clima da equipe',
                          style: AppTypeScale.subtitulo.copyWith(color: b.textDark)),
                      const SizedBox(height: 2),
                      Text(
                        humor != null
                            ? '${humor.responderam}/${humor.totalAtivos} informaram o humor hoje'
                            : 'Carregando…',
                        style: TextStyle(color: b.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: b.textMuted),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppStatTile(
                icon: Icons.groups_outlined,
                value: '',
                label: 'VER EQUIPE',
                compact: true,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EquipeHojeScreen()),
                ),
              ),
            ),
            if (podeVincular) ...[
              const SizedBox(width: 12),
              Expanded(
                child: AppStatTile(
                  icon: Icons.link,
                  value: '',
                  label: 'VINCULAR COLABORADOR',
                  compact: true,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const VincularScreen()),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Aviso de marcações capturadas offline aguardando sincronizar — mostra
/// quantas e deixa tentar de novo manualmente (além da tentativa
/// automática ao abrir a tela). Itens com erro de negócio (ex.: janela de
/// tolerância vencida) podem ser descartados individualmente.
class _PendentesBanner extends StatelessWidget {
  const _PendentesBanner({required this.prov, required this.branding});
  final JornadaProvider prov;
  final AppBranding branding;

  @override
  Widget build(BuildContext context) {
    final comErro = prov.filaPendente.where((p) => p.erro != null).toList();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_upload_outlined, color: branding.warning, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${prov.filaPendente.length} marcação(ões) aguardando sincronizar',
                  style: TextStyle(fontWeight: FontWeight.w600, color: branding.textDark),
                ),
              ),
              if (prov.sincronizando)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                TextButton(
                  onPressed: prov.sincronizarFila,
                  child: const Text('Sincronizar'),
                ),
            ],
          ),
          for (final pendente in comErro)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(pendente.erro!,
                        style: TextStyle(fontSize: 12, color: branding.danger)),
                  ),
                  TextButton(
                    onPressed: () => prov.descartarPendente(pendente.id),
                    child: const Text('Descartar'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}


class _NotifBell extends StatelessWidget {
  const _NotifBell({required this.branding});
  final AppBranding branding;

  @override
  Widget build(BuildContext context) {
    final count = context.watch<NotificacoesProvider>().naoLidas;
    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.notifications_none, color: branding.textDark),
          if (count > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: branding.danger,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: branding.card, width: 1.5),
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
      tooltip: 'Notificações',
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NotificacoesScreen()),
        );
      },
    );
  }
}

/// Avatar grande (96px) com nome do usuário, usado no topo da Home.
class _AvatarHeader extends StatelessWidget {
  const _AvatarHeader({
    required this.name,
    required this.branding,
    this.foto,
  });
  final String name;
  final String? foto;
  final AppBranding branding;

  @override
  Widget build(BuildContext context) {
    const size = 96.0;
    return Center(
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: branding.primarySoft,
              shape: BoxShape.circle,
              border: Border.all(color: branding.primary, width: 3),
            ),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            child: _avatarChild(size),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: BoxDecoration(
              color: branding.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarChild(double size) {
    final fallback = _iniciais().isEmpty
        ? Icon(Icons.person, size: size * 0.56, color: branding.textMuted)
        : Text(
            _iniciais(),
            style: TextStyle(
              color: branding.primary,
              fontWeight: FontWeight.w800,
              fontSize: size * 0.36,
            ),
          );
    final f = foto;
    if (f == null || f.isEmpty) return fallback;
    if (f.startsWith('http')) {
      return Image.network(
        f,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    final bytes = decodeFotoBase64(f);
    if (bytes == null) return fallback;
    return Image.memory(
      bytes,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
    );
  }

  String _iniciais() {
    final partes = name.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty || partes.first.isEmpty) return '';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return (partes.first[0] + partes.last[0]).toUpperCase();
  }
}

String _saudacao(String nome) {
  final hora = DateTime.now().hour;
  final cumprimento = hora < 12 ? 'Bom dia' : hora < 18 ? 'Boa tarde' : 'Boa noite';
  final primeiroNome = nome.split(' ').first;
  return '$cumprimento, $primeiroNome';
}
