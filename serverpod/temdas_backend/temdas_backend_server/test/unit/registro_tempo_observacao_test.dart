import 'dart:convert';
import 'package:temdas_backend_server/src/generated/protocol.dart';
import 'package:temdas_backend_server/src/registros_tempo/registro_tempo_normalizacao_service.dart';
import 'package:temdas_backend_server/src/registros_tempo/registro_tempo_observacao_service.dart';
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
List<dynamic> origens(RegistroTempo registro) =>
    jsonDecode(registro.observacaoOrigens!) as List;

void main() {
  final service = RegistroTempoNormalizacaoService();
  final observacoes = RegistroTempoObservacaoService();
  test(
    'preserva texto integral e horários UTC tipados, sem IDs privados na resposta',
    () {
      final resultado = service.normalizar(r(null, 30, ' segunda\nlinha '), [
        r(1, 0, 'primeira'),
      ]).resultante;
      expect(resultado.duracaoMinutos, 60);
      expect(resultado.observacao, 'primeira\n\n segunda\nlinha ');
      final resposta = observacoes.paraResposta(resultado);
      expect(resposta.observacoesOriginais!.map((e) => e.texto), [
        'primeira',
        ' segunda\nlinha ',
      ]);
      expect(
        resposta.observacoesOriginais![1].inicioEm,
        DateTime.utc(2026, 10, 1, 9, 30),
      );
      expect(
        resposta.observacoesOriginais![1].fimEm,
        DateTime.utc(2026, 10, 1, 10),
      );
      expect(
        resposta.toJsonForProtocol(),
        isNot(contains('observacaoOrigens')),
      );
      expect(
        resposta.observacoesOriginais![0].toJson(),
        isNot(contains('origem')),
      );
    },
  );
  test('uniões consecutivas não duplicam nem reempacotam observações', () {
    final primeiro = service.normalizar(r(null, 30, 'B'), [
      r(1, 0, 'A'),
    ]).resultante;
    final segundo = service.normalizar(r(null, 60, 'C'), [primeiro]).resultante;
    expect(origens(segundo), hasLength(3));
    expect(segundo.observacao, 'A\n\nB\n\nC');
    expect(origens(segundo).map((e) => e['origem']).toSet(), hasLength(3));
  });
  test('sobreposições e ordem de entrada geram resultado determinístico', () {
    final novo = r(null, 20, 'N', duracao: 60);
    final a = r(1, 0, 'A');
    final b = r(2, 60, 'B');
    expect(
      service.normalizar(novo, [a, b]).resultante.observacaoOrigens,
      service.normalizar(novo, [b, a]).resultante.observacaoOrigens,
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
        'A',
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
    'origens distintas com mesmo texto e intervalo devem ser preservadas',
    () {
      final resultado = service.normalizar(r(null, 0, 'A'), [
        r(1, 0, 'A'),
      ]).resultante;
      expect(origens(resultado), hasLength(2));
      expect(origens(resultado).map((e) => e['origem']).toSet(), hasLength(2));
      expect(resultado.observacao, 'A\n\nA');
      final seguinte = service.normalizar(r(null, 30, 'B'), [
        resultado,
      ]).resultante;
      expect(origens(seguinte), hasLength(3));
      expect(seguinte.observacao, 'A\n\nA\n\nB');
    },
  );
  test(
    'mesma origem reapresentada em agregações sucessivas aparece só uma vez',
    () {
      final primeiro = service.normalizar(r(2, 30, 'B'), [
        r(1, 0, 'A'),
      ]).resultante;
      final repetido = observacoes.unir(primeiro, [
        primeiro.copyWith(id: 3),
        r(4, 60, 'C'),
      ]);
      expect(jsonDecode(repetido.origens!) as List, hasLength(3));
      expect(repetido.texto, 'A\n\nB\n\nC');
    },
  );
  test(
    'mesma origem com conteúdo divergente aborta em vez de sobrescrever',
    () {
      expect(
        () => observacoes.unir(r(1, 0, 'A'), [r(1, 0, 'B')]),
        throwsFormatException,
      );
    },
  );
  test(
    'empate de horários tem ordenação determinística por identidade persistida',
    () {
      final a = r(10, 0, 'igual');
      final b = r(2, 0, 'igual');
      final novo = r(3, 30, 'C');
      expect(
        observacoes.unir(novo, [a, b]).origens,
        observacoes.unir(novo, [b, a]).origens,
      );
      expect(
        jsonDecode(observacoes.unir(novo, [a, b]).origens!) as List,
        hasLength(3),
      );
    },
  );
  test(
    'mover intervalo agregado mantém horários originais inclusive virada de dia',
    () {
      final a = r(
        1,
        0,
        'noite',
      ).copyWith(inicioEm: DateTime.utc(2026, 11, 1, 2, 45));
      final b = r(
        2,
        0,
        'madrugada',
      ).copyWith(inicioEm: DateTime.utc(2026, 11, 1, 3, 15));
      final unido = service.normalizar(b, [a]).resultante;
      final movido = unido.copyWith(inicioEm: DateTime.utc(2026, 11, 2, 9));
      final resposta = observacoes.paraResposta(movido);
      expect(
        resposta.observacoesOriginais!.first.inicioEm,
        DateTime.utc(2026, 11, 1, 2, 45),
      );
      expect(
        resposta.observacoesOriginais!.last.fimEm,
        DateTime.utc(2026, 11, 1, 3, 45),
      );
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
      expect(
        () => observacoes.paraResposta(
          r(1, 0, 'A').copyWith(observacaoOrigens: '[]'),
        ),
        throwsFormatException,
      );
    },
  );
}
