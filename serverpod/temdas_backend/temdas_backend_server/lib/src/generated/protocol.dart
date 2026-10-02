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
import 'package:serverpod/protocol.dart' as _i2;
import 'demandas/demanda.dart' as _i3;
import 'demandas/demanda_create_request.dart' as _i4;
import 'demandas/demanda_movimentacao_request.dart' as _i5;
import 'demandas/demanda_status.dart' as _i6;
import 'demandas/demanda_update_request.dart' as _i7;
import 'demandas/movimentacao_demanda_erro_codigo.dart' as _i8;
import 'demandas/movimentacao_demanda_exception.dart' as _i9;
import 'demandas/prioridade.dart' as _i10;
import 'demandas/transicao_status_erro_codigo.dart' as _i11;
import 'demandas/transicao_status_exception.dart' as _i12;
import 'greetings/greeting.dart' as _i13;
import 'registros_tempo/conflito_horario_exception.dart' as _i14;
import 'registros_tempo/registro_tempo.dart' as _i15;
import 'registros_tempo/registro_tempo_create_request.dart' as _i16;
import 'registros_tempo/registro_tempo_update_request.dart' as _i17;
import 'relatorios/relatorio_demanda_item.dart' as _i18;
import 'relatorios/relatorio_demanda_request.dart' as _i19;
import 'relatorios/relatorio_demandas_response.dart' as _i20;
import 'sprints/sprint.dart' as _i21;
import 'sprints/sprint_conclusao_response.dart' as _i22;
import 'sprints/sprint_create_request.dart' as _i23;
import 'sprints/sprint_demanda.dart' as _i24;
import 'sprints/sprint_erro_codigo.dart' as _i25;
import 'sprints/sprint_exception.dart' as _i26;
import 'sprints/sprint_indicadores.dart' as _i27;
import 'sprints/sprint_status.dart' as _i28;
import 'sprints/sprint_update_request.dart' as _i29;
import 'usuarios/email_whitelist.dart' as _i30;
import 'usuarios/usuario.dart' as _i31;
import 'package:temdas_backend_server/src/generated/demandas/demanda.dart'
    as _i32;
import 'package:temdas_backend_server/src/generated/registros_tempo/registro_tempo.dart'
    as _i33;
import 'package:temdas_backend_server/src/generated/sprints/sprint.dart'
    as _i34;
import 'package:temdas_backend_server/src/generated/sprints/sprint_demanda.dart'
    as _i35;
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

class Protocol extends _i1.SerializationManagerServer {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static final List<_i2.TableDefinition> targetTableDefinitions = [
    _i2.TableDefinition(
      name: 'demandas',
      dartName: 'Demanda',
      schema: 'public',
      module: 'temdas_backend',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'demandas_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'usuarioId',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'demandaPaiId',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'ordem',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'titulo',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'descricao',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'status',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:DemandaStatus',
        ),
        _i2.ColumnDefinition(
          name: 'motivoCancelamento',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'prioridade',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:Prioridade',
        ),
        _i2.ColumnDefinition(
          name: 'tempoEstimadoMinutos',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'tempoExecutadoMinutos',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'observacoes',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'criadoEm',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'atualizadoEm',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'concluidoEm',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'demandas_fk_0',
          columns: ['usuarioId'],
          referenceTable: 'usuarios',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'demandas_fk_1',
          columns: ['demandaPaiId'],
          referenceTable: 'demandas',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'demandas_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'demandas_demanda_pai_id_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'demandaPaiId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'emails_whitelist',
      dartName: 'EmailWhitelist',
      schema: 'public',
      module: 'temdas_backend',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'emails_whitelist_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'emailNormalizado',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'utilizadoEm',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'emails_whitelist_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'emails_whitelist_email_normalizado_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'emailNormalizado',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'registros_tempo',
      dartName: 'RegistroTempo',
      schema: 'public',
      module: 'temdas_backend',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'registros_tempo_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'demandaId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'inicioEm',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'duracaoMinutos',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'criadoEm',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'registros_tempo_fk_0',
          columns: ['demandaId'],
          referenceTable: 'demandas',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'registros_tempo_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'registros_tempo_inicio_em_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'inicioEm',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'registros_tempo_demanda_inicio_em_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'demandaId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'inicioEm',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'sprints',
      dartName: 'Sprint',
      schema: 'public',
      module: 'temdas_backend',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'sprints_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'usuarioId',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'nome',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'nomeNormalizado',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'dataInicio',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'dataFim',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'tempoPrevistoMinutos',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'status',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:SprintStatus',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'sprints_fk_0',
          columns: ['usuarioId'],
          referenceTable: 'usuarios',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'sprints_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'sprints_nome_normalizado_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'usuarioId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'nomeNormalizado',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'sprints_demandas',
      dartName: 'SprintDemanda',
      schema: 'public',
      module: 'temdas_backend',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'sprints_demandas_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'sprintId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'demandaId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'sprints_demandas_fk_0',
          columns: ['sprintId'],
          referenceTable: 'sprints',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'sprints_demandas_fk_1',
          columns: ['demandaId'],
          referenceTable: 'demandas',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'sprints_demandas_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'sprints_demandas_sprint_demanda_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'sprintId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'demandaId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'usuarios',
      dartName: 'Usuario',
      schema: 'public',
      module: 'temdas_backend',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'usuarios_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'supabaseUserId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'usuarios_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'usuarios_supabase_user_id_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'supabaseUserId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    ..._i2.Protocol.targetTableDefinitions,
  ];

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

    if (t == _i3.Demanda) {
      return _i3.Demanda.fromJson(data) as T;
    }
    if (t == _i4.DemandaCreateRequest) {
      return _i4.DemandaCreateRequest.fromJson(data) as T;
    }
    if (t == _i5.DemandaMovimentacaoRequest) {
      return _i5.DemandaMovimentacaoRequest.fromJson(data) as T;
    }
    if (t == _i6.DemandaStatus) {
      return _i6.DemandaStatus.fromJson(data) as T;
    }
    if (t == _i7.DemandaUpdateRequest) {
      return _i7.DemandaUpdateRequest.fromJson(data) as T;
    }
    if (t == _i8.MovimentacaoDemandaErroCodigo) {
      return _i8.MovimentacaoDemandaErroCodigo.fromJson(data) as T;
    }
    if (t == _i9.MovimentacaoDemandaException) {
      return _i9.MovimentacaoDemandaException.fromJson(data) as T;
    }
    if (t == _i10.Prioridade) {
      return _i10.Prioridade.fromJson(data) as T;
    }
    if (t == _i11.TransicaoStatusErroCodigo) {
      return _i11.TransicaoStatusErroCodigo.fromJson(data) as T;
    }
    if (t == _i12.TransicaoStatusException) {
      return _i12.TransicaoStatusException.fromJson(data) as T;
    }
    if (t == _i13.Greeting) {
      return _i13.Greeting.fromJson(data) as T;
    }
    if (t == _i14.ConflitoHorarioException) {
      return _i14.ConflitoHorarioException.fromJson(data) as T;
    }
    if (t == _i15.RegistroTempo) {
      return _i15.RegistroTempo.fromJson(data) as T;
    }
    if (t == _i16.RegistroTempoCreateRequest) {
      return _i16.RegistroTempoCreateRequest.fromJson(data) as T;
    }
    if (t == _i17.RegistroTempoUpdateRequest) {
      return _i17.RegistroTempoUpdateRequest.fromJson(data) as T;
    }
    if (t == _i18.RelatorioDemandaItem) {
      return _i18.RelatorioDemandaItem.fromJson(data) as T;
    }
    if (t == _i19.RelatorioDemandaRequest) {
      return _i19.RelatorioDemandaRequest.fromJson(data) as T;
    }
    if (t == _i20.RelatorioDemandasResponse) {
      return _i20.RelatorioDemandasResponse.fromJson(data) as T;
    }
    if (t == _i21.Sprint) {
      return _i21.Sprint.fromJson(data) as T;
    }
    if (t == _i22.SprintConclusaoResponse) {
      return _i22.SprintConclusaoResponse.fromJson(data) as T;
    }
    if (t == _i23.SprintCreateRequest) {
      return _i23.SprintCreateRequest.fromJson(data) as T;
    }
    if (t == _i24.SprintDemanda) {
      return _i24.SprintDemanda.fromJson(data) as T;
    }
    if (t == _i25.SprintErroCodigo) {
      return _i25.SprintErroCodigo.fromJson(data) as T;
    }
    if (t == _i26.SprintException) {
      return _i26.SprintException.fromJson(data) as T;
    }
    if (t == _i27.SprintIndicadores) {
      return _i27.SprintIndicadores.fromJson(data) as T;
    }
    if (t == _i28.SprintStatus) {
      return _i28.SprintStatus.fromJson(data) as T;
    }
    if (t == _i29.SprintUpdateRequest) {
      return _i29.SprintUpdateRequest.fromJson(data) as T;
    }
    if (t == _i30.EmailWhitelist) {
      return _i30.EmailWhitelist.fromJson(data) as T;
    }
    if (t == _i31.Usuario) {
      return _i31.Usuario.fromJson(data) as T;
    }
    if (t == _i1.getType<_i3.Demanda?>()) {
      return (data != null ? _i3.Demanda.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.DemandaCreateRequest?>()) {
      return (data != null ? _i4.DemandaCreateRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i5.DemandaMovimentacaoRequest?>()) {
      return (data != null
              ? _i5.DemandaMovimentacaoRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i6.DemandaStatus?>()) {
      return (data != null ? _i6.DemandaStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.DemandaUpdateRequest?>()) {
      return (data != null ? _i7.DemandaUpdateRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i8.MovimentacaoDemandaErroCodigo?>()) {
      return (data != null
              ? _i8.MovimentacaoDemandaErroCodigo.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i9.MovimentacaoDemandaException?>()) {
      return (data != null
              ? _i9.MovimentacaoDemandaException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i10.Prioridade?>()) {
      return (data != null ? _i10.Prioridade.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.TransicaoStatusErroCodigo?>()) {
      return (data != null
              ? _i11.TransicaoStatusErroCodigo.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i12.TransicaoStatusException?>()) {
      return (data != null
              ? _i12.TransicaoStatusException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i13.Greeting?>()) {
      return (data != null ? _i13.Greeting.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.ConflitoHorarioException?>()) {
      return (data != null
              ? _i14.ConflitoHorarioException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i15.RegistroTempo?>()) {
      return (data != null ? _i15.RegistroTempo.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i16.RegistroTempoCreateRequest?>()) {
      return (data != null
              ? _i16.RegistroTempoCreateRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i17.RegistroTempoUpdateRequest?>()) {
      return (data != null
              ? _i17.RegistroTempoUpdateRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i18.RelatorioDemandaItem?>()) {
      return (data != null ? _i18.RelatorioDemandaItem.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i19.RelatorioDemandaRequest?>()) {
      return (data != null ? _i19.RelatorioDemandaRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i20.RelatorioDemandasResponse?>()) {
      return (data != null
              ? _i20.RelatorioDemandasResponse.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i21.Sprint?>()) {
      return (data != null ? _i21.Sprint.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i22.SprintConclusaoResponse?>()) {
      return (data != null ? _i22.SprintConclusaoResponse.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i23.SprintCreateRequest?>()) {
      return (data != null ? _i23.SprintCreateRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i24.SprintDemanda?>()) {
      return (data != null ? _i24.SprintDemanda.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i25.SprintErroCodigo?>()) {
      return (data != null ? _i25.SprintErroCodigo.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i26.SprintException?>()) {
      return (data != null ? _i26.SprintException.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i27.SprintIndicadores?>()) {
      return (data != null ? _i27.SprintIndicadores.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i28.SprintStatus?>()) {
      return (data != null ? _i28.SprintStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i29.SprintUpdateRequest?>()) {
      return (data != null ? _i29.SprintUpdateRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i30.EmailWhitelist?>()) {
      return (data != null ? _i30.EmailWhitelist.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i31.Usuario?>()) {
      return (data != null ? _i31.Usuario.fromJson(data) : null) as T;
    }
    if (t == List<_i18.RelatorioDemandaItem>) {
      return (data as List)
              .map((e) => deserialize<_i18.RelatorioDemandaItem>(e))
              .toList()
          as T;
    }
    if (t == List<_i32.Demanda>) {
      return (data as List).map((e) => deserialize<_i32.Demanda>(e)).toList()
          as T;
    }
    if (t == List<_i33.RegistroTempo>) {
      return (data as List)
              .map((e) => deserialize<_i33.RegistroTempo>(e))
              .toList()
          as T;
    }
    if (t == List<_i34.Sprint>) {
      return (data as List).map((e) => deserialize<_i34.Sprint>(e)).toList()
          as T;
    }
    if (t == List<_i35.SprintDemanda>) {
      return (data as List)
              .map((e) => deserialize<_i35.SprintDemanda>(e))
              .toList()
          as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    try {
      return _i2.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i3.Demanda => 'Demanda',
      _i4.DemandaCreateRequest => 'DemandaCreateRequest',
      _i5.DemandaMovimentacaoRequest => 'DemandaMovimentacaoRequest',
      _i6.DemandaStatus => 'DemandaStatus',
      _i7.DemandaUpdateRequest => 'DemandaUpdateRequest',
      _i8.MovimentacaoDemandaErroCodigo => 'MovimentacaoDemandaErroCodigo',
      _i9.MovimentacaoDemandaException => 'MovimentacaoDemandaException',
      _i10.Prioridade => 'Prioridade',
      _i11.TransicaoStatusErroCodigo => 'TransicaoStatusErroCodigo',
      _i12.TransicaoStatusException => 'TransicaoStatusException',
      _i13.Greeting => 'Greeting',
      _i14.ConflitoHorarioException => 'ConflitoHorarioException',
      _i15.RegistroTempo => 'RegistroTempo',
      _i16.RegistroTempoCreateRequest => 'RegistroTempoCreateRequest',
      _i17.RegistroTempoUpdateRequest => 'RegistroTempoUpdateRequest',
      _i18.RelatorioDemandaItem => 'RelatorioDemandaItem',
      _i19.RelatorioDemandaRequest => 'RelatorioDemandaRequest',
      _i20.RelatorioDemandasResponse => 'RelatorioDemandasResponse',
      _i21.Sprint => 'Sprint',
      _i22.SprintConclusaoResponse => 'SprintConclusaoResponse',
      _i23.SprintCreateRequest => 'SprintCreateRequest',
      _i24.SprintDemanda => 'SprintDemanda',
      _i25.SprintErroCodigo => 'SprintErroCodigo',
      _i26.SprintException => 'SprintException',
      _i27.SprintIndicadores => 'SprintIndicadores',
      _i28.SprintStatus => 'SprintStatus',
      _i29.SprintUpdateRequest => 'SprintUpdateRequest',
      _i30.EmailWhitelist => 'EmailWhitelist',
      _i31.Usuario => 'Usuario',
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
      case _i3.Demanda():
        return 'Demanda';
      case _i4.DemandaCreateRequest():
        return 'DemandaCreateRequest';
      case _i5.DemandaMovimentacaoRequest():
        return 'DemandaMovimentacaoRequest';
      case _i6.DemandaStatus():
        return 'DemandaStatus';
      case _i7.DemandaUpdateRequest():
        return 'DemandaUpdateRequest';
      case _i8.MovimentacaoDemandaErroCodigo():
        return 'MovimentacaoDemandaErroCodigo';
      case _i9.MovimentacaoDemandaException():
        return 'MovimentacaoDemandaException';
      case _i10.Prioridade():
        return 'Prioridade';
      case _i11.TransicaoStatusErroCodigo():
        return 'TransicaoStatusErroCodigo';
      case _i12.TransicaoStatusException():
        return 'TransicaoStatusException';
      case _i13.Greeting():
        return 'Greeting';
      case _i14.ConflitoHorarioException():
        return 'ConflitoHorarioException';
      case _i15.RegistroTempo():
        return 'RegistroTempo';
      case _i16.RegistroTempoCreateRequest():
        return 'RegistroTempoCreateRequest';
      case _i17.RegistroTempoUpdateRequest():
        return 'RegistroTempoUpdateRequest';
      case _i18.RelatorioDemandaItem():
        return 'RelatorioDemandaItem';
      case _i19.RelatorioDemandaRequest():
        return 'RelatorioDemandaRequest';
      case _i20.RelatorioDemandasResponse():
        return 'RelatorioDemandasResponse';
      case _i21.Sprint():
        return 'Sprint';
      case _i22.SprintConclusaoResponse():
        return 'SprintConclusaoResponse';
      case _i23.SprintCreateRequest():
        return 'SprintCreateRequest';
      case _i24.SprintDemanda():
        return 'SprintDemanda';
      case _i25.SprintErroCodigo():
        return 'SprintErroCodigo';
      case _i26.SprintException():
        return 'SprintException';
      case _i27.SprintIndicadores():
        return 'SprintIndicadores';
      case _i28.SprintStatus():
        return 'SprintStatus';
      case _i29.SprintUpdateRequest():
        return 'SprintUpdateRequest';
      case _i30.EmailWhitelist():
        return 'EmailWhitelist';
      case _i31.Usuario():
        return 'Usuario';
    }
    className = _i2.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod.$className';
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
      return deserialize<_i3.Demanda>(data['data']);
    }
    if (dataClassName == 'DemandaCreateRequest') {
      return deserialize<_i4.DemandaCreateRequest>(data['data']);
    }
    if (dataClassName == 'DemandaMovimentacaoRequest') {
      return deserialize<_i5.DemandaMovimentacaoRequest>(data['data']);
    }
    if (dataClassName == 'DemandaStatus') {
      return deserialize<_i6.DemandaStatus>(data['data']);
    }
    if (dataClassName == 'DemandaUpdateRequest') {
      return deserialize<_i7.DemandaUpdateRequest>(data['data']);
    }
    if (dataClassName == 'MovimentacaoDemandaErroCodigo') {
      return deserialize<_i8.MovimentacaoDemandaErroCodigo>(data['data']);
    }
    if (dataClassName == 'MovimentacaoDemandaException') {
      return deserialize<_i9.MovimentacaoDemandaException>(data['data']);
    }
    if (dataClassName == 'Prioridade') {
      return deserialize<_i10.Prioridade>(data['data']);
    }
    if (dataClassName == 'TransicaoStatusErroCodigo') {
      return deserialize<_i11.TransicaoStatusErroCodigo>(data['data']);
    }
    if (dataClassName == 'TransicaoStatusException') {
      return deserialize<_i12.TransicaoStatusException>(data['data']);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_i13.Greeting>(data['data']);
    }
    if (dataClassName == 'ConflitoHorarioException') {
      return deserialize<_i14.ConflitoHorarioException>(data['data']);
    }
    if (dataClassName == 'RegistroTempo') {
      return deserialize<_i15.RegistroTempo>(data['data']);
    }
    if (dataClassName == 'RegistroTempoCreateRequest') {
      return deserialize<_i16.RegistroTempoCreateRequest>(data['data']);
    }
    if (dataClassName == 'RegistroTempoUpdateRequest') {
      return deserialize<_i17.RegistroTempoUpdateRequest>(data['data']);
    }
    if (dataClassName == 'RelatorioDemandaItem') {
      return deserialize<_i18.RelatorioDemandaItem>(data['data']);
    }
    if (dataClassName == 'RelatorioDemandaRequest') {
      return deserialize<_i19.RelatorioDemandaRequest>(data['data']);
    }
    if (dataClassName == 'RelatorioDemandasResponse') {
      return deserialize<_i20.RelatorioDemandasResponse>(data['data']);
    }
    if (dataClassName == 'Sprint') {
      return deserialize<_i21.Sprint>(data['data']);
    }
    if (dataClassName == 'SprintConclusaoResponse') {
      return deserialize<_i22.SprintConclusaoResponse>(data['data']);
    }
    if (dataClassName == 'SprintCreateRequest') {
      return deserialize<_i23.SprintCreateRequest>(data['data']);
    }
    if (dataClassName == 'SprintDemanda') {
      return deserialize<_i24.SprintDemanda>(data['data']);
    }
    if (dataClassName == 'SprintErroCodigo') {
      return deserialize<_i25.SprintErroCodigo>(data['data']);
    }
    if (dataClassName == 'SprintException') {
      return deserialize<_i26.SprintException>(data['data']);
    }
    if (dataClassName == 'SprintIndicadores') {
      return deserialize<_i27.SprintIndicadores>(data['data']);
    }
    if (dataClassName == 'SprintStatus') {
      return deserialize<_i28.SprintStatus>(data['data']);
    }
    if (dataClassName == 'SprintUpdateRequest') {
      return deserialize<_i29.SprintUpdateRequest>(data['data']);
    }
    if (dataClassName == 'EmailWhitelist') {
      return deserialize<_i30.EmailWhitelist>(data['data']);
    }
    if (dataClassName == 'Usuario') {
      return deserialize<_i31.Usuario>(data['data']);
    }
    if (dataClassName.startsWith('serverpod.')) {
      data['className'] = dataClassName.substring(10);
      return _i2.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  @override
  _i1.Table? getTableForType(Type t) {
    {
      var table = _i2.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    switch (t) {
      case _i3.Demanda:
        return _i3.Demanda.t;
      case _i15.RegistroTempo:
        return _i15.RegistroTempo.t;
      case _i21.Sprint:
        return _i21.Sprint.t;
      case _i24.SprintDemanda:
        return _i24.SprintDemanda.t;
      case _i30.EmailWhitelist:
        return _i30.EmailWhitelist.t;
      case _i31.Usuario:
        return _i31.Usuario.t;
    }
    return null;
  }

  @override
  List<_i2.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

  @override
  String getModuleName() => 'temdas_backend';

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _i2.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
