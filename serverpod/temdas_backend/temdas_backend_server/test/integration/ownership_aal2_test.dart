import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jose/jose.dart';
// The test server exposes this helper only through its internal API.
// ignore: implementation_imports
import 'package:serverpod/src/server/server.dart';
// ignore: implementation_imports
import 'package:serverpod/src/server/session.dart';
import 'package:temdas_backend_server/src/auth/supabase_auth_service.dart';
import 'package:temdas_backend_server/src/demandas/demanda_endpoint.dart';
import 'package:temdas_backend_server/src/generated/protocol.dart';
import 'package:temdas_backend_server/src/registros_tempo/registro_tempo_endpoint.dart';
import 'package:temdas_backend_server/src/relatorios/relatorio_endpoint.dart';
import 'package:temdas_backend_server/src/sprints/sprint_endpoint.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('AAL2 and ownership of business endpoints', (
    sessionBuilder,
    _,
  ) {
    test('two users cannot read or mutate each other\'s resources', () async {
      final privateKey = JsonWebKey.fromJson({
        ...JsonWebKey.generate('ES256').toJson(),
        'kid': 'ownership-test-key',
        'alg': 'ES256',
      });
      final publicKey = Map<String, dynamic>.from(privateKey.toJson())
        ..remove('d');
      final authService = SupabaseAuthService(
        supabaseUrl: 'https://project.supabase.co',
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'keys': [publicKey],
            }),
            200,
          ),
        ),
      );
      setUsuarioResolverForTesting(null);
      setSupabaseAuthServiceForTesting(authService);
      addTearDown(() => setSupabaseAuthServiceForTesting(null));

      String token(String sub, String aal) {
        final builder = JsonWebSignatureBuilder()
          ..jsonContent = {
            'sub': sub,
            'aal': aal,
            'iss': authService.issuer,
            'aud': 'authenticated',
            'exp':
                DateTime.now()
                    .add(const Duration(hours: 1))
                    .millisecondsSinceEpoch ~/
                1000,
          };
        builder.addRecipient(privateKey, algorithm: 'ES256');
        return builder.build().toCompactSerialization();
      }

      final setupSession = sessionBuilder.build();
      final usuarioA = await Usuario.db.insertRow(
        setupSession,
        Usuario(
          supabaseUserId: 'ownership-a',
          createdAt: DateTime.now().toUtc(),
        ),
      );
      final usuarioB = await Usuario.db.insertRow(
        setupSession,
        Usuario(
          supabaseUserId: 'ownership-b',
          createdAt: DateTime.now().toUtc(),
        ),
      );
      Future<Session> asUser(String sub, String aal) async {
        final session = sessionBuilder.build();
        session.server.setAuthenticationHandlerForTesting((_, _) async => null);
        await session.updateAuthenticationKey(token(sub, aal));
        return session;
      }

      final a = await asUser('ownership-a', 'aal2');
      final b = await asUser('ownership-b', 'aal2');
      final aAal1 = await asUser('ownership-a', 'aal1');
      final demandas = DemandaEndpoint();
      final sprints = SprintEndpoint();
      final tempos = RegistroTempoEndpoint();
      final relatorios = RelatorioEndpoint();

      DemandaCreateRequest request(String titulo, {int? pai}) =>
          DemandaCreateRequest(
            titulo: titulo,
            demandaPaiId: pai,
            tempoEstimadoMinutos: 60,
          );
      final demandaA = await demandas.criarDemanda(a, request('A'));
      final demandaB = await demandas.criarDemanda(b, request('B'));
      final demandaForjada = await demandas.criarDemanda(
        a,
        DemandaCreateRequest.fromJson({
          ...request('tentativa de owner B').toJson(),
          'usuarioId': usuarioB.id,
        }),
      );
      expect(demandaA.usuarioId, usuarioA.id);
      expect(demandaB.usuarioId, usuarioB.id);
      expect(demandaForjada.usuarioId, usuarioA.id);
      expect(
        (await demandas.listarDemandas(a)).map((d) => d.id),
        contains(demandaA.id),
      );
      expect(
        (await demandas.listarDemandas(a)).map((d) => d.id),
        isNot(contains(demandaB.id)),
      );
      expect(await demandas.buscarDemandaPorId(a, demandaB.id!), isNull);
      await expectLater(
        demandas.atualizarDemanda(
          a,
          DemandaUpdateRequest(
            id: demandaB.id!,
            titulo: 'invasão',
            status: DemandaStatus.aberta,
            prioridade: Prioridade.media,
            tempoEstimadoMinutos: 60,
          ),
        ),
        throwsA(isA<TransicaoStatusException>()),
      );
      expect(await demandas.excluirDemanda(a, demandaB.id!), isFalse);
      await expectLater(
        demandas.alterarStatusDemanda(a, demandaB.id!, DemandaStatus.concluida),
        throwsA(isA<TransicaoStatusException>()),
      );
      await expectLater(
        demandas.criarDemanda(a, request('filha cruzada', pai: demandaB.id)),
        throwsA(isA<TransicaoStatusException>()),
      );

      final inicio = DateTime.utc(2026, 10, 1);
      SprintCreateRequest sprintRequest() => SprintCreateRequest(
        nome: 'Teste',
        dataInicio: inicio,
        dataFim: inicio.add(const Duration(days: 4)),
      );
      final sprintA = await sprints.criarSprint(a, sprintRequest());
      final sprintB = await sprints.criarSprint(b, sprintRequest());
      final sprintForjada = await sprints.criarSprint(
        a,
        SprintCreateRequest.fromJson({
          ...SprintCreateRequest(
            nome: 'Outra',
            dataInicio: DateTime.utc(2026, 11, 1),
            dataFim: DateTime.utc(2026, 11, 5),
          ).toJson(),
          'usuarioId': usuarioB.id,
        }),
      );
      expect(sprintA.usuarioId, usuarioA.id);
      expect(sprintB.usuarioId, usuarioB.id);
      expect(sprintForjada.usuarioId, usuarioA.id);
      expect(
        (await sprints.listarSprints(a)).map((s) => s.id),
        isNot(contains(sprintB.id)),
      );
      await expectLater(
        sprints.buscarSprintPorId(a, sprintB.id!),
        throwsA(isA<SprintException>()),
      );
      await expectLater(
        sprints.atualizarSprint(
          a,
          SprintUpdateRequest(
            id: sprintB.id!,
            nome: 'Outro',
            dataInicio: inicio,
            dataFim: inicio.add(const Duration(days: 4)),
          ),
        ),
        throwsA(isA<SprintException>()),
      );
      expect(await sprints.excluirSprint(a, sprintB.id!), isFalse);
      await expectLater(
        sprints.vincularDemanda(a, sprintB.id!, demandaA.id!),
        throwsA(isA<SprintException>()),
      );
      await expectLater(
        sprints.vincularDemandas(a, sprintB.id!, []),
        throwsA(isA<SprintException>()),
      );
      await expectLater(
        sprints.vincularDemanda(a, sprintA.id!, demandaB.id!),
        throwsA(isA<SprintException>()),
      );
      expect(
        await sprints.vincularDemanda(a, sprintA.id!, demandaA.id!),
        isNotEmpty,
      );
      expect(
        await sprints.desvincularDemanda(a, sprintB.id!, demandaA.id!),
        isFalse,
      );

      final momento = DateTime.utc(2026, 10, 2, 12);
      await expectLater(
        tempos.registrarTempo(
          a,
          RegistroTempoCreateRequest(
            demandaId: demandaB.id!,
            inicioEm: momento,
            duracaoMinutos: 30,
          ),
        ),
        throwsA(
          isA<RegistroTempoException>().having(
            (e) => e.codigo,
            'codigo',
            'demandaNaoEncontrada',
          ),
        ),
      );
      final registroB = await tempos.registrarTempo(
        b,
        RegistroTempoCreateRequest(
          demandaId: demandaB.id!,
          inicioEm: momento,
          duracaoMinutos: 30,
        ),
      );
      final registroA = await tempos.registrarTempo(
        a,
        RegistroTempoCreateRequest(
          demandaId: demandaA.id!,
          inicioEm: momento,
          duracaoMinutos: 30,
        ),
      );
      expect(registroA.demandaId, demandaA.id);
      await expectLater(
        tempos.listarRegistrosTempoDaDemanda(a, demandaB.id!),
        throwsA(
          isA<RegistroTempoException>().having(
            (e) => e.codigo,
            'codigo',
            'demandaNaoEncontrada',
          ),
        ),
      );
      expect(
        (await tempos.listarRegistrosTempoPorPeriodo(
          a,
          momento.subtract(const Duration(hours: 1)),
          momento.add(const Duration(hours: 1)),
        )).map((r) => r.id),
        isNot(contains(registroB.id)),
      );
      expect(await tempos.excluirRegistroTempo(a, registroB.id!), isFalse);
      await expectLater(
        tempos.editarRegistroTempo(
          a,
          RegistroTempoUpdateRequest(
            id: registroB.id!,
            inicioEm: momento,
            duracaoMinutos: 45,
          ),
        ),
        throwsA(
          isA<RegistroTempoException>().having(
            (e) => e.codigo,
            'codigo',
            'registroNaoEncontrado',
          ),
        ),
      );
      final relatorioA = await relatorios.gerarRelatorioDemandas(
        a,
        RelatorioDemandaRequest(
          inicioEm: momento.subtract(const Duration(hours: 1)),
          fimExclusivo: momento.add(const Duration(hours: 1)),
        ),
      );
      expect(
        relatorioA.itens.map((item) => item.demandaId),
        contains(demandaA.id),
      );
      expect(
        relatorioA.itens.map((item) => item.demandaId),
        isNot(contains(demandaB.id)),
      );

      await expectLater(
        demandas.listarDemandas(aAal1),
        throwsA(
          isA<AuthException>().having(
            (e) => e.codigo,
            'codigo',
            'aal2Required',
          ),
        ),
      );
      await expectLater(
        sprints.listarSprints(aAal1),
        throwsA(
          isA<AuthException>().having(
            (e) => e.codigo,
            'codigo',
            'aal2Required',
          ),
        ),
      );
      await expectLater(
        tempos.listarRegistrosTempoDaDemanda(aAal1, demandaA.id!),
        throwsA(
          isA<AuthException>().having(
            (e) => e.codigo,
            'codigo',
            'aal2Required',
          ),
        ),
      );
      await expectLater(
        relatorios.gerarRelatorioDemandas(
          aAal1,
          RelatorioDemandaRequest(
            inicioEm: momento,
            fimExclusivo: momento.add(const Duration(hours: 1)),
          ),
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.codigo,
            'codigo',
            'aal2Required',
          ),
        ),
      );
      expect(
        (await demandas.buscarDemandaPorId(a, demandaA.id!))?.id,
        demandaA.id,
      );
      expect((await sprints.buscarSprintPorId(a, sprintA.id!)).id, sprintA.id);
    });
  });
}
