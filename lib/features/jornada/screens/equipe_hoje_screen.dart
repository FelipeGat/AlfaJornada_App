import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/branding/app_branding.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/app_card.dart';
import '../models/equipe_hoje_item.dart';
import '../state/jornada_gestor_provider.dart';

/// Lista da equipe ativa com status de ponto do dia — tela do gestor.
class EquipeHojeScreen extends StatefulWidget {
  const EquipeHojeScreen({super.key});

  @override
  State<EquipeHojeScreen> createState() => _EquipeHojeScreenState();
}

class _EquipeHojeScreenState extends State<EquipeHojeScreen> {
  final _buscaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final prov = context.read<JornadaGestorProvider>();
      if (prov.equipe.isEmpty && !prov.loadingEquipe) {
        prov.carregarEquipe();
      }
    });
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = AppBranding.of(context);
    final prov = context.watch<JornadaGestorProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Equipe hoje')),
      body: RefreshIndicator(
        onRefresh: () => prov.carregarEquipe(refresh: true),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _buscaCtrl,
                decoration: InputDecoration(
                  hintText: 'Buscar por nome',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: b.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    borderSide: BorderSide(color: b.border),
                  ),
                ),
                onSubmitted: (v) => prov.carregarEquipe(refresh: true, busca: v),
              ),
            ),
            Expanded(child: _buildLista(prov, b)),
          ],
        ),
      ),
    );
  }

  Widget _buildLista(JornadaGestorProvider prov, AppBranding b) {
    if (prov.loadingEquipe && prov.equipe.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (prov.erroEquipe != null && prov.equipe.isEmpty) {
      return ListView(children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.cloud_off_outlined, size: 56, color: b.danger),
              const SizedBox(height: 12),
              Text(prov.erroEquipe!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => prov.carregarEquipe(refresh: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar de novo'),
              ),
            ],
          ),
        ),
      ]);
    }
    if (prov.equipe.isEmpty) {
      return ListView(children: [
        const SizedBox(height: 80),
        Icon(Icons.groups_outlined, size: 56, color: b.textMuted),
        const SizedBox(height: 12),
        Center(
          child: Text('Nenhum colaborador encontrado.',
              style: TextStyle(color: b.textMuted)),
        ),
      ]);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: prov.equipe.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        if (i == prov.equipe.length) {
          if (prov.loadingEquipe) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (!prov.equipeTemMais) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: OutlinedButton(
                onPressed: () => prov.carregarEquipe(),
                child: const Text('Carregar mais'),
              ),
            ),
          );
        }
        return _EquipeTile(item: prov.equipe[i], branding: b);
      },
    );
  }
}

class _EquipeTile extends StatelessWidget {
  const _EquipeTile({required this.item, required this.branding});
  final EquipeHojeItem item;
  final AppBranding branding;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: (item.bateuPontoHoje ? branding.success : branding.warning).withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.bateuPontoHoje ? Icons.check_circle_outline : Icons.schedule,
              color: item.bateuPontoHoje ? branding.success : branding.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.nome, style: AppTypeScale.subtitulo.copyWith(color: branding.textDark)),
                if (item.departamentoNome != null) ...[
                  const SizedBox(height: 2),
                  Text(item.departamentoNome!,
                      style: TextStyle(color: branding.textMuted, fontSize: 12)),
                ],
              ],
            ),
          ),
          Text(
            item.bateuPontoHoje ? (item.ultimaMarcacao ?? 'Bateu') : 'Não bateu',
            style: TextStyle(
              color: item.bateuPontoHoje ? branding.textDark : branding.warning,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
