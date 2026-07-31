import 'package:flutter/material.dart';

/// Traduz o código do tipo de notificação pra label humano.
/// Tipos atuais (backend): ACESSO, ACESSO_PROPRIO, ACESSO_DEPENDENTE,
/// encomenda_recebida, acesso_liberado. Fallback: retorna o código cru.
String traduzirTipoNotificacao(String tipo) {
  switch (tipo) {
    case 'ACESSO':
      return 'Acesso';
    case 'ACESSO_PROPRIO':
      return 'Meu acesso';
    case 'ACESSO_DEPENDENTE':
      return 'Acesso de dependente';
    case 'acesso_liberado':
      return 'Acesso liberado';
    case 'encomenda_recebida':
      return 'Encomenda';
    case 'MANUTENCAO':
    case 'manutencao':
      return 'Manutenção';
    case 'SISTEMA':
    case 'sistema':
      return 'Sistema';
    default:
      return tipo;
  }
}

/// Ícone por tipo — usado no card e nos chips de filtro.
IconData iconeTipoNotificacao(String tipo) {
  switch (tipo) {
    case 'ACESSO':
    case 'ACESSO_PROPRIO':
    case 'ACESSO_DEPENDENTE':
    case 'acesso_liberado':
      return Icons.door_front_door_outlined;
    case 'encomenda_recebida':
      return Icons.inbox;
    case 'MANUTENCAO':
    case 'manutencao':
      return Icons.build_circle_outlined;
    case 'SISTEMA':
    case 'sistema':
      return Icons.info_outline;
    default:
      return Icons.notifications_none;
  }
}
