import 'package:flutter/material.dart';

/// Um único registro de seleção por superfície, inclusive em painéis isolados.
class AppSelection extends StatelessWidget {
  const AppSelection({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      SelectionContainer.maybeOf(context) == null
      ? SelectionArea(child: child)
      : child;
}
