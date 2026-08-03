import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/branding/app_branding.dart';
import '../../../core/responsive/responsive_list_view.dart';
import '../models/notificacao.dart';
import '../state/notificacoes_provider.dart';
import '../utils/notificacao_labels.dart';

class NotificacoesScreen extends StatefulWidget {
  const NotificacoesScreen({super.key});

  @override
  State<NotificacoesScreen> createState() => _NotificacoesScreenState();
}

class _NotificacoesScreenState extends State<NotificacoesScreen> {
  final _buscaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<NotificacoesProvider>().carregarTudo(),
    );
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  Future<void> _abrirFiltrosAvancados() async {
    final provider = context.read<NotificacoesProvider>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _FiltrosAvancadosSheet(
        inicio: provider.dataInicio,
        fim: provider.dataFim,
        onAplicar: (inicio, fim) {
          provider.setDataInicio(inicio);
          provider.setDataFim(fim);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = AppBranding.of(context);
    final prov = context.watch<NotificacoesProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        actions: [
          IconButton(
            tooltip: 'Filtros avançados',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.tune),
                if (prov.dataInicio != null || prov.dataFim != null)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: b.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _abrirFiltrosAvancados,
          ),
          if (prov.naoLidas > 0)
            TextButton(
              onPressed: () async {
                final ok = await prov.marcarTodasLidas();
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Não foi possível marcar as notificações como lidas. Verifique sua conexão.')),
                  );
                }
              },
              child: Text(
                'Marcar todas',
                style: TextStyle(color: b.primary),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => prov.carregarTudo(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: TextField(
              controller: _buscaCtrl,
              onChanged: prov.setBusca,
              decoration: InputDecoration(
                hintText: 'Buscar no título ou mensagem',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _buscaCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _buscaCtrl.clear();
                          prov.setBusca('');
                        },
                      ),
                filled: true,
                fillColor: b.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: b.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: b.border),
                ),
              ),
            ),
          ),
          _StatusChips(provider: prov, branding: b),
          if (prov.tiposDisponiveis.isNotEmpty)
            _TipoChips(provider: prov, branding: b),
          if (prov.dataInicio != null || prov.dataFim != null)
            _ResumoData(provider: prov, branding: b),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => prov.carregarTudo(),
              child: _buildBody(prov, b),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(NotificacoesProvider prov, AppBranding b) {
    if (prov.loading && prov.lista.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (prov.erro != null && prov.lista.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [Text(prov.erro!, style: TextStyle(color: b.danger))],
      );
    }
    final itens = prov.filtradas;
    if (itens.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 80),
          Icon(
            prov.temAlgumFiltro
                ? Icons.filter_alt_off_outlined
                : Icons.notifications_none,
            size: 100,
            color: b.textMuted,
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              prov.temAlgumFiltro
                  ? 'Nenhuma notificação encontrada com esses filtros'
                  : 'Você está em dia',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (prov.temAlgumFiltro) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  _buscaCtrl.clear();
                  prov.limparFiltros();
                },
                icon: const Icon(Icons.clear),
                label: const Text('Limpar filtros'),
              ),
            ),
          ],
        ],
      );
    }
    return ResponsiveListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: itens.length,
      compactSeparator: (_, _) => const SizedBox(height: 10),
      tabletAspectRatio: 2.4,
      itemBuilder: (context, i) => _NotifCard(
        n: itens[i],
        b: b,
        onTap: () async {
          final estavaNaoLida = !itens[i].lida;
          final ok = await prov.marcarLida(itens[i].id);
          if (!ok && estavaNaoLida && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'Não foi possível marcar como lida. Verifique sua conexão.')),
            );
          }
        },
      ),
    );
  }
}

class _StatusChips extends StatelessWidget {
  const _StatusChips({required this.provider, required this.branding});
  final NotificacoesProvider provider;
  final AppBranding branding;

  @override
  Widget build(BuildContext context) {
    final b = branding;
    Widget chip(String label, FiltroStatusNotif valor, {int? count}) {
      final sel = provider.filtroStatus == valor;
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: FilterChip(
          label: Text(count != null && count > 0
              ? '$label ($count)'
              : label),
          selected: sel,
          showCheckmark: false,
          onSelected: (_) => provider.setFiltroStatus(valor),
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: sel ? b.primary : b.textDark,
          ),
          backgroundColor: b.card,
          selectedColor: b.primary.withValues(alpha: 0.12),
          side: BorderSide(
            color: sel ? b.primary.withValues(alpha: 0.5) : b.border,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            chip('Todas', FiltroStatusNotif.todas),
            chip('Não lidas', FiltroStatusNotif.naoLidas,
                count: provider.naoLidas),
            chip('Lidas', FiltroStatusNotif.lidas),
          ],
        ),
      ),
    );
  }
}

class _TipoChips extends StatelessWidget {
  const _TipoChips({required this.provider, required this.branding});
  final NotificacoesProvider provider;
  final AppBranding branding;

  @override
  Widget build(BuildContext context) {
    final b = branding;
    Widget chip(String? tipo, String label) {
      final sel = provider.filtroTipo == tipo;
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: FilterChip(
          label: Text(label),
          selected: sel,
          showCheckmark: false,
          onSelected: (_) => provider.setFiltroTipo(sel ? null : tipo),
          labelStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: sel ? b.primary : b.textMuted,
          ),
          backgroundColor: b.card,
          selectedColor: b.primary.withValues(alpha: 0.12),
          side: BorderSide(
            color: sel ? b.primary.withValues(alpha: 0.5) : b.border,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            chip(null, 'Todos tipos'),
            for (final t in provider.tiposDisponiveis)
              chip(t, traduzirTipoNotificacao(t)),
          ],
        ),
      ),
    );
  }
}

class _ResumoData extends StatelessWidget {
  const _ResumoData({required this.provider, required this.branding});
  final NotificacoesProvider provider;
  final AppBranding branding;

  static final _fmt = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    final b = branding;
    final inicio = provider.dataInicio;
    final fim = provider.dataFim;
    final partes = <String>[];
    if (inicio != null) partes.add('A partir de ${_fmt.format(inicio)}');
    if (fim != null) partes.add('Até ${_fmt.format(fim)}');
    return Container(
      color: b.card,
      padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
      child: Row(
        children: [
          Icon(Icons.calendar_today_outlined, size: 12, color: b.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              partes.join(' · '),
              style: TextStyle(fontSize: 11, color: b.textMuted),
            ),
          ),
          TextButton.icon(
            onPressed: () {
              provider.setDataInicio(null);
              provider.setDataFim(null);
            },
            icon: Icon(Icons.clear, size: 14, color: b.danger),
            label: Text(
              'Limpar datas',
              style: TextStyle(color: b.danger, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltrosAvancadosSheet extends StatefulWidget {
  const _FiltrosAvancadosSheet({
    required this.inicio,
    required this.fim,
    required this.onAplicar,
  });
  final DateTime? inicio;
  final DateTime? fim;
  final void Function(DateTime? inicio, DateTime? fim) onAplicar;

  @override
  State<_FiltrosAvancadosSheet> createState() => _FiltrosAvancadosSheetState();
}

class _FiltrosAvancadosSheetState extends State<_FiltrosAvancadosSheet> {
  late DateTime? _inicio;
  late DateTime? _fim;

  static final _fmt = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _inicio = widget.inicio;
    _fim = widget.fim;
  }

  Future<void> _pick({
    required DateTime? atual,
    required ValueChanged<DateTime?> onChange,
  }) async {
    final hoje = DateTime.now();
    final res = await showDatePicker(
      context: context,
      initialDate: atual ?? hoje,
      firstDate: DateTime(hoje.year - 5),
      lastDate: DateTime(hoje.year + 1),
    );
    if (res != null) onChange(res);
  }

  @override
  Widget build(BuildContext context) {
    final b = AppBranding.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Filtros avançados',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: b.textDark,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Janela de data',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: b.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pick(
                    atual: _inicio,
                    onChange: (d) => setState(() =>
                        _inicio = DateTime(d!.year, d.month, d.day)),
                  ),
                  icon: Icon(Icons.calendar_today_outlined,
                      size: 16, color: b.textMuted),
                  label: Text(
                    _inicio != null ? _fmt.format(_inicio!) : 'Data início',
                    style: TextStyle(
                      fontSize: 13,
                      color: _inicio != null ? b.textDark : b.textMuted,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    side: BorderSide(color: b.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pick(
                    atual: _fim,
                    onChange: (d) => setState(
                      () => _fim = DateTime(d!.year, d.month, d.day,
                          23, 59, 59),
                    ),
                  ),
                  icon: Icon(Icons.calendar_today_outlined,
                      size: 16, color: b.textMuted),
                  label: Text(
                    _fim != null ? _fmt.format(_fim!) : 'Data fim',
                    style: TextStyle(
                      fontSize: 13,
                      color: _fim != null ? b.textDark : b.textMuted,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    side: BorderSide(color: b.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _inicio = null;
                      _fim = null;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Limpar'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    widget.onAplicar(_inicio, _fim);
                    Navigator.of(context).pop();
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Aplicar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  const _NotifCard({required this.n, required this.b, required this.onTap});
  final Notificacao n;
  final AppBranding b;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: b.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: n.lida ? b.border : b.primary.withValues(alpha: 0.4),
            width: n.lida ? 1 : 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: b.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                iconeTipoNotificacao(n.tipo),
                color: b.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n.titulo,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                n.lida ? FontWeight.w600 : FontWeight.w800,
                          ),
                        ),
                      ),
                      if (!n.lida)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: b.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n.mensagem,
                    style: TextStyle(color: b.textDark, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (n.tipo.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: b.primarySoft,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            traduzirTipoNotificacao(n.tipo),
                            style: TextStyle(
                              color: b.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          DateFormat("dd/MM/yyyy 'às' HH:mm")
                              .format(n.createdAt),
                          style:
                              TextStyle(color: b.textMuted, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
