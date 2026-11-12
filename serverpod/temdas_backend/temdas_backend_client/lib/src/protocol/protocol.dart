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
import 'admin/convite_exception.dart' as _i2;
import 'anotacoes/anotacao_demanda.dart' as _i3;
import 'auth/auth_exception.dart' as _i4;
import 'auth/auth_me.dart' as _i5;
import 'demandas/backlog_previa.dart' as _i6;
import 'demandas/demanda.dart' as _i7;
import 'demandas/demanda_create_request.dart' as _i8;
import 'demandas/demanda_localizacao.dart' as _i9;
import 'demandas/demanda_movimentacao_request.dart' as _i10;
import 'demandas/demanda_status.dart' as _i11;
import 'demandas/demanda_update_request.dart' as _i12;
import 'demandas/movimentacao_demanda_erro_codigo.dart' as _i13;
import 'demandas/movimentacao_demanda_exception.dart' as _i14;
import 'demandas/prioridade.dart' as _i15;
import 'demandas/transicao_status_erro_codigo.dart' as _i16;
import 'demandas/transicao_status_exception.dart' as _i17;
import 'greetings/greeting.dart' as _i18;
import 'registros_tempo/conflito_horario_exception.dart' as _i19;
import 'registros_tempo/registro_tempo.dart' as _i20;
import 'registros_tempo/registro_tempo_create_request.dart' as _i21;
import 'registros_tempo/registro_tempo_exception.dart' as _i22;
import 'registros_tempo/registro_tempo_observacao.dart' as _i23;
import 'registros_tempo/registro_tempo_update_request.dart' as _i24;
import 'relatorios/relatorio_demanda_item.dart' as _i25;
import 'relatorios/relatorio_demanda_request.dart' as _i26;
import 'relatorios/relatorio_demandas_response.dart' as _i27;
import 'sprints/sprint.dart' as _i28;
import 'sprints/sprint_conclusao_response.dart' as _i29;
import 'sprints/sprint_contexto_demandas.dart' as _i30;
import 'sprints/sprint_create_request.dart' as _i31;
import 'sprints/sprint_demanda.dart' as _i32;
import 'sprints/sprint_erro_codigo.dart' as _i33;
import 'sprints/sprint_exception.dart' as _i34;
import 'sprints/sprint_indicadores.dart' as _i35;
import 'sprints/sprint_status.dart' as _i36;
import 'sprints/sprint_update_request.dart' as _i37;
import 'todos/todo.dart' as _i38;
import 'todos/todo_linha.dart' as _i39;
import 'todos/todo_tipo_linha.dart' as _i40;
import 'usuarios/email_whitelist.dart' as _i41;
import 'usuarios/usuario.dart' as _i42;
import 'package:temdas_backend_client/src/protocol/anotacoes/anotacao_demanda.dart'
    as _i43;
import 'package:temdas_backend_client/src/protocol/demandas/demanda.dart'
    as _i44;
import 'package:temdas_backend_client/src/protocol/registros_tempo/registro_tempo.dart'
    as _i45;
import 'package:temdas_backend_client/src/protocol/sprints/sprint.dart' as _i46;
import 'package:temdas_backend_client/src/protocol/sprints/sprint_demanda.dart'
    as _i47;
import 'package:temdas_backend_client/src/protocol/todos/todo.dart' as _i48;
import 'package:temdas_backend_client/src/protocol/todos/todo_linha.dart'
    as _i49;
export 'admin/convite_exception.dart';
export 'anotacoes/anotacao_demanda.dart';
export 'auth/auth_exception.dart';
export 'auth/auth_me.dart';
export 'demandas/backlog_previa.dart';
export 'demandas/demanda.dart';
export 'demandas/demanda_create_request.dart';
export 'demandas/demanda_localizacao.dart';
export 'demandas/demanda_movimentacao_request.dart';
export 'demandas/demanda_status.dart';
export 'demandas/demanda_update_request.dart';
export 'demandas/movimentacao_demanda_erro_codigo.dart';
export 'demandas/movimentacao_demanda_exception.dart';
export 'demandas/prioridade.dart';
export 'demandas/transicao_status_erro_codigo.dart';
export 'demandas/transicao_status_exception.dart';
export 'greetings/greeting.dart';
export 'registros_tempo/conflito_horario_exception.dart';
export 'registros_tempo/registro_tempo.dart';
export 'registros_tempo/registro_tempo_create_request.dart';
export 'registros_tempo/registro_tempo_exception.dart';
export 'registros_tempo/registro_tempo_observacao.dart';
export 'registros_tempo/registro_tempo_update_request.dart';
export 'relatorios/relatorio_demanda_item.dart';
export 'relatorios/relatorio_demanda_request.dart';
export 'relatorios/relatorio_demandas_response.dart';
export 'sprints/sprint.dart';
export 'sprints/sprint_conclusao_response.dart';
export 'sprints/sprint_contexto_demandas.dart';
export 'sprints/sprint_create_request.dart';
export 'sprints/sprint_demanda.dart';
export 'sprints/sprint_erro_codigo.dart';
export 'sprints/sprint_exception.dart';
export 'sprints/sprint_indicadores.dart';
export 'sprints/sprint_status.dart';
export 'sprints/sprint_update_request.dart';
export 'todos/todo.dart';
export 'todos/todo_linha.dart';
export 'todos/todo_tipo_linha.dart';
export 'usuarios/email_whitelist.dart';
export 'usuarios/usuario.dart';
export 'client.dart';

class Protocol extends _i1.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on FormatException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i2.ConviteException) {
      return _i2.ConviteException.fromJson(data) as T;
    }
    if (t == _i3.AnotacaoDemanda) {
      return _i3.AnotacaoDemanda.fromJson(data) as T;
    }
    if (t == _i4.AuthException) {
      return _i4.AuthException.fromJson(data) as T;
    }
    if (t == _i5.AuthMe) {
      return _i5.AuthMe.fromJson(data) as T;
    }
    if (t == _i6.BacklogPrevia) {
      return _i6.BacklogPrevia.fromJson(data) as T;
    }
    if (t == _i7.Demanda) {
      return _i7.Demanda.fromJson(data) as T;
    }
    if (t == _i8.DemandaCreateRequest) {
      return _i8.DemandaCreateRequest.fromJson(data) as T;
    }
    if (t == _i9.DemandaLocalizacao) {
      return _i9.DemandaLocalizacao.fromJson(data) as T;
    }
    if (t == _i10.DemandaMovimentacaoRequest) {
      return _i10.DemandaMovimentacaoRequest.fromJson(data) as T;
    }
    if (t == _i11.DemandaStatus) {
      return _i11.DemandaStatus.fromJson(data) as T;
    }
    if (t == _i12.DemandaUpdateRequest) {
      return _i12.DemandaUpdateRequest.fromJson(data) as T;
    }
    if (t == _i13.MovimentacaoDemandaErroCodigo) {
      return _i13.MovimentacaoDemandaErroCodigo.fromJson(data) as T;
    }
    if (t == _i14.MovimentacaoDemandaException) {
      return _i14.MovimentacaoDemandaException.fromJson(data) as T;
    }
    if (t == _i15.Prioridade) {
      return _i15.Prioridade.fromJson(data) as T;
    }
    if (t == _i16.TransicaoStatusErroCodigo) {
      return _i16.TransicaoStatusErroCodigo.fromJson(data) as T;
    }
    if (t == _i17.TransicaoStatusException) {
      return _i17.TransicaoStatusException.fromJson(data) as T;
    }
    if (t == _i18.Greeting) {
      return _i18.Greeting.fromJson(data) as T;
    }
    if (t == _i19.ConflitoHorarioException) {
      return _i19.ConflitoHorarioException.fromJson(data) as T;
    }
    if (t == _i20.RegistroTempo) {
      return _i20.RegistroTempo.fromJson(data) as T;
    }
    if (t == _i21.RegistroTempoCreateRequest) {
      return _i21.RegistroTempoCreateRequest.fromJson(data) as T;
    }
    if (t == _i22.RegistroTempoException) {
      return _i22.RegistroTempoException.fromJson(data) as T;
    }
    if (t == _i23.RegistroTempoObservacao) {
      return _i23.RegistroTempoObservacao.fromJson(data) as T;
    }
    if (t == _i24.RegistroTempoUpdateRequest) {
      return _i24.RegistroTempoUpdateRequest.fromJson(data) as T;
    }
    if (t == _i25.RelatorioDemandaItem) {
      return _i25.RelatorioDemandaItem.fromJson(data) as T;
    }
    if (t == _i26.RelatorioDemandaRequest) {
      return _i26.RelatorioDemandaRequest.fromJson(data) as T;
    }
    if (t == _i27.RelatorioDemandasResponse) {
      return _i27.RelatorioDemandasResponse.fromJson(data) as T;
    }
    if (t == _i28.Sprint) {
      return _i28.Sprint.fromJson(data) as T;
    }
    if (t == _i29.SprintConclusaoResponse) {
      return _i29.SprintConclusaoResponse.fromJson(data) as T;
    }
    if (t == _i30.SprintContextoDemandas) {
      return _i30.SprintContextoDemandas.fromJson(data) as T;
    }
    if (t == _i31.SprintCreateRequest) {
      return _i31.SprintCreateRequest.fromJson(data) as T;
    }
    if (t == _i32.SprintDemanda) {
      return _i32.SprintDemanda.fromJson(data) as T;
    }
    if (t == _i33.SprintErroCodigo) {
      return _i33.SprintErroCodigo.fromJson(data) as T;
    }
    if (t == _i34.SprintException) {
      return _i34.SprintException.fromJson(data) as T;
    }
    if (t == _i35.SprintIndicadores) {
      return _i35.SprintIndicadores.fromJson(data) as T;
    }
    if (t == _i36.SprintStatus) {
      return _i36.SprintStatus.fromJson(data) as T;
    }
    if (t == _i37.SprintUpdateRequest) {
      return _i37.SprintUpdateRequest.fromJson(data) as T;
    }
    if (t == _i38.Todo) {
      return _i38.Todo.fromJson(data) as T;
    }
    if (t == _i39.TodoLinha) {
      return _i39.TodoLinha.fromJson(data) as T;
    }
    if (t == _i40.TodoTipoLinha) {
      return _i40.TodoTipoLinha.fromJson(data) as T;
    }
    if (t == _i41.EmailWhitelist) {
      return _i41.EmailWhitelist.fromJson(data) as T;
    }
    if (t == _i42.Usuario) {
      return _i42.Usuario.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.ConviteException?>()) {
      return (data != null ? _i2.ConviteException.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.AnotacaoDemanda?>()) {
      return (data != null ? _i3.AnotacaoDemanda.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.AuthException?>()) {
      return (data != null ? _i4.AuthException.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.AuthMe?>()) {
      return (data != null ? _i5.AuthMe.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.BacklogPrevia?>()) {
      return (data != null ? _i6.BacklogPrevia.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.Demanda?>()) {
      return (data != null ? _i7.Demanda.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.DemandaCreateRequest?>()) {
      return (data != null ? _i8.DemandaCreateRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i9.DemandaLocalizacao?>()) {
      return (data != null ? _i9.DemandaLocalizacao.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.DemandaMovimentacaoRequest?>()) {
      return (data != null
              ? _i10.DemandaMovimentacaoRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i11.DemandaStatus?>()) {
      return (data != null ? _i11.DemandaStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.DemandaUpdateRequest?>()) {
      return (data != null ? _i12.DemandaUpdateRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i13.MovimentacaoDemandaErroCodigo?>()) {
      return (data != null
              ? _i13.MovimentacaoDemandaErroCodigo.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i14.MovimentacaoDemandaException?>()) {
      return (data != null
              ? _i14.MovimentacaoDemandaException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i15.Prioridade?>()) {
      return (data != null ? _i15.Prioridade.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i16.TransicaoStatusErroCodigo?>()) {
      return (data != null
              ? _i16.TransicaoStatusErroCodigo.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i17.TransicaoStatusException?>()) {
      return (data != null
              ? _i17.TransicaoStatusException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i18.Greeting?>()) {
      return (data != null ? _i18.Greeting.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i19.ConflitoHorarioException?>()) {
      return (data != null
              ? _i19.ConflitoHorarioException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i20.RegistroTempo?>()) {
      return (data != null ? _i20.RegistroTempo.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i21.RegistroTempoCreateRequest?>()) {
      return (data != null
              ? _i21.RegistroTempoCreateRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i22.RegistroTempoException?>()) {
      return (data != null ? _i22.RegistroTempoException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i23.RegistroTempoObservacao?>()) {
      return (data != null ? _i23.RegistroTempoObservacao.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i24.RegistroTempoUpdateRequest?>()) {
      return (data != null
              ? _i24.RegistroTempoUpdateRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i25.RelatorioDemandaItem?>()) {
      return (data != null ? _i25.RelatorioDemandaItem.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i26.RelatorioDemandaRequest?>()) {
      return (data != null ? _i26.RelatorioDemandaRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i27.RelatorioDemandasResponse?>()) {
      return (data != null
              ? _i27.RelatorioDemandasResponse.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i28.Sprint?>()) {
      return (data != null ? _i28.Sprint.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i29.SprintConclusaoResponse?>()) {
      return (data != null ? _i29.SprintConclusaoResponse.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i30.SprintContextoDemandas?>()) {
      return (data != null ? _i30.SprintContextoDemandas.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i31.SprintCreateRequest?>()) {
      return (data != null ? _i31.SprintCreateRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i32.SprintDemanda?>()) {
      return (data != null ? _i32.SprintDemanda.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i33.SprintErroCodigo?>()) {
      return (data != null ? _i33.SprintErroCodigo.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i34.SprintException?>()) {
      return (data != null ? _i34.SprintException.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i35.SprintIndicadores?>()) {
      return (data != null ? _i35.SprintIndicadores.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i36.SprintStatus?>()) {
      return (data != null ? _i36.SprintStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i37.SprintUpdateRequest?>()) {
      return (data != null ? _i37.SprintUpdateRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i38.Todo?>()) {
      return (data != null ? _i38.Todo.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i39.TodoLinha?>()) {
      return (data != null ? _i39.TodoLinha.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i40.TodoTipoLinha?>()) {
      return (data != null ? _i40.TodoTipoLinha.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i41.EmailWhitelist?>()) {
      return (data != null ? _i41.EmailWhitelist.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i42.Usuario?>()) {
      return (data != null ? _i42.Usuario.fromJson(data) : null) as T;
    }
    if (t == List<_i28.Sprint>) {
      return (data as List).map((e) => deserialize<_i28.Sprint>(e)).toList()
          as T;
    }
    if (t == List<_i32.SprintDemanda>) {
      return (data as List)
              .map((e) => deserialize<_i32.SprintDemanda>(e))
              .toList()
          as T;
    }
    if (t == List<_i23.RegistroTempoObservacao>) {
      return (data as List)
              .map((e) => deserialize<_i23.RegistroTempoObservacao>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i23.RegistroTempoObservacao>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i23.RegistroTempoObservacao>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i25.RelatorioDemandaItem>) {
      return (data as List)
              .map((e) => deserialize<_i25.RelatorioDemandaItem>(e))
              .toList()
          as T;
    }
    if (t == List<_i39.TodoLinha>) {
      return (data as List).map((e) => deserialize<_i39.TodoLinha>(e)).toList()
          as T;
    }
    if (t == _i1.getType<List<_i39.TodoLinha>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i39.TodoLinha>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i43.AnotacaoDemanda>) {
      return (data as List)
              .map((e) => deserialize<_i43.AnotacaoDemanda>(e))
              .toList()
          as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    if (t == List<_i44.Demanda>) {
      return (data as List).map((e) => deserialize<_i44.Demanda>(e)).toList()
          as T;
    }
    if (t == List<_i45.RegistroTempo>) {
      return (data as List)
              .map((e) => deserialize<_i45.RegistroTempo>(e))
              .toList()
          as T;
    }
    if (t == List<_i46.Sprint>) {
      return (data as List).map((e) => deserialize<_i46.Sprint>(e)).toList()
          as T;
    }
    if (t == List<_i47.SprintDemanda>) {
      return (data as List)
              .map((e) => deserialize<_i47.SprintDemanda>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<int>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<int>(e)).toList()
              : null)
          as T;
    }
    if (t == List<_i48.Todo>) {
      return (data as List).map((e) => deserialize<_i48.Todo>(e)).toList() as T;
    }
    if (t == List<_i49.TodoLinha>) {
      return (data as List).map((e) => deserialize<_i49.TodoLinha>(e)).toList()
          as T;
    }
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.ConviteException => 'ConviteException',
      _i3.AnotacaoDemanda => 'AnotacaoDemanda',
      _i4.AuthException => 'AuthException',
      _i5.AuthMe => 'AuthMe',
      _i6.BacklogPrevia => 'BacklogPrevia',
      _i7.Demanda => 'Demanda',
      _i8.DemandaCreateRequest => 'DemandaCreateRequest',
      _i9.DemandaLocalizacao => 'DemandaLocalizacao',
      _i10.DemandaMovimentacaoRequest => 'DemandaMovimentacaoRequest',
      _i11.DemandaStatus => 'DemandaStatus',
      _i12.DemandaUpdateRequest => 'DemandaUpdateRequest',
      _i13.MovimentacaoDemandaErroCodigo => 'MovimentacaoDemandaErroCodigo',
      _i14.MovimentacaoDemandaException => 'MovimentacaoDemandaException',
      _i15.Prioridade => 'Prioridade',
      _i16.TransicaoStatusErroCodigo => 'TransicaoStatusErroCodigo',
      _i17.TransicaoStatusException => 'TransicaoStatusException',
      _i18.Greeting => 'Greeting',
      _i19.ConflitoHorarioException => 'ConflitoHorarioException',
      _i20.RegistroTempo => 'RegistroTempo',
      _i21.RegistroTempoCreateRequest => 'RegistroTempoCreateRequest',
      _i22.RegistroTempoException => 'RegistroTempoException',
      _i23.RegistroTempoObservacao => 'RegistroTempoObservacao',
      _i24.RegistroTempoUpdateRequest => 'RegistroTempoUpdateRequest',
      _i25.RelatorioDemandaItem => 'RelatorioDemandaItem',
      _i26.RelatorioDemandaRequest => 'RelatorioDemandaRequest',
      _i27.RelatorioDemandasResponse => 'RelatorioDemandasResponse',
      _i28.Sprint => 'Sprint',
      _i29.SprintConclusaoResponse => 'SprintConclusaoResponse',
      _i30.SprintContextoDemandas => 'SprintContextoDemandas',
      _i31.SprintCreateRequest => 'SprintCreateRequest',
      _i32.SprintDemanda => 'SprintDemanda',
      _i33.SprintErroCodigo => 'SprintErroCodigo',
      _i34.SprintException => 'SprintException',
      _i35.SprintIndicadores => 'SprintIndicadores',
      _i36.SprintStatus => 'SprintStatus',
      _i37.SprintUpdateRequest => 'SprintUpdateRequest',
      _i38.Todo => 'Todo',
      _i39.TodoLinha => 'TodoLinha',
      _i40.TodoTipoLinha => 'TodoTipoLinha',
      _i41.EmailWhitelist => 'EmailWhitelist',
      _i42.Usuario => 'Usuario',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst(
        'temdas_backend.',
        '',
      );
    }

    switch (data) {
      case _i2.ConviteException():
        return 'ConviteException';
      case _i3.AnotacaoDemanda():
        return 'AnotacaoDemanda';
      case _i4.AuthException():
        return 'AuthException';
      case _i5.AuthMe():
        return 'AuthMe';
      case _i6.BacklogPrevia():
        return 'BacklogPrevia';
      case _i7.Demanda():
        return 'Demanda';
      case _i8.DemandaCreateRequest():
        return 'DemandaCreateRequest';
      case _i9.DemandaLocalizacao():
        return 'DemandaLocalizacao';
      case _i10.DemandaMovimentacaoRequest():
        return 'DemandaMovimentacaoRequest';
      case _i11.DemandaStatus():
        return 'DemandaStatus';
      case _i12.DemandaUpdateRequest():
        return 'DemandaUpdateRequest';
      case _i13.MovimentacaoDemandaErroCodigo():
        return 'MovimentacaoDemandaErroCodigo';
      case _i14.MovimentacaoDemandaException():
        return 'MovimentacaoDemandaException';
      case _i15.Prioridade():
        return 'Prioridade';
      case _i16.TransicaoStatusErroCodigo():
        return 'TransicaoStatusErroCodigo';
      case _i17.TransicaoStatusException():
        return 'TransicaoStatusException';
      case _i18.Greeting():
        return 'Greeting';
      case _i19.ConflitoHorarioException():
        return 'ConflitoHorarioException';
      case _i20.RegistroTempo():
        return 'RegistroTempo';
      case _i21.RegistroTempoCreateRequest():
        return 'RegistroTempoCreateRequest';
      case _i22.RegistroTempoException():
        return 'RegistroTempoException';
      case _i23.RegistroTempoObservacao():
        return 'RegistroTempoObservacao';
      case _i24.RegistroTempoUpdateRequest():
        return 'RegistroTempoUpdateRequest';
      case _i25.RelatorioDemandaItem():
        return 'RelatorioDemandaItem';
      case _i26.RelatorioDemandaRequest():
        return 'RelatorioDemandaRequest';
      case _i27.RelatorioDemandasResponse():
        return 'RelatorioDemandasResponse';
      case _i28.Sprint():
        return 'Sprint';
      case _i29.SprintConclusaoResponse():
        return 'SprintConclusaoResponse';
      case _i30.SprintContextoDemandas():
        return 'SprintContextoDemandas';
      case _i31.SprintCreateRequest():
        return 'SprintCreateRequest';
      case _i32.SprintDemanda():
        return 'SprintDemanda';
      case _i33.SprintErroCodigo():
        return 'SprintErroCodigo';
      case _i34.SprintException():
        return 'SprintException';
      case _i35.SprintIndicadores():
        return 'SprintIndicadores';
      case _i36.SprintStatus():
        return 'SprintStatus';
      case _i37.SprintUpdateRequest():
        return 'SprintUpdateRequest';
      case _i38.Todo():
        return 'Todo';
      case _i39.TodoLinha():
        return 'TodoLinha';
      case _i40.TodoTipoLinha():
        return 'TodoTipoLinha';
      case _i41.EmailWhitelist():
        return 'EmailWhitelist';
      case _i42.Usuario():
        return 'Usuario';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'ConviteException') {
      return deserialize<_i2.ConviteException>(data['data']);
    }
    if (dataClassName == 'AnotacaoDemanda') {
      return deserialize<_i3.AnotacaoDemanda>(data['data']);
    }
    if (dataClassName == 'AuthException') {
      return deserialize<_i4.AuthException>(data['data']);
    }
    if (dataClassName == 'AuthMe') {
      return deserialize<_i5.AuthMe>(data['data']);
    }
    if (dataClassName == 'BacklogPrevia') {
      return deserialize<_i6.BacklogPrevia>(data['data']);
    }
    if (dataClassName == 'Demanda') {
      return deserialize<_i7.Demanda>(data['data']);
    }
    if (dataClassName == 'DemandaCreateRequest') {
      return deserialize<_i8.DemandaCreateRequest>(data['data']);
    }
    if (dataClassName == 'DemandaLocalizacao') {
      return deserialize<_i9.DemandaLocalizacao>(data['data']);
    }
    if (dataClassName == 'DemandaMovimentacaoRequest') {
      return deserialize<_i10.DemandaMovimentacaoRequest>(data['data']);
    }
    if (dataClassName == 'DemandaStatus') {
      return deserialize<_i11.DemandaStatus>(data['data']);
    }
    if (dataClassName == 'DemandaUpdateRequest') {
      return deserialize<_i12.DemandaUpdateRequest>(data['data']);
    }
    if (dataClassName == 'MovimentacaoDemandaErroCodigo') {
      return deserialize<_i13.MovimentacaoDemandaErroCodigo>(data['data']);
    }
    if (dataClassName == 'MovimentacaoDemandaException') {
      return deserialize<_i14.MovimentacaoDemandaException>(data['data']);
    }
    if (dataClassName == 'Prioridade') {
      return deserialize<_i15.Prioridade>(data['data']);
    }
    if (dataClassName == 'TransicaoStatusErroCodigo') {
      return deserialize<_i16.TransicaoStatusErroCodigo>(data['data']);
    }
    if (dataClassName == 'TransicaoStatusException') {
      return deserialize<_i17.TransicaoStatusException>(data['data']);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_i18.Greeting>(data['data']);
    }
    if (dataClassName == 'ConflitoHorarioException') {
      return deserialize<_i19.ConflitoHorarioException>(data['data']);
    }
    if (dataClassName == 'RegistroTempo') {
      return deserialize<_i20.RegistroTempo>(data['data']);
    }
    if (dataClassName == 'RegistroTempoCreateRequest') {
      return deserialize<_i21.RegistroTempoCreateRequest>(data['data']);
    }
    if (dataClassName == 'RegistroTempoException') {
      return deserialize<_i22.RegistroTempoException>(data['data']);
    }
    if (dataClassName == 'RegistroTempoObservacao') {
      return deserialize<_i23.RegistroTempoObservacao>(data['data']);
    }
    if (dataClassName == 'RegistroTempoUpdateRequest') {
      return deserialize<_i24.RegistroTempoUpdateRequest>(data['data']);
    }
    if (dataClassName == 'RelatorioDemandaItem') {
      return deserialize<_i25.RelatorioDemandaItem>(data['data']);
    }
    if (dataClassName == 'RelatorioDemandaRequest') {
      return deserialize<_i26.RelatorioDemandaRequest>(data['data']);
    }
    if (dataClassName == 'RelatorioDemandasResponse') {
      return deserialize<_i27.RelatorioDemandasResponse>(data['data']);
    }
    if (dataClassName == 'Sprint') {
      return deserialize<_i28.Sprint>(data['data']);
    }
    if (dataClassName == 'SprintConclusaoResponse') {
      return deserialize<_i29.SprintConclusaoResponse>(data['data']);
    }
    if (dataClassName == 'SprintContextoDemandas') {
      return deserialize<_i30.SprintContextoDemandas>(data['data']);
    }
    if (dataClassName == 'SprintCreateRequest') {
      return deserialize<_i31.SprintCreateRequest>(data['data']);
    }
    if (dataClassName == 'SprintDemanda') {
      return deserialize<_i32.SprintDemanda>(data['data']);
    }
    if (dataClassName == 'SprintErroCodigo') {
      return deserialize<_i33.SprintErroCodigo>(data['data']);
    }
    if (dataClassName == 'SprintException') {
      return deserialize<_i34.SprintException>(data['data']);
    }
    if (dataClassName == 'SprintIndicadores') {
      return deserialize<_i35.SprintIndicadores>(data['data']);
    }
    if (dataClassName == 'SprintStatus') {
      return deserialize<_i36.SprintStatus>(data['data']);
    }
    if (dataClassName == 'SprintUpdateRequest') {
      return deserialize<_i37.SprintUpdateRequest>(data['data']);
    }
    if (dataClassName == 'Todo') {
      return deserialize<_i38.Todo>(data['data']);
    }
    if (dataClassName == 'TodoLinha') {
      return deserialize<_i39.TodoLinha>(data['data']);
    }
    if (dataClassName == 'TodoTipoLinha') {
      return deserialize<_i40.TodoTipoLinha>(data['data']);
    }
    if (dataClassName == 'EmailWhitelist') {
      return deserialize<_i41.EmailWhitelist>(data['data']);
    }
    if (dataClassName == 'Usuario') {
      return deserialize<_i42.Usuario>(data['data']);
    }
    return super.deserializeByClassName(data);
  }

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
