/// Contrato de providers que mantêm estado escopado a um tenant
/// (cliente/academia/unidade) e precisam ser zerados quando o tenant
/// muda (logout, troca de academia/unidade, super_admin alternando
/// X-Cliente-Id).
///
/// Implementar em qualquer provider que cacheie listas/detalhes
/// vinculados ao tenant atual. Helper [clearAll] itera e zera todos.
///
/// Adotado na Fase F2 da integração AlfaGym pra evitar vazamento
/// cross-tenant: ao trocar de tenant, providers que cacheiam dados
/// (alunos, planos, faturas, etc.) precisam ser limpos antes do
/// próximo carregamento — caso contrário o usuário vê dados do tenant
/// anterior por uma janela curta.
abstract interface class Clearable {
  void limpar();
}

/// Zera todos os providers passados. Ordem é arbitrária — providers
/// não devem depender uns dos outros pra limpar.
void clearAll(Iterable<Clearable> targets) {
  for (final target in targets) {
    target.limpar();
  }
}
