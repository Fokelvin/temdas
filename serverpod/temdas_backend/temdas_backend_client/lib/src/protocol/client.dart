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
import 'package:temdas_backend_client/src/protocol/auth/auth_me.dart' as _i3;
import 'package:temdas_backend_client/src/protocol/demandas/demanda.dart'
    as _i4;
import 'package:temdas_backend_client/src/protocol/demandas/demanda_status.dart'
    as _i5;
import 'package:temdas_backend_client/src/protocol/demandas/demanda_movimentacao_request.dart'
    as _i6;
import 'package:temdas_backend_client/src/protocol/demandas/demanda_create_request.dart'
    as _i7;
import 'package:temdas_backend_client/src/protocol/demandas/demanda_update_request.dart'
    as _i8;
import 'package:temdas_backend_client/src/protocol/greetings/greeting.dart'
    as _i9;
import 'package:temdas_backend_client/src/protocol/registros_tempo/registro_tempo.dart'
    as _i10;
import 'package:temdas_backend_client/src/protocol/registros_tempo/registro_tempo_create_request.dart'
    as _i11;
import 'package:temdas_backend_client/src/protocol/registros_tempo/registro_tempo_update_request.dart'
    as _i12;
import 'package:temdas_backend_client/src/protocol/relatorios/relatorio_demandas_response.dart'
    as _i13;
import 'package:temdas_backend_client/src/protocol/relatorios/relatorio_demanda_request.dart'
    as _i14;
import 'package:temdas_backend_client/src/protocol/sprints/sprint.dart' as _i15;
import 'package:temdas_backend_client/src/protocol/sprints/sprint_demanda.dart'
    as _i16;
import 'package:temdas_backend_client/src/protocol/sprints/sprint_create_request.dart'
    as _i17;
import 'package:temdas_backend_client/src/protocol/sprints/sprint_update_request.dart'
    as _i18;
import 'package:temdas_backend_client/src/protocol/sprints/sprint_conclusao_response.dart'
    as _i19;
import 'package:temdas_backend_client/src/protocol/sprints/sprint_indicadores.dart'
    as _i20;
import 'protocol.dart' as _i21;

/// {@category Endpoint}
class EndpointConvite extends _i1.EndpointRef {
  EndpointConvite(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'convite';

  _i2.Future<String> consultar(String email) =>
      caller.callServerEndpoint<String>(
        'convite',
        'consultar',
        {'email': email},
      );

  _i2.Future<String> convidar(String email) =>
      caller.callServerEndpoint<String>(
        'convite',
        'convidar',
        {'email': email},
      );

  _i2.Future<String> reenviar(String email) =>
      caller.callServerEndpoint<String>(
        'convite',
        'reenviar',
        {'email': email},
      );
}

/// {@category Endpoint}
class EndpointAuth extends _i1.EndpointRef {
  EndpointAuth(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'auth';

  /// Onboarding accepts AAL1/AAL2 before an internal Usuario exists.
  _i2.Future<_i3.AuthMe> provisionar() => caller.callServerEndpoint<_i3.AuthMe>(
    'auth',
    'provisionar',
    {},
  );

  _i2.Future<_i3.AuthMe> me() => caller.callServerEndpoint<_i3.AuthMe>(
    'auth',
    'me',
    {},
  );
}

/// {@category Endpoint}
class EndpointDemanda extends _i1.EndpointRef {
  EndpointDemanda(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'demanda';

  _i2.Future<_i4.Demanda> alterarStatusDemanda(
    int id,
    _i5.DemandaStatus status, {
    String? motivoCancelamento,
  }) => caller.callServerEndpoint<_i4.Demanda>(
    'demanda',
    'alterarStatusDemanda',
    {
      'id': id,
      'status': status,
      'motivoCancelamento': motivoCancelamento,
    },
  );

  _i2.Future<_i4.Demanda> concluirDemandaEmCascata(int id) =>
      caller.callServerEndpoint<_i4.Demanda>(
        'demanda',
        'concluirDemandaEmCascata',
        {'id': id},
      );

  _i2.Future<_i4.Demanda> cancelarDemandaEmCascata(
    int id,
    String motivoCancelamento,
  ) => caller.callServerEndpoint<_i4.Demanda>(
    'demanda',
    'cancelarDemandaEmCascata',
    {
      'id': id,
      'motivoCancelamento': motivoCancelamento,
    },
  );

  _i2.Future<_i4.Demanda> moverDemanda(
    _i6.DemandaMovimentacaoRequest request,
  ) => caller.callServerEndpoint<_i4.Demanda>(
    'demanda',
    'moverDemanda',
    {'request': request},
  );

  _i2.Future<_i4.Demanda> criarDemanda(_i7.DemandaCreateRequest request) =>
      caller.callServerEndpoint<_i4.Demanda>(
        'demanda',
        'criarDemanda',
        {'request': request},
      );

  _i2.Future<List<_i4.Demanda>> listarDemandas() =>
      caller.callServerEndpoint<List<_i4.Demanda>>(
        'demanda',
        'listarDemandas',
        {},
      );

  _i2.Future<_i4.Demanda?> buscarDemandaPorId(int id) =>
      caller.callServerEndpoint<_i4.Demanda?>(
        'demanda',
        'buscarDemandaPorId',
        {'id': id},
      );

  _i2.Future<_i4.Demanda> atualizarDemanda(_i8.DemandaUpdateRequest request) =>
      caller.callServerEndpoint<_i4.Demanda>(
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
  _i2.Future<_i9.Greeting> hello(String name) =>
      caller.callServerEndpoint<_i9.Greeting>(
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

  _i2.Future<_i10.RegistroTempo> registrarTempo(
    _i11.RegistroTempoCreateRequest request,
  ) => caller.callServerEndpoint<_i10.RegistroTempo>(
    'registroTempo',
    'registrarTempo',
    {'request': request},
  );

  _i2.Future<_i10.RegistroTempo> editarRegistroTempo(
    _i12.RegistroTempoUpdateRequest request,
  ) => caller.callServerEndpoint<_i10.RegistroTempo>(
    'registroTempo',
    'editarRegistroTempo',
    {'request': request},
  );

  _i2.Future<List<_i10.RegistroTempo>> listarRegistrosTempoPorPeriodo(
    DateTime inicio,
    DateTime fim,
  ) => caller.callServerEndpoint<List<_i10.RegistroTempo>>(
    'registroTempo',
    'listarRegistrosTempoPorPeriodo',
    {
      'inicio': inicio,
      'fim': fim,
    },
  );

  _i2.Future<List<_i10.RegistroTempo>> listarRegistrosTempoDaDemanda(
    int demandaId,
  ) => caller.callServerEndpoint<List<_i10.RegistroTempo>>(
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

/// {@category Endpoint}
class EndpointRelatorio extends _i1.EndpointRef {
  EndpointRelatorio(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'relatorio';

  _i2.Future<_i13.RelatorioDemandasResponse> gerarRelatorioDemandas(
    _i14.RelatorioDemandaRequest request,
  ) => caller.callServerEndpoint<_i13.RelatorioDemandasResponse>(
    'relatorio',
    'gerarRelatorioDemandas',
    {'request': request},
  );
}

/// {@category Endpoint}
class EndpointSprint extends _i1.EndpointRef {
  EndpointSprint(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'sprint';

  _i2.Future<List<_i15.Sprint>> listarSprints() =>
      caller.callServerEndpoint<List<_i15.Sprint>>(
        'sprint',
        'listarSprints',
        {},
      );

  _i2.Future<_i15.Sprint> buscarSprintPorId(int id) =>
      caller.callServerEndpoint<_i15.Sprint>(
        'sprint',
        'buscarSprintPorId',
        {'id': id},
      );

  _i2.Future<List<_i16.SprintDemanda>> listarDemandasDaSprint(int sprintId) =>
      caller.callServerEndpoint<List<_i16.SprintDemanda>>(
        'sprint',
        'listarDemandasDaSprint',
        {'sprintId': sprintId},
      );

  _i2.Future<_i15.Sprint> criarSprint(_i17.SprintCreateRequest request) =>
      caller.callServerEndpoint<_i15.Sprint>(
        'sprint',
        'criarSprint',
        {'request': request},
      );

  _i2.Future<_i15.Sprint> atualizarSprint(_i18.SprintUpdateRequest request) =>
      caller.callServerEndpoint<_i15.Sprint>(
        'sprint',
        'atualizarSprint',
        {'request': request},
      );

  _i2.Future<_i15.Sprint> ativarSprint(int id) =>
      caller.callServerEndpoint<_i15.Sprint>(
        'sprint',
        'ativarSprint',
        {'id': id},
      );

  _i2.Future<_i15.Sprint> cancelarSprint(int id) =>
      caller.callServerEndpoint<_i15.Sprint>(
        'sprint',
        'cancelarSprint',
        {'id': id},
      );

  _i2.Future<_i19.SprintConclusaoResponse> concluirSprint(int id) =>
      caller.callServerEndpoint<_i19.SprintConclusaoResponse>(
        'sprint',
        'concluirSprint',
        {'id': id},
      );

  _i2.Future<_i19.SprintConclusaoResponse> obterResumoConclusaoSprint(int id) =>
      caller.callServerEndpoint<_i19.SprintConclusaoResponse>(
        'sprint',
        'obterResumoConclusaoSprint',
        {'id': id},
      );

  _i2.Future<_i20.SprintIndicadores> calcularIndicadoresSprint(int id) =>
      caller.callServerEndpoint<_i20.SprintIndicadores>(
        'sprint',
        'calcularIndicadoresSprint',
        {'id': id},
      );

  _i2.Future<bool> excluirSprint(int id) => caller.callServerEndpoint<bool>(
    'sprint',
    'excluirSprint',
    {'id': id},
  );

  _i2.Future<_i15.Sprint> reabrirSprint(int id) =>
      caller.callServerEndpoint<_i15.Sprint>(
        'sprint',
        'reabrirSprint',
        {'id': id},
      );

  _i2.Future<List<_i16.SprintDemanda>> vincularDemanda(
    int sprintId,
    int demandaId,
  ) => caller.callServerEndpoint<List<_i16.SprintDemanda>>(
    'sprint',
    'vincularDemanda',
    {
      'sprintId': sprintId,
      'demandaId': demandaId,
    },
  );

  /// Vincula várias Demandas como uma única operação atômica.
  ///
  /// A propagação da árvore, os locks e as validações continuam
  /// concentrados no serviço. Qualquer falha aborta a transação inteira.
  _i2.Future<List<_i16.SprintDemanda>> vincularDemandas(
    int sprintId,
    List<int> demandaIds,
  ) => caller.callServerEndpoint<List<_i16.SprintDemanda>>(
    'sprint',
    'vincularDemandas',
    {
      'sprintId': sprintId,
      'demandaIds': demandaIds,
    },
  );

  _i2.Future<bool> desvincularDemanda(
    int sprintId,
    int demandaId,
  ) => caller.callServerEndpoint<bool>(
    'sprint',
    'desvincularDemanda',
    {
      'sprintId': sprintId,
      'demandaId': demandaId,
    },
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
         _i21.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
       ) {
    convite = EndpointConvite(this);
    auth = EndpointAuth(this);
    demanda = EndpointDemanda(this);
    greeting = EndpointGreeting(this);
    registroTempo = EndpointRegistroTempo(this);
    relatorio = EndpointRelatorio(this);
    sprint = EndpointSprint(this);
  }

  late final EndpointConvite convite;

  late final EndpointAuth auth;

  late final EndpointDemanda demanda;

  late final EndpointGreeting greeting;

  late final EndpointRegistroTempo registroTempo;

  late final EndpointRelatorio relatorio;

  late final EndpointSprint sprint;

  @override
  Map<String, _i1.EndpointRef> get endpointRefLookup => {
    'convite': convite,
    'auth': auth,
    'demanda': demanda,
    'greeting': greeting,
    'registroTempo': registroTempo,
    'relatorio': relatorio,
    'sprint': sprint,
  };

  @override
  Map<String, _i1.ModuleEndpointCaller> get moduleLookup => {};
}
