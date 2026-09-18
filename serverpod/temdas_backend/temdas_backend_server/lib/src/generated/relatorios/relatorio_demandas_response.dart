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
import '../relatorios/relatorio_demanda_item.dart' as _i2;
import 'package:temdas_backend_server/src/generated/protocol.dart' as _i3;

abstract class RelatorioDemandasResponse
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  RelatorioDemandasResponse._({
    required this.inicioEm,
    required this.fimExclusivo,
    required this.tempoRealizadoTotalMinutos,
    required this.quantidadeDemandasComTempo,
    required this.itens,
  });

  factory RelatorioDemandasResponse({
    required DateTime inicioEm,
    required DateTime fimExclusivo,
    required int tempoRealizadoTotalMinutos,
    required int quantidadeDemandasComTempo,
    required List<_i2.RelatorioDemandaItem> itens,
  }) = _RelatorioDemandasResponseImpl;

  factory RelatorioDemandasResponse.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return RelatorioDemandasResponse(
      inicioEm: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['inicioEm'],
      ),
      fimExclusivo: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['fimExclusivo'],
      ),
      tempoRealizadoTotalMinutos:
          jsonSerialization['tempoRealizadoTotalMinutos'] as int,
      quantidadeDemandasComTempo:
          jsonSerialization['quantidadeDemandasComTempo'] as int,
      itens: _i3.Protocol().deserialize<List<_i2.RelatorioDemandaItem>>(
        jsonSerialization['itens'],
      ),
    );
  }

  DateTime inicioEm;

  DateTime fimExclusivo;

  int tempoRealizadoTotalMinutos;

  int quantidadeDemandasComTempo;

  List<_i2.RelatorioDemandaItem> itens;

  /// Returns a shallow copy of this [RelatorioDemandasResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  RelatorioDemandasResponse copyWith({
    DateTime? inicioEm,
    DateTime? fimExclusivo,
    int? tempoRealizadoTotalMinutos,
    int? quantidadeDemandasComTempo,
    List<_i2.RelatorioDemandaItem>? itens,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RelatorioDemandasResponse',
      'inicioEm': inicioEm.toJson(),
      'fimExclusivo': fimExclusivo.toJson(),
      'tempoRealizadoTotalMinutos': tempoRealizadoTotalMinutos,
      'quantidadeDemandasComTempo': quantidadeDemandasComTempo,
      'itens': itens.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'RelatorioDemandasResponse',
      'inicioEm': inicioEm.toJson(),
      'fimExclusivo': fimExclusivo.toJson(),
      'tempoRealizadoTotalMinutos': tempoRealizadoTotalMinutos,
      'quantidadeDemandasComTempo': quantidadeDemandasComTempo,
      'itens': itens.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _RelatorioDemandasResponseImpl extends RelatorioDemandasResponse {
  _RelatorioDemandasResponseImpl({
    required DateTime inicioEm,
    required DateTime fimExclusivo,
    required int tempoRealizadoTotalMinutos,
    required int quantidadeDemandasComTempo,
    required List<_i2.RelatorioDemandaItem> itens,
  }) : super._(
         inicioEm: inicioEm,
         fimExclusivo: fimExclusivo,
         tempoRealizadoTotalMinutos: tempoRealizadoTotalMinutos,
         quantidadeDemandasComTempo: quantidadeDemandasComTempo,
         itens: itens,
       );

  /// Returns a shallow copy of this [RelatorioDemandasResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  RelatorioDemandasResponse copyWith({
    DateTime? inicioEm,
    DateTime? fimExclusivo,
    int? tempoRealizadoTotalMinutos,
    int? quantidadeDemandasComTempo,
    List<_i2.RelatorioDemandaItem>? itens,
  }) {
    return RelatorioDemandasResponse(
      inicioEm: inicioEm ?? this.inicioEm,
      fimExclusivo: fimExclusivo ?? this.fimExclusivo,
      tempoRealizadoTotalMinutos:
          tempoRealizadoTotalMinutos ?? this.tempoRealizadoTotalMinutos,
      quantidadeDemandasComTempo:
          quantidadeDemandasComTempo ?? this.quantidadeDemandasComTempo,
      itens: itens ?? this.itens.map((e0) => e0.copyWith()).toList(),
    );
  }
}
