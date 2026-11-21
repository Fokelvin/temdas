import 'dart:js_interop';

import 'package:flutter/rendering.dart' show PlatformViewHitTestBehavior;
import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

Widget buildPlatformLink(
  String route,
  bool newTab,
  VoidCallback follow,
  Widget Function(VoidCallback) builder,
) {
  final base = Uri.parse(web.document.baseURI);
  final href = route == '/' ? base : base.replace(fragment: route);
  final leaveDocument = Uri.base.path != base.path;
  final nativeClick = newTab || leaveDocument;

  void activate() {
    if (newTab) {
      web.window.open(href.toString(), '_blank', 'noopener,noreferrer');
    } else if (leaveDocument) {
      web.window.location.assign(href.toString());
    } else {
      follow();
    }
  }

  return Stack(
    fit: StackFit.passthrough,
    children: [
      builder(activate),
      Positioned.fill(
        child: HtmlElementView.fromTagName(
          key: ValueKey((href, newTab, nativeClick)),
          tagName: 'a',
          isVisible: false,
          hitTestBehavior: PlatformViewHitTestBehavior.transparent,
          onElementCreated: (element) {
            final anchor = element as web.HTMLAnchorElement;
            anchor
              ..href = href.toString()
              ..target = newTab ? '_blank' : '_self'
              ..rel = 'noopener noreferrer'
              ..tabIndex = -1
              ..setAttribute('aria-hidden', 'true');
            anchor.style
              ..display = 'block'
              ..opacity = '0'
              ..width = '100%'
              ..height = '100%'
              ..cursor = 'pointer';

            // Flutter handles ordinary taps and keyboard activation. Keep
            // native mouse gestures on the anchor out of Flutter's tap handling.
            anchor.addEventListener(
              'pointerdown',
              ((web.PointerEvent event) {
                if (nativeClick || event.button != 0 || _modified(event)) {
                  event.stopPropagation();
                }
              }).toJS,
            );
            anchor.addEventListener(
              'click',
              ((web.MouseEvent event) {
                if (!nativeClick && !_modified(event)) {
                  event.preventDefault();
                }
              }).toJS,
            );
            anchor.addEventListener(
              'contextmenu',
              ((web.Event event) => event.stopPropagation()).toJS,
            );
          },
        ),
      ),
    ],
  );
}

bool _modified(web.MouseEvent event) =>
    event.ctrlKey || event.metaKey || event.shiftKey || event.altKey;
