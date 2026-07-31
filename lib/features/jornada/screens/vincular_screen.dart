import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/branding/app_branding.dart';
import '../../../core/widgets/app_card.dart';
import '../models/vinculo_candidatos.dart';
import '../state/jornada_gestor_provider.dart';

/// Vincula um usuário (login) a um colaborador — habilita o self-service de
/// ponto pelo app pra ele. Só usuários e colaboradores SEM vínculo aparecem.
class VincularScreen extends StatefulWidget {
  const VincularScreen({super.key});

  @override
  State<VincularScreen> createState() => _VincularScreenState();
}

class _VincularScreenState extends State<VincularScreen> {
  UsuarioSemVinculo? _usuario;
  FuncionarioSemVinculo? _funcionario;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final prov = context.read<JornadaGestorProvider>();
      if (prov.candidatos == null && !prov.loadingCandidatos) {
        prov.carregarCandidatos();
      }
    });
  }

  Future<void> _vincular() async {
    final usuario = _usuario;
    final funcionario = _funcionario;
    if (usuario == null || funcionario == null) return;
    final prov = context.read<JornadaGestorProvider>();
    final erro = await prov.vincular(usuarioId: usuario.id, funcionarioId: funcionario.id);
    if (!mounted) return;
    if (erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erro)));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${usuario.nome} vinculado a ${funcionario.nome}.')),
    );
    setState(() {
      _usuario = null;
      _funcionario = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final b = AppBranding.of(context);
    final prov = context.watch<JornadaGestorProvider>();
    final candidatos = prov.candidatos;

    return Scaffold(
      appBar: AppBar(title: const Text('Vincular colaborador')),
      body: RefreshIndicator(
        onRefresh: () => prov.carregarCandidatos(refresh: true),
        child: _buildBody(prov, candidatos, b),
      ),
    );
  }

  Widget _buildBody(JornadaGestorProvider prov, VinculoCandidatos? candidatos, AppBranding b) {
    if (prov.loadingCandidatos && candidatos == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (prov.erroCandidatos != null && candidatos == null) {
      return ListView(children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.cloud_off_outlined, size: 56, color: b.danger),
              const SizedBox(height: 12),
              Text(prov.erroCandidatos!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => prov.carregarCandidatos(refresh: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar de novo'),
              ),
            ],
          ),
        ),
      ]);
    }

    final usuarios = candidatos?.usuarios ?? const [];
    final funcionarios = candidatos?.funcionarios ?? const [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Usuário (login)', style: TextStyle(color: b.textMuted, fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        AppCard(
          child: usuarios.isEmpty
              ? Text('Todos os usuários já estão vinculados.', style: TextStyle(color: b.textMuted))
              : DropdownButtonFormField<UsuarioSemVinculo>(
                  initialValue: _usuario,
                  isExpanded: true,
                  decoration: const InputDecoration(border: InputBorder.none),
                  hint: const Text('Selecione o usuário'),
                  items: usuarios
                      .map((u) => DropdownMenuItem(value: u, child: Text('${u.nome} · ${u.email}')))
                      .toList(),
                  onChanged: (v) => setState(() => _usuario = v),
                ),
        ),
        const SizedBox(height: 20),
        Text('Colaborador', style: TextStyle(color: b.textMuted, fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        AppCard(
          child: funcionarios.isEmpty
              ? Text('Todos os colaboradores já estão vinculados.', style: TextStyle(color: b.textMuted))
              : DropdownButtonFormField<FuncionarioSemVinculo>(
                  initialValue: _funcionario,
                  isExpanded: true,
                  decoration: const InputDecoration(border: InputBorder.none),
                  hint: const Text('Selecione o colaborador'),
                  items: funcionarios
                      .map((f) => DropdownMenuItem(value: f, child: Text(f.nome)))
                      .toList(),
                  onChanged: (v) => setState(() => _funcionario = v),
                ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: (_usuario != null && _funcionario != null && !prov.vinculando) ? _vincular : null,
            child: prov.vinculando
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Vincular'),
          ),
        ),
      ],
    );
  }
}
