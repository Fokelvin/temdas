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
import 'package:temdas_backend_server/src/generated/demandas/demanda_create_request.dart'
    as _i5;
import 'package:temdas_backend_server/src/generated/demandas/demanda_update_request.dart'
    as _i6;
import 'package:temdas_backend_server/src/generated/registros_tempo/registro_tempo_create_request.dart'
    as _i7;

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
    };
    connectors['demanda'] = _i1.EndpointConnector(
      name: 'demanda',
      endpoint: endpoints['demanda']!,
      methodConnectors: {
        'criarDemanda': _i1.MethodConnector(
          name: 'criarDemanda',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i5.DemandaCreateRequest>(),
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
              type: _i1.getType<_i6.DemandaUpdateRequest>(),
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
              type: _i1.getType<_i7.RegistroTempoCreateRequest>(),
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
  }
}
