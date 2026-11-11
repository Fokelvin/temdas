import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import '../view/formatters/demanda_hierarquia.dart';
import '../view/formatters/texto_busca.dart';
import 'demanda_lista_preferencias.dart';

enum TipoDemanda {
  mae('Mãe'),
  filha('Filha'),
  independente('Independente');

  const TipoDemanda(this.rotulo);
  final String rotulo;
}

/// Usa a coleção completa, inclusive quando a Lista recebe apenas uma projeção.
class DemandaHierarquiaLista {
  DemandaHierarquiaLista(this.demandas)
    : porId = indexarDemandas(demandas),
      _pais = demandas.map((d) => d.demandaPaiId).whereType<int>().toSet();

  final List<backend.Demanda> demandas;
  final Map<int, backend.Demanda> porId;
  final Set<int> _pais;
  final _emArvore = <int, bool>{};

  TipoDemanda tipo(backend.Demanda demanda) {
    if (demanda.demandaPaiId != null) return TipoDemanda.filha;
    return _pais.contains(demanda.id)
        ? TipoDemanda.mae
        : TipoDemanda.independente;
  }

  /// Uma correspondência em qualquer nível pode qualificar a raiz da árvore.
  bool pertenceAArvoreComFilhas(backend.Demanda demanda) {
    final visitados = <int>{};
    var atual = demanda;
    var resultado = false;
    while (true) {
      final id = atual.id;
      if (id != null) {
        final cache = _emArvore[id];
        if (cache != null) {
          resultado = cache;
          break;
        }
        if (!visitados.add(id)) break;
      }
      final pai = porId[atual.demandaPaiId];
      if (pai == null) {
        resultado = _pais.contains(id);
        break;
      }
      atual = pai;
    }
    for (final id in visitados) {
      _emArvore[id] = resultado;
    }
    return resultado;
  }

  ResultadoBuscaDemanda buscar({
    required String texto,
    required bool filtrosAtivos,
    required bool possuiFilhas,
    bool incluirSemId = true,
    required bool Function(backend.Demanda) atendeFiltros,
  }) {
    if (texto.trim().isEmpty && !filtrosAtivos && !possuiFilhas) {
      return ResultadoBuscaDemanda(demandas, const {}, null);
    }

    final busca = normalizarTextoBusca(texto.trim());
    final idTexto = busca.replaceFirst(RegExp(r'^#'), '');
    final id = int.tryParse(idTexto);
    final trechoId = busca.replaceFirst('#', '');
    final candidatas = demandas
        .where(
          (demanda) =>
              atendeFiltros(demanda) &&
              (!possuiFilhas || pertenceAArvoreComFilhas(demanda)),
        )
        .toList();
    final correspondentes = busca.isEmpty
        ? candidatas
        : candidatas.any((d) => id != null && d.id == id)
        ? candidatas.where((d) => d.id == id).toList()
        : candidatas
              .where(
                (d) =>
                    normalizarTextoBusca(d.titulo).contains(busca) ||
                    (d.id?.toString().contains(trechoId) ?? false),
              )
              .toList();

    final visiveis = <int>{};
    final semId = Set<backend.Demanda>.identity();
    final expandir = <int>{};
    for (final demanda in correspondentes) {
      final id = demanda.id;
      if (id == null && incluirSemId) semId.add(demanda);
      if (id != null) visiveis.add(id);
      var pai = demanda.demandaPaiId;
      while (pai != null && expandir.add(pai)) {
        visiveis.add(pai);
        pai = porId[pai]?.demandaPaiId;
      }
    }
    return ResultadoBuscaDemanda(
      demandas
          .where((d) => visiveis.contains(d.id) || semId.contains(d))
          .toList(),
      expandir,
      correspondentes.length == 1 ? correspondentes.single.id : null,
    );
  }

  /// A ordem de entrada desempata valores iguais, inclusive em ordem decrescente.
  /// O consumidor distribui os nós em irmãos e grupos mantendo esta ordem.
  List<backend.Demanda> ordenar(
    List<backend.Demanda> visiveis,
    OrdemListaDemanda? ordem,
    Map<int, int> tempos,
  ) {
    if (ordem == null) return visiveis;
    Comparable<Object> valor(backend.Demanda d) => switch (ordem.coluna) {
      ColunaDemanda.id => d.id ?? 0,
      ColunaDemanda.demanda => normalizarTextoBusca(d.titulo),
      ColunaDemanda.prioridade => d.prioridade.index,
      ColunaDemanda.estimado => d.tempoEstimadoMinutos,
      ColunaDemanda.executado => tempos[d.id] ?? d.tempoExecutadoMinutos,
      ColunaDemanda.status => d.status.index,
      ColunaDemanda.criadoEm => d.criadoEm,
      ColunaDemanda.tipo => normalizarTextoBusca(tipo(d).rotulo),
      ColunaDemanda.sprint => 0,
    };
    final itens =
        [
          for (final (indice, demanda) in visiveis.indexed)
            (indice: indice, demanda: demanda, valor: valor(demanda)),
        ]..sort((a, b) {
          final comparacao = a.valor.compareTo(b.valor);
          if (comparacao == 0) return a.indice.compareTo(b.indice);
          return ordem.crescente ? comparacao : -comparacao;
        });
    return itens.map((item) => item.demanda).toList();
  }
}

class ResultadoBuscaDemanda {
  const ResultadoBuscaDemanda(
    this.demandas,
    this.autoExpandIds,
    this.focoDemandaId,
  );
  final List<backend.Demanda> demandas;
  final Set<int> autoExpandIds;
  final int? focoDemandaId;
}
