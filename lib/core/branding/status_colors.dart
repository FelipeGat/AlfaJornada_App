import 'package:flutter/material.dart';

import 'app_branding.dart';

/// Status canônico de tenant SaaS — espelha os valores `statusSaas`/
/// `subscriptionStatus` que o backend AlfaGym/AlfaControl emite.
enum SaasStatus {
  active,
  trial,
  pastDue,
  suspended,
  canceled,
  unknown;

  /// Normaliza string vinda do backend (case-insensitive + sinônimos PT).
  /// `ATIVO` → active; `CANCELADO`/`CANCELLED` → canceled; etc.
  static SaasStatus parse(String? raw) {
    final s = raw?.toUpperCase().trim();
    if (s == null || s.isEmpty) return SaasStatus.unknown;
    switch (s) {
      case 'ACTIVE':
      case 'ATIVO':
        return SaasStatus.active;
      case 'TRIAL':
        return SaasStatus.trial;
      case 'PAST_DUE':
        return SaasStatus.pastDue;
      case 'SUSPENDED':
      case 'SUSPENSO':
        return SaasStatus.suspended;
      case 'CANCELED':
      case 'CANCELLED':
      case 'CANCELADO':
        return SaasStatus.canceled;
      default:
        return SaasStatus.unknown;
    }
  }
}

/// Paleta canônica de cores por status. Centraliza fora do branding pra
/// garantir contraste consistente entre `SaasDashboardGymScreen` e
/// `TenantsListScreen` (e futuras telas do painel SaaS).
extension SaasStatusColors on SaasStatus {
  /// Cor de destaque (texto/ícone). Usa tokens do `AppBranding` quando
  /// existem (success/danger/primary) e cai em paleta Material pra os
  /// que ainda não têm token (`warning`/`info` — virar token quando o
  /// branding ganhar esses campos).
  Color color(AppBranding b) {
    switch (this) {
      case SaasStatus.active:
        return b.success;
      case SaasStatus.trial:
        return Colors.blue.shade600;
      case SaasStatus.pastDue:
        return Colors.orange.shade700;
      case SaasStatus.suspended:
      case SaasStatus.canceled:
        return b.danger;
      case SaasStatus.unknown:
        return b.primary;
    }
  }

  /// Label em PT-BR pra exibir em chips e badges. Quando `unknown`,
  /// devolve a string crua original via fallback no caller.
  String get label {
    switch (this) {
      case SaasStatus.active:
        return 'Ativos';
      case SaasStatus.trial:
        return 'Em trial';
      case SaasStatus.pastDue:
        return 'Em atraso';
      case SaasStatus.suspended:
        return 'Suspensos';
      case SaasStatus.canceled:
        return 'Cancelados';
      case SaasStatus.unknown:
        return 'Outro';
    }
  }

  /// Variante singular do label (pra badge num cartão único, não chip
  /// de filtro coletivo).
  String get labelSingular {
    switch (this) {
      case SaasStatus.active:
        return 'Ativo';
      case SaasStatus.trial:
        return 'Em trial';
      case SaasStatus.pastDue:
        return 'Em atraso';
      case SaasStatus.suspended:
        return 'Suspenso';
      case SaasStatus.canceled:
        return 'Cancelado';
      case SaasStatus.unknown:
        return 'Outro';
    }
  }
}

/// Cor pra badge de "dias restantes" de licença/contrato — mapeia
/// urgência baseada no tempo até vencimento. Negativo = vencida.
/// Reusa tokens do branding pra ficar consistente com o resto.
Color corDiasRestantes(int dias, AppBranding b) {
  if (dias < 0 || dias <= 7) return b.danger;
  if (dias <= 15) return Colors.orange.shade700;
  return b.success;
}
