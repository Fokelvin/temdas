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
import '../demandas/demanda_status.dart' as _i2;
import '../demandas/prioridade.dart' as _i3;

abstract class RelatorioDemandaItem
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  RelatorioDemandaItem._({
    required this.demandaId,
    required this.titulo,
    this.demandaMaeId,
    required this.nivelHierarquico,
    required this.status,
    required this.prioridade,
    required this.tempoEstimadoMinutos,
    required this.tempoRealizadoProprioMinutos,
    required this.tempoRealizadoTotalArvoreMinutos,
    required this.apenasContexto,
  });

  factory RelatorioDemandaItem({
    required int demandaId,
    required String titulo,
    int? demandaMaeId,
    required int nivelHierarquico,
    required _i2.DemandaStatus status,
    required _i3.Prioridade prioridade,
    required int tempoEstimadoMinutos,
    required int tempoRealizadoProprioMinutos,
    required int tempoRealizadoTotalArvoreMinutos,
    required bool apenasContexto,
  }) = _RelatorioDemandaItemImpl;

  factory RelatorioDemandaItem.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return RelatorioDemandaItem(
      demandaId: jsonSerialization['demandaId'] as int,
      titulo: jsonSerialization['titulo'] as String,
      demandaMaeId: jsonSerialization['demandaMaeId'] as int?,
      nivelHierarquico: jsonSerialization['nivelHierarquico'] as int,
      status: _i2.DemandaStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      prioridade: _i3.Prioridade.fromJson(
        (jsonSerialization['prioridade'] as String),
      ),
      tempoEstimadoMinutos: jsonSerialization['tempoEstimadoMinutos'] as int,
      tempoRealizadoProprioMinutos:
          jsonSerialization['tempoRealizadoProprioMinutos'] as int,
      tempoRealizadoTotalArvoreMinutos:
          jsonSerialization['tempoRealizadoTotalArvoreMinutos'] as int,
      apenasContexto: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['apenasContexto'],
      ),
    );
  }

  int demandaId;

  String titulo;

  int? demandaMaeId;

  int nivelHierarquico;

  _i2.DemandaStatus status;

  _i3.Prioridade prioridade;

  int tempoEstimadoMinutos;

  int tempoRealizadoProprioMinutos;

  int tempoRealizadoTotalArvoreMinutos;

  bool apenasContexto;

  /// Returns a shallow copy of this [RelatorioDemandaItem]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  RelatorioDemandaItem copyWith({
    int? demandaId,
    String? titulo,
    int? demandaMaeId,
    int? nivelHierarquico,
    _i2.DemandaStatus? status,
    _i3.Prioridade? prioridade,
    int? tempoEstimadoMinutos,
    int? tempoRealizadoProprioMinutos,
    int? tempoRealizadoTotalArvoreMinutos,
    bool? apenasContexto,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RelatorioDemandaItem',
      'demandaId': demandaId,
      'titulo': titulo,
      if (demandaMaeId != null) 'demandaMaeId': demandaMaeId,
      'nivelHierarquico': nivelHierarquico,
      'status': status.toJson(),
      'prioridade': prioridade.toJson(),
      'tempoEstimadoMinutos': tempoEstimadoMinutos,
      'tempoRealizadoProprioMinutos': tempoRealizadoProprioMinutos,
      'tempoRealizadoTotalArvoreMinutos': tempoRealizadoTotalArvoreMinutos,
      'apenasContexto': apenasContexto,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'RelatorioDemandaItem',
      'demandaId': demandaId,
      'titulo': titulo,
      if (demandaMaeId != null) 'demandaMaeId': demandaMaeId,
      'nivelHierarquico': nivelHierarquico,
      'status': status.toJson(),
      'prioridade': prioridade.toJson(),
      'tempoEstimadoMinutos': tempoEstimadoMinutos,
      'tempoRealizadoProprioMinutos': tempoRealizadoProprioMinutos,
      'tempoRealizadoTotalArvoreMinutos': tempoRealizadoTotalArvoreMinutos,
      'apenasContexto': apenasContexto,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _RelatorioDemandaItemImpl extends RelatorioDemandaItem {
  _RelatorioDemandaItemImpl({
    required int demandaId,
    required String titulo,
    int? demandaMaeId,
    required int nivelHierarquico,
    required _i2.DemandaStatus status,
    required _i3.Prioridade prioridade,
    required int tempoEstimadoMinutos,
    required int tempoRealizadoProprioMinutos,
    required int tempoRealizadoTotalArvoreMinutos,
    required bool apenasContexto,
  }) : super._(
         demandaId: demandaId,
         titulo: titulo,
         demandaMaeId: demandaMaeId,
         nivelHierarquico: nivelHierarquico,
         status: status,
         prioridade: prioridade,
         tempoEstimadoMinutos: tempoEstimadoMinutos,
         tempoRealizadoProprioMinutos: tempoRealizadoProprioMinutos,
         tempoRealizadoTotalArvoreMinutos: tempoRealizadoTotalArvoreMinutos,
         apenasContexto: apenasContexto,
       );

  /// Returns a shallow copy of this [RelatorioDemandaItem]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  RelatorioDemandaItem copyWith({
    int? demandaId,
    String? titulo,
    Object? demandaMaeId = _Undefined,
    int? nivelHierarquico,
    _i2.DemandaStatus? status,
    _i3.Prioridade? prioridade,
    int? tempoEstimadoMinutos,
    int? tempoRealizadoProprioMinutos,
    int? tempoRealizadoTotalArvoreMinutos,
    bool? apenasContexto,
  }) {
    return RelatorioDemandaItem(
      demandaId: demandaId ?? this.demandaId,
      titulo: titulo ?? this.titulo,
      demandaMaeId: demandaMaeId is int? ? demandaMaeId : this.demandaMaeId,
      nivelHierarquico: nivelHierarquico ?? this.nivelHierarquico,
      status: status ?? this.status,
      prioridade: prioridade ?? this.prioridade,
      tempoEstimadoMinutos: tempoEstimadoMinutos ?? this.tempoEstimadoMinutos,
      tempoRealizadoProprioMinutos:
          tempoRealizadoProprioMinutos ?? this.tempoRealizadoProprioMinutos,
      tempoRealizadoTotalArvoreMinutos:
          tempoRealizadoTotalArvoreMinutos ??
          this.tempoRealizadoTotalArvoreMinutos,
      apenasContexto: apenasContexto ?? this.apenasContexto,
    );
  }
}
