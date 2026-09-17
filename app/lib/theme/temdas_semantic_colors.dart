import 'package:flutter/material.dart';

import 'temdas_colors.dart';

@immutable
class TemdasSemanticColors extends ThemeExtension<TemdasSemanticColors> {
  const TemdasSemanticColors({
    required this.prioridadeAlta,
    required this.prioridadeAltaContainer,
    required this.prioridadeMedia,
    required this.prioridadeMediaContainer,
    required this.prioridadeBaixa,
    required this.prioridadeBaixaContainer,
    required this.aberta,
    required this.emAndamento,
    required this.pausada,
    required this.concluida,
    required this.cancelada,
  });

  // Alta e urgente compartilham o alerta; o rótulo distingue a prioridade.
  final Color prioridadeAlta;
  final Color prioridadeAltaContainer;
  final Color prioridadeMedia;
  final Color prioridadeMediaContainer;
  final Color prioridadeBaixa;
  final Color prioridadeBaixaContainer;
  final Color aberta;
  final Color emAndamento;
  final Color pausada;
  final Color concluida;
  final Color cancelada;

  static final light = TemdasSemanticColors(
    prioridadeAlta: TemdasColors.lightRed,
    prioridadeAltaContainer: TemdasColors.lightRedContainer,
    prioridadeMedia: TemdasColors.lightAmber,
    prioridadeMediaContainer: TemdasColors.lightAmberContainer,
    prioridadeBaixa: TemdasColors.lightGreen,
    prioridadeBaixaContainer: TemdasColors.lightGreenContainer,
    aberta: TemdasColors.light.onSurfaceVariant,
    emAndamento: TemdasColors.light.primary,
    pausada: TemdasColors.lightAmber,
    concluida: TemdasColors.lightGreen,
    cancelada: TemdasColors.light.onSurfaceVariant,
  );

  static final dark = TemdasSemanticColors(
    prioridadeAlta: TemdasColors.darkRed,
    prioridadeAltaContainer: TemdasColors.darkRedContainer,
    prioridadeMedia: TemdasColors.darkAmber,
    prioridadeMediaContainer: TemdasColors.darkAmberContainer,
    prioridadeBaixa: TemdasColors.darkGreen,
    prioridadeBaixaContainer: TemdasColors.darkGreenContainer,
    aberta: TemdasColors.dark.onSurfaceVariant,
    emAndamento: TemdasColors.dark.primary,
    pausada: TemdasColors.darkAmber,
    concluida: TemdasColors.darkGreen,
    cancelada: TemdasColors.dark.onSurfaceVariant,
  );

  static TemdasSemanticColors of(BuildContext context) {
    final theme = Theme.of(context);
    // Também permite usar widgets isolados em previews com um ThemeData básico.
    return theme.extension<TemdasSemanticColors>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  @override
  TemdasSemanticColors copyWith({
    Color? prioridadeAlta,
    Color? prioridadeAltaContainer,
    Color? prioridadeMedia,
    Color? prioridadeMediaContainer,
    Color? prioridadeBaixa,
    Color? prioridadeBaixaContainer,
    Color? aberta,
    Color? emAndamento,
    Color? pausada,
    Color? concluida,
    Color? cancelada,
  }) => TemdasSemanticColors(
    prioridadeAlta: prioridadeAlta ?? this.prioridadeAlta,
    prioridadeAltaContainer:
        prioridadeAltaContainer ?? this.prioridadeAltaContainer,
    prioridadeMedia: prioridadeMedia ?? this.prioridadeMedia,
    prioridadeMediaContainer:
        prioridadeMediaContainer ?? this.prioridadeMediaContainer,
    prioridadeBaixa: prioridadeBaixa ?? this.prioridadeBaixa,
    prioridadeBaixaContainer:
        prioridadeBaixaContainer ?? this.prioridadeBaixaContainer,
    aberta: aberta ?? this.aberta,
    emAndamento: emAndamento ?? this.emAndamento,
    pausada: pausada ?? this.pausada,
    concluida: concluida ?? this.concluida,
    cancelada: cancelada ?? this.cancelada,
  );

  @override
  TemdasSemanticColors lerp(TemdasSemanticColors? other, double t) {
    if (other == null) return this;
    return TemdasSemanticColors(
      prioridadeAlta: Color.lerp(prioridadeAlta, other.prioridadeAlta, t)!,
      prioridadeAltaContainer: Color.lerp(
        prioridadeAltaContainer,
        other.prioridadeAltaContainer,
        t,
      )!,
      prioridadeMedia: Color.lerp(prioridadeMedia, other.prioridadeMedia, t)!,
      prioridadeMediaContainer: Color.lerp(
        prioridadeMediaContainer,
        other.prioridadeMediaContainer,
        t,
      )!,
      prioridadeBaixa: Color.lerp(prioridadeBaixa, other.prioridadeBaixa, t)!,
      prioridadeBaixaContainer: Color.lerp(
        prioridadeBaixaContainer,
        other.prioridadeBaixaContainer,
        t,
      )!,
      aberta: Color.lerp(aberta, other.aberta, t)!,
      emAndamento: Color.lerp(emAndamento, other.emAndamento, t)!,
      pausada: Color.lerp(pausada, other.pausada, t)!,
      concluida: Color.lerp(concluida, other.concluida, t)!,
      cancelada: Color.lerp(cancelada, other.cancelada, t)!,
    );
  }
}
