import 'dart:js_interop';

import 'auth_callback_storage_stub.dart'
    show CallbackStorage, sanitizedAuthEntryUri;
export 'auth_callback_storage_stub.dart'
    show CallbackStorage, sanitizedAuthEntryUri;

@JS('window.sessionStorage.getItem')
external JSString? _getItem(String key);

@JS('window.sessionStorage.setItem')
external void _setItem(String key, String value);

@JS('window.sessionStorage.removeItem')
external void _removeItem(String key);

@JS('window.history.replaceState')
external void _replaceState(JSAny? state, String title, String url);

@JS('window.history.state')
external JSAny? get _historyState;

final CallbackStorage browserCallbackStorage = _WebCallbackStorage();

class _WebCallbackStorage implements CallbackStorage {
  @override
  String? read(String key) {
    try {
      return _getItem(key)?.toDart;
    } catch (_) {
      return null;
    }
  }

  @override
  void write(String key, String value) {
    try {
      _setItem(key, value);
    } catch (_) {}
  }

  @override
  void remove(String key) {
    try {
      _removeItem(key);
    } catch (_) {}
  }

  @override
  void clearUrl() {
    try {
      final uri = Uri.base;
      _replaceState(_historyState, '', sanitizedAuthEntryUri(uri).toString());
    } catch (_) {}
  }

  @override
  void leaveCallback() {
    try {
      final uri = Uri.base;
      if (!const {'/auth/callback', '/auth/confirm'}.contains(uri.path)) return;
      _replaceState(
        _historyState,
        '',
        sanitizedAuthEntryUri(uri.replace(path: '/', fragment: '')).toString(),
      );
    } catch (_) {}
  }
}
