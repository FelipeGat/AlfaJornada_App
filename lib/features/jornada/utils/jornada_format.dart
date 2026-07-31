/// Rótulo do "estágio da jornada" de uma marcação, pela posição dela no
/// dia (0-based) — o backend só devolve ENTRADA/SAIDA alternado (o
/// sentido é calculado pelo servidor a partir de quantas batidas já
/// existem no dia — ver `JornadaProvider.sincronizarFila`); aqui só
/// nomeamos o padrão de 4 marcações (entrada/saída almoço/volta
/// almoço/saída) pro colaborador entender de forma inequívoca o que
/// cada marcação representa.
String rotuloMarcacaoJornada(int indiceZeroBased) {
  switch (indiceZeroBased % 4) {
    case 0:
      return 'Entrada';
    case 1:
      return 'Saída (almoço)';
    case 2:
      return 'Volta (almoço)';
    default:
      return 'Saída';
  }
}

String duasCasasJornada(int n) => n.toString().padLeft(2, '0');

const _kDiasSemanaJornada = [
  'domingo',
  'segunda-feira',
  'terça-feira',
  'quarta-feira',
  'quinta-feira',
  'sexta-feira',
  'sábado',
];
const _kMesesJornada = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

/// "Terça-feira, 26 de julho" — sem depender de `intl` com locale pt_BR
/// (não inicializado no app), pra não arriscar `LocaleDataException`.
String dataExtensoJornada(DateTime d) {
  final dia = _kDiasSemanaJornada[d.weekday % 7];
  final diaCapitalizado = dia[0].toUpperCase() + dia.substring(1);
  return '$diaCapitalizado, ${d.day} de ${_kMesesJornada[d.month - 1]}';
}

/// "26/07" — usado como cabeçalho compacto de grupo por dia no histórico.
String dataCurtaJornada(DateTime d) => '${duasCasasJornada(d.day)}/${duasCasasJornada(d.month)}';
