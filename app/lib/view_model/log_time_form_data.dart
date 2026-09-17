import 'package:flutter/material.dart';

/// Intervalo informado no formulário, com duração inteira em minutos.
class LogTimeFormData {
  const LogTimeFormData({
    required this.data,
    required this.hora,
    required this.duracaoMinutos,
  });

  final DateTime data;
  final TimeOfDay hora;
  final int duracaoMinutos;

  /// Adapta o formulário às operações existentes da AgendaViewModel.
  double get duracaoHoras => duracaoMinutos / Duration.minutesPerHour;

  DateTime get inicioEm =>
      DateTime(data.year, data.month, data.day, hora.hour, hora.minute).toUtc();

  /// Retorna null para horários iguais, invertidos ou passando da meia-noite.
  static LogTimeFormData? doMesmoDia({
    required DateTime data,
    required TimeOfDay inicio,
    required TimeOfDay fim,
  }) {
    final minutos =
        (fim.hour - inicio.hour) * Duration.minutesPerHour +
        fim.minute -
        inicio.minute;
    if (minutos <= 0) return null;
    return LogTimeFormData(data: data, hora: inicio, duracaoMinutos: minutos);
  }
}
