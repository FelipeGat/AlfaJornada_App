import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/branding/app_branding.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/app_card.dart';
import '../models/banco_horas.dart';
import '../models/batida_ponto.dart';
import '../models/humor_historico_item.dart';
import '../state/jornada_provider.dart';
import '../utils/jornada_format.dart';

const _kEmojisHumorHistorico = ['😞', '😕', '😐', '🙂', '😄'];

/// Histórico do colaborador — 2ª aba do AlfaJornada. Três abas: Batidas
/// (agrupadas por dia, com estágio da jornada e total trabalhado),
/// Banco de horas (saldo + extrato) e Humor (histórico sigiloso, só o
/// próprio colaborador vê).
class HistoricoPontoScreen extends StatefulWidget {
  const HistoricoPontoScreen({super.key});

  @override
  State<HistoricoPontoScreen> createState() => _HistoricoPontoScreenState();
}

class _HistoricoPontoScreenState extends State<HistoricoPontoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final prov = context.read<JornadaProvider>();
      if (prov.historico.isEmpty && !prov.loadingHistorico) {
        prov.carregarHistorico();
      }
      prov.carregarBancoHoras();
      prov.carregarHumorHistorico();
    });
  }

  @override
  Widget build(BuildContext context) {
    final b = AppBranding.of(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Histórico'),
          bottom: TabBar(
            labelColor: b.primary,
            unselectedLabelColor: b.textMuted,
            indicatorColor: b.primary,
            tabs: const [
              Tab(text: 'Batidas'),
              Tab(text: 'Banco de horas'),
              Tab(text: 'Humor'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _BatidasTab(branding: b),
            _BancoHorasTab(branding: b),
            _HumorTab(branding: b),
          ],
        ),
      ),
    );
  }
}

// ─── Aba Batidas ────────────────────────────────────────────────────────────

class _BatidasTab extends StatelessWidget {
  const _BatidasTab({required this.branding});
  final AppBranding branding;

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<JornadaProvider>();
    return RefreshIndicator(
      onRefresh: () => prov.carregarHistorico(refresh: true),
      child: _buildBody(prov),
    );
  }

  Widget _buildBody(JornadaProvider prov) {
    if (prov.loadingHistorico && prov.historico.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (prov.erroHistorico != null && prov.historico.isEmpty) {
      return _EstadoErro(
        mensagem: prov.erroHistorico!,
        branding: branding,
        onTentar: () => prov.carregarHistorico(refresh: true),
      );
    }
    if (prov.historico.isEmpty) {
      return _EstadoVazio(
        icone: Icons.history,
        mensagem: 'Nenhuma marcação registrada ainda.',
        branding: branding,
      );
    }

    final grupos = _agruparPorDia(prov.historico);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: grupos.length + 1,
      itemBuilder: (context, i) {
        if (i == grupos.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 4),
            child: _RodapePaginacao(prov: prov),
          );
        }
        final dia = grupos[i].key;
        final ascendente = grupos[i].value;
        return _GrupoDiaBatidas(dia: dia, batidas: ascendente, branding: branding);
      },
    );
  }

  /// Agrupa por dia (mais recente primeiro); dentro do dia, ordena
  /// cronologicamente (mais antiga primeiro) pra o índice virar o
  /// estágio certo da jornada (entrada/saída almoço/volta/saída) —
  /// ordena localmente em vez de confiar na ordem da API.
  List<MapEntry<DateTime, List<BatidaHistorico>>> _agruparPorDia(List<BatidaHistorico> lista) {
    final grupos = <DateTime, List<BatidaHistorico>>{};
    final ordenadaDesc = [...lista]..sort((a, b) => b.dataHora.compareTo(a.dataHora));
    for (final batida in ordenadaDesc) {
      final dia = DateTime(batida.dataHora.year, batida.dataHora.month, batida.dataHora.day);
      (grupos[dia] ??= []).add(batida);
    }
    for (final entrada in grupos.entries) {
      entrada.value.sort((a, b) => a.dataHora.compareTo(b.dataHora));
    }
    return grupos.entries.toList();
  }
}

class _GrupoDiaBatidas extends StatelessWidget {
  const _GrupoDiaBatidas({required this.dia, required this.batidas, required this.branding});

  final DateTime dia;
  final List<BatidaHistorico> batidas;
  final AppBranding branding;

  Duration? get _totalTrabalhado {
    if (batidas.length < 2) return null;
    var total = Duration.zero;
    for (var i = 0; i + 1 < batidas.length; i += 2) {
      total += batidas[i + 1].dataHora.difference(batidas[i].dataHora);
    }
    return total;
  }

  String _formatDuracao(Duration d) =>
      '${d.inHours}h${(d.inMinutes % 60).toString().padLeft(2, '0')}';

  String _origemLabel(String origem) => switch (origem) {
        'MOBILE' => 'App',
        'DISPOSITIVO' => 'Relógio de ponto',
        'KIOSK' => 'Totem',
        _ => 'Lançamento manual (RH)',
      };

  @override
  Widget build(BuildContext context) {
    final total = _totalTrabalhado;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 2),
            child: Row(
              children: [
                Text(
                  dataExtensoJornada(dia),
                  style: TextStyle(
                    color: branding.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                if (total != null) ...[
                  const Spacer(),
                  Text(
                    '${_formatDuracao(total)} trabalhadas',
                    style: TextStyle(
                      color: branding.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(
              children: [
                for (final (i, batida) in batidas.indexed) ...[
                  if (i > 0) Divider(height: 1, color: branding.border),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: branding.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            i.isEven ? Icons.login_rounded : Icons.logout_rounded,
                            color: branding.primary,
                            size: 17,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(rotuloMarcacaoJornada(i),
                                  style: AppTypeScale.texto
                                      .copyWith(color: branding.textDark, fontSize: 14)),
                              const SizedBox(height: 1),
                              Text(_origemLabel(batida.origem),
                                  style: AppTypeScale.descricao.copyWith(color: branding.textMuted)),
                            ],
                          ),
                        ),
                        Text(
                          '${duasCasasJornada(batida.dataHora.hour)}:${duasCasasJornada(batida.dataHora.minute)}',
                          style: TextStyle(
                            color: branding.textDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RodapePaginacao extends StatelessWidget {
  const _RodapePaginacao({required this.prov});
  final JornadaProvider prov;

  @override
  Widget build(BuildContext context) {
    if (prov.loadingHistorico) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (!prov.historicoTemMais) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: OutlinedButton(
          onPressed: () => prov.carregarHistorico(),
          child: const Text('Carregar mais'),
        ),
      ),
    );
  }
}

// ─── Aba Banco de horas ─────────────────────────────────────────────────────

class _BancoHorasTab extends StatelessWidget {
  const _BancoHorasTab({required this.branding});
  final AppBranding branding;

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<JornadaProvider>();
    return RefreshIndicator(
      onRefresh: () => prov.carregarBancoHoras(refresh: true),
      child: _buildBody(prov),
    );
  }

  Widget _buildBody(JornadaProvider prov) {
    if (prov.loadingBancoHoras && prov.bancoHoras == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (prov.erroBancoHoras != null && prov.bancoHoras == null) {
      return _EstadoErro(
        mensagem: prov.erroBancoHoras!,
        branding: branding,
        onTentar: () => prov.carregarBancoHoras(refresh: true),
      );
    }
    final banco = prov.bancoHoras;
    if (banco == null) return const SizedBox.shrink();

    final positivo = banco.saldoMinutos >= 0;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: positivo ? branding.success.withValues(alpha: 0.12) : branding.danger.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: positivo ? branding.success : branding.danger, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Saldo atual',
                  style: AppTypeScale.descricao.copyWith(color: branding.textMuted)),
              const SizedBox(height: 4),
              Text(
                banco.saldoFormatado,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: positivo ? branding.success : branding.danger,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (banco.extrato.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: _EstadoVazio(
              icone: Icons.receipt_long_outlined,
              mensagem: 'Nenhum movimento no banco de horas ainda.',
              branding: branding,
            ),
          )
        else ...[
          Text('Extrato',
              style: AppTypeScale.subtitulo.copyWith(color: branding.textDark, fontSize: 15)),
          const SizedBox(height: 10),
          for (final mov in banco.extrato.reversed) _MovimentoTile(mov: mov, branding: branding),
        ],
      ],
    );
  }
}

class _MovimentoTile extends StatelessWidget {
  const _MovimentoTile({required this.mov, required this.branding});
  final MovimentoBancoHoras mov;
  final AppBranding branding;

  String get _origemLabel => switch (mov.origem) {
        'APURACAO' => 'Fechamento do período',
        'COMPENSACAO' => 'Compensação',
        _ => 'Ajuste manual (RH)',
      };

  @override
  Widget build(BuildContext context) {
    final credito = mov.tipo == 'CREDITO';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(
              credito ? Icons.add_circle_outline : Icons.remove_circle_outline,
              color: credito ? branding.success : branding.danger,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mov.descricao?.isNotEmpty == true ? mov.descricao! : _origemLabel,
                    style: AppTypeScale.texto.copyWith(color: branding.textDark, fontSize: 14),
                  ),
                  Text(dataCurtaJornada(mov.data),
                      style: AppTypeScale.descricao.copyWith(color: branding.textMuted)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  mov.minutosFormatado,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: credito ? branding.success : branding.danger,
                  ),
                ),
                Text('saldo ${mov.saldoAcumuladoFormatado}',
                    style: AppTypeScale.descricao.copyWith(color: branding.textMuted, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Aba Humor ──────────────────────────────────────────────────────────────

class _HumorTab extends StatelessWidget {
  const _HumorTab({required this.branding});
  final AppBranding branding;

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<JornadaProvider>();
    return RefreshIndicator(
      onRefresh: () => prov.carregarHumorHistorico(refresh: true),
      child: _buildBody(prov),
    );
  }

  Widget _buildBody(JornadaProvider prov) {
    if (prov.loadingHumorHistorico && prov.humorHistorico.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (prov.erroHumorHistorico != null && prov.humorHistorico.isEmpty) {
      return _EstadoErro(
        mensagem: prov.erroHumorHistorico!,
        branding: branding,
        onTentar: () => prov.carregarHumorHistorico(refresh: true),
      );
    }
    if (prov.humorHistorico.isEmpty) {
      return _EstadoVazio(
        icone: Icons.mood_outlined,
        mensagem: 'Nenhum humor registrado ainda.',
        branding: branding,
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Icon(Icons.lock_outline_rounded, size: 13, color: branding.textMuted),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                'Sigiloso — só você tem acesso a esse histórico e aos motivos contados.',
                style: TextStyle(color: branding.textMuted, fontSize: 11.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final item in prov.humorHistorico) _HumorHistoricoTile(item: item, branding: branding),
      ],
    );
  }
}

class _HumorHistoricoTile extends StatelessWidget {
  const _HumorHistoricoTile({required this.item, required this.branding});
  final HumorHistoricoItem item;
  final AppBranding branding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _kEmojisHumorHistorico[(item.nota.clamp(1, 5)) - 1],
              style: const TextStyle(
                fontSize: 26,
                fontFamily: 'Apple Color Emoji',
                fontFamilyFallback: ['Noto Color Emoji'],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dataExtensoJornada(item.data),
                      style: AppTypeScale.texto.copyWith(color: branding.textDark, fontSize: 14)),
                  if (item.motivo != null && item.motivo!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(item.motivo!,
                        style: AppTypeScale.descricao.copyWith(color: branding.textMuted)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Estados compartilhados ─────────────────────────────────────────────────

class _EstadoVazio extends StatelessWidget {
  const _EstadoVazio({required this.icone, required this.mensagem, required this.branding});
  final IconData icone;
  final String mensagem;
  final AppBranding branding;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Icon(icone, size: 56, color: branding.textMuted),
        const SizedBox(height: 12),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(mensagem, textAlign: TextAlign.center, style: TextStyle(color: branding.textMuted)),
          ),
        ),
      ],
    );
  }
}

class _EstadoErro extends StatelessWidget {
  const _EstadoErro({required this.mensagem, required this.branding, required this.onTentar});
  final String mensagem;
  final AppBranding branding;
  final VoidCallback onTentar;

  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.cloud_off_outlined, size: 56, color: branding.danger),
            const SizedBox(height: 12),
            Text(mensagem, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onTentar,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar de novo'),
            ),
          ],
        ),
      ),
    ]);
  }
}
