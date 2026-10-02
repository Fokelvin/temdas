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
import 'demandas/demanda.dart' as _i2;
import 'demandas/demanda_create_request.dart' as _i3;
import 'demandas/demanda_movimentacao_request.dart' as _i4;
import 'demandas/demanda_status.dart' as _i5;
import 'demandas/demanda_update_request.dart' as _i6;
import 'demandas/movimentacao_demanda_erro_codigo.dart' as _i7;
import 'demandas/movimentacao_demanda_exception.dart' as _i8;
import 'demandas/prioridade.dart' as _i9;
import 'demandas/transicao_status_erro_codigo.dart' as _i10;
import 'demandas/transicao_status_exception.dart' as _i11;
import 'greetings/greeting.dart' as _i12;
import 'registros_tempo/conflito_horario_exception.dart' as _i13;
import 'registros_tempo/registro_tempo.dart' as _i14;
import 'registros_tempo/registro_tempo_create_request.dart' as _i15;
import 'registros_tempo/registro_tempo_update_request.dart' as _i16;
import 'relatorios/relatorio_demanda_item.dart' as _i17;
import 'relatorios/relatorio_demanda_request.dart' as _i18;
import 'relatorios/relatorio_demandas_response.dart' as _i19;
import 'sprints/sprint.dart' as _i20;
import 'sprints/sprint_conclusao_response.dart' as _i21;
import 'sprints/sprint_create_request.dart' as _i22;
import 'sprints/sprint_demanda.dart' as _i23;
import 'sprints/sprint_erro_codigo.dart' as _i24;
import 'sprints/sprint_exception.dart' as _i25;
import 'sprints/sprint_indicadores.dart' as _i26;
import 'sprints/sprint_status.dart' as _i27;
import 'sprints/sprint_update_request.dart' as _i28;
import 'usuarios/email_whitelist.dart' as _i29;
import 'usuarios/usuario.dart' as _i30;
import 'package:temdas_backend_client/src/protocol/demandas/demanda.dart'
    as _i31;
import 'package:temdas_backend_client/src/protocol/registros_tempo/registro_tempo.dart'
    as _i32;
import 'package:temdas_backend_client/src/protocol/sprints/sprint.dart' as _i33;
import 'package:temdas_backend_client/src/protocol/sprints/sprint_demanda.dart'
    as _i34;
export 'demandas/demanda.dart';
export 'demandas/demanda_create_request.dart';
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
export 'registros_tempo/registro_tempo_update_request.dart';
export 'relatorios/relatorio_demanda_item.dart';
export 'relatorios/relatorio_demanda_request.dart';
export 'relatorios/relatorio_demandas_response.dart';
export 'sprints/sprint.dart';
export 'sprints/sprint_conclusao_response.dart';
export 'sprints/sprint_create_request.dart';
export 'sprints/sprint_demanda.dart';
export 'sprints/sprint_erro_codigo.dart';
export 'sprints/sprint_exception.dart';
export 'sprints/sprint_indicadores.dart';
export 'sprints/sprint_status.dart';
export 'sprints/sprint_update_request.dart';
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

    if (t == _i2.Demanda) {
      return _i2.Demanda.fromJson(data) as T;
    }
    if (t == _i3.DemandaCreateRequest) {
      return _i3.DemandaCreateRequest.fromJson(data) as T;
    }
    if (t == _i4.DemandaMovimentacaoRequest) {
      return _i4.DemandaMovimentacaoRequest.fromJson(data) as T;
    }
    if (t == _i5.DemandaStatus) {
      return _i5.DemandaStatus.fromJson(data) as T;
    }
    if (t == _i6.DemandaUpdateRequest) {
      return _i6.DemandaUpdateRequest.fromJson(data) as T;
    }
    if (t == _i7.MovimentacaoDemandaErroCodigo) {
      return _i7.MovimentacaoDemandaErroCodigo.fromJson(data) as T;
    }
    if (t == _i8.MovimentacaoDemandaException) {
      return _i8.MovimentacaoDemandaException.fromJson(data) as T;
    }
    if (t == _i9.Prioridade) {
      return _i9.Prioridade.fromJson(data) as T;
    }
    if (t == _i10.TransicaoStatusErroCodigo) {
      return _i10.TransicaoStatusErroCodigo.fromJson(data) as T;
    }
    if (t == _i11.TransicaoStatusException) {
      return _i11.TransicaoStatusException.fromJson(data) as T;
    }
    if (t == _i12.Greeting) {
      return _i12.Greeting.fromJson(data) as T;
    }
    if (t == _i13.ConflitoHorarioException) {
      return _i13.ConflitoHorarioException.fromJson(data) as T;
    }
    if (t == _i14.RegistroTempo) {
      return _i14.RegistroTempo.fromJson(data) as T;
    }
    if (t == _i15.RegistroTempoCreateRequest) {
      return _i15.RegistroTempoCreateRequest.fromJson(data) as T;
    }
    if (t == _i16.RegistroTempoUpdateRequest) {
      return _i16.RegistroTempoUpdateRequest.fromJson(data) as T;
    }
    if (t == _i17.RelatorioDemandaItem) {
      return _i17.RelatorioDemandaItem.fromJson(data) as T;
    }
    if (t == _i18.RelatorioDemandaRequest) {
      return _i18.RelatorioDemandaRequest.fromJson(data) as T;
    }
    if (t == _i19.RelatorioDemandasResponse) {
      return _i19.RelatorioDemandasResponse.fromJson(data) as T;
    }
    if (t == _i20.Sprint) {
      return _i20.Sprint.fromJson(data) as T;
    }
    if (t == _i21.SprintConclusaoResponse) {
      return _i21.SprintConclusaoResponse.fromJson(data) as T;
    }
    if (t == _i22.SprintCreateRequest) {
      return _i22.SprintCreateRequest.fromJson(data) as T;
    }
    if (t == _i23.SprintDemanda) {
      return _i23.SprintDemanda.fromJson(data) as T;
    }
    if (t == _i24.SprintErroCodigo) {
      return _i24.SprintErroCodigo.fromJson(data) as T;
    }
    if (t == _i25.SprintException) {
      return _i25.SprintException.fromJson(data) as T;
    }
    if (t == _i26.SprintIndicadores) {
      return _i26.SprintIndicadores.fromJson(data) as T;
    }
    if (t == _i27.SprintStatus) {
      return _i27.SprintStatus.fromJson(data) as T;
    }
    if (t == _i28.SprintUpdateRequest) {
      return _i28.SprintUpdateRequest.fromJson(data) as T;
    }
    if (t == _i29.EmailWhitelist) {
      return _i29.EmailWhitelist.fromJson(data) as T;
    }
    if (t == _i30.Usuario) {
      return _i30.Usuario.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.Demanda?>()) {
      return (data != null ? _i2.Demanda.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.DemandaCreateRequest?>()) {
      return (data != null ? _i3.DemandaCreateRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i4.DemandaMovimentacaoRequest?>()) {
      return (data != null
              ? _i4.DemandaMovimentacaoRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i5.DemandaStatus?>()) {
      return (data != null ? _i5.DemandaStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.DemandaUpdateRequest?>()) {
      return (data != null ? _i6.DemandaUpdateRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i7.MovimentacaoDemandaErroCodigo?>()) {
      return (data != null
              ? _i7.MovimentacaoDemandaErroCodigo.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i8.MovimentacaoDemandaException?>()) {
      return (data != null
              ? _i8.MovimentacaoDemandaException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i9.Prioridade?>()) {
      return (data != null ? _i9.Prioridade.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.TransicaoStatusErroCodigo?>()) {
      return (data != null
              ? _i10.TransicaoStatusErroCodigo.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i11.TransicaoStatusException?>()) {
      return (data != null
              ? _i11.TransicaoStatusException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i12.Greeting?>()) {
      return (data != null ? _i12.Greeting.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.ConflitoHorarioException?>()) {
      return (data != null
              ? _i13.ConflitoHorarioException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i14.RegistroTempo?>()) {
      return (data != null ? _i14.RegistroTempo.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.RegistroTempoCreateRequest?>()) {
      return (data != null
              ? _i15.RegistroTempoCreateRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i16.RegistroTempoUpdateRequest?>()) {
      return (data != null
              ? _i16.RegistroTempoUpdateRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i17.RelatorioDemandaItem?>()) {
      return (data != null ? _i17.RelatorioDemandaItem.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i18.RelatorioDemandaRequest?>()) {
      return (data != null ? _i18.RelatorioDemandaRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i19.RelatorioDemandasResponse?>()) {
      return (data != null
              ? _i19.RelatorioDemandasResponse.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i20.Sprint?>()) {
      return (data != null ? _i20.Sprint.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i21.SprintConclusaoResponse?>()) {
      return (data != null ? _i21.SprintConclusaoResponse.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i22.SprintCreateRequest?>()) {
      return (data != null ? _i22.SprintCreateRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i23.SprintDemanda?>()) {
      return (data != null ? _i23.SprintDemanda.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i24.SprintErroCodigo?>()) {
      return (data != null ? _i24.SprintErroCodigo.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i25.SprintException?>()) {
      return (data != null ? _i25.SprintException.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i26.SprintIndicadores?>()) {
      return (data != null ? _i26.SprintIndicadores.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i27.SprintStatus?>()) {
      return (data != null ? _i27.SprintStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i28.SprintUpdateRequest?>()) {
      return (data != null ? _i28.SprintUpdateRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i29.EmailWhitelist?>()) {
      return (data != null ? _i29.EmailWhitelist.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i30.Usuario?>()) {
      return (data != null ? _i30.Usuario.fromJson(data) : null) as T;
    }
    if (t == List<_i17.RelatorioDemandaItem>) {
      return (data as List)
              .map((e) => deserialize<_i17.RelatorioDemandaItem>(e))
              .toList()
          as T;
    }
    if (t == List<_i31.Demanda>) {
      return (data as List).map((e) => deserialize<_i31.Demanda>(e)).toList()
          as T;
    }
    if (t == List<_i32.RegistroTempo>) {
      return (data as List)
              .map((e) => deserialize<_i32.RegistroTempo>(e))
              .toList()
          as T;
    }
    if (t == List<_i33.Sprint>) {
      return (data as List).map((e) => deserialize<_i33.Sprint>(e)).toList()
          as T;
    }
    if (t == List<_i34.SprintDemanda>) {
      return (data as List)
              .map((e) => deserialize<_i34.SprintDemanda>(e))
              .toList()
          as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.Demanda => 'Demanda',
      _i3.DemandaCreateRequest => 'DemandaCreateRequest',
      _i4.DemandaMovimentacaoRequest => 'DemandaMovimentacaoRequest',
      _i5.DemandaStatus => 'DemandaStatus',
      _i6.DemandaUpdateRequest => 'DemandaUpdateRequest',
      _i7.MovimentacaoDemandaErroCodigo => 'MovimentacaoDemandaErroCodigo',
      _i8.MovimentacaoDemandaException => 'MovimentacaoDemandaException',
      _i9.Prioridade => 'Prioridade',
      _i10.TransicaoStatusErroCodigo => 'TransicaoStatusErroCodigo',
      _i11.TransicaoStatusException => 'TransicaoStatusException',
      _i12.Greeting => 'Greeting',
      _i13.ConflitoHorarioException => 'ConflitoHorarioException',
      _i14.RegistroTempo => 'RegistroTempo',
      _i15.RegistroTempoCreateRequest => 'RegistroTempoCreateRequest',
      _i16.RegistroTempoUpdateRequest => 'RegistroTempoUpdateRequest',
      _i17.RelatorioDemandaItem => 'RelatorioDemandaItem',
      _i18.RelatorioDemandaRequest => 'RelatorioDemandaRequest',
      _i19.RelatorioDemandasResponse => 'RelatorioDemandasResponse',
      _i20.Sprint => 'Sprint',
      _i21.SprintConclusaoResponse => 'SprintConclusaoResponse',
      _i22.SprintCreateRequest => 'SprintCreateRequest',
      _i23.SprintDemanda => 'SprintDemanda',
      _i24.SprintErroCodigo => 'SprintErroCodigo',
      _i25.SprintException => 'SprintException',
      _i26.SprintIndicadores => 'SprintIndicadores',
      _i27.SprintStatus => 'SprintStatus',
      _i28.SprintUpdateRequest => 'SprintUpdateRequest',
      _i29.EmailWhitelist => 'EmailWhitelist',
      _i30.Usuario => 'Usuario',
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
      case _i2.Demanda():
        return 'Demanda';
      case _i3.DemandaCreateRequest():
        return 'DemandaCreateRequest';
      case _i4.DemandaMovimentacaoRequest():
        return 'DemandaMovimentacaoRequest';
      case _i5.DemandaStatus():
        return 'DemandaStatus';
      case _i6.DemandaUpdateRequest():
        return 'DemandaUpdateRequest';
      case _i7.MovimentacaoDemandaErroCodigo():
        return 'MovimentacaoDemandaErroCodigo';
      case _i8.MovimentacaoDemandaException():
        return 'MovimentacaoDemandaException';
      case _i9.Prioridade():
        return 'Prioridade';
      case _i10.TransicaoStatusErroCodigo():
        return 'TransicaoStatusErroCodigo';
      case _i11.TransicaoStatusException():
        return 'TransicaoStatusException';
      case _i12.Greeting():
        return 'Greeting';
      case _i13.ConflitoHorarioException():
        return 'ConflitoHorarioException';
      case _i14.RegistroTempo():
        return 'RegistroTempo';
      case _i15.RegistroTempoCreateRequest():
        return 'RegistroTempoCreateRequest';
      case _i16.RegistroTempoUpdateRequest():
        return 'RegistroTempoUpdateRequest';
      case _i17.RelatorioDemandaItem():
        return 'RelatorioDemandaItem';
      case _i18.RelatorioDemandaRequest():
        return 'RelatorioDemandaRequest';
      case _i19.RelatorioDemandasResponse():
        return 'RelatorioDemandasResponse';
      case _i20.Sprint():
        return 'Sprint';
      case _i21.SprintConclusaoResponse():
        return 'SprintConclusaoResponse';
      case _i22.SprintCreateRequest():
        return 'SprintCreateRequest';
      case _i23.SprintDemanda():
        return 'SprintDemanda';
      case _i24.SprintErroCodigo():
        return 'SprintErroCodigo';
      case _i25.SprintException():
        return 'SprintException';
      case _i26.SprintIndicadores():
        return 'SprintIndicadores';
      case _i27.SprintStatus():
        return 'SprintStatus';
      case _i28.SprintUpdateRequest():
        return 'SprintUpdateRequest';
      case _i29.EmailWhitelist():
        return 'EmailWhitelist';
      case _i30.Usuario():
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
    if (dataClassName == 'Demanda') {
      return deserialize<_i2.Demanda>(data['data']);
    }
    if (dataClassName == 'DemandaCreateRequest') {
      return deserialize<_i3.DemandaCreateRequest>(data['data']);
    }
    if (dataClassName == 'DemandaMovimentacaoRequest') {
      return deserialize<_i4.DemandaMovimentacaoRequest>(data['data']);
    }
    if (dataClassName == 'DemandaStatus') {
      return deserialize<_i5.DemandaStatus>(data['data']);
    }
    if (dataClassName == 'DemandaUpdateRequest') {
      return deserialize<_i6.DemandaUpdateRequest>(data['data']);
    }
    if (dataClassName == 'MovimentacaoDemandaErroCodigo') {
      return deserialize<_i7.MovimentacaoDemandaErroCodigo>(data['data']);
    }
    if (dataClassName == 'MovimentacaoDemandaException') {
      return deserialize<_i8.MovimentacaoDemandaException>(data['data']);
    }
    if (dataClassName == 'Prioridade') {
      return deserialize<_i9.Prioridade>(data['data']);
    }
    if (dataClassName == 'TransicaoStatusErroCodigo') {
      return deserialize<_i10.TransicaoStatusErroCodigo>(data['data']);
    }
    if (dataClassName == 'TransicaoStatusException') {
      return deserialize<_i11.TransicaoStatusException>(data['data']);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_i12.Greeting>(data['data']);
    }
    if (dataClassName == 'ConflitoHorarioException') {
      return deserialize<_i13.ConflitoHorarioException>(data['data']);
    }
    if (dataClassName == 'RegistroTempo') {
      return deserialize<_i14.RegistroTempo>(data['data']);
    }
    if (dataClassName == 'RegistroTempoCreateRequest') {
      return deserialize<_i15.RegistroTempoCreateRequest>(data['data']);
    }
    if (dataClassName == 'RegistroTempoUpdateRequest') {
      return deserialize<_i16.RegistroTempoUpdateRequest>(data['data']);
    }
    if (dataClassName == 'RelatorioDemandaItem') {
      return deserialize<_i17.RelatorioDemandaItem>(data['data']);
    }
    if (dataClassName == 'RelatorioDemandaRequest') {
      return deserialize<_i18.RelatorioDemandaRequest>(data['data']);
    }
    if (dataClassName == 'RelatorioDemandasResponse') {
      return deserialize<_i19.RelatorioDemandasResponse>(data['data']);
    }
    if (dataClassName == 'Sprint') {
      return deserialize<_i20.Sprint>(data['data']);
    }
    if (dataClassName == 'SprintConclusaoResponse') {
      return deserialize<_i21.SprintConclusaoResponse>(data['data']);
    }
    if (dataClassName == 'SprintCreateRequest') {
      return deserialize<_i22.SprintCreateRequest>(data['data']);
    }
    if (dataClassName == 'SprintDemanda') {
      return deserialize<_i23.SprintDemanda>(data['data']);
    }
    if (dataClassName == 'SprintErroCodigo') {
      return deserialize<_i24.SprintErroCodigo>(data['data']);
    }
    if (dataClassName == 'SprintException') {
      return deserialize<_i25.SprintException>(data['data']);
    }
    if (dataClassName == 'SprintIndicadores') {
      return deserialize<_i26.SprintIndicadores>(data['data']);
    }
    if (dataClassName == 'SprintStatus') {
      return deserialize<_i27.SprintStatus>(data['data']);
    }
    if (dataClassName == 'SprintUpdateRequest') {
      return deserialize<_i28.SprintUpdateRequest>(data['data']);
    }
    if (dataClassName == 'EmailWhitelist') {
      return deserialize<_i29.EmailWhitelist>(data['data']);
    }
    if (dataClassName == 'Usuario') {
      return deserialize<_i30.Usuario>(data['data']);
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
