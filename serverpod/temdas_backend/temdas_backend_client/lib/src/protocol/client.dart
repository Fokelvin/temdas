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
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import 'dart:async' as _i2;
import 'package:temdas_backend_client/src/protocol/demandas/demanda.dart'
    as _i3;
import 'package:temdas_backend_client/src/protocol/demandas/demanda_status.dart'
    as _i4;
import 'package:temdas_backend_client/src/protocol/demandas/demanda_create_request.dart'
    as _i5;
import 'package:temdas_backend_client/src/protocol/demandas/demanda_update_request.dart'
    as _i6;
import 'package:temdas_backend_client/src/protocol/greetings/greeting.dart'
    as _i7;
import 'package:temdas_backend_client/src/protocol/registros_tempo/registro_tempo.dart'
    as _i8;
import 'package:temdas_backend_client/src/protocol/registros_tempo/registro_tempo_create_request.dart'
    as _i9;
import 'package:temdas_backend_client/src/protocol/registros_tempo/registro_tempo_update_request.dart'
    as _i10;
import 'protocol.dart' as _i11;

/// {@category Endpoint}
class EndpointDemanda extends _i1.EndpointRef {
  EndpointDemanda(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'demanda';

  _i2.Future<_i3.Demanda> alterarStatusDemanda(
    int id,
    _i4.DemandaStatus status, {
    String? motivoCancelamento,
  }) => caller.callServerEndpoint<_i3.Demanda>(
    'demanda',
    'alterarStatusDemanda',
    {
      'id': id,
      'status': status,
      'motivoCancelamento': motivoCancelamento,
    },
  );

  _i2.Future<_i3.Demanda> concluirDemandaEmCascata(int id) =>
      caller.callServerEndpoint<_i3.Demanda>(
        'demanda',
        'concluirDemandaEmCascata',
        {'id': id},
      );

  _i2.Future<_i3.Demanda> cancelarDemandaEmCascata(
    int id,
    String motivoCancelamento,
  ) => caller.callServerEndpoint<_i3.Demanda>(
    'demanda',
    'cancelarDemandaEmCascata',
    {
      'id': id,
      'motivoCancelamento': motivoCancelamento,
    },
  );

  _i2.Future<_i3.Demanda> criarDemanda(_i5.DemandaCreateRequest request) =>
      caller.callServerEndpoint<_i3.Demanda>(
        'demanda',
        'criarDemanda',
        {'request': request},
      );

  _i2.Future<List<_i3.Demanda>> listarDemandas() =>
      caller.callServerEndpoint<List<_i3.Demanda>>(
        'demanda',
        'listarDemandas',
        {},
      );

  _i2.Future<_i3.Demanda?> buscarDemandaPorId(int id) =>
      caller.callServerEndpoint<_i3.Demanda?>(
        'demanda',
        'buscarDemandaPorId',
        {'id': id},
      );

  _i2.Future<_i3.Demanda> atualizarDemanda(_i6.DemandaUpdateRequest request) =>
      caller.callServerEndpoint<_i3.Demanda>(
        'demanda',
        'atualizarDemanda',
        {'request': request},
      );

  _i2.Future<bool> excluirDemanda(int id) => caller.callServerEndpoint<bool>(
    'demanda',
    'excluirDemanda',
    {'id': id},
  );

  _i2.Future<bool> excluirArvoreDemanda(int id) =>
      caller.callServerEndpoint<bool>(
        'demanda',
        'excluirArvoreDemanda',
        {'id': id},
      );
}

/// This is an example endpoint that returns a greeting message through
/// its [hello] method.
/// {@category Endpoint}
class EndpointGreeting extends _i1.EndpointRef {
  EndpointGreeting(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'greeting';

  /// Returns a personalized greeting message: "Hello {name}".
  _i2.Future<_i7.Greeting> hello(String name) =>
      caller.callServerEndpoint<_i7.Greeting>(
        'greeting',
        'hello',
        {'name': name},
      );
}

/// {@category Endpoint}
class EndpointRegistroTempo extends _i1.EndpointRef {
  EndpointRegistroTempo(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'registroTempo';

  _i2.Future<_i8.RegistroTempo> registrarTempo(
    _i9.RegistroTempoCreateRequest request,
  ) => caller.callServerEndpoint<_i8.RegistroTempo>(
    'registroTempo',
    'registrarTempo',
    {'request': request},
  );

  _i2.Future<_i8.RegistroTempo> editarRegistroTempo(
    _i10.RegistroTempoUpdateRequest request,
  ) => caller.callServerEndpoint<_i8.RegistroTempo>(
    'registroTempo',
    'editarRegistroTempo',
    {'request': request},
  );

  _i2.Future<List<_i8.RegistroTempo>> listarRegistrosTempoPorPeriodo(
    DateTime inicio,
    DateTime fim,
  ) => caller.callServerEndpoint<List<_i8.RegistroTempo>>(
    'registroTempo',
    'listarRegistrosTempoPorPeriodo',
    {
      'inicio': inicio,
      'fim': fim,
    },
  );

  _i2.Future<List<_i8.RegistroTempo>> listarRegistrosTempoDaDemanda(
    int demandaId,
  ) => caller.callServerEndpoint<List<_i8.RegistroTempo>>(
    'registroTempo',
    'listarRegistrosTempoDaDemanda',
    {'demandaId': demandaId},
  );

  _i2.Future<bool> excluirRegistroTempo(int id) =>
      caller.callServerEndpoint<bool>(
        'registroTempo',
        'excluirRegistroTempo',
        {'id': id},
      );
}

class Client extends _i1.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    @Deprecated(
      'Use authKeyProvider instead. This will be removed in future releases.',
    )
    super.authenticationKeyManager,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _i1.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_i1.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
  }) : super(
         host,
         _i11.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
       ) {
    demanda = EndpointDemanda(this);
    greeting = EndpointGreeting(this);
    registroTempo = EndpointRegistroTempo(this);
  }

  late final EndpointDemanda demanda;

  late final EndpointGreeting greeting;

  late final EndpointRegistroTempo registroTempo;

  @override
  Map<String, _i1.EndpointRef> get endpointRefLookup => {
    'demanda': demanda,
    'greeting': greeting,
    'registroTempo': registroTempo,
  };

  @override
  Map<String, _i1.ModuleEndpointCaller> get moduleLookup => {};
}
