import 'dart:convert';
import 'dart:math';

import '../generated/protocol.dart';

/// Identidade privada distingue origens legítimas, mesmo com texto/horário iguais.
/// O texto livre nunca é analisado para extrair datas ou identificar duplicações.
class RegistroTempoObservacaoService {
  static final _aleatorio = Random.secure();
  static final _novasOrigens = Expando<String>();

  String _identidade(RegistroTempo registro) {
    if (registro.id != null)
      return 'registro:${registro.demandaId}:${registro.id}';
    return _novasOrigens[registro] ??=
        'novo:${registro.demandaId}:${List.generate(4, (_) => _aleatorio.nextInt(1 << 32).toRadixString(16).padLeft(8, '0')).join()}';
  }

  List<Map<String, String>> _ler(RegistroTempo registro) {
    if (registro.observacaoOrigens case final json?) {
      final itens = jsonDecode(json) as List;
      if (itens.isEmpty) throw const FormatException('Proveniência vazia.');
      return [
        for (var i = 0; i < itens.length; i++)
          _validar(
            Map<String, String>.from(itens[i] as Map),
            // Compatibilidade defensiva com o formato da branch antes da revisão.
            // Sem identidade antiga, não presume que textos iguais são a mesma origem.
            fallback: 'legado:${_identidade(registro)}:$i',
          ),
      ];
    }
    if (!(registro.observacao?.trim().isNotEmpty ?? false)) return [];
    return [
      {
        'origem': _identidade(registro),
        'inicio': registro.inicioEm.toUtc().toIso8601String(),
        'fim': registro.inicioEm
            .add(Duration(minutes: registro.duracaoMinutos))
            .toUtc()
            .toIso8601String(),
        'texto': registro.observacao!,
      },
    ];
  }

  Map<String, String> _validar(
    Map<String, String> entrada, {
    required String fallback,
  }) {
    final inicio = DateTime.parse(entrada['inicio']!).toUtc();
    final fim = DateTime.parse(entrada['fim']!).toUtc();
    final origem = entrada['origem'] ?? fallback;
    if (!fim.isAfter(inicio) || origem.isEmpty)
      throw const FormatException('Origem inválida.');
    return {
      'origem': origem,
      'inicio': inicio.toIso8601String(),
      'fim': fim.toIso8601String(),
      'texto': entrada['texto']!,
    };
  }

  ({String? texto, String? origens}) unir(
    RegistroTempo novo,
    Iterable<RegistroTempo> absorvidos,
  ) {
    final entradas = <String, Map<String, String>>{};
    for (final registro in [novo, ...absorvidos]) {
      for (final entrada in _ler(registro)) {
        final anterior = entradas[entrada['origem']];
        if (anterior != null && jsonEncode(anterior) != jsonEncode(entrada)) {
          throw const FormatException(
            'Mesma origem com conteúdos divergentes.',
          );
        }
        entradas[entrada['origem']!] = entrada;
      }
    }
    final ordenadas = entradas.values.toList()
      ..sort((a, b) {
        for (final campo in ['inicio', 'fim', 'origem']) {
          final comparacao = a[campo]!.compareTo(b[campo]!);
          if (comparacao != 0) return comparacao;
        }
        return 0;
      });
    if (ordenadas.isEmpty) return (texto: null, origens: null);
    return (
      texto: ordenadas.map((e) => e['texto']!).join('\n\n'),
      origens: jsonEncode(ordenadas),
    );
  }

  /// Projeção somente de resposta: não persiste outra coluna nem expõe IDs privados.
  RegistroTempo paraResposta(RegistroTempo registro) => registro.copyWith(
    observacoesOriginais: registro.observacaoOrigens == null
        ? null
        : [
            for (final entrada in _ler(registro))
              RegistroTempoObservacao(
                inicioEm: DateTime.parse(entrada['inicio']!),
                fimEm: DateTime.parse(entrada['fim']!),
                texto: entrada['texto']!,
              ),
          ],
  );
}
