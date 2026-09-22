/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:serverpod/serverpod.dart' as _i1;
import '../demandas/demanda_endpoint.dart' as _i2;
import '../greetings/greeting_endpoint.dart' as _i3;
import '../registros_tempo/registro_tempo_endpoint.dart' as _i4;
import '../relatorios/relatorio_endpoint.dart' as _i5;
import '../sprints/sprint_endpoint.dart' as _i6;
import 'package:temdas_backend_server/src/generated/demandas/demanda_status.dart'
    as _i7;
import 'package:temdas_backend_server/src/generated/demandas/demanda_movimentacao_request.dart'
    as _i8;
import 'package:temdas_backend_server/src/generated/demandas/demanda_create_request.dart'
    as _i9;
import 'package:temdas_backend_server/src/generated/demandas/demanda_update_request.dart'
    as _i10;
import 'package:temdas_backend_server/src/generated/registros_tempo/registro_tempo_create_request.dart'
    as _i11;
import 'package:temdas_backend_server/src/generated/registros_tempo/registro_tempo_update_request.dart'
    as _i12;
import 'package:temdas_backend_server/src/generated/relatorios/relatorio_demanda_request.dart'
    as _i13;
import 'package:temdas_backend_server/src/generated/sprints/sprint_create_request.dart'
    as _i14;
import 'package:temdas_backend_server/src/generated/sprints/sprint_update_request.dart'
    as _i15;

class Endpoints extends _i1.EndpointDispatch {
  @override
  void initializeEndpoints(_i1.Server server) {
    var endpoints = <String, _i1.Endpoint>{
      'demanda': _i2.DemandaEndpoint()
        ..initialize(
          server,
          'demanda',
          null,
        ),
      'greeting': _i3.GreetingEndpoint()
        ..initialize(
          server,
          'greeting',
          null,
        ),
      'registroTempo': _i4.RegistroTempoEndpoint()
        ..initialize(
          server,
          'registroTempo',
          null,
        ),
      'relatorio': _i5.RelatorioEndpoint()
        ..initialize(
          server,
          'relatorio',
          null,
        ),
      'sprint': _i6.SprintEndpoint()
        ..initialize(
          server,
          'sprint',
          null,
        ),
    };
    connectors['demanda'] = _i1.EndpointConnector(
      name: 'demanda',
      endpoint: endpoints['demanda']!,
      methodConnectors: {
        'alterarStatusDemanda': _i1.MethodConnector(
          name: 'alterarStatusDemanda',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'status': _i1.ParameterDescription(
              name: 'status',
              type: _i1.getType<_i7.DemandaStatus>(),
              nullable: false,
            ),
            'motivoCancelamento': _i1.ParameterDescription(
              name: 'motivoCancelamento',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['demanda'] as _i2.DemandaEndpoint)
                  .alterarStatusDemanda(
                    session,
                    params['id'],
                    params['status'],
                    motivoCancelamento: params['motivoCancelamento'],
                  ),
        ),
        'concluirDemandaEmCascata': _i1.MethodConnector(
          name: 'concluirDemandaEmCascata',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['demanda'] as _i2.DemandaEndpoint)
                  .concluirDemandaEmCascata(
                    session,
                    params['id'],
                  ),
        ),
        'cancelarDemandaEmCascata': _i1.MethodConnector(
          name: 'cancelarDemandaEmCascata',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'motivoCancelamento': _i1.ParameterDescription(
              name: 'motivoCancelamento',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['demanda'] as _i2.DemandaEndpoint)
                  .cancelarDemandaEmCascata(
                    session,
                    params['id'],
                    params['motivoCancelamento'],
                  ),
        ),
        'moverDemanda': _i1.MethodConnector(
          name: 'moverDemanda',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i8.DemandaMovimentacaoRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['demanda'] as _i2.DemandaEndpoint).moverDemanda(
                    session,
                    params['request'],
                  ),
        ),
        'criarDemanda': _i1.MethodConnector(
          name: 'criarDemanda',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i9.DemandaCreateRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['demanda'] as _i2.DemandaEndpoint).criarDemanda(
                    session,
                    params['request'],
                  ),
        ),
        'listarDemandas': _i1.MethodConnector(
          name: 'listarDemandas',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['demanda'] as _i2.DemandaEndpoint)
                  .listarDemandas(session),
        ),
        'buscarDemandaPorId': _i1.MethodConnector(
          name: 'buscarDemandaPorId',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['demanda'] as _i2.DemandaEndpoint)
                  .buscarDemandaPorId(
                    session,
                    params['id'],
                  ),
        ),
        'atualizarDemanda': _i1.MethodConnector(
          name: 'atualizarDemanda',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i10.DemandaUpdateRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['demanda'] as _i2.DemandaEndpoint)
                  .atualizarDemanda(
                    session,
                    params['request'],
                  ),
        ),
        'excluirDemanda': _i1.MethodConnector(
          name: 'excluirDemanda',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['demanda'] as _i2.DemandaEndpoint).excluirDemanda(
                    session,
                    params['id'],
                  ),
        ),
        'excluirArvoreDemanda': _i1.MethodConnector(
          name: 'excluirArvoreDemanda',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['demanda'] as _i2.DemandaEndpoint)
                  .excluirArvoreDemanda(
                    session,
                    params['id'],
                  ),
        ),
      },
    );
    connectors['greeting'] = _i1.EndpointConnector(
      name: 'greeting',
      endpoint: endpoints['greeting']!,
      methodConnectors: {
        'hello': _i1.MethodConnector(
          name: 'hello',
          params: {
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['greeting'] as _i3.GreetingEndpoint).hello(
                session,
                params['name'],
              ),
        ),
      },
    );
    connectors['registroTempo'] = _i1.EndpointConnector(
      name: 'registroTempo',
      endpoint: endpoints['registroTempo']!,
      methodConnectors: {
        'registrarTempo': _i1.MethodConnector(
          name: 'registrarTempo',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i11.RegistroTempoCreateRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['registroTempo'] as _i4.RegistroTempoEndpoint)
                      .registrarTempo(
                        session,
                        params['request'],
                      ),
        ),
        'editarRegistroTempo': _i1.MethodConnector(
          name: 'editarRegistroTempo',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i12.RegistroTempoUpdateRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['registroTempo'] as _i4.RegistroTempoEndpoint)
                      .editarRegistroTempo(
                        session,
                        params['request'],
                      ),
        ),
        'listarRegistrosTempoPorPeriodo': _i1.MethodConnector(
          name: 'listarRegistrosTempoPorPeriodo',
          params: {
            'inicio': _i1.ParameterDescription(
              name: 'inicio',
              type: _i1.getType<DateTime>(),
              nullable: false,
            ),
            'fim': _i1.ParameterDescription(
              name: 'fim',
              type: _i1.getType<DateTime>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['registroTempo'] as _i4.RegistroTempoEndpoint)
                      .listarRegistrosTempoPorPeriodo(
                        session,
                        params['inicio'],
                        params['fim'],
                      ),
        ),
        'listarRegistrosTempoDaDemanda': _i1.MethodConnector(
          name: 'listarRegistrosTempoDaDemanda',
          params: {
            'demandaId': _i1.ParameterDescription(
              name: 'demandaId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['registroTempo'] as _i4.RegistroTempoEndpoint)
                      .listarRegistrosTempoDaDemanda(
                        session,
                        params['demandaId'],
                      ),
        ),
        'excluirRegistroTempo': _i1.MethodConnector(
          name: 'excluirRegistroTempo',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['registroTempo'] as _i4.RegistroTempoEndpoint)
                      .excluirRegistroTempo(
                        session,
                        params['id'],
                      ),
        ),
      },
    );
    connectors['relatorio'] = _i1.EndpointConnector(
      name: 'relatorio',
      endpoint: endpoints['relatorio']!,
      methodConnectors: {
        'gerarRelatorioDemandas': _i1.MethodConnector(
          name: 'gerarRelatorioDemandas',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i13.RelatorioDemandaRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['relatorio'] as _i5.RelatorioEndpoint)
                  .gerarRelatorioDemandas(
                    session,
                    params['request'],
                  ),
        ),
      },
    );
    connectors['sprint'] = _i1.EndpointConnector(
      name: 'sprint',
      endpoint: endpoints['sprint']!,
      methodConnectors: {
        'listarSprints': _i1.MethodConnector(
          name: 'listarSprints',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sprint'] as _i6.SprintEndpoint)
                  .listarSprints(session),
        ),
        'buscarSprintPorId': _i1.MethodConnector(
          name: 'buscarSprintPorId',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['sprint'] as _i6.SprintEndpoint).buscarSprintPorId(
                    session,
                    params['id'],
                  ),
        ),
        'listarDemandasDaSprint': _i1.MethodConnector(
          name: 'listarDemandasDaSprint',
          params: {
            'sprintId': _i1.ParameterDescription(
              name: 'sprintId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sprint'] as _i6.SprintEndpoint)
                  .listarDemandasDaSprint(
                    session,
                    params['sprintId'],
                  ),
        ),
        'criarSprint': _i1.MethodConnector(
          name: 'criarSprint',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i14.SprintCreateRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['sprint'] as _i6.SprintEndpoint).criarSprint(
                    session,
                    params['request'],
                  ),
        ),
        'atualizarSprint': _i1.MethodConnector(
          name: 'atualizarSprint',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i15.SprintUpdateRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['sprint'] as _i6.SprintEndpoint).atualizarSprint(
                    session,
                    params['request'],
                  ),
        ),
        'ativarSprint': _i1.MethodConnector(
          name: 'ativarSprint',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['sprint'] as _i6.SprintEndpoint).ativarSprint(
                    session,
                    params['id'],
                  ),
        ),
        'cancelarSprint': _i1.MethodConnector(
          name: 'cancelarSprint',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['sprint'] as _i6.SprintEndpoint).cancelarSprint(
                    session,
                    params['id'],
                  ),
        ),
        'concluirSprint': _i1.MethodConnector(
          name: 'concluirSprint',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['sprint'] as _i6.SprintEndpoint).concluirSprint(
                    session,
                    params['id'],
                  ),
        ),
        'obterResumoConclusaoSprint': _i1.MethodConnector(
          name: 'obterResumoConclusaoSprint',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sprint'] as _i6.SprintEndpoint)
                  .obterResumoConclusaoSprint(
                    session,
                    params['id'],
                  ),
        ),
        'calcularIndicadoresSprint': _i1.MethodConnector(
          name: 'calcularIndicadoresSprint',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sprint'] as _i6.SprintEndpoint)
                  .calcularIndicadoresSprint(
                    session,
                    params['id'],
                  ),
        ),
        'excluirSprint': _i1.MethodConnector(
          name: 'excluirSprint',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['sprint'] as _i6.SprintEndpoint).excluirSprint(
                    session,
                    params['id'],
                  ),
        ),
        'reabrirSprint': _i1.MethodConnector(
          name: 'reabrirSprint',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['sprint'] as _i6.SprintEndpoint).reabrirSprint(
                    session,
                    params['id'],
                  ),
        ),
        'vincularDemanda': _i1.MethodConnector(
          name: 'vincularDemanda',
          params: {
            'sprintId': _i1.ParameterDescription(
              name: 'sprintId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'demandaId': _i1.ParameterDescription(
              name: 'demandaId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['sprint'] as _i6.SprintEndpoint).vincularDemanda(
                    session,
                    params['sprintId'],
                    params['demandaId'],
                  ),
        ),
        'vincularDemandas': _i1.MethodConnector(
          name: 'vincularDemandas',
          params: {
            'sprintId': _i1.ParameterDescription(
              name: 'sprintId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'demandaIds': _i1.ParameterDescription(
              name: 'demandaIds',
              type: _i1.getType<List<int>>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['sprint'] as _i6.SprintEndpoint).vincularDemandas(
                    session,
                    params['sprintId'],
                    params['demandaIds'],
                  ),
        ),
        'desvincularDemanda': _i1.MethodConnector(
          name: 'desvincularDemanda',
          params: {
            'sprintId': _i1.ParameterDescription(
              name: 'sprintId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'demandaId': _i1.ParameterDescription(
              name: 'demandaId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sprint'] as _i6.SprintEndpoint)
                  .desvincularDemanda(
                    session,
                    params['sprintId'],
                    params['demandaId'],
                  ),
        ),
      },
    );
  }
}
