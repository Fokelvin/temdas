import 'package:flutter/widgets.dart';

Widget buildPlatformLink(
  String route,
  bool newTab,
  VoidCallback follow,
  Widget Function(VoidCallback) builder,
) => builder(follow);
