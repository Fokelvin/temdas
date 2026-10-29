import 'dart:convert';
import '../generated/protocol.dart';

/// Proveniência privada evita reanalisar texto livre e reempacotar uniões antigas.
/// Não aceita metadados do cliente. Metadados inválidos abortam a transação.
class RegistroTempoObservacaoService {
  ({String? texto, String? origens}) unir(
    RegistroTempo novo,
    Iterable<RegistroTempo> absorvidos,
  ) {
    final entradas = <String, Map<String, String>>{};
    for (final registro in [novo, ...absorvidos]) {
      if (registro.observacaoOrigens case final origens?) {
        for (final item in jsonDecode(origens) as List) {
          final entrada = Map<String, String>.from(item as Map);
          DateTime.parse(entrada['inicio']!);
          DateTime.parse(entrada['fim']!);
          entrada['texto']!;
          entradas[jsonEncode(entrada)] = entrada;
        }
      } else if (registro.observacao?.trim().isNotEmpty ?? false) {
        final entrada = <String, String>{
          'inicio': registro.inicioEm.toUtc().toIso8601String(),
          'fim': registro.inicioEm
              .add(Duration(minutes: registro.duracaoMinutos))
              .toUtc()
              .toIso8601String(),
          'texto': registro.observacao!,
        };
        entradas[jsonEncode(entrada)] = entrada;
      }
    }
    final ordenadas = entradas.values.toList()
      ..sort((a, b) {
        for (final campo in ['inicio', 'fim', 'texto']) {
          final comparacao = a[campo]!.compareTo(b[campo]!);
          if (comparacao != 0) return comparacao;
        }
        return 0;
      });
    if (ordenadas.isEmpty) return (texto: null, origens: null);
    return (
      texto: ordenadas
          .map((e) => '[${e['inicio']} — ${e['fim']}]\n${e['texto']}')
          .join('\n\n'),
      origens: jsonEncode(ordenadas),
    );
  }
}
