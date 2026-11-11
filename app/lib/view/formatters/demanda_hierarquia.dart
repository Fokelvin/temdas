import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

Map<int, backend.Demanda> indexarDemandas(Iterable<backend.Demanda> demandas) =>
    {
      for (final demanda in demandas)
        if (demanda.id case final int id) id: demanda,
    };

String? _caminho(
  int? id,
  int? pai,
  ({String titulo, int? pai})? Function(int) buscar,
) {
  final visitados = {?id};
  final titulos = <String>[];
  while (pai != null && visitados.add(pai)) {
    final mae = buscar(pai);
    if (mae == null) break;
    titulos.add(mae.titulo);
    pai = mae.pai;
  }
  return titulos.isEmpty ? null : titulos.reversed.join(' › ');
}

String? caminhoAncestral(
  backend.Demanda demanda,
  backend.Demanda? Function(int) buscar,
) => _caminho(demanda.id, demanda.demandaPaiId, (id) {
  final mae = buscar(id);
  return mae == null ? null : (titulo: mae.titulo, pai: mae.demandaPaiId);
});

String tituloComHierarquia(String titulo, String? ancestrais) =>
    ancestrais == null ? titulo : '$ancestrais › $titulo';

Map<int, String> caminhosDoRelatorio(List<backend.RelatorioDemandaItem> itens) {
  final porId = {for (final item in itens) item.demandaId: item};
  final resultado = <int, String>{};
  for (final item in itens) {
    final caminho = _caminho(item.demandaId, item.demandaMaeId, (id) {
      final mae = porId[id];
      return mae == null ? null : (titulo: mae.titulo, pai: mae.demandaMaeId);
    });
    if (caminho != null) resultado[item.demandaId] = caminho;
  }
  return resultado;
}
