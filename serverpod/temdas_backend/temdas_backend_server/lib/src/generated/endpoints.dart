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
import '../admin/convite_endpoint.dart' as _i2;
import '../anotacoes/anotacao_demanda_endpoint.dart' as _i3;
import '../auth/auth_endpoint.dart' as _i4;
import '../demandas/demanda_endpoint.dart' as _i5;
import '../greetings/greeting_endpoint.dart' as _i6;
import '../registros_tempo/registro_tempo_endpoint.dart' as _i7;
import '../relatorios/relatorio_endpoint.dart' as _i8;
import '../sprints/sprint_endpoint.dart' as _i9;
import '../todos/todo_endpoint.dart' as _i10;
import 'package:temdas_backend_server/src/generated/demandas/demanda_localizacao.dart'
    as _i11;
import 'package:temdas_backend_server/src/generated/demandas/demanda_status.dart'
    as _i12;
import 'package:temdas_backend_server/src/generated/demandas/demanda_movimentacao_request.dart'
    as _i13;
import 'package:temdas_backend_server/src/generated/demandas/demanda_create_request.dart'
    as _i14;
import 'package:temdas_backend_server/src/generated/demandas/demanda_update_request.dart'
    as _i15;
import 'package:temdas_backend_server/src/generated/registros_tempo/registro_tempo_create_request.dart'
    as _i16;
import 'package:temdas_backend_server/src/generated/registros_tempo/registro_tempo_update_request.dart'
    as _i17;
import 'package:temdas_backend_server/src/generated/relatorios/relatorio_demanda_request.dart'
    as _i18;
import 'package:temdas_backend_server/src/generated/sprints/sprint_create_request.dart'
    as _i19;
import 'package:temdas_backend_server/src/generated/sprints/sprint_update_request.dart'
    as _i20;

class Endpoints extends _i1.EndpointDispatch {
  @override
  void initializeEndpoints(_i1.Server server) {
    var endpoints = <String, _i1.Endpoint>{
      'convite': _i2.ConviteEndpoint()
        ..initialize(
          server,
          'convite',
          null,
        ),
      'anotacaoDemanda': _i3.AnotacaoDemandaEndpoint()
        ..initialize(
          server,
          'anotacaoDemanda',
          null,
        ),
      'auth': _i4.AuthEndpoint()
        ..initialize(
          server,
          'auth',
          null,
        ),
      'demanda': _i5.DemandaEndpoint()
        ..initialize(
          server,
          'demanda',
          null,
        ),
      'greeting': _i6.GreetingEndpoint()
        ..initialize(
          server,
          'greeting',
          null,
        ),
      'registroTempo': _i7.RegistroTempoEndpoint()
        ..initialize(
          server,
          'registroTempo',
          null,
        ),
      'relatorio': _i8.RelatorioEndpoint()
        ..initialize(
          server,
          'relatorio',
          null,
        ),
      'sprint': _i9.SprintEndpoint()
        ..initialize(
          server,
          'sprint',
          null,
        ),
      'todo': _i10.TodoEndpoint()
        ..initialize(
          server,
          'todo',
          null,
        ),
    };
    connectors['convite'] = _i1.EndpointConnector(
      name: 'convite',
      endpoint: endpoints['convite']!,
      methodConnectors: {
        'consultar': _i1.MethodConnector(
          name: 'consultar',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['convite'] as _i2.ConviteEndpoint).consultar(
                    session,
                    params['email'],
                  ),
        ),
        'convidar': _i1.MethodConnector(
          name: 'convidar',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['convite'] as _i2.ConviteEndpoint).convidar(
                session,
                params['email'],
              ),
        ),
        'reenviar': _i1.MethodConnector(
          name: 'reenviar',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['convite'] as _i2.ConviteEndpoint).reenviar(
                session,
                params['email'],
              ),
        ),
      },
    );
    connectors['anotacaoDemanda'] = _i1.EndpointConnector(
      name: 'anotacaoDemanda',
      endpoint: endpoints['anotacaoDemanda']!,
      methodConnectors: {
        'listar': _i1.MethodConnector(
          name: 'listar',
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
                  (endpoints['anotacaoDemanda'] as _i3.AnotacaoDemandaEndpoint)
                      .listar(
                        session,
                        params['demandaId'],
                      ),
        ),
        'criar': _i1.MethodConnector(
          name: 'criar',
          params: {
            'demandaId': _i1.ParameterDescription(
              name: 'demandaId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'conteudo': _i1.ParameterDescription(
              name: 'conteudo',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['anotacaoDemanda'] as _i3.AnotacaoDemandaEndpoint)
                      .criar(
                        session,
                        params['demandaId'],
                        params['conteudo'],
                      ),
        ),
        'editar': _i1.MethodConnector(
          name: 'editar',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'conteudo': _i1.ParameterDescription(
              name: 'conteudo',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['anotacaoDemanda'] as _i3.AnotacaoDemandaEndpoint)
                      .editar(
                        session,
                        params['id'],
                        params['conteudo'],
                      ),
        ),
        'excluir': _i1.MethodConnector(
          name: 'excluir',
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
                  (endpoints['anotacaoDemanda'] as _i3.AnotacaoDemandaEndpoint)
                      .excluir(
                        session,
                        params['id'],
                      ),
        ),
      },
    );
    connectors['auth'] = _i1.EndpointConnector(
      name: 'auth',
      endpoint: endpoints['auth']!,
      methodConnectors: {
        'provisionar': _i1.MethodConnector(
          name: 'provisionar',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['auth'] as _i4.AuthEndpoint).provisionar(session),
        ),
        'me': _i1.MethodConnector(
          name: 'me',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['auth'] as _i4.AuthEndpoint).me(session),
        ),
      },
    );
    connectors['demanda'] = _i1.EndpointConnector(
      name: 'demanda',
      endpoint: endpoints['demanda']!,
      methodConnectors: {
        'preverEnvioAoBacklog': _i1.MethodConnector(
          name: 'preverEnvioAoBacklog',
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
              ) async => (endpoints['demanda'] as _i5.DemandaEndpoint)
                  .preverEnvioAoBacklog(
                    session,
                    params['id'],
                  ),
        ),
        'alterarLocalizacao': _i1.MethodConnector(
          name: 'alterarLocalizacao',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'destino': _i1.ParameterDescription(
              name: 'destino',
              type: _i1.getType<_i11.DemandaLocalizacao>(),
              nullable: false,
            ),
            'vinculosConfirmados': _i1.ParameterDescription(
              name: 'vinculosConfirmados',
              type: _i1.getType<List<int>>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['demanda'] as _i5.DemandaEndpoint)
                  .alterarLocalizacao(
                    session,
                    params['id'],
                    params['destino'],
                    params['vinculosConfirmados'],
                  ),
        ),
        'buscarDemandasGlobalmente': _i1.MethodConnector(
          name: 'buscarDemandasGlobalmente',
          params: {
            'consulta': _i1.ParameterDescription(
              name: 'consulta',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['demanda'] as _i5.DemandaEndpoint)
                  .buscarDemandasGlobalmente(
                    session,
                    params['consulta'],
                  ),
        ),
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
              type: _i1.getType<_i12.DemandaStatus>(),
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
              ) async => (endpoints['demanda'] as _i5.DemandaEndpoint)
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
              ) async => (endpoints['demanda'] as _i5.DemandaEndpoint)
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
              ) async => (endpoints['demanda'] as _i5.DemandaEndpoint)
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
              type: _i1.getType<_i13.DemandaMovimentacaoRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['demanda'] as _i5.DemandaEndpoint).moverDemanda(
                    session,
                    params['request'],
                  ),
        ),
        'criarDemanda': _i1.MethodConnector(
          name: 'criarDemanda',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i14.DemandaCreateRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['demanda'] as _i5.DemandaEndpoint).criarDemanda(
                    session,
                    params['request'],
                  ),
        ),
        'listarDemandas': _i1.MethodConnector(
          name: 'listarDemandas',
          params: {
            'localizacao': _i1.ParameterDescription(
              name: 'localizacao',
              type: _i1.getType<_i11.DemandaLocalizacao?>(),
              nullable: true,
            ),
            'incluirBacklog': _i1.ParameterDescription(
              name: 'incluirBacklog',
              type: _i1.getType<bool?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['demanda'] as _i5.DemandaEndpoint).listarDemandas(
                    session,
                    localizacao: params['localizacao'],
                    incluirBacklog: params['incluirBacklog'],
                  ),
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
              ) async => (endpoints['demanda'] as _i5.DemandaEndpoint)
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
              type: _i1.getType<_i15.DemandaUpdateRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['demanda'] as _i5.DemandaEndpoint)
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
                  (endpoints['demanda'] as _i5.DemandaEndpoint).excluirDemanda(
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
              ) async => (endpoints['demanda'] as _i5.DemandaEndpoint)
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
              ) async => (endpoints['greeting'] as _i6.GreetingEndpoint).hello(
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
              type: _i1.getType<_i16.RegistroTempoCreateRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['registroTempo'] as _i7.RegistroTempoEndpoint)
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
              type: _i1.getType<_i17.RegistroTempoUpdateRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['registroTempo'] as _i7.RegistroTempoEndpoint)
                      .editarRegistroTempo(
                        session,
                        params['request'],
                      ),
        ),
        'atualizarObservacao': _i1.MethodConnector(
          name: 'atualizarObservacao',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'observacao': _i1.ParameterDescription(
              name: 'observacao',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['registroTempo'] as _i7.RegistroTempoEndpoint)
                      .atualizarObservacao(
                        session,
                        params['id'],
                        params['observacao'],
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
                  (endpoints['registroTempo'] as _i7.RegistroTempoEndpoint)
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
                  (endpoints['registroTempo'] as _i7.RegistroTempoEndpoint)
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
                  (endpoints['registroTempo'] as _i7.RegistroTempoEndpoint)
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
              type: _i1.getType<_i18.RelatorioDemandaRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['relatorio'] as _i8.RelatorioEndpoint)
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
              ) async => (endpoints['sprint'] as _i9.SprintEndpoint)
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
                  (endpoints['sprint'] as _i9.SprintEndpoint).buscarSprintPorId(
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
              ) async => (endpoints['sprint'] as _i9.SprintEndpoint)
                  .listarDemandasDaSprint(
                    session,
                    params['sprintId'],
                  ),
        ),
        'listarContextoDemandas': _i1.MethodConnector(
          name: 'listarContextoDemandas',
          params: {
            'demandaIds': _i1.ParameterDescription(
              name: 'demandaIds',
              type: _i1.getType<List<int>?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sprint'] as _i9.SprintEndpoint)
                  .listarContextoDemandas(
                    session,
                    params['demandaIds'],
                  ),
        ),
        'criarSprint': _i1.MethodConnector(
          name: 'criarSprint',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i19.SprintCreateRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['sprint'] as _i9.SprintEndpoint).criarSprint(
                    session,
                    params['request'],
                  ),
        ),
        'atualizarSprint': _i1.MethodConnector(
          name: 'atualizarSprint',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i20.SprintUpdateRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['sprint'] as _i9.SprintEndpoint).atualizarSprint(
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
                  (endpoints['sprint'] as _i9.SprintEndpoint).ativarSprint(
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
                  (endpoints['sprint'] as _i9.SprintEndpoint).cancelarSprint(
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
                  (endpoints['sprint'] as _i9.SprintEndpoint).concluirSprint(
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
              ) async => (endpoints['sprint'] as _i9.SprintEndpoint)
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
              ) async => (endpoints['sprint'] as _i9.SprintEndpoint)
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
                  (endpoints['sprint'] as _i9.SprintEndpoint).excluirSprint(
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
                  (endpoints['sprint'] as _i9.SprintEndpoint).reabrirSprint(
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
                  (endpoints['sprint'] as _i9.SprintEndpoint).vincularDemanda(
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
                  (endpoints['sprint'] as _i9.SprintEndpoint).vincularDemandas(
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
              ) async => (endpoints['sprint'] as _i9.SprintEndpoint)
                  .desvincularDemanda(
                    session,
                    params['sprintId'],
                    params['demandaId'],
                  ),
        ),
      },
    );
    connectors['todo'] = _i1.EndpointConnector(
      name: 'todo',
      endpoint: endpoints['todo']!,
      methodConnectors: {
        'listar': _i1.MethodConnector(
          name: 'listar',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['todo'] as _i10.TodoEndpoint).listar(session),
        ),
        'criar': _i1.MethodConnector(
          name: 'criar',
          params: {
            'conteudo': _i1.ParameterDescription(
              name: 'conteudo',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'demandaId': _i1.ParameterDescription(
              name: 'demandaId',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['todo'] as _i10.TodoEndpoint).criar(
                session,
                params['conteudo'],
                params['demandaId'],
              ),
        ),
        'editarTexto': _i1.MethodConnector(
          name: 'editarTexto',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'conteudo': _i1.ParameterDescription(
              name: 'conteudo',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['todo'] as _i10.TodoEndpoint).editarTexto(
                session,
                params['id'],
                params['conteudo'],
              ),
        ),
        'alterarData': _i1.MethodConnector(
          name: 'alterarData',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'data': _i1.ParameterDescription(
              name: 'data',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['todo'] as _i10.TodoEndpoint).alterarData(
                session,
                params['id'],
                params['data'],
              ),
        ),
        'alterarConclusao': _i1.MethodConnector(
          name: 'alterarConclusao',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'concluido': _i1.ParameterDescription(
              name: 'concluido',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['todo'] as _i10.TodoEndpoint).alterarConclusao(
                    session,
                    params['id'],
                    params['concluido'],
                  ),
        ),
        'redimensionar': _i1.MethodConnector(
          name: 'redimensionar',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'largura': _i1.ParameterDescription(
              name: 'largura',
              type: _i1.getType<double>(),
              nullable: false,
            ),
            'altura': _i1.ParameterDescription(
              name: 'altura',
              type: _i1.getType<double>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['todo'] as _i10.TodoEndpoint).redimensionar(
                session,
                params['id'],
                params['largura'],
                params['altura'],
              ),
        ),
        'vincular': _i1.MethodConnector(
          name: 'vincular',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'demandaId': _i1.ParameterDescription(
              name: 'demandaId',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['todo'] as _i10.TodoEndpoint).vincular(
                session,
                params['id'],
                params['demandaId'],
              ),
        ),
        'mover': _i1.MethodConnector(
          name: 'mover',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'destinoId': _i1.ParameterDescription(
              name: 'destinoId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'depois': _i1.ParameterDescription(
              name: 'depois',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['todo'] as _i10.TodoEndpoint).mover(
                session,
                params['id'],
                params['destinoId'],
                params['depois'],
              ),
        ),
        'excluir': _i1.MethodConnector(
          name: 'excluir',
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
              ) async => (endpoints['todo'] as _i10.TodoEndpoint).excluir(
                session,
                params['id'],
              ),
        ),
      },
    );
  }
}
