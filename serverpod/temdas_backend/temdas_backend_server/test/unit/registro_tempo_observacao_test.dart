import 'dart:convert';
import 'package:temdas_backend_server/src/generated/protocol.dart';
import 'package:temdas_backend_server/src/registros_tempo/registro_tempo_normalizacao_service.dart';
import 'package:test/test.dart';

RegistroTempo r(int? id, int minuto, String? texto, {int duracao = 30}) =>
    RegistroTempo(
      id: id,
      demandaId: 1,
      inicioEm: DateTime.utc(2026, 10, 1, 9, minuto),
      duracaoMinutos: duracao,
      observacao: texto,
      criadoEm: DateTime.utc(2026),
    );

void main() {
  final service = RegistroTempoNormalizacaoService();
  test(
    'união preserva texto integral e horários originais em ordem cronológica',
    () {
      final resultado = service.normalizar(r(null, 30, ' segunda\nlinha '), [
        r(1, 0, 'primeira'),
      ]);
      expect(resultado.resultante.duracaoMinutos, 60);
      expect(
        resultado.resultante.toJsonForProtocol(),
        isNot(contains('observacaoOrigens')),
      );
      expect(resultado.resultante.observacao, contains(' segunda\nlinha '));
      expect(
        resultado.resultante.observacao!.indexOf('primeira'),
        lessThan(resultado.resultante.observacao!.indexOf('segunda')),
      );
      expect(
        resultado.resultante.observacao,
        contains('2026-10-01T09:30:00.000Z'),
      );
      expect(
        jsonDecode(resultado.resultante.observacaoOrigens!) as List,
        hasLength(2),
      );
    },
  );
  test('uniões consecutivas não duplicam nem reempacotam observações', () {
    final primeiro = service.normalizar(r(null, 30, 'B'), [
      r(1, 0, 'A'),
    ]).resultante;
    final segundo = service.normalizar(r(null, 60, 'C'), [primeiro]).resultante;
    expect(jsonDecode(segundo.observacaoOrigens!) as List, hasLength(3));
    expect(RegExp(r'\nA').allMatches(segundo.observacao!), hasLength(1));
    expect(
      segundo.observacao,
      isNot(contains('[2026-10-01T09:00:00.000Z — 2026-10-01T10:00:00.000Z]')),
    );
  });
  test('sobreposições e ordem de entrada geram resultado determinístico', () {
    final novo = r(null, 20, 'N', duracao: 60);
    final a = r(1, 0, 'A');
    final b = r(2, 60, 'B');
    expect(
      service.normalizar(novo, [a, b]).resultante.observacao,
      service.normalizar(novo, [b, a]).resultante.observacao,
    );
  });
  test(
    'observações vazias não geram cabeçalhos e não apagam texto existente',
    () {
      expect(
        service
            .normalizar(r(null, 30, '  '), [r(1, 0, null)])
            .resultante
            .observacao,
        isNull,
      );
      expect(
        service
            .normalizar(r(null, 30, ''), [r(1, 0, 'A')])
            .resultante
            .observacao,
        contains('A'),
      );
    },
  );
  test('sem união preserva texto livre e não inventa proveniência', () {
    final resultado = service.normalizar(r(1, 0, ' original '), [
      r(2, 120, 'outro'),
    ]);
    expect(resultado.resultante.observacao, ' original ');
    expect(resultado.resultante.observacaoOrigens, isNull);
    expect(resultado.absorvidos, isEmpty);
  });
  test(
    'origens repetidas são deduplicadas por conteúdo e intervalo original',
    () {
      final primeiro = service.normalizar(r(null, 0, 'A'), [
        r(1, 0, 'A'),
      ]).resultante;
      expect(jsonDecode(primeiro.observacaoOrigens!) as List, hasLength(1));
    },
  );
  test(
    'proveniência inválida impede perda silenciosa antes da persistência',
    () {
      expect(
        () => service.normalizar(r(null, 30, 'B'), [
          r(1, 0, 'A').copyWith(observacaoOrigens: 'invalido'),
        ]),
        throwsFormatException,
      );
    },
  );
}
