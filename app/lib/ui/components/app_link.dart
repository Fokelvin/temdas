import 'package:flutter/material.dart';

import 'app_link_platform_stub.dart'
    if (dart.library.js_interop) 'app_link_platform_web.dart';

/// A route link with the same Flutter styling and focus behavior as its control.
class AppLink extends StatelessWidget {
  const AppLink({
    super.key,
    required this.route,
    required this.builder,
    this.onFollow,
    this.newTab = false,
  });

  final String route;
  final Widget Function(VoidCallback follow) builder;
  final VoidCallback? onFollow;
  final bool newTab;

  @override
  Widget build(BuildContext context) {
    void follow() {
      if (onFollow case final callback?) {
        callback();
      } else {
        Navigator.of(context).pushNamed(route);
      }
    }

    return buildPlatformLink(route, newTab, follow, (activate) {
      return Semantics(link: true, child: builder(activate));
    });
  }
}
