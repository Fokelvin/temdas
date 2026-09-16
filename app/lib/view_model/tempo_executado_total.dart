import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

/// Totais de apresentação derivados da lista atual, sem alterar o tempo próprio.
Map<int, int> calcularTemposExecutadosTotais(List<backend.Demanda> demandas) {
  final porPai = <int, List<backend.Demanda>>{};
  for (final demanda in demandas) {
    final paiId = demanda.demandaPaiId;
    if (paiId != null) {
      porPai.putIfAbsent(paiId, () => []).add(demanda);
    }
  }

  final totais = <int, int>{};
  final emVisita = <int>{};
  int totalDe(backend.Demanda demanda) {
    final id = demanda.id;
    if (id == null) return demanda.tempoExecutadoMinutos;
    if (totais[id] case final total?) return total;
    // Uma relação inválida não pode provocar recursão infinita.
    if (!emVisita.add(id)) return 0;
    var total = demanda.tempoExecutadoMinutos;
    for (final filha in porPai[id] ?? const <backend.Demanda>[]) {
      total += totalDe(filha);
    }
    emVisita.remove(id);
    return totais[id] = total;
  }

  for (final demanda in demandas) {
    totalDe(demanda);
  }
  return totais;
}
