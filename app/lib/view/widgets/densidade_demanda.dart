import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Configuração visual do board, sem persistência ou estado de negócio.
enum DensidadeDemanda {
  normal,
  compacta;

  bool get isCompacta => this == compacta;

  double get larguraMinimaColuna => isCompacta ? 304 : 360;
  double get espacamentoEntreColunas => isCompacta ? 10 : 16;

  double larguraColunaPara(double larguraDisponivel, int quantidadeColunas) {
    // Compacto mantém sua largura também em telas grandes. Normal conserva
    // a distribuição responsiva anterior, com o mínimo de 360 px.
    if (isCompacta) return larguraMinimaColuna;
    return math.max(
      larguraMinimaColuna,
      (larguraDisponivel - espacamentoEntreColunas * (quantidadeColunas - 1)) /
          quantidadeColunas,
    );
  }

  EdgeInsets get paddingPagina => EdgeInsets.all(
    isCompacta ? TemdasTokens.contentGap : TemdasTokens.pagePadding,
  );
  double get recuoPorNivel => isCompacta ? 12 : 20;
  double get recuoMaximo => isCompacta ? 48 : 100;
  double get espacoAposLinhaArvore => isCompacta ? 6 : 10;

  double get alturaMinimaCabecalho => isCompacta ? 48 : 80;
  double get paddingVerticalCabecalho => isCompacta ? 4 : 12;
  double get espacamentoChevron => isCompacta ? 4 : 12;
  EdgeInsets get paddingCabecalho =>
      EdgeInsets.symmetric(horizontal: isCompacta ? 10 : 12);

  EdgeInsets get paddingConteudo => isCompacta
      ? const EdgeInsets.fromLTRB(10, 0, 10, 8)
      : const EdgeInsets.fromLTRB(16, 0, 16, 16);

  double get espacamentoEntreCards => isCompacta ? 6 : 12;
  double get espacamentoEntreCampos => isCompacta ? 4 : 8;
  double get espacamentoEntreSecoes => isCompacta ? 6 : 12;

  EdgeInsets get paddingStatus =>
      EdgeInsets.symmetric(horizontal: 8, vertical: isCompacta ? 4 : 8);

  ButtonStyle? get estiloBotao => isCompacta
      ? const ButtonStyle(
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          minimumSize: WidgetStatePropertyAll(Size(32, 32)),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        )
      : null;
}
