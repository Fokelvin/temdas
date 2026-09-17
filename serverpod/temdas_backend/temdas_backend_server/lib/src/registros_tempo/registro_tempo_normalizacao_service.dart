import '../generated/protocol.dart';

/// Regra de domínio pura: calcula a união sem consultar ou alterar o banco.
class RegistroTempoNormalizacaoService {
  NormalizacaoRegistroTempo normalizar(
    RegistroTempo novo,
    Iterable<RegistroTempo> existentes,
  ) {
    var inicio = novo.inicioEm;
    var fim = inicio.add(Duration(minutes: novo.duracaoMinutos));
    final pendentes = existentes
        .where(
          (registro) =>
              registro.demandaId == novo.demandaId &&
              (novo.id == null || registro.id != novo.id),
        )
        .toList();
    final sobrepostos = <RegistroTempo>[];

    bool expandiu;
    do {
      expandiu = false;
      for (var index = pendentes.length - 1; index >= 0; index--) {
        final registro = pendentes[index];
        final fimRegistro = registro.inicioEm.add(
          Duration(minutes: registro.duracaoMinutos),
        );
        // Une sobreposição e adjacência exata; só um intervalo real separa.
        if (registro.inicioEm.isAfter(fim) || inicio.isAfter(fimRegistro)) {
          continue;
        }

        sobrepostos.add(registro);
        pendentes.removeAt(index);
        if (registro.inicioEm.isBefore(inicio)) inicio = registro.inicioEm;
        if (fimRegistro.isAfter(fim)) fim = fimRegistro;
        expandiu = true;
      }
      // O novo limite pode alcançar registros já examinados nesta passagem.
    } while (expandiu);

    final duracao = fim.difference(inicio);
    if (duracao.inMicroseconds % Duration.microsecondsPerMinute != 0) {
      throw Exception(
        'A união dos registros deve resultar em uma duração de minutos inteiros.',
      );
    }

    // Na edição, o próprio registro é a base, mesmo se outro tiver ID menor.
    // Na criação, mantém a escolha determinística do menor ID envolvido.
    sobrepostos.sort((a, b) => a.id!.compareTo(b.id!));
    final base = novo.id != null || sobrepostos.isEmpty
        ? novo
        : sobrepostos.first;
    return NormalizacaoRegistroTempo(
      resultante: base.copyWith(
        inicioEm: inicio,
        duracaoMinutos: duracao.inMinutes,
      ),
      absorvidos: List.unmodifiable(
        sobrepostos.where((registro) => registro.id != base.id),
      ),
    );
  }
}

/// Plano de persistência; não é um modelo armazenado no banco.
class NormalizacaoRegistroTempo {
  const NormalizacaoRegistroTempo({
    required this.resultante,
    required this.absorvidos,
  });

  final RegistroTempo resultante;
  final List<RegistroTempo> absorvidos;
}
