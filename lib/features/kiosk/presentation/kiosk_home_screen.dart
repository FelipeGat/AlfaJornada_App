import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/branding/app_branding.dart';
import '../../../core/storage/kiosk_storage.dart';
import '../../jornada/branding/alfa_jornada_mark.dart';
import '../data/kiosk_api.dart';
import '../data/kiosk_face_store.dart';
import '../data/kiosk_sync_service.dart';
import 'kiosk_setup_screen.dart';

enum _KioskEstado {
  carregando,
  idle,
  identificando,
  confirmando,
  registrando,
  sucesso,
  erro,
  semCamera,
}

/// Tela fixa do Modo Totem: câmera ao vivo tentando reconhecer o rosto de
/// quem se aproxima, confirmação manual obrigatória antes de gravar (não
/// há liveness detection — a confirmação + a foto de evidência são a
/// mitigação, não bloqueio em tempo real), e PIN sempre disponível como
/// alternativa quando o rosto não é reconhecido.
class KioskHomeScreen extends StatefulWidget {
  const KioskHomeScreen({
    super.key,
    required this.api,
    required this.storage,
    required this.faceStore,
  });

  final KioskApi api;
  final KioskStorage storage;
  final KioskFaceStore faceStore;

  @override
  State<KioskHomeScreen> createState() => _KioskHomeScreenState();
}

class _KioskHomeScreenState extends State<KioskHomeScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  CameraController? _controller;
  Timer? _scanTimer;
  Timer? _clockTimer;
  Timer? _recentesTimer;
  Timer? _syncTimer;
  bool _scanEmAndamento = false;
  bool _dialogAberto = false;
  String? _token;

  /// Cooldown local por funcionário: quem acabou de bater e continua na
  /// frente da câmera não pode ser re-prompted em loop (o backend também
  /// rejeitaria pelo intervalo mínimo — melhor nem perguntar).
  final Map<int, DateTime> _ultimaBatidaLocal = {};
  static const _cooldownPorFuncionario = Duration(seconds: 60);

  _KioskEstado _estado = _KioskEstado.carregando;
  KioskIdentificacao? _candidato;
  String? _fotoConfirmacaoPath;
  KioskRegistro? _resultado;
  String? _mensagemErro;
  DateTime _agora = DateTime.now();
  List<KioskRecenteItem> _recentes = [];

  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Totem fica ligado o dia inteiro — sem wakelock a tela apaga pelo
    // timeout do SO e o terminal "morre" pra quem chega na recepção.
    WakelockPlus.enable();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _agora = DateTime.now());
    });
    // Cliente pode ter mais de um totem — atualiza mesmo sem ninguém bater
    // ponto NESTE aparelho, pra refletir marcações feitas em outro terminal.
    _recentesTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _carregarRecentes(),
    );
    // Roster não pode congelar no do dia do setup: contratado novo precisa
    // ser reconhecido e desligado/revogado precisa sumir da base local.
    _syncTimer = Timer.periodic(
      const Duration(hours: 4),
      (_) => _sincronizarRoster(),
    );
    _iniciar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    _scanTimer?.cancel();
    _clockTimer?.cancel();
    _recentesTimer?.cancel();
    _syncTimer?.cancel();
    _pulseCtrl.dispose();
    _controller?.dispose();
    _apagarFoto(_fotoConfirmacaoPath);
    super.dispose();
  }

  /// Re-sync best-effort do roster — falha (offline, backend fora) nunca
  /// derruba o totem; a base local continua valendo até a próxima tentativa.
  Future<void> _sincronizarRoster() async {
    final token = _token;
    if (token == null || token.isEmpty) return;
    try {
      await KioskSyncService(widget.api, widget.faceStore).sincronizar(token);
    } on KioskApiException catch (e) {
      if (e.tokenInvalido && mounted) _abrirConfiguracao();
    } catch (_) {
      // silencioso: tenta de novo no próximo ciclo de 4h
    }
  }

  /// Fotos de scan/evidência são efêmeras: apagadas assim que deixam de
  /// ser necessárias — o tablet fica ligado o dia inteiro e um JPEG a
  /// cada ~1,6s encheria o disco (e reteria imagem de quem só passou).
  void _apagarFoto(String? path) {
    if (path == null) return;
    try {
      File(path).deleteSync();
    } catch (_) {
      // Best-effort: arquivo pode já ter sido limpo pelo SO.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _scanTimer?.cancel();
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _iniciarCamera();
    }
  }

  Future<void> _iniciar() async {
    _token = await widget.storage.readToken();
    if (_token == null || _token!.isEmpty) {
      _abrirConfiguracao();
      return;
    }
    await _iniciarCamera();
    // Tablet pode ter ficado dias desligado (ou reiniciado) — atualiza o
    // roster já na abertura, sem bloquear a câmera.
    unawaited(_sincronizarRoster());
  }

  Future<void> _iniciarCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) setState(() => _estado = _KioskEstado.semCamera);
      return;
    }
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _estado = _KioskEstado.semCamera);
        return;
      }
      final frontal = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        frontal,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _estado = _KioskEstado.idle;
      });
      _agendarProximoScan();
      _carregarRecentes();
    } catch (e) {
      if (mounted) setState(() => _estado = _KioskEstado.semCamera);
    }
  }

  /// Feed "Últimos registros" — best-effort: falha aqui nunca deve travar o
  /// totem, é só um enfeite de tela de espera.
  Future<void> _carregarRecentes() async {
    final token = _token;
    if (token == null) return;
    try {
      final recentes = await widget.api.recentes(token);
      if (mounted) setState(() => _recentes = recentes);
    } catch (_) {
      // silencioso de propósito
    }
  }

  /// Caminho local da foto já sincronizada desse funcionário (baixada no
  /// último sync do roster) — evita nova ida à rede só pra mostrar a
  /// miniatura no feed de últimos registros.
  Future<String?> _fotoLocalCache(int funcionarioId) async {
    final path = await KioskSyncService.fotoLocalPath(funcionarioId);
    final file = File(path);
    return file.existsSync() ? file.path : null;
  }

  void _abrirConfiguracao() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            KioskSetupScreen(api: widget.api, storage: widget.storage),
      ),
    );
  }

  void _agendarProximoScan() {
    _scanTimer?.cancel();
    _scanTimer = Timer(const Duration(milliseconds: 1600), _tentarReconhecer);
  }

  Future<void> _tentarReconhecer() async {
    if (_estado != _KioskEstado.idle || _scanEmAndamento || _dialogAberto) {
      if (_estado == _KioskEstado.idle) _agendarProximoScan();
      return;
    }
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture) {
      _agendarProximoScan();
      return;
    }
    _scanEmAndamento = true;
    String? fotoPath;
    try {
      final foto = await controller.takePicture();
      fotoPath = foto.path;
      final matches = await widget.faceStore.identificar(foto.path);
      if (matches.length == 1 && _estado == _KioskEstado.idle) {
        final funcionarioId = int.tryParse(matches.first);
        final ultima = funcionarioId != null
            ? _ultimaBatidaLocal[funcionarioId]
            : null;
        if (ultima != null &&
            DateTime.now().difference(ultima) < _cooldownPorFuncionario) {
          return; // acabou de bater — não re-prompta quem ainda está na frente
        }
        setState(() => _estado = _KioskEstado.identificando);
        final identificacao = await widget.api.identificar(
          _token!,
          'FACE',
          matches.first,
        );
        if (!mounted) return;
        setState(() {
          _candidato = identificacao;
          _fotoConfirmacaoPath = foto.path;
          _estado = _KioskEstado.confirmando;
        });
        return; // pausa o scan enquanto espera confirmação manual
      }
      // 0 (ninguém reconhecido) ou >1 (ambíguo, nunca autoescolhe) — continua
      // escaneando em silêncio, sem interromper quem só está passando.
    } on KioskApiException catch (e) {
      if (e.tokenInvalido && mounted) {
        // Token revogado no servidor — escanear em vão pra sempre não
        // ajuda ninguém; volta pra configuração.
        _abrirConfiguracao();
        return;
      }
    } catch (_) {
      // Falha pontual de captura/match — tenta de novo no próximo ciclo.
    } finally {
      // A foto do scan só sobrevive se virou a foto de confirmação.
      if (fotoPath != _fotoConfirmacaoPath) _apagarFoto(fotoPath);
      _scanEmAndamento = false;
      if (_estado == _KioskEstado.idle ||
          _estado == _KioskEstado.identificando) {
        if (mounted && _estado == _KioskEstado.identificando) {
          // identificar() falhou (ex: revogado entre o sync e agora) — volta pro idle.
          setState(() => _estado = _KioskEstado.idle);
        }
        _agendarProximoScan();
      }
    }
  }

  Future<void> _confirmar() async {
    final candidato = _candidato;
    final fotoPath = _fotoConfirmacaoPath;
    if (candidato == null || fotoPath == null) return;
    setState(() => _estado = _KioskEstado.registrando);
    try {
      final bytes = await File(fotoPath).readAsBytes();
      final dataUri = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      final resultado = await widget.api.registrarPorFace(
        _token!,
        candidato.funcionarioId,
        dataUri,
      );
      if (!mounted) return;
      _ultimaBatidaLocal[resultado.funcionarioId] = DateTime.now();
      setState(() {
        _resultado = resultado;
        _estado = _KioskEstado.sucesso;
      });
      _carregarRecentes();
      Timer(const Duration(seconds: 3), _voltarParaIdle);
    } on KioskApiException catch (e) {
      if (!mounted) return;
      if (e.tokenInvalido) {
        _abrirConfiguracao();
        return;
      }
      setState(() {
        _mensagemErro = e.message;
        _estado = _KioskEstado.erro;
      });
      Timer(const Duration(seconds: 4), _voltarParaIdle);
    } catch (_) {
      // Qualquer outra exceção (arquivo da foto purgado pelo SO, contrato
      // quebrado) NÃO pode deixar o totem preso em "Registrando..." — o
      // aparelho roda sozinho, ninguém vai reiniciar o app por ele.
      if (!mounted) return;
      setState(() {
        _mensagemErro = 'Não foi possível registrar. Tente de novo.';
        _estado = _KioskEstado.erro;
      });
      Timer(const Duration(seconds: 4), _voltarParaIdle);
    }
  }

  void _naoSouEu() => _voltarParaIdle();

  void _voltarParaIdle() {
    if (!mounted) return;
    _apagarFoto(_fotoConfirmacaoPath);
    setState(() {
      _estado = _KioskEstado.idle;
      _candidato = null;
      _fotoConfirmacaoPath = null;
      _resultado = null;
      _mensagemErro = null;
    });
    _agendarProximoScan();
  }

  /// Sair do modo totem exige credencial de administrador: o PIN definido
  /// no setup ou, em terminal configurado antes do PIN existir, o próprio
  /// token do terminal (digitado — nunca exibido).
  Future<bool> _pedirCredencialAdmin() async {
    final adminPin = await widget.storage.readAdminPin();
    final token = await widget.storage.readToken();
    if (!mounted) return false;
    final usaPin = adminPin != null && adminPin.isNotEmpty;
    final controller = TextEditingController();
    _dialogAberto = true;
    final digitado = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sair do Modo Totem'),
        content: TextField(
          controller: controller,
          keyboardType: usaPin ? TextInputType.number : TextInputType.text,
          obscureText: true,
          autofocus: true,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: usaPin ? 'PIN de administrador' : 'Token do terminal',
            helperText: usaPin
                ? null
                : 'Terminal sem PIN — digite o token completo.',
          ),
          onSubmitted: (v) => Navigator.of(dialogContext).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    controller.dispose();
    _dialogAberto = false;
    if (digitado == null || digitado.isEmpty) return false;
    final esperado = usaPin ? adminPin : token;
    final ok = esperado != null && digitado == esperado;
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(usaPin ? 'PIN incorreto.' : 'Token incorreto.')),
      );
    }
    return ok;
  }

  Future<void> _sairDoTotem() async {
    final autorizado = await _pedirCredencialAdmin();
    if (!autorizado || !mounted) return;
    final desativar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sair do Modo Totem'),
        content: const Text(
          'Só sair mantém o terminal configurado (token e rostos '
          'sincronizados continuam neste tablet).\n\n'
          'Desativar o terminal apaga o token, o PIN e TODOS os rostos '
          'sincronizados — use ao aposentar ou transferir o tablet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Só sair'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Desativar terminal'),
          ),
        ],
      ),
    );
    if (desativar == null || !mounted) return;
    if (desativar) {
      // LGPD: desprovisionar não pode deixar biometria pra trás.
      await KioskSyncService(widget.api, widget.faceStore).limparDadosLocais();
      await widget.storage.clear();
      if (!mounted) return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _abrirFallbackPin() async {
    final token = _token;
    if (token == null) return;
    final pinController = TextEditingController();
    final b = AppBranding.of(context);
    _dialogAberto = true;
    final pin = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Marcar com PIN'),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'PIN'),
          onSubmitted: (v) => Navigator.of(dialogContext).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: b.primary),
            onPressed: () =>
                Navigator.of(dialogContext).pop(pinController.text.trim()),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    pinController.dispose();
    _dialogAberto = false;
    if (pin == null || pin.isEmpty || !mounted) return;
    setState(() => _estado = _KioskEstado.registrando);
    try {
      final resultado = await widget.api.registrar(token, 'PIN', pin);
      if (!mounted) return;
      _ultimaBatidaLocal[resultado.funcionarioId] = DateTime.now();
      setState(() {
        _resultado = resultado;
        _estado = _KioskEstado.sucesso;
      });
      _carregarRecentes();
      Timer(const Duration(seconds: 3), _voltarParaIdle);
    } on KioskApiException catch (e) {
      if (!mounted) return;
      if (e.tokenInvalido) {
        _abrirConfiguracao();
        return;
      }
      setState(() {
        _mensagemErro = e.message;
        _estado = _KioskEstado.erro;
      });
      Timer(const Duration(seconds: 4), _voltarParaIdle);
    } catch (_) {
      // Mesmo racional do _confirmar: totem nunca fica preso em "Registrando...".
      if (!mounted) return;
      setState(() {
        _mensagemErro = 'Não foi possível registrar. Tente de novo.';
        _estado = _KioskEstado.erro;
      });
      Timer(const Duration(seconds: 4), _voltarParaIdle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = AppBranding.of(context);
    // canPop: false — o botão voltar do Android não pode tirar a recepção
    // do modo totem sem credencial de administrador.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _sairDoTotem();
      },
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0B1020), Color(0xFF101828)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Long-press no logotipo = saída administrativa (com
                      // credencial) — alternativa ao botão voltar pra tablets
                      // com navegação por gesto travada.
                      GestureDetector(
                        onLongPress: _sairDoTotem,
                        child: AlfaJornadaWordmark(
                          24,
                          textColor: Colors.white,
                          brandColor: b.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Bem-vindo',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('HH:mm:ss').format(_agora),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 56,
                          fontWeight: FontWeight.w700,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(_agora),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.10),
                            ),
                          ),
                          child: Center(child: _conteudoCentral(b)),
                        ),
                      ),
                      if (_estado == _KioskEstado.idle &&
                          _recentes.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _ultimosRegistros(b),
                      ],
                      const SizedBox(height: 14),
                      _MetodoButton(
                        onTap:
                            _estado == _KioskEstado.idle ||
                                _estado == _KioskEstado.semCamera
                            ? _abrirFallbackPin
                            : null,
                        icon: Icons.dialpad_rounded,
                        label: 'Teclado',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _conteudoCentral(AppBranding b) {
    switch (_estado) {
      case _KioskEstado.carregando:
        return const CircularProgressIndicator(color: Colors.white);

      case _KioskEstado.semCamera:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.videocam_off_outlined,
              color: Colors.white54,
              size: 56,
            ),
            const SizedBox(height: 12),
            const Text(
              'Câmera indisponível — verifique a permissão do app.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _iniciarCamera,
              child: const Text('Tentar de novo'),
            ),
          ],
        );

      case _KioskEstado.idle:
      case _KioskEstado.identificando:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _cameraCircular(b),
            const SizedBox(height: 20),
            Text(
              _estado == _KioskEstado.identificando
                  ? 'Identificando...'
                  : 'Aproxime seu rosto da câmera',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );

      case _KioskEstado.confirmando:
        final candidato = _candidato!;
        final fotoPath = _fotoConfirmacaoPath;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: b.primary, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: b.primary.withValues(alpha: 0.45),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: fotoPath != null
                  ? Image.file(File(fotoPath), fit: BoxFit.cover)
                  : ColoredBox(
                      color: b.primary,
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              'Olá, ${candidato.nome.split(' ').first}!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Confirmar ${candidato.proximoSentido == 'ENTRADA' ? 'entrada' : 'saída'}?',
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: _naoSouEu,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white30),
                  ),
                  child: const Text('Não sou eu'),
                ),
                const SizedBox(width: 16),
                FilledButton(
                  onPressed: _confirmar,
                  style: FilledButton.styleFrom(
                    backgroundColor: b.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: const Text('Confirmar'),
                ),
              ],
            ),
          ],
        );

      case _KioskEstado.registrando:
        return const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text('Registrando...', style: TextStyle(color: Colors.white70)),
          ],
        );

      case _KioskEstado.sucesso:
        final resultado = _resultado!;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: b.success.withValues(alpha: 0.15),
                boxShadow: [
                  BoxShadow(
                    color: b.success.withValues(alpha: 0.35),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(Icons.check_rounded, color: b.success, size: 56),
            ),
            const SizedBox(height: 20),
            Text(
              resultado.mensagem,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );

      case _KioskEstado.erro:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: b.danger.withValues(alpha: 0.15),
              ),
              child: Icon(
                Icons.priority_high_rounded,
                color: b.danger,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _mensagemErro ?? 'Não foi possível registrar.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ],
        );
    }
  }

  Widget _ultimosRegistros(AppBranding b) {
    return SizedBox(
      height: 76,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ÚLTIMOS REGISTROS',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _recentes.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) => _RegistroRecenteTile(
                item: _recentes[i],
                primary: b.primary,
                fotoLocal: _fotoLocalCache,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cameraCircular(AppBranding b) {
    final controller = _controller;
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, child) {
        final glow = 0.25 + 0.20 * _pulseCtrl.value;
        return Container(
          width: 232,
          height: 232,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: b.primary.withValues(alpha: glow),
                blurRadius: 28,
                spreadRadius: 4,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: b.primary.withValues(alpha: 0.55),
            width: 3,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: controller != null && controller.value.isInitialized
            ? CameraPreview(controller)
            : const ColoredBox(color: Color(0xFF1E293B)),
      ),
    );
  }
}

/// Botão de método alternativo de marcação — mesma linguagem de "escolha
/// um jeito de bater o ponto" que os totens do mercado usam (ícone grande +
/// rótulo), em vez de um linkzinho de texto discreto.
class _MetodoButton extends StatelessWidget {
  const _MetodoButton({
    required this.onTap,
    required this.icon,
    required this.label,
  });

  final VoidCallback? onTap;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ativo = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: ativo ? 0.35 : 0.15),
                ),
              ),
              child: Icon(
                icon,
                color: Colors.white.withValues(alpha: ativo ? 0.9 : 0.35),
                size: 20,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: ativo ? 0.8 : 0.3),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegistroRecenteTile extends StatelessWidget {
  const _RegistroRecenteTile({
    required this.item,
    required this.primary,
    required this.fotoLocal,
  });

  final KioskRecenteItem item;
  final Color primary;
  final Future<String?> Function(int funcionarioId) fotoLocal;

  @override
  Widget build(BuildContext context) {
    final entrada = item.sentido == 'ENTRADA';
    return SizedBox(
      width: 64,
      child: Column(
        children: [
          FutureBuilder<String?>(
            future: fotoLocal(item.funcionarioId),
            builder: (context, snap) {
              final path = snap.data;
              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary.withValues(alpha: 0.25),
                  border: Border.all(
                    color: entrada
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFF59E0B),
                    width: 2,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: path != null
                    ? Image.file(File(path), fit: BoxFit.cover)
                    : Center(
                        child: Text(
                          item.nome.isNotEmpty
                              ? item.nome[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            item.nome.split(' ').first,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
          Text(
            DateFormat('HH:mm').format(item.dataHora),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}
