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
import 'demandas/demanda_status.dart' as _i5;
import 'demandas/demanda_update_request.dart' as _i6;
import 'demandas/prioridade.dart' as _i7;
import 'greetings/greeting.dart' as _i8;
import 'package:temdas_backend_server/src/generated/demandas/demanda.dart'
    as _i9;
export 'demandas/demanda.dart';
export 'demandas/demanda_create_request.dart';
export 'demandas/demanda_status.dart';
export 'demandas/demanda_update_request.dart';
export 'demandas/prioridade.dart';
export 'greetings/greeting.dart';

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
          name: 'prioridade',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:Prioridade',
        ),
        _i2.ColumnDefinition(
          name: 'sprint',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
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
      foreignKeys: [],
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
    if (t == _i5.DemandaStatus) {
      return _i5.DemandaStatus.fromJson(data) as T;
    }
    if (t == _i6.DemandaUpdateRequest) {
      return _i6.DemandaUpdateRequest.fromJson(data) as T;
    }
    if (t == _i7.Prioridade) {
      return _i7.Prioridade.fromJson(data) as T;
    }
    if (t == _i8.Greeting) {
      return _i8.Greeting.fromJson(data) as T;
    }
    if (t == _i1.getType<_i3.Demanda?>()) {
      return (data != null ? _i3.Demanda.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.DemandaCreateRequest?>()) {
      return (data != null ? _i4.DemandaCreateRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i5.DemandaStatus?>()) {
      return (data != null ? _i5.DemandaStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.DemandaUpdateRequest?>()) {
      return (data != null ? _i6.DemandaUpdateRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i7.Prioridade?>()) {
      return (data != null ? _i7.Prioridade.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.Greeting?>()) {
      return (data != null ? _i8.Greeting.fromJson(data) : null) as T;
    }
    if (t == List<_i9.Demanda>) {
      return (data as List).map((e) => deserialize<_i9.Demanda>(e)).toList()
          as T;
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
      _i5.DemandaStatus => 'DemandaStatus',
      _i6.DemandaUpdateRequest => 'DemandaUpdateRequest',
      _i7.Prioridade => 'Prioridade',
      _i8.Greeting => 'Greeting',
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
      case _i5.DemandaStatus():
        return 'DemandaStatus';
      case _i6.DemandaUpdateRequest():
        return 'DemandaUpdateRequest';
      case _i7.Prioridade():
        return 'Prioridade';
      case _i8.Greeting():
        return 'Greeting';
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
    if (dataClassName == 'DemandaStatus') {
      return deserialize<_i5.DemandaStatus>(data['data']);
    }
    if (dataClassName == 'DemandaUpdateRequest') {
      return deserialize<_i6.DemandaUpdateRequest>(data['data']);
    }
    if (dataClassName == 'Prioridade') {
      return deserialize<_i7.Prioridade>(data['data']);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_i8.Greeting>(data['data']);
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
