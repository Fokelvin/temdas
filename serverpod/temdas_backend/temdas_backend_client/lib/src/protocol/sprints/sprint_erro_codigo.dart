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

enum SprintErroCodigo implements _i1.SerializableModel {
  nomeObrigatorio,
  nomeDuplicado,
  periodoInvalido,
  periodoSobreposto,
  sprintNaoEncontrada,
  sprintAtivaExistente,
  inicioAntesDataInicio,
  tempoPrevistoInvalido,
  transicaoStatusInvalida,
  demandaOutraSprintAberta,
  vinculoStatusProibido,
  demandaFilhaSemMae,
  demandaFilhaComMaeVinculada,
  demandaNaoEncontrada,
  usuarioDiferenteDaSprint,
  historicoSprintConcluida;

  static SprintErroCodigo fromJson(String name) {
    switch (name) {
      case 'nomeObrigatorio':
        return SprintErroCodigo.nomeObrigatorio;
      case 'nomeDuplicado':
        return SprintErroCodigo.nomeDuplicado;
      case 'periodoInvalido':
        return SprintErroCodigo.periodoInvalido;
      case 'periodoSobreposto':
        return SprintErroCodigo.periodoSobreposto;
      case 'sprintNaoEncontrada':
        return SprintErroCodigo.sprintNaoEncontrada;
      case 'sprintAtivaExistente':
        return SprintErroCodigo.sprintAtivaExistente;
      case 'inicioAntesDataInicio':
        return SprintErroCodigo.inicioAntesDataInicio;
      case 'tempoPrevistoInvalido':
        return SprintErroCodigo.tempoPrevistoInvalido;
      case 'transicaoStatusInvalida':
        return SprintErroCodigo.transicaoStatusInvalida;
      case 'demandaOutraSprintAberta':
        return SprintErroCodigo.demandaOutraSprintAberta;
      case 'vinculoStatusProibido':
        return SprintErroCodigo.vinculoStatusProibido;
      case 'demandaFilhaSemMae':
        return SprintErroCodigo.demandaFilhaSemMae;
      case 'demandaFilhaComMaeVinculada':
        return SprintErroCodigo.demandaFilhaComMaeVinculada;
      case 'demandaNaoEncontrada':
        return SprintErroCodigo.demandaNaoEncontrada;
      case 'usuarioDiferenteDaSprint':
        return SprintErroCodigo.usuarioDiferenteDaSprint;
      case 'historicoSprintConcluida':
        return SprintErroCodigo.historicoSprintConcluida;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "SprintErroCodigo"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
